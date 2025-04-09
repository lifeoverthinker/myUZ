import logging
import threading
from typing import Optional

import requests
from bs4 import BeautifulSoup

try:
    # noinspection PyPep8Naming
    import Queue as queue  # Python 2
except ImportError:
    import queue  # Python 3

logger = logging.getLogger('UZ_Scraper.Grupy')


class GrupyScraper:
    def __init__(self, db, base_url):
        self.db = db
        self.base_url = base_url
        self.session = requests.Session()
        self.task_queue = queue.Queue()
        self.lock = threading.Lock()
        self.total_updated = 0
        self.max_threads = 8

    @staticmethod
    def fix_url(url: Optional[str]) -> str:
        """Poprawia nieprawidłowy URL."""
        if url is None:
            return ""
        if isinstance(url, str) and url.startswith('/'):
            url = url[1:]
        return url

    def scrape_and_save(self):
        """Scrapuje grupy zajęciowe i zapisuje je do bazy danych."""
        try:
            logger.info("Rozpoczęto scrapowanie grup zajęciowych")

            # Pobieranie kierunków z bazy danych
            kierunki = self.db.get_all_kierunki()
            logger.info("Znaleziono {len(kierunki)} kierunków do scrapowania")

            # Dodaj kierunki do kolejki
            for kierunek in kierunki:
                self.task_queue.put(kierunek)

            # Uruchom wątki
            threads = []
            for i in range(min(self.max_threads, len(kierunki))):
                t = threading.Thread(target=self.worker)
                t.daemon = True
                threads.append(t)
                t.start()

            # Czekaj na zakończenie wszystkich wątków
            self.task_queue.join()

            logger.info("Zakończono scrapowanie grup. Zaktualizowano {self.total_updated} grup")
            return self.total_updated
        except Exception as e:
            logger.error("Błąd podczas scrapowania grup: {str(e)}")
            raise e

    def worker(self):
        """Funkcja pracownika dla wątku."""
        while True:
            try:
                kierunek = self.task_queue.get(block=False)
                updated_count = self.scrape_kierunek(kierunek)
                with self.lock:
                    self.total_updated += updated_count
                self.task_queue.task_done()
            except queue.Empty:
                break
            except Exception as e:
                logger.error("Błąd w wątku scrapowania grup: {str(e)}")
                self.task_queue.task_done()

    def scrape_kierunek(self, kierunek):
        """Scrapuje grupy dla konkretnego kierunku."""
        try:
            link_grupy = kierunek.get('link_grupy', '')
            nazwa_kierunku = kierunek.get('nazwa_kierunku', 'Nieznany kierunek')

            # Sprawdzenie czy link jest prawidłowy
            if not link_grupy or not isinstance(link_grupy, str):
                logger.warning("Brak lub nieprawidłowy link dla kierunku {nazwa_kierunku}")
                return 0

            # Pobieranie strony z grupami
            response = self.session.get(link_grupy)
            soup = BeautifulSoup(response.content, 'html.parser')

            grupy_links = soup.select('table.table tr td:first-child a')
            updated_count = 0

            for link in grupy_links:
                nazwa_grupy = link.text.strip()
                href = link.get('href', '')

                # Sprawdzenie czy href jest stringiem
                if not isinstance(href, str):
                    continue

                # Tworzenie pełnego URL
                if not href.startswith('http'):
                    if href.startswith('/'):
                        href = "{self.base_url}{href}"
                    else:
                        href = "{self.base_url}/{GrupyScraper.fix_url(href)}"

                grupa = {
                    "nazwa_grupy": nazwa_grupy,
                    "kierunek_id": kierunek.get('id'),
                    "link_plan": href
                }

                self.db.upsert_grupa(grupa)
                updated_count += 1

            logger.info(
                "Scrapowanie zakończone dla kierunku {nazwa_kierunku}. Zaktualizowano {updated_count} grup.")
            return updated_count
        except Exception as e:
            logger.error(
                "Błąd podczas scrapowania kierunku {kierunek.get('nazwa_kierunku', 'Nieznany')}: {str(e)}")
            return 0
