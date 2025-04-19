"""
Moduł do pobierania informacji o nauczycielach akademickich z planu UZ.
"""
import concurrent.futures
from functools import lru_cache
from typing import List

from scraper.models import Nauczyciel, Grupa
from scraper.downloader import fetch_page, BASE_URL
from scraper.parsers.nauczyciel_parser import parse_nauczyciele_from_group_page, parse_nauczyciel_details


def sanitize_string(text):
    """Oczyszcza ciąg znaków z nieprawidłowych kodowań i znaków binarnych."""
    if text is None:
        return None

    if not isinstance(text, str):
        return str(text)

    # Poprawna lista polskich znaków
    polish_chars = "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ"

    # Zachowaj tylko znaki drukowalne i polskie znaki
    result = ""
    for char in text:
        if char.isprintable() or char in polish_chars:
            result += char

    return result


@lru_cache(maxsize=500)
def fetch_page_cached(url: str) -> str:
    """Cachowana wersja fetch_page dla zwiększenia wydajności."""
    return fetch_page(url)


def fetch_and_parse_nauczyciel(nauczyciel: Nauczyciel) -> Nauczyciel:
    """Pobiera i parsuje stronę nauczyciela, uzupełniając dane."""
    link = nauczyciel.link_strony_nauczyciela
    html = fetch_page(link)

    if not html:
        print(f"❌ Nie udało się pobrać strony nauczyciela: {sanitize_string(nauczyciel.nazwa)}")
        return nauczyciel

    szczegoly = parse_nauczyciel_details(html)

    # Aktualizacja atrybutów obiektu Nauczyciel
    if 'imie_nazwisko' in szczegoly:
        nauczyciel.imie_nazwisko = szczegoly['imie_nazwisko']
    if 'instytut' in szczegoly:
        nauczyciel.instytut = szczegoly['instytut']
    if 'email' in szczegoly:
        nauczyciel.email = szczegoly['email']
    if 'link_plan_nauczyciela' in szczegoly:
        nauczyciel.link_plan_nauczyciela = szczegoly['link_plan_nauczyciela']

    return nauczyciel


def pobierz_nauczycieli_z_grupy(link_grupy: str, grupa_id) -> List[Nauczyciel]:
    """Pomocnicza funkcja do pobierania nauczycieli z jednej grupy."""
    html = fetch_page_cached(link_grupy)
    if not html:
        return []
    return parse_nauczyciele_from_group_page(html, grupa_id)


def scrape_nauczyciele_from_grupy(grupy: list, max_workers=10) -> List[Nauczyciel]:
    """Scrapuje nauczycieli z planów zajęć podanych grup równolegle."""
    wszystkie_linki_nauczycieli = []
    wszyscy_nauczyciele = []
    znalezieni_nauczyciele_id = set()

    # 1. Równoległe pobieranie linków nauczycieli
    print(f"🧑‍🏫 Pobieram linki nauczycieli dla {len(grupy)} grup równolegle...")
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        zadania = {}
        for grupa in grupy:
            # Obsługuje zarówno obiekty Grupa jak i słowniki podczas okresu przejściowego
            kod_grupy = grupa.kod_grupy if hasattr(grupa, 'kod_grupy') else grupa.get('kod_grupy')
            link_grupy = grupa.link_grupy if hasattr(grupa, 'link_grupy') else grupa.get('link_grupy')
            grupa_id = grupa.grupa_id if hasattr(grupa, 'grupa_id') else grupa.get('grupa_id')

            zadania[executor.submit(pobierz_nauczycieli_z_grupy, link_grupy, grupa_id)] = kod_grupy

        for zadanie in concurrent.futures.as_completed(zadania):
            kod_grupy = zadania[zadanie]
            try:
                nauczyciele = zadanie.result()
                wszystkie_linki_nauczycieli.extend(nauczyciele)
                print(f"✅ Znaleziono {len(nauczyciele)} nauczycieli w grupie {kod_grupy}")
            except Exception as e:
                print(f"❌ Błąd pobierania nauczycieli dla grupy {kod_grupy}: {str(e)}")

    print(f"\n🔍 Znaleziono {len(wszystkie_linki_nauczycieli)} łącznie nauczycieli, pobieram szczegóły...")

    # 2. Równoległe pobieranie szczegółów nauczycieli
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        zadania = []

        for nauczyciel in wszystkie_linki_nauczycieli:
            if nauczyciel.nauczyciel_id not in znalezieni_nauczyciele_id:
                znalezieni_nauczyciele_id.add(nauczyciel.nauczyciel_id)
                zadania.append(executor.submit(fetch_and_parse_nauczyciel, nauczyciel))

        ukonczone = 0
        for zadanie in concurrent.futures.as_completed(zadania):
            try:
                nauczyciel = zadanie.result()
                wszyscy_nauczyciele.append(nauczyciel)
                ukonczone += 1
                if ukonczone % 10 == 0:
                    print(f"🧪 Pobrano {ukonczone}/{len(zadania)} szczegółów nauczycieli...")
            except Exception as e:
                print(f"❌ Błąd pobierania szczegółów nauczyciela: {str(e)}")

    return wszyscy_nauczyciele


if __name__ == "__main__":
    # Dla samodzielnego testowania
    from scraper.scrapers.kierunki_scraper import scrape_kierunki
    from scraper.scrapers.grupy_scraper import scrape_grupy_for_kierunki

    kierunki = scrape_kierunki()
    # Testujemy tylko na kilku pierwszych kierunkach
    grupy = scrape_grupy_for_kierunki(kierunki[:1])
    # Testujemy tylko na kilku pierwszych grupach
    nauczyciele = scrape_nauczyciele_from_grupy(grupy[:3])

    print(f"\nPobrano {len(nauczyciele)} nauczycieli.")
    for n in nauczyciele:
        sanitized_name = sanitize_string(n.imie_nazwisko)
        print(f"Nauczyciel: {sanitized_name}, Email: {n.email if hasattr(n, 'email') else 'brak'}")