"""
Moduł do parsowania danych nauczycieli akademickich z planu UZ.
"""
from bs4 import BeautifulSoup
from typing import List, Dict

from scraper.models import Nauczyciel

BASE_URL = "https://plan.uz.zgora.pl/"


def parse_nauczyciele_from_group_page(html: str, grupa_id: str = None) -> List[Nauczyciel]:
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

            nauczyciel = Nauczyciel(
                nauczyciel_id=nauczyciel_id,
                nazwa=nauczyciel_name,
                link_strony_nauczyciela=nauczyciel_url,
                grupa_id=grupa_id
            )

            wynik.append(nauczyciel)
            print(f"🧑‍🏫 Znaleziono nauczyciela: {nauczyciel_name}")

    return wynik


def parse_nauczyciel_details(html: str) -> Dict[str, str]:
    """Parsuje stronę nauczyciela, aby wydobyć dodatkowe informacje."""
    soup = BeautifulSoup(html, "html.parser")
    dane = {}

    # Imię i nazwisko jako jedna wartość
    name_tag = soup.find("h2", string=lambda s: s and "Plan zajęć" not in s)
    if name_tag:
        imie_nazwisko = name_tag.get_text(strip=True)
        dane["imie_nazwisko"] = imie_nazwisko

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
        dane["link_plan_nauczyciela"] = BASE_URL + ics_link["href"]

    return dane