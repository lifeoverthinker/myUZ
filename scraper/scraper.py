import requests
from bs4 import BeautifulSoup
import logging
import re
from typing import Dict, List, Any, Optional, Tuple
from collections import defaultdict
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class PlanUZScraper:
    BASE_URL = "https://plan.uz.zgora.pl"

    # Metadata
    VERSION = "2.1.0"
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

    def __init__(self):
        self.session = requests.Session()
        # Cache dla kierunków posortowanych według wydziałów
        self._kierunki_cache = None
        self._wydzialy_cache = None
        self._terminy_kalendarzy_cache = {}  # Cache dla terminów wydziałów (ID -> lista dat)
        self.scrape_timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")

        logger.info(f"Inicjalizacja scrapera PlanUZ v{self.VERSION}")
        logger.info(f"Data aktualizacji: {self.LAST_UPDATE}, Autor: {self.UPDATED_BY}")
        logger.info(f"Rozpoczęcie scrapowania: {self.scrape_timestamp}")

    def get_metadata(self) -> Dict[str, str]:
        """Zwraca metadane o scraperze"""
        return {
            "version": self.VERSION,
            "last_update": self.LAST_UPDATE,
            "updated_by": self.UPDATED_BY,
            "scrape_timestamp": self.scrape_timestamp
        }

    def get_kierunki(self) -> List[Dict[str, str]]:
        """Pobiera listę kierunków"""
        url = f"{self.BASE_URL}/grupy_lista_kierunkow.php"
        logger.info(f"Pobieranie listy kierunków z {url}")

        response = self.session.get(url)
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

        response = self.session.get(url)
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

        logger.info(f"Znaleziono {len(grupy)} grup")
        return grupy

    def get_plan_grupy(self, grupa_link: str) -> Dict[str, Any]:
        """Pobiera plan dla danej grupy oraz link do ICS"""
        url = f"{self.BASE_URL}/{grupa_link}"
        logger.info(f"Pobieranie planu z {url}")

        response = self.session.get(url)
        soup = BeautifulSoup(response.text, 'html.parser')

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
                        od = komorki[1].text.strip()
                        do = komorki[2].text.strip()
                        przedmiot = komorki[3].text.strip()
                        typ_zajec = komorki[4].find('label').text.strip() if komorki[4].find('label') else ""

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
                            'prowadzacy': prowadzacy_str,
                            'miejsce': miejsce_str,
                            'terminy': terminy,
                            'kalendarz_id': kalendarz_id
                        }
                        wydarzenia.append(wydarzenie)
                    except Exception as e:
                        logger.error(f"Błąd podczas parsowania wiersza: {str(e)}")

        return {
            'link_ics': ics_link,
            'nauczyciele': nauczyciele,
            'wydarzenia': wydarzenia,
            'data_aktualizacji': self.scrape_timestamp
        }

    def get_kalendarz_terminy(self, kalendarz_id: str) -> List[str]:
        """Pobiera terminy z kalendarza dla danego ID"""
        # Najpierw sprawdź cache
        if kalendarz_id in self._terminy_kalendarzy_cache:
            return self._terminy_kalendarzy_cache[kalendarz_id]

        url = f"{self.BASE_URL}/kalendarze_lista_szczegoly.php?ID={kalendarz_id}"
        logger.info(f"Pobieranie terminów z kalendarza {url}")

        response = self.session.get(url)
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
        self._terminy_kalendarzy_cache[kalendarz_id] = daty
        return daty

    def get_nauczyciel_info(self, nauczyciel_link: str) -> Dict[str, str]:
        """Pobiera informacje o nauczycielu"""
        url = f"{self.BASE_URL}/{nauczyciel_link}"
        logger.info(f"Pobieranie informacji o nauczycielu z {url}")

        response = self.session.get(url)
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

    def get_nauczyciel_plan(self, nauczyciel_link: str) -> Dict[str, Any]:
        """Pobiera plan zajęć nauczyciela z terminami"""
        url = f"{self.BASE_URL}/{nauczyciel_link}"
        logger.info(f"Pobieranie planu zajęć nauczyciela z {url}")

        response = self.session.get(url)
        soup = BeautifulSoup(response.text, 'html.parser')

        # Pobierz link do ICS
        ics_link = ""
        for a_tag in soup.find_all('a'):
            href = a_tag.get('href', '')
            if 'nauczyciel_ics.php' in href:
                ics_link = href
                break

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
                        od = komorki[1].text.strip()
                        do = komorki[2].text.strip()
                        przedmiot = komorki[3].text.strip()
                        typ_zajec = komorki[4].find('label').text.strip() if komorki[4].find('label') else ""

                        # Pobierz grupy - może być kilka
                        grupy_cell = komorki[5]
                        grupy = [a.text.strip() for a in grupy_cell.find_all('a')]
                        grupy_str = "; ".join(grupy)

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
                            'grupy': grupy_str,
                            'miejsce': miejsce_str,
                            'terminy': terminy,
                            'kalendarz_id': kalendarz_id
                        }
                        wydarzenia.append(wydarzenie)
                    except Exception as e:
                        logger.error(f"Błąd podczas parsowania wiersza: {str(e)}")

        return {
            'link_ics': ics_link,
            'wydarzenia': wydarzenia,
            'data_aktualizacji': self.scrape_timestamp
        }

    def download_ics(self, ics_url: str) -> str:
        """Pobiera plik ICS"""
        full_url = f"{self.BASE_URL}/{ics_url}" if not ics_url.startswith('http') else ics_url
        logger.info(f"Pobieranie pliku ICS z {full_url}")

        response = self.session.get(full_url)
        return response.text

    # --- METODY OBSŁUGI ICS ---

    def parse_ics_and_enrich(self, ics_content: str, plan_html: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Parsuje plik ICS i wzbogaca go o terminy z planu HTML"""
        from datetime import datetime
        import re

        wydarzenia_ics = []
        wydarzenia_html = {self._create_event_key(e): e for e in plan_html.get('wydarzenia', [])}

        current_event = None
        for line in ics_content.splitlines():
            line = line.strip()

            if line == "BEGIN:VEVENT":
                current_event = {}
            elif line == "END:VEVENT" and current_event:
                # Wzbogać wydarzenie o terminy z HTML
                key = self._create_event_key(current_event)
                if key in wydarzenia_html:
                    current_event['terminy'] = wydarzenia_html[key].get('terminy', '')

                wydarzenia_ics.append(current_event)
                current_event = None
            elif current_event is not None and ":" in line:
                key, value = line.split(":", 1)

                # Przetwarzanie daty i czasu
                if key == "DTSTART":
                    # Format: 20250402T104000
                    try:
                        dt = datetime.strptime(value, "%Y%m%dT%H%M%S")
                        current_event["od"] = dt.strftime("%H:%M:%S")
                        current_event["data"] = dt.strftime("%Y-%m-%d")
                    except ValueError:
                        current_event["od"] = value
                elif key == "DTEND":
                    try:
                        dt = datetime.strptime(value, "%Y%m%dT%H%M%S")
                        current_event["do"] = dt.strftime("%H:%M:%S")
                    except ValueError:
                        current_event["do"] = value
                elif key == "SUMMARY":
                    # Przykład: "Animacja obrazu graficznego (Ć): mgr Joanna Fuczko"
                    self._parse_summary(current_event, value)
                elif key == "LOCATION":
                    current_event["miejsce"] = value
                elif key == "CATEGORIES":
                    current_event["typ_zajec"] = value

        return wydarzenia_ics

    def _parse_summary(self, event: Dict[str, Any], summary: str) -> None:
        """Parsuje pole SUMMARY i wypełnia odpowiednie pola w event"""
        # Przykład: "Animacja obrazu graficznego (Ć): mgr Joanna Fuczko"
        match = re.match(r"(.*?)\s*(\([^)]+\))?\s*:?\s*(.*)", summary)

        if match:
            przedmiot, typ_zajec, prowadzacy = match.groups()

            event["przedmiot"] = przedmiot.strip() if przedmiot else ""

            if typ_zajec:
                # Usunięcie nawiasów
                event["typ_zajec"] = typ_zajec.strip("() ")

            event["prowadzacy"] = prowadzacy.strip() if prowadzacy else ""
        else:
            # Jeśli nie udało się sparsować, zachowaj oryginalne SUMMARY
            event["przedmiot"] = summary

    def _create_event_key(self, event: Dict[str, Any]) -> str:
        """Tworzy unikalny klucz dla wydarzenia bazując na przedmiocie, czasie i typie zajęć"""
        przedmiot = event.get('przedmiot', '')
        od = event.get('od', '')
        typ_zajec = event.get('typ_zajec', '')
        return f"{przedmiot}_{od}_{typ_zajec}".lower().replace(' ', '_')

    # --- METODY SEGREGACJI I WYSZUKIWANIA ---

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

    def get_statystyki(self) -> Dict[str, Any]:
        """Zwraca statystyki dotyczące kierunków i grup"""
        if not self._kierunki_cache:
            self.get_kierunki()

        # Liczba kierunków według typu
        typy_kierunkow = defaultdict(int)
        for kierunek in self._kierunki_cache:
            typy_kierunkow[kierunek.get('typ_kierunku', 'standardowy')] += 1

        # Liczba kierunków według wydziału
        kierunki_wg_wydzialu = defaultdict(int)
        for kierunek in self._kierunki_cache:
            kierunki_wg_wydzialu[kierunek['wydzial']] += 1

        return {
            'liczba_kierunkow': len(self._kierunki_cache),
            'liczba_wydzialow': len(self.get_wydzialy()),
            'typy_kierunkow': dict(typy_kierunkow),
            'kierunki_wg_wydzialu': dict(kierunki_wg_wydzialu),
            'data_aktualizacji': self.scrape_timestamp
        }

    def search_kierunki(self, query: str) -> List[Dict[str, str]]:
        """Wyszukuje kierunki według podanej frazy"""
        if not self._kierunki_cache:
            self.get_kierunki()

        query = query.lower()
        results = []

        for kierunek in self._kierunki_cache:
            if (query in kierunek['nazwa_kierunku'].lower() or
                    query in kierunek['wydzial'].lower()):
                results.append(kierunek)

        return sorted(results, key=lambda k: (k['wydzial'], k['nazwa_kierunku']))

    def get_kierunek_by_id(self, kierunek_id: str) -> Optional[Dict[str, str]]:
        """Znajduje kierunek po ID"""
        if not self._kierunki_cache:
            self.get_kierunki()

        for kierunek in self._kierunki_cache:
            if kierunek['kierunek_id'] == kierunek_id:
                return kierunek

        return None