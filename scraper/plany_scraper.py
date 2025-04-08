"""
Moduł do pobierania planów zajęć
Autor: lifeoverthinker
Data: 2025-04-08
"""

import re
import logging
import requests
from bs4 import BeautifulSoup
from datetime import datetime
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

class PlanyScraper:
    """Klasa do pobierania planów zajęć"""

    BASE_URL = "https://plan.uz.zgora.pl"

    # Słownik terminów (kody skrótów)
    TERMINY_KODY = {
        "D": "Dni robocze, studia stacjonarne",
        "DI": "Studia stacjonarne I-sza połowa sem.",
        "DII": "Studia stacjonarne II-ga połowa sem.",
        "DN": "Studia stacjonarne Nieparzyste",
        "DP": "Studia stacjonarne Parzyste",
        "WPA": "Wydział Nauk Prawnych i Ekonomicznych - terminy zjazdów"
    }

    def __init__(self):
        self.session = requests.Session()
        self.scrape_timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
        self._terminy_kalendarzy_cache = {}  # Prosty cache dla terminów kalendarzy

    def get_plan_grupy(self, grupa_link: str) -> Dict[str, Any]:
        """
        Pobiera plan zajęć dla danej grupy

        Args:
            grupa_link: Link do planu zajęć grupy

        Returns:
            Słownik z danymi planu zajęć
        """
        url = f"{self.BASE_URL}/{grupa_link}"
        logger.info(f"Pobieranie planu z {url}")

        try:
            response = self.session.get(url)
            response.raise_for_status()

            soup = BeautifulSoup(response.text, 'html.parser')

            # Pobierz kod grupy z nagłówka
            kod_grupy = ""
            h2_elements = soup.find_all('h2')
            if len(h2_elements) >= 2:
                kod_grupy = h2_elements[1].text.strip()

            # Pobierz link do pliku ICS
            ics_link = ""
            ics_element = soup.find('a', id='idGG')
            if ics_element:
                ics_link = ics_element.get('href', '')

            # Pobierz linki do nauczycieli
            nauczyciele = []
            for a_tag in soup.find_all('a'):
                href = a_tag.get('href', '')
                if 'nauczyciel_plan.php' in href:
                    match = re.search(r'ID=(\d+)', href)
                    if match:
                        nauczyciel_id = match.group(1)
                        nauczyciele.append({
                            'link': href,
                            'nazwa': a_tag.text.strip(),
                            'nauczyciel_id': nauczyciel_id
                        })

            # Pobierz plan zajęć z tabeli
            wydarzenia = []
            tabela_plan = soup.find('table', class_='table-bordered')
            if tabela_plan:
                for wiersz in tabela_plan.find_all('tr'):
                    # Pomijamy wiersz nagłówkowy
                    if wiersz.find('th'):
                        continue

                    # Pobierz komórki
                    komorki = wiersz.find_all('td')
                    if len(komorki) >= 7:
                        try:
                            # Pobierz dane z poszczególnych kolumn zgodnie z przybornik
                            przedmiot = komorki[0].text.strip()
                            nauczyciel = komorki[1].text.strip()
                            rz = komorki[2].text.strip()  # Rodzaj zajęć
                            miejsce = komorki[3].text.strip()
                            terminy_html = komorki[4].text.strip()

                            # Parsowanie godzin
                            czas_tekst = komorki[5].text.strip()
                            czas_match = re.search(r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})', czas_tekst)
                            if czas_match:
                                od_godz, od_min, do_godz, do_min = map(int, czas_match.groups())
                                od = f"{od_godz:02d}:{od_min:02d}"
                                do = f"{do_godz:02d}:{do_min:02d}"
                            else:
                                od = None
                                do = None

                            # Link do pojedynczego ICS
                            event_ics = ""
                            event_ics_link = komorki[6].find('a')
                            if event_ics_link:
                                event_ics = event_ics_link.get('href', '')

                            # Terminy
                            terminy = terminy_html

                            # Dodaj wydarzenie do listy
                            wydarzenia.append({
                                'przedmiot': przedmiot,
                                'prowadzacy': nauczyciel,
                                'typ_zajec': rz,
                                'miejsce': miejsce,
                                'terminy': terminy,
                                'od': od,
                                'do': do,
                                'link_ics': event_ics
                            })
                        except Exception as e:
                            logger.error(f"Błąd podczas parsowania wiersza planu: {str(e)}")

            return {
                'kod_grupy': kod_grupy,
                'link_ics': ics_link,
                'nauczyciele': nauczyciele,
                'wydarzenia': wydarzenia,
                'data_aktualizacji': self.scrape_timestamp
            }

        except Exception as e:
            logger.error(f"Błąd podczas pobierania planu grupy: {str(e)}")
            return {
                'kod_grupy': "",
                'link_ics': "",
                'nauczyciele': [],
                'wydarzenia': [],
                'data_aktualizacji': self.scrape_timestamp
            }

    def get_kalendarz_terminy(self, kalendarz_id: str) -> List[str]:
        """
        Pobiera terminy z kalendarza dla danego ID

        Args:
            kalendarz_id: ID kalendarza

        Returns:
            Lista dat w formacie YYYY-MM-DD
        """
        # Sprawdź cache
        if kalendarz_id in self._terminy_kalendarzy_cache:
            return self._terminy_kalendarzy_cache[kalendarz_id]

        url = f"{self.BASE_URL}/kalendarze_lista_szczegoly.php?ID={kalendarz_id}"
        logger.info(f"Pobieranie terminów z kalendarza {url}")

        try:
            response = self.session.get(url)
            response.raise_for_status()

            soup = BeautifulSoup(response.text, 'html.parser')
            daty = []

            tabela = soup.find('table', class_='table-bordered')
            if tabela:
                for wiersz in tabela.find_all('tr'):
                    komorki = wiersz.find_all('td')
                    if len(komorki) >= 2:
                        data_cell = komorki[1]
                        if data_cell:
                            data = data_cell.text.strip()
                            if re.match(r'\d{4}-\d{2}-\d{2}', data):
                                daty.append(data)

            # Zapisz do cache
            self._terminy_kalendarzy_cache[kalendarz_id] = daty
            return daty

        except Exception as e:
            logger.error(f"Błąd podczas pobierania terminów z kalendarza: {str(e)}")
            return []

    def download_ics(self, ics_url: str) -> Optional[str]:
        """
        Pobiera plik ICS

        Args:
            ics_url: Adres URL pliku ICS

        Returns:
            Zawartość pliku ICS jako tekst lub None w przypadku błędu
        """
        full_url = f"{self.BASE_URL}/{ics_url}" if not ics_url.startswith('http') else ics_url
        logger.info(f"Pobieranie pliku ICS z {full_url}")

        try:
            response = self.session.get(full_url)
            response.raise_for_status()
            return response.text
        except Exception as e:
            logger.error(f"Błąd podczas pobierania pliku ICS: {str(e)}")
            return None