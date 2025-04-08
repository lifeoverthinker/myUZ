"""
Moduł do pobierania danych o grupach studenckich
Autor: lifeoverthinker
Data: 2025-04-08
"""

import re
import logging
import requests
from bs4 import BeautifulSoup
from datetime import datetime, UTC
from typing import List, Dict

logger = logging.getLogger(__name__)

class GrupyScraper:
    """Klasa do pobierania danych o grupach studenckich"""

    BASE_URL = "https://plan.uz.zgora.pl"

    def __init__(self):
        self.session = requests.Session()
        self.scrape_timestamp = datetime.now(UTC).strftime("%Y-%m-%d %H:%M:%S")

    def get_grupy(self, kierunek_link: str) -> List[Dict[str, str]]:
        """
        Pobiera listę grup dla danego kierunku

        Args:
            kierunek_link: Link do strony z grupami danego kierunku

        Returns:
            Lista słowników z danymi grup
        """
        url = f"{self.BASE_URL}/{kierunek_link}"
        logger.info(f"Pobieranie grup z {url}")

        try:
            response = self.session.get(url)
            response.raise_for_status()

            soup = BeautifulSoup(response.text, 'html.parser')
            grupy = []
            current_semestr = ""

            # Szukaj informacji o semestrze
            h3_elements = soup.select('h3')
            if h3_elements:
                current_semestr = h3_elements[0].text.strip()

            # Szukaj linków do planów grup
            for a_element in soup.select('a[href*="grupy_plan.php"]'):
                link_href = a_element.get('href', '')
                pelna_nazwa_grupy = a_element.text.strip()

                # Wyodrębnij kod grupy (część przed pierwszą spacją)
                match = re.match(r'^(\S+)', pelna_nazwa_grupy)
                kod_grupy = match.group(1) if match else pelna_nazwa_grupy

                # Określ tryb studiów
                tryb = "stacjonarne"
                if "niestacjonarne" in pelna_nazwa_grupy.lower():
                    tryb = "niestacjonarne"

                # Wyciągnij ID grupy
                match = re.search(r'ID=(\d+)', link_href)
                if match:
                    grupa_id = match.group(1)
                    grupy.append({
                        'nazwa_grupy': pelna_nazwa_grupy,
                        'kod_grupy': kod_grupy,
                        'semestr': current_semestr,
                        'tryb_studiow': tryb,
                        'link_planu': link_href,
                        'grupa_id': grupa_id,
                        'data_aktualizacji': self.scrape_timestamp
                    })

            logger.info(f"Znaleziono {len(grupy)} grup dla kierunku {kierunek_link}")
            return grupy

        except Exception as e:
            logger.error(f"Błąd podczas pobierania grup: {str(e)}")
            return []