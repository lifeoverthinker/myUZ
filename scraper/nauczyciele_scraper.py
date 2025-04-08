"""
Moduł do pobierania danych o nauczycielach
Autor: lifeoverthinker
Data: 2025-04-08
"""

import re
import logging
import requests
from bs4 import BeautifulSoup
from datetime import datetime, UTC
from typing import Dict

logger = logging.getLogger(__name__)

class NauczycieleScraper:
    """Klasa do pobierania informacji o nauczycielach"""

    BASE_URL = "https://plan.uz.zgora.pl"

    def __init__(self):
        self.session = requests.Session()
        self.scrape_timestamp = datetime.now(UTC).strftime("%Y-%m-%d %H:%M:%S")

    def get_nauczyciel_info(self, nauczyciel_link: str) -> Dict[str, str]:
        """
        Pobiera informacje o nauczycielu

        Args:
            nauczyciel_link: Link do profilu nauczyciela

        Returns:
            Słownik z danymi nauczyciela
        """
        url = f"{self.BASE_URL}/{nauczyciel_link}"
        logger.info(f"Pobieranie informacji o nauczycielu z {url}")

        try:
            response = self.session.get(url)
            response.raise_for_status()

            soup = BeautifulSoup(response.text, 'html.parser')

            # Pobierz imię i nazwisko z nagłówka H2
            imie_nazwisko = ""
            h2_element = soup.find('h2')
            if h2_element:
                imie_nazwisko = h2_element.text.strip()

            # Pobierz instytut z nagłówka H3
            instytut = ""
            h3_element = soup.find('h3')
            if h3_element:
                instytut = h3_element.text.strip()

            # Pobierz email z linku mailto
            email = ""
            email_element = soup.find('a', href=lambda href_attr: href_attr and href_attr.startswith('mailto:'))
            if email_element:
                email = email_element.get('href', '').replace('mailto:', '')

            # Pobierz link do ICS
            ics_link = ""
            dropdown_menu = soup.find('ul', class_='dropdown-menu')
            if dropdown_menu:
                for a_tag in dropdown_menu.find_all('a'):
                    a_href = a_tag.get('href', '')
                    if 'nauczyciel_ics.php' in a_href:
                        ics_link = a_href
                        break

            # Wyciągnij ID nauczyciela z URL
            nauczyciel_id = ""
            match = re.search(r'ID=(\d+)', nauczyciel_link)
            if match:
                nauczyciel_id = match.group(1)

            return {
                'id': nauczyciel_id,
                'imie_nazwisko': imie_nazwisko,
                'instytut': instytut,
                'email': email,
                'link_ics': ics_link,
                'link_planu': nauczyciel_link,
                'data_aktualizacji': self.scrape_timestamp
            }

        except Exception as e:
            logger.error(f"Błąd podczas pobierania informacji o nauczycielu: {str(e)}")
            return {
                'id': "",
                'imie_nazwisko': "",
                'instytut': "",
                'email': "",
                'link_ics': "",
                'link_planu': nauczyciel_link,
                'data_aktualizacji': self.scrape_timestamp
            }