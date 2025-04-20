"""
Moduł do parsowania danych dotyczących grup studenckich.
"""
from bs4 import BeautifulSoup
from icalendar import Calendar
import re
from typing import Tuple, List, Dict, Optional, Any

from scraper.downloader import fetch_page, BASE_URL


def wyodrebnij_dane_z_summary(summary: str, categories: Optional[Any] = None) -> Tuple[
    str, Optional[str], Optional[str], str]:
    """
    Ekstrahuje przedmiot, rodzaj zajęć (RZ), nauczyciela i podgrupę (PG) z opisu.

    Args:
        summary: Pole SUMMARY z pliku ICS
        categories: Pole CATEGORIES z pliku ICS (opcjonalne)
    """
    przedmiot = summary
    nauczyciel = None
    pg = "CAŁY KIERUNEK"

    # Rodzaj zajęć bierzemy wyłącznie z categories
    rz = None
    if categories:
        try:
            # Próba konwersji obiektu vCategory na string
            rz = str(categories).strip()
        except:
            pass

    # Szukamy wzorca do wyodrębnienia nazwy przedmiotu i nauczyciela
    match = re.search(r"(.*?)\s*\(([^():]+)\):\s+(.+)", summary)
    if match:
        przedmiot = match.group(1).strip()
        nauczyciel = match.group(3).strip()
    else:
        przedmiot = summary.strip()

    # Szukamy podgrupy PG w nawiasie, np. (PG: SN)
    pg_match = re.search(r"\(PG:\s*([^)]+)\)", summary)
    if pg_match:
        pg = pg_match.group(1).strip()
        # Usuwamy ten fragment z nauczyciela
        nauczyciel = re.sub(r"\(PG:.*?\)", "", nauczyciel).strip() if nauczyciel else None

    return przedmiot, rz, nauczyciel, pg


def parse_grupa_details(html_content):
    """Parsuje HTML planu zajęć grupy, wyciągając kod grupy, tryb studiów i semestr."""
    soup = BeautifulSoup(html_content, 'html.parser')

    # Kod grupy z drugiego elementu H2
    h2_elements = soup.find_all('h2')
    kod_grupy = h2_elements[1].text.strip() if len(h2_elements) > 1 else "Nieznany"

    # Informacje z H3
    h3 = soup.find('h3')
    h3_text = h3.text if h3 else ""

    # Tryb studiów - szukamy dokładniej
    tryb_studiow = "nieznany"
    if "niestacjonarne" in h3_text.lower():
        tryb_studiow = "niestacjonarne"
    elif "stacjonarne" in h3_text.lower():
        tryb_studiow = "stacjonarne"

    # Semestr
    semestr = "nieznany"
    if "letni" in h3_text.lower():
        semestr = "letni"
    elif "zimowy" in h3_text.lower():
        semestr = "zimowy"

    return {
        "kod_grupy": kod_grupy,
        "tryb_studiow": tryb_studiow,
        "semestr": semestr
    }


# Alias dla zachowania kompatybilności
parsuj_html_grupa = parse_grupa_details


def parse_ics(content: str, grupa_id=None) -> List[Dict[str, Any]]:
    """Parsuje plik ICS i wydobywa wydarzenia (zajęcia)."""
    events = []
    cal = Calendar.from_ical(content)

    for component in cal.walk():
        if component.name != "VEVENT":
            continue

        summary = component.get("SUMMARY")
        start = component.get("DTSTART").dt
        end = component.get("DTEND").dt
        location = component.get("LOCATION")
        categories = component.get("CATEGORIES")

        # Wyodrębnianie danych z summary z uwzględnieniem categories jeśli dostępne
        przedmiot, rz, nauczyciel, pg = wyodrebnij_dane_z_summary(summary, categories)

        event_data = {
            "przedmiot": przedmiot,
            "rz": rz,
            "nauczyciel": nauczyciel,
            "pg": pg,
            "od": start,
            "do_": end,
            "miejsce": location
        }

        # Dodaj grupa_id jeśli podano
        if grupa_id is not None:
            event_data["grupa_id"] = grupa_id

        events.append(event_data)

    return events


def wyodrebnij_semestr_i_tryb(h3_tag) -> Tuple[str, str]:
    """Ekstrahuje semestr i tryb studiów z tagu H3."""
    semestr = "nieznany"
    tryb_studiow = "nieznany"

    if h3_tag:
        text = h3_tag.get_text(strip=True).lower()
        if "semestr letni" in text:
            semestr = "letni"
        elif "semestr zimowy" in text:
            semestr = "zimowy"

        if "stacjonarne" in text and "niestacjonarne" not in text:
            tryb_studiow = "stacjonarny"
        elif "niestacjonarne" in text:
            tryb_studiow = "niestacjonarny"

    return semestr, tryb_studiow


def wyodrebnij_kod_grupy(h2_tags) -> str:
    """Ekstrahuje kod grupy z drugiego tagu H2."""
    if len(h2_tags) < 2:
        raise ValueError("Nie znaleziono drugiego <h2> z kodem grupy.")

    kod_grupy_text = h2_tags[1].get_text(strip=True)

    # Wyodrębnij krótszy kod - pierwszą część przed spacją lub '/'
    kod_parts = re.split(r'[ /]', kod_grupy_text)
    if kod_parts and kod_parts[0]:
        return kod_parts[0]

    return kod_grupy_text


def pobierz_semestr_i_tryb_z_grupy(url: str) -> Tuple[str, str]:
    """Pobiera informację o semestrze i trybie studiów z podstrony grupy."""
    print(f"Pobieranie semestru i trybu z URL: {url}")
    html = fetch_page(url)
    if not html:
        print("❌ Nie udało się pobrać HTML!")
        return "nieznany", "nieznany"

    soup = BeautifulSoup(html, "html.parser")
    h3_tag = soup.find('h3')

    if not h3_tag:
        print("❌ Nie znaleziono tagu h3 w HTML!")
    else:
        print(f"Znaleziony tekst h3: {h3_tag.get_text(strip=True)}")

    semestr, tryb = wyodrebnij_semestr_i_tryb(h3_tag)
    print(f"Wyodrębniony semestr: {semestr}, tryb: {tryb}")
    return semestr, tryb


def pobierz_semestr_z_grupy(url: str) -> str:
    """Pobiera informację o semestrze z podstrony grupy."""
    semestr, _ = pobierz_semestr_i_tryb_z_grupy(url)
    return semestr

# Usunięto funkcję parse_grupy - pozostaje tylko w scraper/scrapers/grupy_scraper.py