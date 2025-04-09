import logging
import threading

import requests
from bs4 import BeautifulSoup

try:
    # noinspection PyPep8Naming
    import Queue as queue  # Python 2
except ImportError:
    import queue  # Python 3

logger = logging.getLogger('UZ_Scraper.Nauczyciele')


class NauczycieleScraper:
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
        """Scrapuje nauczycieli i zapisuje ich do bazy danych."""
        try:
            logger.info("Rozpoczęto scrapowanie nauczycieli")

            # Pobieranie strony z listą instytutów
            response = self.session.get("{self.base_url}/nauczyciele.php")
            soup = BeautifulSoup(response.content, 'html.parser')

            # Wyszukanie wszystkich tabel z nauczycielami (każda tabela to jeden instytut)
            tables = soup.select('div.container table.table')

            for table in tables:
                instytut = table.find_previous('h3').text.strip()
                rows = table.select('tr')

                for row in rows[1:]:  # Pomijamy nagłówek tabeli
                    cols = row.select('td')
                    if len(cols) >= 2:
                        link = cols[0].select_one('a')
                        if link:
                            imie_nazwisko = link.text.strip()
                            href = link.get('href', '')
                            self.task_queue.put((imie_nazwisko, href, instytut))

            # Uruchom wątki
            threads = []
            for i in range(self.max_threads):
                t = threading.Thread(target=self.worker)
                t.daemon = True
                threads.append(t)
                t.start()

            # Czekaj na zakończenie wszystkich wątków
            self.task_queue.join()

            logger.info(
                "Zakończono scrapowanie nauczycieli. Zaktualizowano {self.total_updated} nauczycieli")
            return self.total_updated
        except Exception as e:
            logger.error("Błąd podczas scrapowania nauczycieli: {str(e)}")
            raise e

    def worker(self):
        """Funkcja pracownika dla wątku."""
        while True:
            # noinspection PyBroadException
            try:
                imie_nazwisko, href, instytut = self.task_queue.get(block=False)
                success = self.scrape_nauczyciel(imie_nazwisko, href, instytut)
                if success:
                    with self.lock:
                        self.total_updated += 1
                self.task_queue.task_done()
            except queue.Empty:
                break
            except Exception as e:
                logger.error("Błąd w wątku scrapowania nauczycieli: {str(e)}")
                self.task_queue.task_done()

    def scrape_nauczyciel(self, imie_nazwisko, href, instytut):
        """Scrapuje informacje o pojedynczym nauczycielu."""
        # noinspection PyBroadException
        try:
            link_planu = href
            if isinstance(link_planu, str) and not link_planu.startswith('http'):
                if link_planu.startswith('/'):
                    link_planu = "{self.base_url}{link_planu}"
                else:
                    link_planu = "{self.base_url}/{NauczycieleScraper.fix_url(link_planu)}"

            # Pobieranie strony nauczyciela
            response = self.session.get(link_planu)
            soup = BeautifulSoup(response.content, 'html.parser')

            # Pobieranie adresu email (jeśli dostępny)
            email = None
            email_link = soup.select_one('a[href^="mailto:"]')
            if email_link:
                email = email_link.get('href').replace('mailto:', '')

            # Tworzenie wpisu nauczyciela
            nauczyciel = {
                "imie_nazwisko": imie_nazwisko,
                "instytut": instytut,
                "email": email,
                "link_planu": link_planu
            }

            # Zapis do bazy danych
            self.db.upsert_nauczyciel(nauczyciel)
            return True
        except Exception as e:
            logger.error("Błąd podczas scrapowania nauczyciela {imie_nazwisko}: {str(e)}")
            return False
