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

logger = logging.getLogger('UZ_Scraper.Nauczyciele')

class NauczycieleScraper:
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
        """Scrapuje nauczycieli i zapisuje ich do bazy danych."""
        try:
            logger.info("Rozpoczęto scrapowanie nauczycieli")

            # URL do strony z listą nauczycieli
            nauczyciele_url = "{}/nauczyciele_lista.php".format(self.base_url)
            response = self.session.get(nauczyciele_url)
            soup = BeautifulSoup(response.content, 'html.parser')

            # Wyszukanie tabeli z listą nauczycieli
            table = soup.select_one('table.table')
            if not table:
                logger.warning("Nie znaleziono tabeli z nauczycielami")
                return 0

            # Wyszukanie wierszy tabeli (każdy wiersz to jeden nauczyciel)
            rows = table.select('tr')

            # Pierwszy wiersz to nagłówek, więc pomijamy go
            for row in rows[1:]:
                cols = row.select('td')
                if len(cols) < 2:
                    continue

                # Pobieranie linku do planu nauczyciela
                link = cols[0].select_one('a')
                if not link:
                    continue

                # Dodaj nauczyciela do kolejki
                self.task_queue.put((link.text.strip(), link.get('href'), cols[1].text.strip()))

            logger.info("Znaleziono {} nauczycieli do scrapowania".format(self.task_queue.qsize()))

            # Uruchom wątki
            threads = []
            queue_size = self.task_queue.qsize()
            for i in range(min(self.max_threads, queue_size)):
                t = threading.Thread(target=self.worker)
                t.daemon = True
                threads.append(t)
                t.start()

            # Czekaj na zakończenie wszystkich wątków
            self.task_queue.join()

            logger.info("Zakończono scrapowanie nauczycieli. Zaktualizowano {} nauczycieli".format(self.total_updated))
            return self.total_updated
        except Exception as e:
            logger.error("Błąd podczas scrapowania nauczycieli: {}".format(str(e)))
            raise e

    def worker(self):
        """Funkcja pracownika dla wątku."""
        while True:
            try:
                imie_nazwisko, href, instytut = self.task_queue.get(block=False)  # non-blocking get
                result = self.scrape_nauczyciel(imie_nazwisko, href, instytut)
                if result:
                    with self.lock:
                        self.total_updated += 1
                self.task_queue.task_done()
            except queue.Empty:  # Zmienione z Queue.Empty
                break
            except Exception as e:
                logger.error("Błąd w wątku scrapowania nauczycieli: {}".format(str(e)))
                self.task_queue.task_done()

    def scrape_nauczyciel(self, imie_nazwisko, href, instytut):
        """Scrapuje informacje o pojedynczym nauczycielu."""
        try:
            link_planu = href
            if isinstance(link_planu, str) and not link_planu.startswith('http'):  # Dodane sprawdzenie typu
                if link_planu.startswith('/'):
                    link_planu = "{}{}".format(self.base_url, link_planu)
                else:
                    link_planu = "{}/{}".format(self.base_url, NauczycieleScraper.fix_url(link_planu))

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
            logger.error("Błąd podczas scrapowania nauczyciela {}: {}".format(imie_nazwisko, str(e)))
            return False