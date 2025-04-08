import logging
import re
from bs4 import BeautifulSoup
import requests
import threading
import sys

# Kompatybilność z Python 2.7 i Python 3.x
if sys.version_info[0] >= 3:
    import queue
else:
    import Queue as queue

logger = logging.getLogger('UZ_Scraper.Kierunki')

class KierunkiScraper:
    def __init__(self, db, base_url):
        self.db = db
        self.base_url = base_url
        self.session = requests.Session()
        self.task_queue = queue.Queue()  # Zmieniona nazwa dla klarowności
        self.lock = threading.Lock()
        self.total_updated = 0
        self.max_threads = 8

    @staticmethod
    def fix_url(url):
        """Poprawia nieprawidłowy URL."""
        if isinstance(url, str) and url.startswith('/'):  # Dodane sprawdzenie typu
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
            logger.info("Znaleziono {} wydziałów".format(len(wydzialy_links)))

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

            logger.info("Zakończono scrapowanie kierunków. Zaktualizowano {} kierunków".format(self.total_updated))
            return self.total_updated
        except Exception as e:
            logger.error("Błąd podczas scrapowania kierunków: {}".format(str(e)))
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
            except queue.Empty:  # Zmienione z Queue.Empty
                break
            except Exception as e:
                logger.error("Błąd w wątku scrapowania kierunków: {}".format(str(e)))
                self.task_queue.task_done()

    def scrape_wydzial(self, link, nazwa_wydzialu):
        """Scrapuje kierunki dla konkretnego wydziału."""
        try:
            url = link
            if isinstance(url, str) and not url.startswith('http'):  # Dodane sprawdzenie typu
                url = "{}/{}".format(self.base_url, KierunkiScraper.fix_url(url))

            response = self.session.get(url)
            soup = BeautifulSoup(response.content, 'html.parser')

            kierunki_links = soup.select('table.table tr td:first-child a')
            updated_count = 0

            for link in kierunki_links:
                nazwa_kierunku = link.text.strip()
                href = link.get('href')

                if isinstance(href, str) and not href.startswith('http'):  # Dodane sprawdzenie typu
                    if href.startswith('/'):
                        href = "{}{}".format(self.base_url, href)
                    else:
                        href = "{}/{}".format(self.base_url, href)

                kierunek = {
                    "nazwa_kierunku": nazwa_kierunku,
                    "wydzial": nazwa_wydzialu,
                    "link_grupy": href
                }

                self.db.upsert_kierunek(kierunek)
                updated_count += 1

            logger.info("Scrapowanie zakończone dla wydziału {}. Zaktualizowano {} kierunków.".format(
                nazwa_wydzialu, updated_count
            ))
            return updated_count
        except Exception as e:
            logger.error("Błąd podczas scrapowania wydziału {}: {}".format(nazwa_wydzialu, str(e)))
            return 0