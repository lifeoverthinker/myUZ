import requests
from bs4 import BeautifulSoup
import logging
import re

logger = logging.getLogger('UZ_Scraper.Kierunki')


class KierunkiScraper:
    def __init__(self, db, base_url):
        self.db = db
        self.base_url = base_url
        self.total_updated = 0

    def scrape_and_save(self):
        """Scrapuje i zapisuje kierunki studiów do bazy danych."""
        logger.info("Rozpoczęto scrapowanie kierunków studiów")
        try:
            url = f"{self.base_url}/grupy_lista_kierunkow.php"
            logger.info(f"Pobieranie danych z URL: {url}")

            response = requests.get(url)
            if response.status_code != 200:
                logger.error(f"Błąd HTTP {response.status_code} podczas pobierania listy kierunków")
                return 0

            soup = BeautifulSoup(response.text, 'html.parser')

            # Znajdź główną listę
            main_list = soup.find('ul', class_='list-group')
            if not main_list:
                logger.error("Nie znaleziono głównej listy grup")
                return 0

            # Znajdź wydziały (bezpośrednie elementy li w głównej liście)
            wydzialy_items = main_list.find_all('li', class_='list-group-item', recursive=False)

            logger.info(f"Znaleziono {len(wydzialy_items)} wydziałów")

            for wydzial_item in wydzialy_items:
                # Pobierz nazwę wydziału (tekst przed zagnieżdżoną listą)
                wydzial_text = wydzial_item.get_text().strip().split('\n')[0]
                wydzial_name = wydzial_text.strip()

                # Znajdź zagnieżdżoną listę kierunków
                kierunki_list = wydzial_item.find('ul', class_='list-group')
                if not kierunki_list:
                    continue

                # Znajdź kierunki w zagnieżdżonej liście
                kierunki_items = kierunki_list.find_all('li', class_='list-group-item')
                logger.info(
                    f"Znaleziono {len(kierunki_items)} kierunków dla wydziału {wydzial_name}")

                for kierunek_item in kierunki_items:
                    link_element = kierunek_item.find('a')
                    if link_element:
                        nazwa_kierunku = link_element.text.strip()
                        link_grupy = link_element['href']

                        kierunek_data = {
                            'nazwa_kierunku': nazwa_kierunku,
                            'wydzial': wydzial_name,
                            'link_grupy': link_grupy
                        }

                        kierunek_id = self.db.upsert_kierunek(kierunek_data)
                        if kierunek_id:
                            self.total_updated += 1
                            logger.info(f"Dodano/zaktualizowano kierunek: {nazwa_kierunku}")

            logger.info(
                f"Zakończono scrapowanie kierunków. Zaktualizowano {self.total_updated} kierunków")
            return self.total_updated
        except Exception as e:
            logger.error(f"Błąd podczas scrapowania kierunków: {str(e)}")
            return 0
