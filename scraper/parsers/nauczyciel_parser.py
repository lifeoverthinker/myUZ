import requests
from bs4 import BeautifulSoup
import concurrent.futures
from functools import lru_cache
import sys
import os

# Dodaj ścieżkę projektu do sys.path dla importów z katalogu nadrzędnego
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from scraper.scrapers.kierunki_scraper import scrape_kierunki
from scraper.scrapers.grupy_scraper import scrape_grupy_for_kierunki

BASE_URL = "https://plan.uz.zgora.pl/"


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


def fetch_page(url: str) -> str:
    """Pobiera zawartość strony HTML."""
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        print(f"❌ Błąd pobierania strony: {e}")
        return ""


def parse_nauczyciele_from_group_page(html: str, grupa_id: str = None) -> list[dict]:
    """Parsuje HTML planu zajęć grupy i wyodrębnia linki do stron nauczycieli."""
    soup = BeautifulSoup(html, "html.parser")
    wynik = []
    znalezieni_nauczyciele = set()  # Zbiór do unikania duplikatów

    # Znajdź wszystkie linki do nauczycieli
    nauczyciel_links = soup.find_all("a", href=lambda href: href and "nauczyciel_plan.php?ID=" in href)

    for link in nauczyciel_links:
        nauczyciel_url = BASE_URL + link["href"]
        nauczyciel_id = link["href"].split("ID=")[1] if "ID=" in link["href"] else None
        nauczyciel_name = link.get_text(strip=True)

        # Sprawdź czy nauczyciel był już dodany
        if nauczyciel_url not in znalezieni_nauczyciele:
            znalezieni_nauczyciele.add(nauczyciel_url)

            nauczyciel_data = {
                "nazwa": nauczyciel_name,
                "link": nauczyciel_url,
                "nauczyciel_id": nauczyciel_id
            }

            # Dodaj ID grupy, jeśli istnieje
            if grupa_id:
                nauczyciel_data["grupa_id"] = grupa_id

            wynik.append(nauczyciel_data)

            # Używamy funkcji sanitize_string do oczyszczania tekstu przed wyświetleniem
            print(f"🧑‍🏫 Znaleziono nauczyciela: {sanitize_string(nauczyciel_name)}")

    return wynik


def parse_nauczyciel_details(html: str) -> dict:
    """Parsuje stronę nauczyciela, aby wydobyć dodatkowe informacje."""
    soup = BeautifulSoup(html, "html.parser")
    dane = {}

    # Imię i nazwisko
    name_tag = soup.find("h2", string=lambda s: s and "Plan zajęć" not in s)
    if name_tag:
        pelne_imie = name_tag.get_text(strip=True)
        dane["pelne_imie"] = pelne_imie

        # Próba wyodrębnienia tytułu, imienia i nazwiska
        parts = pelne_imie.split()
        if len(parts) >= 2:
            # Zakładamy, że ostatni element to nazwisko
            dane["nazwisko"] = parts[-1]

            # Jeśli jest więcej elementów, pierwszy może być imieniem lub tytułem
            if len(parts) > 2:
                dane["tytul"] = ' '.join(parts[:-2])
                dane["imie"] = parts[-2]
            else:
                dane["imie"] = parts[0]

    # Wydział/Instytut
    instytut_tag = soup.find("h3")
    if instytut_tag:
        dane["instytut"] = instytut_tag.get_text(strip=True)

    # Email
    email_tag = soup.find("a", href=lambda href: href and "mailto:" in href)
    if email_tag:
        dane["email"] = email_tag.get_text(strip=True)

    # Link do ICS
    ics_link = soup.find("a", href=lambda href: href and "nauczyciel_ics.php" in href)
    if ics_link:
        dane["link_ics_nauczyciela"] = BASE_URL + ics_link["href"]

    return dane


def fetch_and_parse_nauczyciel(nauczyciel_data: dict) -> dict:
    """Pobiera i parsuje stronę nauczyciela, uzupełniając dane."""
    link = nauczyciel_data["link"]
    html = fetch_page(link)

    if not html:
        print(f"❌ Nie udało się pobrać strony nauczyciela: {sanitize_string(nauczyciel_data['nazwa'])}")
        return nauczyciel_data

    szczegoly = parse_nauczyciel_details(html)

    # Połącz dane
    return {**nauczyciel_data, **szczegoly}


def pobierz_nauczycieli_z_grupy(link_grupy: str, grupa_id):
    """Pomocnicza funkcja do pobierania nauczycieli z jednej grupy."""
    html = fetch_page_cached(link_grupy)
    if not html:
        return []
    return parse_nauczyciele_from_group_page(html, grupa_id)


def scrape_nauczyciele_from_grupy(grupy: list[dict], max_workers=10) -> list[dict]:
    """Scrapuje nauczycieli z planów zajęć podanych grup równolegle."""
    wszystkie_linki_nauczycieli = []
    wszyscy_nauczyciele = []
    znalezieni_nauczyciele_id = set()

    # 1. Równoległe pobieranie linków nauczycieli
    print(f"🧑‍🏫 Pobieram linki nauczycieli dla {len(grupy)} grup równolegle...")
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        zadania = {}
        for grupa in grupy:
            kod_grupy = grupa['kod_grupy']
            link_grupy = grupa['link_grupy']
            grupa_id = grupa.get('grupa_id') or grupa.get('id')
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

        for n in wszystkie_linki_nauczycieli:
            if n["nauczyciel_id"] not in znalezieni_nauczyciele_id:
                znalezieni_nauczyciele_id.add(n["nauczyciel_id"])
                zadania.append(executor.submit(fetch_and_parse_nauczyciel, n))

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
        sanitized_name = sanitize_string(n.get('pelne_imie', n.get('nazwa')))
        print(f"Nauczyciel: {sanitized_name}, Email: {n.get('email', 'brak')}")
