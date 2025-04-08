import logging
import re
from bs4 import BeautifulSoup
import requests
import threading
import sys
from datetime import datetime

# Kompatybilność z Python 2.7 i Python 3.x
if sys.version_info[0] >= 3:
    import queue
else:
    import Queue as queue

logger = logging.getLogger('UZ_Scraper.Plany')

class PlanyScraper:
    def __init__(self, db, base_url):
        self.db = db
        self.base_url = base_url
        self.session = requests.Session()
        self.max_threads = 16
        self.queue_grupy = queue.Queue()  # Zmieniona nazwa dla klarowności
        self.queue_nauczyciele = queue.Queue()  # Zmieniona nazwa dla klarowności
        self.lock = threading.Lock()
        self.total_updated = 0

    @staticmethod
    def fix_url(url):
        """Poprawia nieprawidłowy URL."""
        if isinstance(url, str) and url.startswith('/'):  # Dodane sprawdzenie typu
            url = url[1:]
            logger.warning("Naprawiono nieprawidłowy URL: {}".format(url))
        return url

    @staticmethod
    def parse_time(time_str):
        """Konwertuje string reprezentujący czas na timestamp."""
        # Zakładamy, że time_str to coś w formacie "HH:MM"
        if not time_str or ':' not in time_str:
            raise ValueError("Nieprawidłowy format czasu: {}".format(time_str))

        hour, minute = map(int, time_str.split(':'))

        # Używamy bieżącej daty jako bazy
        now = datetime.now()
        dt = datetime(now.year, now.month, now.day, hour, minute)

        return dt

    def scrape_and_save(self):
        try:
            self.total_updated = 0

            # Pobieranie planów dla grup
            grupy = self.db.get_grupy()
            if grupy:
                logger.info("Rozpoczęto scrapowanie planów dla {} grup".format(len(grupy)))

                # Dodaj grupy do kolejki
                for grupa in grupy:
                    if grupa.get('link_planu'):
                        self.queue_grupy.put(grupa)

                # Uruchom wątki dla grup
                grupa_threads = []
                for i in range(min(self.max_threads, self.queue_grupy.qsize())):
                    t = threading.Thread(target=self.worker_grupa)
                    t.daemon = True
                    grupa_threads.append(t)
                    t.start()

                # Czekaj na zakończenie wszystkich wątków dla grup
                self.queue_grupy.join()

                logger.info("Zakończono scrapowanie planów dla grup")

            # Pobieranie planów dla nauczycieli
            nauczyciele = self.db.get_nauczyciele()
            if nauczyciele:
                logger.info("Rozpoczęto scrapowanie planów dla {} nauczycieli".format(len(nauczyciele)))

                # Dodaj nauczycieli do kolejki
                for nauczyciel in nauczyciele:
                    if nauczyciel.get('link_planu'):
                        self.queue_nauczyciele.put(nauczyciel)

                # Uruchom wątki dla nauczycieli
                nauczyciel_threads = []
                for i in range(min(self.max_threads, self.queue_nauczyciele.qsize())):
                    t = threading.Thread(target=self.worker_nauczyciel)
                    t.daemon = True
                    nauczyciel_threads.append(t)
                    t.start()

                # Czekaj na zakończenie wszystkich wątków dla nauczycieli
                self.queue_nauczyciele.join()

                logger.info("Zakończono scrapowanie planów dla nauczycieli")

            logger.info("Zakończono scrapowanie planów. Zaktualizowano {} wpisów w planach".format(self.total_updated))
            return self.total_updated
        except Exception as e:
            logger.error("Błąd podczas scrapowania planów: {}".format(str(e)))
            raise e

    def worker_grupa(self):
        """Funkcja pracownika dla wątku grup."""
        while True:
            try:
                grupa = self.queue_grupy.get(block=False)  # non-blocking get
                entries_added = self.scrape_plan_grupy(grupa)
                with self.lock:
                    self.total_updated += entries_added
                self.queue_grupy.task_done()
            except queue.Empty:  # Zmienione z Queue.Empty
                break
            except Exception as e:
                logger.error("Błąd w wątku scrapowania planu grupy: {}".format(str(e)))
                self.queue_grupy.task_done()

    def worker_nauczyciel(self):
        """Funkcja pracownika dla wątku nauczycieli."""
        while True:
            try:
                nauczyciel = self.queue_nauczyciele.get(block=False)  # non-blocking get
                entries_added = self.scrape_plan_nauczyciela(nauczyciel)
                with self.lock:
                    self.total_updated += entries_added
                self.queue_nauczyciele.task_done()
            except queue.Empty:  # Zmienione z Queue.Empty
                break
            except Exception as e:
                logger.error("Błąd w wątku scrapowania planu nauczyciela: {}".format(str(e)))
                self.queue_nauczyciele.task_done()

    def scrape_plan_grupy(self, grupa):
        """Scrapuje plan zajęć dla określonej grupy."""
        try:
            logger.info("Scrapowanie planu dla grupy: {}".format(grupa['kod_grupy']))

            link_planu = grupa['link_planu']
            if isinstance(link_planu, str) and not link_planu.startswith('http'):  # Dodane sprawdzenie typu
                link_planu = PlanyScraper.fix_url(link_planu)
                if not link_planu.startswith('http'):
                    link_planu = "{}/{}".format(self.base_url, link_planu)

            # Pobieranie strony planu grupy
            response = self.session.get(link_planu)
            soup = BeautifulSoup(response.content, 'html.parser')

            # Wyszukanie tabeli z planem
            table = soup.select_one('table#table_groups')
            if not table:
                logger.warning("Nie znaleziono tabeli z planem dla grupy: {}".format(grupa['kod_grupy']))
                return 0

            # Wyszukanie linku do pliku ICS
            ics_links = soup.select('a[href*="grupy_ics.php"]')
            ics_link = None
            for link in ics_links:
                if 'Microsoft' in link.text or 'Zimbra' in link.text:
                    ics_link = link.get('href')
                    break

            if not ics_link:
                logger.warning("Nie znaleziono linku ICS dla grupy: {}".format(grupa['kod_grupy']))
            elif isinstance(ics_link, str) and not ics_link.startswith('http'):  # Dodane sprawdzenie typu
                if ics_link.startswith('/'):
                    ics_link = "{}{}".format(self.base_url, ics_link)
                else:
                    ics_link = "{}/{}".format(self.base_url, ics_link)

            # Parsowanie wierszy tabeli
            rows = table.select('tr:not(.gray)')
            entries_added = 0

            for row in rows:
                cols = row.select('td')
                if len(cols) < 7:  # Pomijanie wierszy bez wystarczającej liczby kolumn
                    continue

                # Pobieranie danych o zajęciach
                from_time = cols[1].text.strip()
                to_time = cols[2].text.strip()
                przedmiot = cols[3].text.strip()
                rz = cols[4].text.strip()

                # Pobieranie ID nauczyciela
                nauczyciel_id = None
                nauczyciel_link = cols[5].select_one('a[href*="nauczyciel_plan.php"]')
                if nauczyciel_link:
                    href = nauczyciel_link.get('href')
                    id_match = re.search(r'ID=(\d+)', href)
                    if id_match:
                        # Sprawdź, czy nauczyciel istnieje w bazie
                        temp_id = id_match.group(1)
                        nauczyciel = self.db.get_nauczyciel_by_external_id(temp_id)
                        if nauczyciel:
                            nauczyciel_id = nauczyciel['id']

                # Pobieranie miejsca zajęć
                miejsce = cols[6].text.strip()

                # Konwersja czasów na timestamp
                try:
                    od_time = PlanyScraper.parse_time(from_time)
                    do_time = PlanyScraper.parse_time(to_time)
                except ValueError as e:
                    logger.warning("Błąd parsowania czasu dla zajęć '{}': {}".format(przedmiot, str(e)))
                    continue

                # Tworzenie wpisu w planie grupy
                plan_entry = {
                    "grupa_id": grupa['id'],
                    "link_ics": ics_link,
                    "nauczyciel_id": nauczyciel_id,
                    "od": od_time,
                    "do_": do_time,
                    "przedmiot": przedmiot,
                    "rz": rz,
                    "miejsce": miejsce
                }

                # Zapis do bazy danych
                result_id = self.db.upsert_plan_grupy(plan_entry)
                if result_id:
                    entries_added += 1

            logger.info("Zakończono scrapowanie planu dla grupy: {}. Dodano {} wpisów".format(grupa['kod_grupy'], entries_added))
            return entries_added
        except Exception as e:
            logger.error("Błąd podczas scrapowania planu dla grupy {}: {}".format(grupa['kod_grupy'], str(e)))
            return 0

    def scrape_plan_nauczyciela(self, nauczyciel):
        """Scrapuje plan zajęć dla określonego nauczyciela."""
        try:
            logger.info("Scrapowanie planu dla nauczyciela: {}".format(nauczyciel['imie_nazwisko']))

            link_planu = nauczyciel['link_planu']
            if isinstance(link_planu, str) and not link_planu.startswith('http'):  # Dodane sprawdzenie typu
                link_planu = PlanyScraper.fix_url(link_planu)
                if not link_planu.startswith('http'):
                    link_planu = "{}/{}".format(self.base_url, link_planu)

            # Pobieranie strony planu nauczyciela
            response = self.session.get(link_planu)
            soup = BeautifulSoup(response.content, 'html.parser')

            # Wyszukanie tabeli z planem
            table = soup.select_one('table#table_groups')
            if not table:
                logger.warning("Nie znaleziono tabeli z planem dla nauczyciela: {}".format(nauczyciel['imie_nazwisko']))
                return 0

            # Wyszukanie linku do pliku ICS
            ics_links = soup.select('a[href*="nauczyciel_ics.php"]')
            ics_link = None
            for link in ics_links:
                if 'Microsoft' in link.text or 'Zimbra' in link.text:
                    ics_link = link.get('href')
                    break

            if not ics_link:
                logger.warning("Nie znaleziono linku ICS dla nauczyciela: {}".format(nauczyciel['imie_nazwisko']))
            elif isinstance(ics_link, str) and not ics_link.startswith('http'):  # Dodane sprawdzenie typu
                if ics_link.startswith('/'):
                    ics_link = "{}{}".format(self.base_url, ics_link)
                else:
                    ics_link = "{}/{}".format(self.base_url, ics_link)

            # Parsowanie wierszy tabeli
            rows = table.select('tr:not(.gray)')
            entries_added = 0

            for row in rows:
                cols = row.select('td')
                if len(cols) < 7:  # Pomijanie wierszy bez wystarczającej liczby kolumn
                    continue

                # Pobieranie danych o zajęciach
                from_time = cols[1].text.strip()
                to_time = cols[2].text.strip()
                przedmiot = cols[3].text.strip()
                rz = cols[4].text.strip()

                # Pobieranie informacji o grupach
                grupy = cols[5].text.strip()

                # Pobieranie miejsca zajęć
                miejsce = cols[6].text.strip()

                # Konwersja czasów na timestamp
                try:
                    od_time = PlanyScraper.parse_time(from_time)
                    do_time = PlanyScraper.parse_time(to_time)
                except ValueError as e:
                    logger.warning("Błąd parsowania czasu dla zajęć '{}': {}".format(przedmiot, str(e)))
                    continue

                # Tworzenie wpisu w planie nauczyciela
                plan_entry = {
                    "nauczyciel_id": nauczyciel['id'],
                    "link_ics": ics_link,
                    "od": od_time,
                    "do_": do_time,
                    "przedmiot": przedmiot,
                    "rz": rz,
                    "grupy": grupy,
                    "miejsce": miejsce
                }

                # Zapis do bazy danych
                result_id = self.db.upsert_plan_nauczyciela(plan_entry)
                if result_id:
                    entries_added += 1

            logger.info("Zakończono scrapowanie planu dla nauczyciela: {}. Dodano {} wpisów".format(nauczyciel['imie_nazwisko'], entries_added))
            return entries_added
        except Exception as e:
            logger.error("Błąd podczas scrapowania planu dla nauczyciela {}: {}".format(nauczyciel['imie_nazwisko'], str(e)))
            return 0