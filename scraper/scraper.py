import requests
from bs4 import BeautifulSoup
import logging
import re
import time
from typing import Dict, List, Any, Optional, Tuple, Set
from collections import defaultdict
from datetime import datetime
import concurrent.futures
from queue import Queue
import threading

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(name)s - %(message)s')
logger = logging.getLogger(__name__)

class PlanUZScraper:
    BASE_URL = "https://plan.uz.zgora.pl"

    # Metadata
    VERSION = "3.0.0"
    LAST_UPDATE = "2025-04-07"
    UPDATED_BY = "lifeoverthinker"

    # Słownik terminów (kody skrótów)
    TERMINY_KODY = {
        "D": "Dni robocze, studia stacjonarne",
        "DI": "Studia stacjonarne I-sza połowa sem.",
        "DII": "Studia stacjonarne II-ga połowa sem.",
        "DN": "Studia stacjonarne Nieparzyste",
        "DP": "Studia stacjonarne Parzyste",
        "WPA": "Wydział Nauk Prawnych i Ekonomicznych - terminy zjazdów"
    }

    # Limity wielowątkowości
    MAX_WORKERS = 10  # Maksymalna liczba równoległych wątków
    REQUEST_DELAY = 0.2  # Opóźnienie między zapytaniami (w sekundach) dla uniknięcia rate limiting

    def __init__(self):
        self._session_local = threading.local()  # Sesja dla każdego wątku osobno

        # Cache dla kierunków i wydziałów
        self._kierunki_cache = None
        self._wydzialy_cache = None

        # Cache dla terminów - używamy thread-safe Dictionary
        self._terminy_kalendarzy_lock = threading.Lock()
        self._terminy_kalendarzy_cache = {}

        # Rate limiting - używamy Semaphore
        self._request_semaphore = threading.BoundedSemaphore(self.MAX_WORKERS)

        # Timestamp rozpoczęcia
        self.scrape_timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")

        logger.info(f"Inicjalizacja scrapera PlanUZ v{self.VERSION}")
        logger.info(f"Data aktualizacji: {self.LAST_UPDATE}, Autor: {self.UPDATED_BY}")
        logger.info(f"Rozpoczęcie scrapowania: {self.scrape_timestamp}")
        logger.info(f"Konfiguracja wielowątkowości: Maksymalna liczba wątków: {self.MAX_WORKERS}")

    @property
    def session(self):
        """Thread-local session dla bezpiecznych zapytań HTTP z wielu wątków"""
        if not hasattr(self._session_local, 'session'):
            self._session_local.session = requests.Session()
        return self._session_local.session

    def get_metadata(self) -> Dict[str, str]:
        """Zwraca metadane o scraperze"""
        return {
            "version": self.VERSION,
            "last_update": self.LAST_UPDATE,
            "updated_by": self.UPDATED_BY,
            "scrape_timestamp": self.scrape_timestamp
        }

    def _make_request(self, url: str) -> requests.Response:
        """Wykonuje zapytanie HTTP z uwzględnieniem rate limiting"""
        with self._request_semaphore:
            time.sleep(self.REQUEST_DELAY)  # Minimalne opóźnienie między zapytaniami
            return self.session.get(url)

    def get_kierunki(self) -> List[Dict[str, str]]:
        """Pobiera listę kierunków"""
        # Ta funkcja nie jest uruchamiana wielowątkowo, bo jest wywoływana tylko raz
        url = f"{self.BASE_URL}/grupy_lista_kierunkow.php"
        logger.info(f"Pobieranie listy kierunków z {url}")

        response = self._make_request(url)
        soup = BeautifulSoup(response.text, 'html.parser')

        kierunki = []

        # Znajdujemy główny kontener
        main_container = soup.find('div', class_='container main')
        if not main_container:
            logger.error("Nie znaleziono głównego kontenera na stronie")
            return []

        # Znajdujemy wszystkie elementy wydziałów (li na najwyższym poziomie)
        wydzialy_elements = [li for li in main_container.find_all('li', class_='list-group-item', recursive=False)]

        for wydzial_element in wydzialy_elements:
            # Pobierz tylko bezpośredni tekst wydziału, bez zagnieżdżonych elementów
            wydzial_text_direct = ''.join([text for text in wydzial_element.find_all(text=True, recursive=False) if text.strip()])
            wydzial_text = wydzial_text_direct.strip()

            # Jeśli nie udało się pobrać bezpośredniego tekstu, użyj innej metody
            if not wydzial_text:
                # Spróbuj pobrać tekst z pierwszego strong lub b
                bold_element = wydzial_element.find(['strong', 'b'])
                if bold_element:
                    wydzial_text = bold_element.get_text(strip=True)
                else:
                    # Ostatecznie, użyj pierwszej linii tekstu
                    wydzial_text = wydzial_element.get_text(strip=True).split('\n')[0].strip()

            # Znajdź podlistę kierunków dla tego wydziału
            kierunki_list = wydzial_element.find('ul', class_='list-group')
            if kierunki_list:
                for kierunek_li in kierunki_list.find_all('li', class_='list-group-item'):
                    kierunek_a = kierunek_li.find('a')
                    if kierunek_a:
                        href = kierunek_a.get('href', '')
                        match = re.search(r'ID=(\d+)', href)
                        if match:
                            kierunek_id = match.group(1)
                            nazwa_kierunku = kierunek_a.text.strip()

                            # Określ typ kierunku
                            typ_kierunku = "standardowy"
                            if "studia podyplomowe" in nazwa_kierunku.lower():
                                typ_kierunku = "podyplomowe"
                            elif "erasmus" in nazwa_kierunku.lower():
                                typ_kierunku = "erasmus"

                            kierunki.append({
                                'nazwa_kierunku': nazwa_kierunku,
                                'wydzial': wydzial_text,
                                'link_grupy': href,
                                'kierunek_id': kierunek_id,
                                'typ_kierunku': typ_kierunku
                            })

        # Zapisujemy do cache
        self._kierunki_cache = kierunki
        logger.info(f"Znaleziono {len(kierunki)} kierunków")
        return kierunki

    def get_grupy(self, kierunek_link: str) -> List[Dict[str, str]]:
        """Pobiera listę grup dla danego kierunku"""
        url = f"{self.BASE_URL}/{kierunek_link}"
        logger.info(f"Pobieranie grup z {url}")

        response = self._make_request(url)
        soup = BeautifulSoup(response.text, 'html.parser')

        grupy = []
        current_semestr = ""

        for element in soup.find_all(['h3', 'a']):
            if element.name == 'h3':
                current_semestr = element.text.strip()
            elif element.name == 'a':
                href = element.get('href', '')
                if 'grupy_plan.php' in href:
                    pelna_nazwa_grupy = element.text.strip()

                    # Wyodrębnij kod grupy (część przed pierwszą spacją)
                    # Przykład: "31AW-SP Architektura wnętrz..." -> "31AW-SP"
                    match = re.match(r'^(\S+)', pelna_nazwa_grupy)
                    kod_grupy = match.group(1) if match else pelna_nazwa_grupy

                    # Określ tryb studiów
                    tryb = "stacjonarne"
                    if "niestacjonarne" in pelna_nazwa_grupy.lower():
                        tryb = "niestacjonarne"

                    match = re.search(r'ID=(\d+)', href)
                    if match:
                        grupa_id = match.group(1)
                        grupy.append({
                            'nazwa_grupy': pelna_nazwa_grupy,
                            'kod_grupy': kod_grupy,
                            'semestr': current_semestr,
                            'tryb_studiow': tryb,
                            'link_planu': href,
                            'grupa_id': grupa_id,
                            'data_aktualizacji': self.scrape_timestamp
                        })

        logger.info(f"Znaleziono {len(grupy)} grup dla kierunku {kierunek_link}")
        return grupy

    def get_plan_grupy(self, grupa_link: str) -> Dict[str, Any]:
        """Pobiera plan dla danej grupy oraz link do ICS"""
        url = f"{self.BASE_URL}/{grupa_link}"
        logger.info(f"Pobieranie planu z {url}")

        response = self._make_request(url)
        soup = BeautifulSoup(response.text, 'html.parser')

        # Pobierz kod grupy bezpośrednio z nagłówka H2
        kod_grupy = ""
        h2_elements = soup.find_all('h2')
        if len(h2_elements) >= 2:  # Drugi H2 zawiera zawsze kod grupy
            kod_grupy = h2_elements[1].text.strip()
            logger.info(f"Znaleziono kod grupy: {kod_grupy}")

        # Pobierz link do ICS
        ics_link = ""
        ics_element = soup.find('a', id='idGG')
        if ics_element:
            ics_link = ics_element.get('href', '')

        # Pobierz linki do nauczycieli
        nauczyciele = []
        for a_tag in soup.find_all('a'):
            href = a_tag.get('href', '')
            if 'nauczyciel_plan.php' in href:
                match = re.search(r'ID=(\d+)', href)
                if match:
                    nauczyciel_id = match.group(1)
                    nauczyciele.append({
                        'link': href,
                        'nazwa': a_tag.text.strip(),
                        'nauczyciel_id': nauczyciel_id
                    })

        # Pobierz plan zajęć z tabelą i terminami
        wydarzenia = []
        tabela_plan = soup.find('table', class_='table-bordered')
        if tabela_plan:
            for wiersz in tabela_plan.find_all('tr', class_=lambda x: x and ('even' in x or 'odd' in x)):
                # Pomiń ewentualne nagłówki bez danych
                if not wiersz.find('td'):
                    continue

                # Pobierz dane o zajęciach
                komorki = wiersz.find_all('td')
                if len(komorki) >= 8:  # Musi być co najmniej 8 kolumn
                    try:
                        # Pobierz informację o podgrupie (PG)
                        podgrupa = komorki[0].text.strip()
                        if podgrupa in ["Â", "&nbsp;", ""] or podgrupa.isspace():
                            podgrupa = ""

                        od = komorki[1].text.strip()
                        do = komorki[2].text.strip()
                        przedmiot = komorki[3].text.strip()

                        # Pobierz pełny kod rodzaju zajęć (może być dłuższy niż 1 znak)
                        typ_zajec_element = komorki[4].find('label')
                        typ_zajec = ""
                        typ_zajec_opis = ""

                        if typ_zajec_element:
                            typ_zajec = typ_zajec_element.text.strip()
                            # Pobierz także pełny opis typu zajęć z atrybutu title
                            title = typ_zajec_element.get('title', '')
                            if title:
                                # Usuń znaczniki HTML z title
                                title = re.sub(r'<[^>]+>', '', title)
                                # Wyizoluj opis po myślniku
                                title_parts = title.split('-')
                                if len(title_parts) > 1:
                                    typ_zajec_opis = title_parts[1].strip()
                                else:
                                    typ_zajec_opis = title.strip()

                        # Pobierz prowadzących - może być kilku
                        prowadzacy_cell = komorki[5]
                        prowadzacy = [a.text.strip() for a in prowadzacy_cell.find_all('a')]
                        prowadzacy_str = "; ".join(prowadzacy)

                        # Pobierz miejsce - może być kilka
                        miejsce_cell = komorki[6]
                        miejsca = [a.text.strip() for a in miejsce_cell.find_all('a')]
                        miejsca_raw = miejsce_cell.text.strip()
                        if not miejsca:
                            miejsca = [miejsca_raw]
                        miejsce_str = "; ".join(miejsca)

                        # Pobierz terminy zajęć
                        terminy_cell = komorki[7]
                        terminy_text = terminy_cell.text.strip()
                        terminy_link = terminy_cell.find('a')

                        terminy = ""
                        kalendarz_id = None

                        if terminy_link:
                            terminy_text = terminy_link.text.strip()
                            # Pobierz ID kalendarza jeśli jest link
                            kalendarz_match = re.search(r'ID=(\d+)', terminy_link.get('href', ''))
                            if kalendarz_match:
                                kalendarz_id = kalendarz_match.group(1)

                        # Przetwórz terminy
                        if terminy_text:
                            if ";" in terminy_text:  # Lista konkretnych dat
                                terminy = terminy_text
                            elif terminy_text in self.TERMINY_KODY:  # Znany kod terminu
                                terminy = self.TERMINY_KODY[terminy_text]
                            elif kalendarz_id:  # Link do kalendarza - pobierz szczegóły
                                kalendarz_daty = self.get_kalendarz_terminy(kalendarz_id)
                                if kalendarz_daty:
                                    terminy = "; ".join(kalendarz_daty)
                            else:
                                terminy = terminy_text

                        # Dodaj wydarzenie do listy
                        wydarzenie = {
                            'od': od,
                            'do': do,
                            'przedmiot': przedmiot,
                            'typ_zajec': typ_zajec,
                            'typ_zajec_pelny': typ_zajec_opis,
                            'prowadzacy': prowadzacy_str,
                            'miejsce': miejsce_str,
                            'terminy': terminy,
                            'kalendarz_id': kalendarz_id,
                            'podgrupa': podgrupa
                        }
                        wydarzenia.append(wydarzenie)
                    except Exception as e:
                        logger.error(f"Błąd podczas parsowania wiersza: {str(e)}")

        return {
            'kod_grupy': kod_grupy,
            'link_ics': ics_link,
            'nauczyciele': nauczyciele,
            'wydarzenia': wydarzenia,
            'data_aktualizacji': self.scrape_timestamp
        }

    def get_kalendarz_terminy(self, kalendarz_id: str) -> List[str]:
        """Pobiera terminy z kalendarza dla danego ID"""
        # Najpierw sprawdź cache
        with self._terminy_kalendarzy_lock:
            if kalendarz_id in self._terminy_kalendarzy_cache:
                return self._terminy_kalendarzy_cache[kalendarz_id]

        url = f"{self.BASE_URL}/kalendarze_lista_szczegoly.php?ID={kalendarz_id}"
        logger.info(f"Pobieranie terminów z kalendarza {url}")

        response = self._make_request(url)
        soup = BeautifulSoup(response.text, 'html.parser')

        daty = []
        tabela = soup.find('table', class_='table-bordered')
        if tabela:
            for wiersz in tabela.find_all('tr', class_=lambda x: x and ('even' in x or 'odd' in x)):
                komorki = wiersz.find_all('td')
                if len(komorki) >= 2:
                    data_cell = komorki[1]
                    if data_cell:
                        data = data_cell.text.strip()
                        if re.match(r'\d{4}-\d{2}-\d{2}', data):  # Sprawdź format daty
                            daty.append(data)

        # Zapisz do cache
        with self._terminy_kalendarzy_lock:
            self._terminy_kalendarzy_cache[kalendarz_id] = daty

        return daty

    def get_nauczyciel_info(self, nauczyciel_link: str) -> Dict[str, str]:
        """Pobiera informacje o nauczycielu"""
        url = f"{self.BASE_URL}/{nauczyciel_link}"
        logger.info(f"Pobieranie informacji o nauczycielu z {url}")

        response = self._make_request(url)
        soup = BeautifulSoup(response.text, 'html.parser')

        imie_nazwisko = soup.find('h2').text.strip() if soup.find('h2') else ""
        instytut = soup.find('h3').text.strip() if soup.find('h3') else ""

        email = ""
        email_tag = soup.find('a', href=re.compile(r'^mailto:'))
        if email_tag:
            email = email_tag.get('href', '').replace('mailto:', '')

        ics_link = ""
        for a_tag in soup.find_all('a'):
            href = a_tag.get('href', '')
            if 'nauczyciel_ics.php' in href:
                ics_link = href
                break

        return {
            'imie_nazwisko': imie_nazwisko,
            'instytut': instytut,
            'email': email,
            'link_ics': ics_link,
            'data_aktualizacji': self.scrape_timestamp
        }

    def download_ics(self, ics_url: str) -> str:
        """Pobiera plik ICS"""
        full_url = f"{self.BASE_URL}/{ics_url}" if not ics_url.startswith('http') else ics_url
        logger.info(f"Pobieranie pliku ICS z {full_url}")

        response = self._make_request(full_url)
        return response.text

    # --- METODY WIELOWĄTKOWE ---

    def get_all_grupy_multi(self, kierunki: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Pobiera grupy dla wielu kierunków równolegle"""
        wszystkie_grupy = []

        with concurrent.futures.ThreadPoolExecutor(max_workers=self.MAX_WORKERS) as executor:
            futures = {executor.submit(self.get_grupy, kierunek['link_grupy']): kierunek for kierunek in kierunki}

            for future in concurrent.futures.as_completed(futures):
                kierunek = futures[future]
                try:
                    grupy = future.result()
                    # Dodajemy do każdej grupy informacje o kierunku
                    for grupa in grupy:
                        grupa['kierunek_nazwa'] = kierunek['nazwa_kierunku']
                        grupa['kierunek_id'] = kierunek['kierunek_id']
                        grupa['wydzial'] = kierunek['wydzial']
                    wszystkie_grupy.extend(grupy)
                    logger.info(f"Pobrano {len(grupy)} grup dla kierunku {kierunek['nazwa_kierunku']}")
                except Exception as e:
                    logger.error(f"Błąd podczas pobierania grup dla kierunku {kierunek['nazwa_kierunku']}: {str(e)}")

        logger.info(f"Łącznie pobrano {len(wszystkie_grupy)} grup")
        return wszystkie_grupy

    def get_all_plany_grup_multi(self, grupy: List[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
        """Pobiera plany zajęć dla wielu grup równolegle"""
        plany_grup = {}

        with concurrent.futures.ThreadPoolExecutor(max_workers=self.MAX_WORKERS) as executor:
            futures = {executor.submit(self.get_plan_grupy, grupa['link_planu']): grupa for grupa in grupy}

            for future in concurrent.futures.as_completed(futures):
                grupa = futures[future]
                try:
                    plan = future.result()
                    plany_grup[grupa['link_planu']] = plan
                    logger.info(f"Pobrano plan zajęć dla grupy {grupa['nazwa_grupy']}")
                except Exception as e:
                    logger.error(f"Błąd podczas pobierania planu dla grupy {grupa['nazwa_grupy']}: {str(e)}")

        logger.info(f"Pobrano plany zajęć dla {len(plany_grup)} grup")
        return plany_grup

    def get_all_nauczyciele_multi(self, plany_grup: Dict[str, Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
        """Pobiera informacje o nauczycielach równolegle"""
        nauczyciele = {}
        nauczyciele_do_pobrania = set()

        # Najpierw zbierz wszystkich unikalnych nauczycieli
        for plan in plany_grup.values():
            for nauczyciel in plan.get('nauczyciele', []):
                nauczyciele_do_pobrania.add((nauczyciel['link'], nauczyciel['nazwa']))

        logger.info(f"Znaleziono {len(nauczyciele_do_pobrania)} unikalnych nauczycieli do pobrania")

        with concurrent.futures.ThreadPoolExecutor(max_workers=self.MAX_WORKERS) as executor:
            futures = {executor.submit(self.get_nauczyciel_info, link): (link, nazwa)
                       for link, nazwa in nauczyciele_do_pobrania}

            for future in concurrent.futures.as_completed(futures):
                link, nazwa = futures[future]
                try:
                    info = future.result()
                    nauczyciele[link] = info
                    logger.info(f"Pobrano informacje o nauczycielu {nazwa}")
                except Exception as e:
                    logger.error(f"Błąd podczas pobierania informacji o nauczycielu {nazwa}: {str(e)}")

        logger.info(f"Pobrano informacje o {len(nauczyciele)} nauczycielach")
        return nauczyciele

    # --- GŁÓWNE METODY SCRAPERA ---

    def scrapuj_wszystko(self) -> Dict[str, Any]:
        """Główna metoda uruchamiająca pełny proces scrapowania"""
        start_time = time.time()
        logger.info("Rozpoczynanie pełnego procesu scrapowania")

        # 1. Pobieramy kierunki
        kierunki = self.get_kierunki()

        # 2. Pobieramy grupy równolegle
        grupy = self.get_all_grupy_multi(kierunki)

        # 3. Pobieramy plany grup równolegle
        plany_grup = self.get_all_plany_grup_multi(grupy)

        # 4. Pobieramy informacje o nauczycielach równolegle
        nauczyciele = self.get_all_nauczyciele_multi(plany_grup)

        elapsed_time = time.time() - start_time
        logger.info(f"Zakończono pełny proces scrapowania w {elapsed_time:.2f} sekund")

        return {
            'kierunki': kierunki,
            'grupy': grupy,
            'plany_grup': plany_grup,
            'nauczyciele': nauczyciele,
            'statystyki': {
                'czas_wykonania': f"{elapsed_time:.2f} s",
                'liczba_kierunkow': len(kierunki),
                'liczba_grup': len(grupy),
                'liczba_planow': len(plany_grup),
                'liczba_nauczycieli': len(nauczyciele)
            }
        }

    # --- POMOCNICZE METODY ---

    def get_kierunki_by_wydzial(self) -> Dict[str, List[Dict[str, str]]]:
        """Zwraca kierunki pogrupowane według wydziałów"""
        if not self._kierunki_cache:
            self.get_kierunki()

        wydzialy = defaultdict(list)
        for kierunek in self._kierunki_cache:
            wydzialy[kierunek['wydzial']].append(kierunek)

        # Sortuj kierunki w każdym wydziale
        for wydzial in wydzialy:
            wydzialy[wydzial].sort(key=lambda k: k['nazwa_kierunku'])

        return dict(wydzialy)

    def get_wydzialy(self) -> List[str]:
        """Zwraca listę wszystkich wydziałów"""
        if not self._wydzialy_cache:
            wydzialy = set()
            if not self._kierunki_cache:
                self.get_kierunki()

            for kierunek in self._kierunki_cache:
                wydzialy.add(kierunek['wydzial'])

            self._wydzialy_cache = sorted(list(wydzialy))

        return self._wydzialy_cache