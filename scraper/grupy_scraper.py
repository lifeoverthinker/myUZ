import requests
from bs4 import BeautifulSoup
import logging
import re
from urllib.parse import urlparse, parse_qs

logger = logging.getLogger('UZ_Scraper.Grupy')


class GrupyScraper:
    def __init__(self, db, base_url):
        self.db = db
        self.base_url = base_url
        self.total_updated = 0

    def scrape_and_save(self):
        """Scrapuje i zapisuje grupy do bazy danych."""
        logger.info("Rozpoczęto scrapowanie grup zajęciowych")

        # Pobierz kierunki z bazy danych
        kierunki = self.db.get_kierunki()

        logger.info(f"Znaleziono {len(kierunki)} kierunków do scrapowania")

        for kierunek in kierunki:
            # Pobierz ID kierunku z linku
            link_grupy = kierunek.get('link_grupy', '')
            if not link_grupy:
                continue

            # Wyciągnij ID kierunku z URL
            parsed_url = urlparse(link_grupy)
            query_params = parse_qs(parsed_url.query)
            kierunek_id_url = query_params.get('ID', [''])[0]

            if not kierunek_id_url:
                continue

            logger.info(
                f"Przetwarzanie kierunku: {kierunek['nazwa_kierunku']}, ID URL: {kierunek_id_url}")

            try:
                # Pełny URL do listy grup
                grupy_url = f"{self.base_url}/grupy_lista_grup_kierunku.php?ID={kierunek_id_url}"
                response = requests.get(grupy_url)

                if response.status_code != 200:
                    logger.error(f"Błąd HTTP {response.status_code} dla URL: {grupy_url}")
                    continue

                soup = BeautifulSoup(response.text, 'html.parser')
                table = soup.find('table', {'class': 'table table-bordered table-condensed'})

                if not table:
                    logger.warning(
                        f"Nie znaleziono tabeli grup dla kierunku: {kierunek['nazwa_kierunku']}")
                    continue

                rows = table.find_all('tr')

                for row in rows:
                    # Znajdujemy jedyną komórkę w wierszu
                    cell = row.find('td')
                    if not cell:
                        continue

                    # Znajdujemy link w komórce
                    link = cell.find('a')
                    if not link:
                        continue

                    # Pobieramy kod grupy i opis z tekstu linku
                    full_text = link.text.strip()

                    # Przykładowy format: "11AW-SP Architektura wnętrz / stacjonarne / pierwszego stopnia z tyt. licencjata"
                    parts = full_text.split(" ", 1)
                    kod_grupy = parts[0] if len(parts) > 0 else ""
                    info_text = parts[1] if len(parts) > 1 else ""

                    # Wyodrębnij tryb studiów
                    tryb_studiow = "stacjonarne" if "stacjonarne" in info_text.lower() else "niestacjonarne"

                    # Wyciągnij semestr - można to dopasować do danych
                    semestr = ""  # Tutaj możesz dodać kod do wyciągania semestru, jeśli jest dostępny

                    # Link do planu
                    link_planu = link['href'] if link else None

                    if kod_grupy and link_planu:
                        grupa_data = {
                            'kod_grupy': kod_grupy,
                            'kierunek_id': kierunek['id'],
                            'link_planu': link_planu,
                            'tryb_studiow': tryb_studiow,
                            'semestr': semestr
                        }

                        grupa_id = self.db.upsert_grupa(grupa_data)
                        if grupa_id:
                            self.total_updated += 1
                            logger.info(f"Dodano/zaktualizowano grupę: {kod_grupy}")

            except Exception as e:
                logger.error(
                    f"Błąd podczas scrapowania grup dla kierunku {kierunek['nazwa_kierunku']}: {str(e)}")

        logger.info(f"Zakończono scrapowanie grup. Zaktualizowano {self.total_updated} grup")
        return self.total_updated
