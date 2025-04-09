import requests
from bs4 import BeautifulSoup
import logging
import re
from urllib.parse import urlparse, parse_qs

logger = logging.getLogger('UZ_Scraper.Nauczyciele')


class NauczycieleScraper:
    def __init__(self, db, base_url):
        self.db = db
        self.base_url = base_url
        self.total_updated = 0
        self.visited_nauczyciele = set()

    def scrape_and_save(self):
        """Scrapuje i zapisuje nauczycieli do bazy danych."""
        logger.info("Rozpoczęto scrapowanie nauczycieli")

        # Pobieramy nauczycieli z planów grup
        grupy = self.db.get_grupy()
        logger.info(f"Znaleziono {len(grupy)} grup do przetworzenia")

        try:
            for grupa in grupy:
                link_planu = grupa.get('link_planu')
                if not link_planu:
                    continue

                # Wyciągnij ID grupy z URL
                parsed_url = urlparse(link_planu)
                query_params = parse_qs(parsed_url.query)
                grupa_id_url = query_params.get('ID', [''])[0]

                if not grupa_id_url:
                    continue

                grupa_plan_url = f"{self.base_url}/grupy_plan.php?ID={grupa_id_url}"
                try:
                    response = requests.get(grupa_plan_url)
                    if response.status_code != 200:
                        logger.error(f"Błąd HTTP {response.status_code} dla URL: {grupa_plan_url}")
                        continue

                    soup = BeautifulSoup(response.text, 'html.parser')
                    # Znajdź linki do planów nauczycieli
                    nauczyciel_links = soup.find_all('a', href=re.compile(
                        r'nauczyciel_plan\.php\?ID=\d+'))

                    for link in nauczyciel_links:
                        nauczyciel_url = link['href']
                        nauczyciel_name = link.text.strip()

                        # Wyciągnij ID nauczyciela z URL
                        parsed_url = urlparse(nauczyciel_url)
                        query_params = parse_qs(parsed_url.query)
                        nauczyciel_id_url = query_params.get('ID', [''])[0]

                        if not nauczyciel_id_url or nauczyciel_id_url in self.visited_nauczyciele:
                            continue

                        self.visited_nauczyciele.add(nauczyciel_id_url)

                        # Pobierz szczegóły nauczyciela
                        self.scrape_and_save_nauczyciel(nauczyciel_id_url, nauczyciel_name)

                except Exception as e:
                    logger.error(
                        f"Błąd podczas przetwarzania planu grupy {grupa.get('kod_grupy')}: {str(e)}")

            logger.info(
                f"Zakończono scrapowanie nauczycieli. Zaktualizowano {self.total_updated} nauczycieli")
            return self.total_updated

        except Exception as e:
            logger.error(f"Błąd podczas scrapowania nauczycieli: {str(e)}")
            return 0

    def scrape_and_save_nauczyciel(self, nauczyciel_id_url, nauczyciel_name=None):
        """Scrapuje szczegóły nauczyciela na podstawie ID."""
        try:
            nauczyciel_url = f"{self.base_url}/nauczyciel_plan.php?ID={nauczyciel_id_url}"
            response = requests.get(nauczyciel_url)

            if response.status_code != 200:
                logger.error(f"Błąd HTTP {response.status_code} dla URL: {nauczyciel_url}")
                return None

            soup = BeautifulSoup(response.text, 'html.parser')

            # Pobierz imię i nazwisko z drugiego nagłówka H2, jeśli nie zostało podane
            if not nauczyciel_name:
                h2_elements = soup.find_all('h2')
                if len(h2_elements) > 1:  # Bierzemy drugi element H2
                    nauczyciel_name = h2_elements[1].text.strip()

            # Pobierz informacje o instytucie z H3
            instytut_element = soup.find('h3')
            instytut = instytut_element.text.strip() if instytut_element else ""

            # Pobierz email z H4
            email_element = soup.find('h4')
            email = ""
            if email_element:
                mail_link = email_element.find('a', href=re.compile(r'mailto:'))
                if mail_link:
                    email = mail_link['href'].replace('mailto:', '')

            if nauczyciel_name and instytut:
                nauczyciel_data = {
                    'imie_nazwisko': nauczyciel_name,
                    'instytut': instytut,
                    'email': email,
                    'link_planu': nauczyciel_url
                }

                nauczyciel_id = self.db.upsert_nauczyciel(nauczyciel_data)
                if nauczyciel_id:
                    self.total_updated += 1
                    return nauczyciel_id

            return None

        except Exception as e:
            logger.error(
                f"Błąd podczas scrapowania szczegółów nauczyciela {nauczyciel_id_url}: {str(e)}")
            return None
