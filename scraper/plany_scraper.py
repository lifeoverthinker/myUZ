import logging
import re
import threading

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
        self.max_threads = 8

    @staticmethod
    def fix_url(url):
        """Poprawia nieprawidłowy URL."""
        if isinstance(url, str) and url.startswith('/'):
            url = url[1:]
        return url

    def scrape_and_save(self):
        """Scrapuje plany zajęć i zapisuje je do bazy danych."""
        try:
            logger.info("Rozpoczęto scrapowanie planów zajęć")

            # Pobieranie grup z bazy danych
            grupy = self.db.get_all_grupy()
            # noinspection PyCompatibility
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

            # noinspection PyCompatibility
            logger.info(f"Zakończono scrapowanie planów. Zaktualizowano {self.total_updated} zajęć")
            return self.total_updated
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas scrapowania planów: {str(e)}")
            raise e

    def worker(self):
        """Funkcja pracownika dla wątku."""
        while True:
            try:
                grupa = self.task_queue.get(block=False)
                updated_count = self.scrape_plan(grupa)
                with self.lock:
                    self.total_updated += updated_count
                self.task_queue.task_done()
            except queue.Empty:
                break
            except Exception as e:
                # noinspection PyCompatibility
                logger.error(f"Błąd w wątku scrapowania planów: {str(e)}")
                self.task_queue.task_done()

    def scrape_plan(self, grupa):
        """Scrapuje plan zajęć dla konkretnej grupy."""
        try:
            link_plan = grupa.get('link_plan', '')
            nazwa_grupy = grupa.get('nazwa_grupy', 'Nieznana grupa')

            # Sprawdzenie czy link jest prawidłowy
            if not link_plan or not isinstance(link_plan, str):
                # noinspection PyCompatibility
                logger.warning(f"Brak lub nieprawidłowy link dla grupy {nazwa_grupy}")
                return 0

            # Pobieranie strony z planem
            response = self.session.get(link_plan)
            soup = BeautifulSoup(response.content, 'html.parser')

            # Pobieranie tabeli z planem zajęć
            table = soup.select_one('table.tabela')
            if not table:
                # noinspection PyCompatibility
                logger.warning(f"Nie znaleziono tabeli z planem dla grupy {nazwa_grupy}")
                return 0

            # Analiza planu zajęć i zapisanie do bazy danych
            updated_count = self._parse_plan_table(table, grupa)

            # noinspection PyCompatibility
            logger.info(
                f"Scrapowanie zakończone dla grupy {nazwa_grupy}. Zaktualizowano {updated_count} zajęć.")
            return updated_count
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(
                f"Błąd podczas scrapowania planu dla grupy {grupa.get('nazwa_grupy', 'Nieznana')}: {str(e)}")
            return 0

    def _parse_plan_table(self, table, grupa):
        """Parsuje tabelę z planem zajęć i zapisuje dane do bazy danych."""
        try:
            updated_count = 0
            rows = table.select('tr')

            # Pobieranie nagłówków (dni tygodnia)
            headers = rows[0].select('th')
            days = [h.text.strip() for h in headers[1:]]  # Pierwszy nagłówek to godziny

            # Parsowanie wierszy z zajęciami
            for row_idx, row in enumerate(rows[1:], 1):
                cols = row.select('td')
                if not cols:
                    continue

                # Pobieranie godzin zajęć
                time_cell = cols[0].text.strip()
                time_match = re.match(r'(\d+):(\d+)-(\d+):(\d+)', time_cell)
                if not time_match:
                    continue

                start_hour, start_min, end_hour, end_min = map(int, time_match.groups())

                # Parsowanie zajęć dla każdego dnia tygodnia
                for day_idx, day in enumerate(days, 1):
                    if day_idx >= len(cols):
                        continue

                    cell = cols[day_idx]
                    if not cell.text.strip():
                        continue  # Pusta komórka

                    # Parsowanie informacji o zajęciach
                    zajecia_elements = cell.select('span.przedmiot')
                    for element in zajecia_elements:
                        nazwa_zajec = element.text.strip()

                        # Pobieranie informacji o prowadzącym
                        prowadzacy_element = element.find_next('span', class_='nauczyciel')
                        prowadzacy = prowadzacy_element.text.strip() if prowadzacy_element else None

                        # Pobieranie informacji o sali
                        sala_element = element.find_next('span', class_='sala')
                        sala = sala_element.text.strip() if sala_element else None

                        # Tworzenie rekordu zajęć
                        # noinspection PyCompatibility
                        zajecia = {
                            "grupa_id": grupa.get('id'),
                            "dzien_tygodnia": day,
                            "godzina_start": f"{start_hour:02d}:{start_min:02d}",
                            "godzina_koniec": f"{end_hour:02d}:{end_min:02d}",
                            "nazwa_zajec": nazwa_zajec,
                            "prowadzacy": prowadzacy,
                            "sala": sala
                        }

                        # Zapisanie zajęć do bazy danych
                        self.db.upsert_zajecia(zajecia)
                        updated_count += 1

            return updated_count
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas parsowania tabeli planu: {str(e)}")
            return 0
