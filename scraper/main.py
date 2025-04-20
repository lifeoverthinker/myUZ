import os

from bs4 import BeautifulSoup
from dotenv import load_dotenv
from supabase import create_client

from scraper.db import update_kierunki, update_grupy, update_nauczyciele, update_zajecia
from scraper.downloader import fetch_page
from scraper.parsers.grupy_parser import wyodrebnij_semestr_i_tryb
from scraper.scrapers.grupy_scraper import scrape_grupy_for_kierunki
from scraper.scrapers.kierunki_scraper import scrape_kierunki

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

def pobierz_semestr_i_tryb_z_grupy(url: str, verbose=False):
    """Pobiera informację o semestrze i trybie studiów z podstrony grupy."""
    if verbose:
        # noinspection PyCompatibility
        print(f"Pobieranie semestru i trybu z URL: {url}")

    html = fetch_page(url)
    if not html:
        return "nieznany", "nieznany"

    soup = BeautifulSoup(html, "html.parser")
    h3_tag = soup.find('h3')

    if not h3_tag:
        return "nieznany", "nieznany"

    semestr, tryb = wyodrebnij_semestr_i_tryb(h3_tag)
    return semestr, tryb

def main():
    """Główna funkcja wykonująca cały proces scrapowania danych."""
    print("ETAP 1: Pobieranie kierunków studiów...")
    # Najpierw pobieramy kierunki, a potem je aktualizujemy
    kierunki_pobrane = scrape_kierunki()
    kierunki = update_kierunki(kierunki_pobrane)
    print(f"Przetworzono {len(kierunki)} kierunków")

    print("\nETAP 2: Pobieranie grup dla kierunków...")
    grupy = scrape_grupy_for_kierunki(kierunki)
    print(f"Przetworzono {len(grupy)} grup z {len(kierunki)} kierunków")

    print("\nETAP 3: Zapisywanie grup do bazy danych...")
    zapisane_grupy = update_grupy(grupy)

    # Tworzenie mapowania oryginalnego ID do UUID z bazy
    uuid_map = {}
    for grupa in grupy:
        orig_id = grupa.get('grupa_id') or grupa.get('id')
        if 'uuid' in grupa and orig_id:
            uuid_map[orig_id] = grupa['uuid']

    print("\nETAP 4: Pobieranie nauczycieli...")
    nauczyciele = update_nauczyciele(grupy, uuid_map)  # Przekazanie mapy UUID
    print(f"Przetworzono {len(nauczyciele)} nauczycieli")

    print("\nETAP 5: Pobieranie planów zajęć...")
    # Wywołanie istniejącej funkcji update_zajecia
    ilosc_zajec = update_zajecia(grupy, nauczyciele)
    print(f"Przetworzono {ilosc_zajec} zajęć")

    print("\nZakończono cały proces scrapowania i zapisu do bazy danych.")

if __name__ == "__main__":
    main()