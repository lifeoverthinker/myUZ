"""
Moduł do pobierania danych o kierunkach studiów
Autor: lifeoverthinker
Data: 2025-04-08
"""

import re
import logging
import requests
from bs4 import BeautifulSoup
from typing import List, Dict

logger = logging.getLogger(__name__)

class KierunkiScraper:
    """Klasa do pobierania danych o kierunkach studiów"""

    BASE_URL = "https://plan.uz.zgora.pl"

    def __init__(self):
        self.session = requests.Session()

    def get_kierunki(self) -> List[Dict[str, str]]:
        """
        Pobiera listę kierunków studiów wraz z ich danymi

        Returns:
            Lista słowników z danymi kierunków studiów
        """
        url = f"{self.BASE_URL}/grupy_lista_kierunkow.php"
        logger.info(f"Pobieranie listy kierunków z {url}")

        try:
            response = self.session.get(url)
            response.raise_for_status()  # Sprawdź czy nie ma błędu HTTP

            soup = BeautifulSoup(response.text, 'html.parser')
            kierunki = []

            # Znajdujemy wszystkie elementy wydziałów (LI z klasą list-group-item)
            wydzialy_elements = soup.select('LI.list-group-item')

            for wydzial_element in wydzialy_elements:
                # Pobierz nazwę wydziału
                wydzial_nazwa = ""
                # Próbujemy pobrać tekst z pierwszego elementu bold lub strong
                bold_element = wydzial_element.find(['strong', 'b'])
                if bold_element:
                    wydzial_nazwa = bold_element.get_text(strip=True)
                else:
                    # Jeśli nie znaleziono, pobierz bezpośredni tekst elementu
                    wydzial_nazwa = wydzial_element.get_text(strip=True).split('\n')[0].strip()

                # Znajdź listę kierunków dla tego wydziału
                for a_element in wydzial_element.select('a'):
                    href = a_element.get('href', '')
                    if 'grupy_lista_grup_kierunku.php' in href:
                        nazwa_kierunku = a_element.text.strip()

                        # Wyciągnij ID kierunku z URL
                        match = re.search(r'ID=(\d+)', href)
                        if match:
                            kierunek_id = match.group(1)

                            # Określ typ kierunku
                            typ_kierunku = "standardowy"
                            if "studia podyplomowe" in nazwa_kierunku.lower():
                                typ_kierunku = "podyplomowe"
                            elif "erasmus" in nazwa_kierunku.lower():
                                typ_kierunku = "erasmus"

                            kierunki.append({
                                'nazwa_kierunku': nazwa_kierunku,
                                'wydzial': wydzial_nazwa,
                                'link_grupy': href,
                                'kierunek_id': kierunek_id,
                                'typ_kierunku': typ_kierunku
                            })

            logger.info(f"Znaleziono {len(kierunki)} kierunków")
            return kierunki

        except Exception as e:
            logger.error(f"Błąd podczas pobierania kierunków: {str(e)}")
            return []