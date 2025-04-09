import logging
import threading

import requests
from bs4 import BeautifulSoup

try:
    # noinspection PyPep8Naming
    import Queue as queue  # Python 2
except ImportError:
    import queue  # Python 3

logger = logging.getLogger('UZ_Scraper.Kierunki')


class KierunkiScraper:
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
        """Scrapuje kierunki studiów i zapisuje je do bazy danych."""
        try:
            logger.info("Rozpoczęto scrapowanie kierunków studiów")

            # Pobieranie strony z listą wydziałów
            response = self.session.get(self.base_url)
            soup = BeautifulSoup(response.content, 'html.parser')

            # Wyszukanie linków do wydziałów
            wydzialy_links = soup.select('div.container a[href*="grupy_lista.php"]')
            # noinspection PyCompatibility
            logger.info(f"Znaleziono {len(wydzialy_links)} wydziałów")

            # Dodaj wydziały do kolejki
            for link in wydzialy_links:
                self.task_queue.put((link.get('href'), link.text.strip()))

            # Uruchom wątki
            threads = []
            for i in range(min(self.max_threads, len(wydzialy_links))):
                t = threading.Thread(target=self.worker)
                t.daemon = True
                threads.append(t)
                t.start()

            # Czekaj na zakończenie wszystkich wątków
            self.task_queue.join()

            # noinspection PyCompatibility
            logger.info(
                f"Zakończono scrapowanie kierunków. Zaktualizowano {self.total_updated} kierunków")
            return self.total_updated
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas scrapowania kierunków: {str(e)}")
            raise e

    def worker(self):
        """Funkcja pracownika dla wątku."""
        while True:
            try:
                link, nazwa_wydzialu = self.task_queue.get(block=False)  # non-blocking get
                updated_count = self.scrape_wydzial(link, nazwa_wydzialu)
                with self.lock:
                    self.total_updated += updated_count
                self.task_queue.task_done()
            except queue.Empty:
                break
            except Exception as e:
                # noinspection PyCompatibility
                logger.error(f"Błąd w wątku scrapowania kierunków: {str(e)}")
                self.task_queue.task_done()

    def scrape_wydzial(self, link, nazwa_wydzialu):
        """Scrapuje kierunki dla konkretnego wydziału."""
        try:
            url = link
            if isinstance(url, str) and not url.startswith('http'):
                # noinspection PyCompatibility
                url = f"{self.base_url}/{KierunkiScraper.fix_url(url)}"

            response = self.session.get(url)
            soup = BeautifulSoup(response.content, 'html.parser')

            kierunki_links = soup.select('table.table tr td:first-child a')
            updated_count = 0

            for link in kierunki_links:
                nazwa_kierunku = link.text.strip()
                href = link.get('href')

                if isinstance(href, str) and not href.startswith('http'):
                    if href.startswith('/'):
                        # noinspection PyCompatibility
                        href = f"{self.base_url}{href}"
                    else:
                        # noinspection PyCompatibility
                        href = f"{self.base_url}/{href}"

                kierunek = {
                    "nazwa_kierunku": nazwa_kierunku,
                    "wydzial": nazwa_wydzialu,
                    "link_grupy": href
                }

                self.db.upsert_kierunek(kierunek)
                updated_count += 1

            # noinspection PyCompatibility
            logger.info(
                f"Scrapowanie zakończone dla wydziału {nazwa_wydzialu}. Zaktualizowano {updated_count} kierunków.")
            return updated_count
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas scrapowania wydziału {nazwa_wydzialu}: {str(e)}")
            return 0
