import logging
import re
import threading
import datetime
from urllib.parse import urlparse, parse_qs

import requests
from bs4 import BeautifulSoup

try:
    # noinspection PyPep8Naming
    import Queue as queue  # Python 2
except ImportError:
    import queue  # Python 3

logger = logging.getLogger('UZ_Scraper.Plany')


class PlanyScraper:
    def __init__(self, db, base_url):
        self.db = db
        self.base_url = base_url
        self.session = requests.Session()
        self.task_queue = queue.Queue()
        self.lock = threading.Lock()
        self.total_updated = 0
        self.max_threads = 4  # Zmniejszono liczbę wątków dla stabilności

    def scrape_and_save(self):
        """Scrapuje plany zajęć i zapisuje je do bazy danych."""
        try:
            logger.info("Rozpoczęto scrapowanie planów zajęć")

            # Pobieranie grup z bazy danych
            grupy = self.db.get_grupy()
            logger.info(f"Znaleziono {len(grupy)} grup do scrapowania")

            # Dodaj grupy do kolejki
            for grupa in grupy:
                self.task_queue.put(grupa)

            # Uruchom wątki
            threads = []
            for i in range(min(self.max_threads, len(grupy))):
                t = threading.Thread(target=self.worker)
                t.daemon = True
                threads.append(t)
                t.start()

            # Czekaj na zakończenie wszystkich wątków
            self.task_queue.join()

            logger.info(f"Zakończono scrapowanie planów. Zaktualizowano {self.total_updated} zajęć")
            return self.total_updated
        except Exception as e:
            logger.error(f"Błąd podczas scrapowania planów: {str(e)}")
            raise e

    def worker(self):
        """Funkcja pracownika dla wątku."""
        while True:
            try:
                grupa = self.task_queue.get(block=False)
                updated_count = self.scrape_plan_grupy(grupa)
                with self.lock:
                    self.total_updated += updated_count
                self.task_queue.task_done()
            except queue.Empty:
                break
            except Exception as e:
                logger.error(f"Błąd w wątku scrapowania planów: {str(e)}")
                self.task_queue.task_done()

    def scrape_plan_grupy(self, grupa):
        """Scrapuje plan zajęć dla konkretnej grupy."""
        try:
            link_planu = grupa.get('link_planu', '')
            kod_grupy = grupa.get('kod_grupy', 'Nieznana grupa')
            grupa_id = grupa.get('id')

            # Sprawdzenie czy link jest prawidłowy
            if not link_planu or not isinstance(link_planu, str):
                logger.warning(f"Brak lub nieprawidłowy link dla grupy {kod_grupy}")
                return 0

            # Wyciągnij ID z URL
            parsed_url = urlparse(link_planu)
            query_params = parse_qs(parsed_url.query)
            grupa_id_url = query_params.get('ID', [''])[0]

            if not grupa_id_url:
                logger.warning(f"Nie można wyciągnąć ID z linku: {link_planu}")
                return 0

            # Pełny URL do planu grupy
            plan_url = f"{self.base_url}/grupy_plan.php?ID={grupa_id_url}"

            logger.info(f"Pobieranie planu dla grupy {kod_grupy} z URL: {plan_url}")
            response = self.session.get(plan_url)

            if response.status_code != 200:
                logger.error(f"Błąd HTTP {response.status_code} dla URL: {plan_url}")
                return 0

            soup = BeautifulSoup(response.content, 'html.parser')

            # Pobieranie informacji o semestrze z H3
            h3_element = soup.find('h3')
            if h3_element:
                h3_text = h3_element.get_text(separator='\n')
                h3_lines = h3_text.split('\n')

                if len(h3_lines) >= 3:
                    semestr_line = h3_lines[2].strip()
                    semestr_match = re.search(r'semestr\s+(letni|zimowy)', semestr_line, re.IGNORECASE)

                    if semestr_match:
                        semestr = semestr_match.group(1).lower()  # "letni" lub "zimowy"

                        # Aktualizuj semestr w bazie danych
                        self.db.update_grupa_semestr(grupa_id, semestr)
                        logger.info(f"Zaktualizowano semestr dla grupy {kod_grupy}: {semestr}")

            # Znajdź link do ICS (Google Calendar)
            ics_link = None
            links = soup.find_all('a')
            for link in links:
                href = link.get('href', '')
                if 'grupy_ics.php' in href:
                    ics_link = href
                    break

            # Pobieranie tabeli z planem zajęć
            table = soup.find('table', {'class': 'st1'})
            if not table:
                logger.warning(f"Nie znaleziono tabeli z planem dla grupy {kod_grupy}")
                return 0

            # Analiza planu zajęć i zapisanie do bazy danych
            updated_count = self._parse_plan_table(table, grupa_id, ics_link)

            logger.info(f"Scrapowanie zakończone dla grupy {kod_grupy}. Zaktualizowano {updated_count} zajęć.")
            return updated_count
        except Exception as e:
            logger.error(f"Błąd podczas scrapowania planu dla grupy {grupa.get('kod_grupy', 'Nieznana')}: {str(e)}")
            return 0

    def _parse_plan_table(self, table, grupa_id, ics_link):
        """Parsuje tabelę z planem zajęć i zapisuje dane do bazy danych."""
        try:
            updated_count = 0
            rows = table.find_all('tr')

            if len(rows) < 2:
                logger.warning("Tabela z planem nie zawiera wystarczającej liczby wierszy")
                return 0

            # Iteracja przez wiersze tabeli planu
            for row in rows[1:]:  # Pomijamy nagłówek
                cells = row.find_all('td')
                if len(cells) < 2:
                    continue

                # Pobierz datę i godziny zajęć
                date_col = cells[0].text.strip()
                if not date_col:
                    continue

                # Pobierz wszystkie komórki z zajęciami
                for cell_idx in range(1, len(cells)):
                    cell = cells[cell_idx]

                    # Jeśli komórka jest pusta, przejdź dalej
                    if not cell.text.strip():
                        continue

                    # Parsowanie informacji o zajęciach
                    przedmiot_div = cell.find('div', {'class': 'p'})
                    if not przedmiot_div:
                        continue

                    przedmiot = przedmiot_div.text.strip()

                    # Czas zajęć (format: 11:15-12:00)
                    time_match = re.search(r'(\d+:\d+)-(\d+:\d+)', cell.text)
                    if not time_match:
                        continue

                    od = time_match.group(1)
                    do = time_match.group(2)

                    # Miejsce zajęć
                    miejsce_div = cell.find('div', {'class': 's'})
                    miejsce = miejsce_div.text.strip() if miejsce_div else ""

                    # Rodzaj zajęć (wykład, ćwiczenia, itp.)
                    rz_div = cell.find('div', {'class': 't'})
                    rz = rz_div.text.strip() if rz_div else ""

                    # Prowadzący
                    nauczyciel_a = cell.find('a', href=re.compile(r'nauczyciel_plan\.php'))

                    nauczyciel_id = None
                    if nauczyciel_a:
                        nauczyciel_name = nauczyciel_a.text.strip()
                        nauczyciel_href = nauczyciel_a['href']
                        parsed_url = urlparse(nauczyciel_href)
                        query_params = parse_qs(parsed_url.query)
                        nauczyciel_id_url = query_params.get('ID', [''])[0]

                        # Pobierz lub dodaj nauczyciela do bazy
                        if nauczyciel_id_url:
                            nauczyciel = {
                                'imie_nazwisko': nauczyciel_name,
                                'instytut': 'Do ustalenia',  # Domyślna wartość, zostanie uzupełniona przez nauczyciele_scraper
                                'link_planu': f"{self.base_url}/nauczyciel_plan.php?ID={nauczyciel_id_url}"
                            }

                            nauczyciel_id = self.db.upsert_nauczyciel(nauczyciel)

                    # Przygotowanie wpisu do bazy danych
                    plan_entry = {
                        'grupa_id': grupa_id,
                        'link_ics': ics_link,
                        'nauczyciel_id': nauczyciel_id,
                        'od': od,
                        'do_': do,
                        'przedmiot': przedmiot,
                        'rz': rz,
                        'miejsce': miejsce
                    }

                    # Dodanie wpisu do bazy danych
                    plan_id = self.db.upsert_plan_grupy(plan_entry)
                    if plan_id:
                        updated_count += 1

            return updated_count
        except Exception as e:
            logger.error(f"Błąd podczas parsowania tabeli planu: {str(e)}")
            return 0

    def scrape_plany_nauczycieli(self):
        """Scrapuje plany zajęć dla nauczycieli."""
        try:
            logger.info("Rozpoczęto scrapowanie planów nauczycieli")

            # Pobieranie nauczycieli z bazy danych
            nauczyciele = self.db.get_nauczyciele()
            logger.info(f"Znaleziono {len(nauczyciele)} nauczycieli do scrapowania")

            updated_count = 0

            for nauczyciel in nauczyciele:
                link_planu = nauczyciel.get('link_planu', '')
                if not link_planu:
                    continue

                try:
                    # Pobieranie strony z planem
                    response = self.session.get(link_planu)
                    if response.status_code != 200:
                        continue

                    soup = BeautifulSoup(response.content, 'html.parser')

                    # Znajdź link do ICS
                    ics_link = None
                    links = soup.find_all('a')
                    for link in links:
                        href = link.get('href', '')
                        if 'nauczyciel_ics.php' in href:
                            ics_link = href
                            break

                    # Pobieranie tabeli z planem
                    table = soup.find('table', {'class': 'st1'})
                    if not table:
                        continue

                    # Parsowanie tabeli i zapisanie do bazy
                    table_count = self._parse_nauczyciel_plan_table(table, nauczyciel['id'], ics_link)
                    updated_count += table_count

                except Exception as e:
                    logger.error(f"Błąd podczas scrapowania planu dla nauczyciela {nauczyciel.get('imie_nazwisko')}: {str(e)}")

            logger.info(f"Zakończono scrapowanie planów nauczycieli. Zaktualizowano {updated_count} zajęć")
            return updated_count

        except Exception as e:
            logger.error(f"Błąd podczas scrapowania planów nauczycieli: {str(e)}")
            return 0

    def _parse_nauczyciel_plan_table(self, table, nauczyciel_id, ics_link):
        """Parsuje tabelę z planem zajęć nauczyciela i zapisuje dane do bazy danych."""
        try:
            updated_count = 0
            rows = table.find_all('tr')

            if len(rows) < 2:
                return 0

            # Iteracja przez wiersze tabeli planu
            for row in rows[1:]:  # Pomijamy nagłówek
                cells = row.find_all('td')
                if len(cells) < 2:
                    continue

                # Pobierz datę i godziny zajęć
                date_col = cells[0].text.strip()
                if not date_col:
                    continue

                # Pobierz wszystkie komórki z zajęciami
                for cell_idx in range(1, len(cells)):
                    cell = cells[cell_idx]

                    # Jeśli komórka jest pusta, przejdź dalej
                    if not cell.text.strip():
                        continue

                    # Parsowanie informacji o zajęciach
                    przedmiot_div = cell.find('div', {'class': 'p'})
                    if not przedmiot_div:
                        continue

                    przedmiot = przedmiot_div.text.strip()

                    # Czas zajęć (format: 11:15-12:00)
                    time_match = re.search(r'(\d+:\d+)-(\d+:\d+)', cell.text)
                    if not time_match:
                        continue

                    od = time_match.group(1)
                    do = time_match.group(2)

                    # Miejsce zajęć
                    miejsce_div = cell.find('div', {'class': 's'})
                    miejsce = miejsce_div.text.strip() if miejsce_div else ""

                    # Rodzaj zajęć (wykład, ćwiczenia, itp.)
                    rz_div = cell.find('div', {'class': 't'})
                    rz = rz_div.text.strip() if rz_div else ""

                    # Grupy
                    grupy_div = cell.find_all('a', href=re.compile(r'grupy_plan\.php'))
                    grupy = ", ".join([g.text.strip() for g in grupy_div]) if grupy_div else ""

                    # Przygotowanie wpisu do bazy danych
                    plan_entry = {
                        'nauczyciel_id': nauczyciel_id,
                        'link_ics': ics_link,
                        'od': od,
                        'do_': do,
                        'przedmiot': przedmiot,
                        'rz': rz,
                        'grupy': grupy,
                        'miejsce': miejsce
                    }

                    # Dodanie wpisu do bazy danych
                    plan_id = self.db.upsert_plan_nauczyciela(plan_entry)
                    if plan_id:
                        updated_count += 1

            return updated_count
        except Exception as e:
            logger.error(f"Błąd podczas parsowania tabeli planu nauczyciela: {str(e)}")
            return 0