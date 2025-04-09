import logging
import re
from bs4 import BeautifulSoup
import requests
import threading

try:
    import Queue as queue  # Python 2
except ImportError:
    import queue  # Python 3

logger = logging.getLogger('UZ_Scraper.Grupy')

class GrupyScraper:
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
            logger.warning("Naprawiono nieprawidłowy URL: {}".format(url))
        return url

    def scrape_and_save(self):
        """
        Scrapuje grupy i zapisuje je do bazy danych.
        Zwraca liczbę zaktualizowanych grup.
        """
        try:
            self.total_updated = 0
            kierunki = self.db.get_kierunki()

            if not kierunki:
                logger.warning("Nie znaleziono żadnych kierunków w bazie danych")
                return 0

            # Dodaj kierunki do kolejki
            for kierunek in kierunki:
                if kierunek.get('link_grupy'):
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

            logger.info("Zakończono scrapowanie grup. Zaktualizowano {} grup".format(self.total_updated))
            return self.total_updated
        except Exception as e:
            logger.error("Błąd podczas scrapowania grup: {}".format(str(e)))
            raise e

    def worker(self):
        """Funkcja pracownika dla wątku."""
        while True:
            try:
                kierunek = self.task_queue.get(block=False)  # non-blocking get
                self.scrape_kierunek(kierunek)
                self.task_queue.task_done()
            except queue.Empty:  # Zmienione z Queue.Empty
                break
            except Exception as e:
                logger.error("Błąd w wątku scrapowania grup: {}".format(str(e)))
                self.task_queue.task_done()

    def scrape_kierunek(self, kierunek):
        """Scrapuje grupy dla jednego kierunku."""
        logger.info("Scrapowanie grup dla kierunku: {}".format(kierunek['nazwa_kierunku']))

        link_grupy = kierunek['link_grupy']
        if isinstance(link_grupy, str) and not link_grupy.startswith('http'):  # Dodane sprawdzenie typu
            link_grupy = self.fix_url(link_grupy)
            if not link_grupy.startswith('http'):
                link_grupy = "{}/{}".format(self.base_url, link_grupy)

        response = self.session.get(link_grupy)
        soup = BeautifulSoup(response.content, 'html.parser')

        grupy_links = soup.select('table.table a')
        logger.info("Znaleziono łącznie {} grup dla kierunku {}".format(len(grupy_links), kierunek['nazwa_kierunku']))

        kierunek_updated = 0
        for link in grupy_links:
            nazwa_grupy = link.text.strip()
            # Wyciągamy tylko krótki kod grupy (przed pierwszą spacją)
            kod_grupy = nazwa_grupy.split(" ", 1)[0]

            href = link.get('href')
            if isinstance(href, str) and not href.startswith('http'):  # Dodane sprawdzenie typu
                if href.startswith('/'):
                    href = "{}{}".format(self.base_url, href)
                else:
                    href = "{}/{}".format(self.base_url, href)

            # Parsowanie strony grupy, aby pobrać dodatkowe informacje
            grupa_response = self.session.get(href)
            grupa_soup = BeautifulSoup(grupa_response.content, 'html.parser')

            # Pobieranie informacji o semestrze
            h3_text = ""
            h3_tag = grupa_soup.find('h3')
            if h3_tag:
                h3_text = h3_tag.text.strip()

            # Wyciąganie informacji o trybie studiów
            tryb_match = re.search(r'(stacjonarne|niestacjonarne)', h3_text)
            tryb_studiow = tryb_match.group(1) if tryb_match else None

            # Wyciąganie informacji o semestrze
            semestr_match = re.search(r'semestr\s+(\w+)\s+(\d{4}/\d{4})', h3_text)
            semestr = "{} {}".format(semestr_match.group(1), semestr_match.group(2)) if semestr_match else None

            # Przygotowanie danych grupy - tylko z krótkim kodem
            grupa = {
                "kod_grupy": kod_grupy,  # Tylko krótki kod, np. "11AW-SP"
                "kierunek_id": kierunek['id'],
                "link_planu": href,
                "tryb_studiow": tryb_studiow,
                "semestr": semestr
            }

            # Zapisywanie danych grupy
            self.db.upsert_grupa(grupa)
            kierunek_updated += 1

        # Aktualizacja licznika globalnego
        with self.lock:
            self.total_updated += kierunek_updated