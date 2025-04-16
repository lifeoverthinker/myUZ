"""
Struktura strony
<H3>Plan grup - lista grup kierunku <i>Historia</i></H3>
<TABLE class="table table-bordered table-condensed">

      <TR class="odd"><td><a href="grupy_plan.php?ID=29180">11H-SD24 Historia / stacjonarne / drugiego stopnia z tyt. magistra</a></td></tr>

      <TR class="even"><td><a href="grupy_plan.php?ID=29181">11H-SP24 Historia / stacjonarne / pierwszego stopnia z tyt. licencjata</a></td></tr>

      <TR class="odd"><td><a href="grupy_plan.php?ID=29182">21H-SD23 Historia / stacjonarne / drugiego stopnia z tyt. magistra</a></td></tr>

      <TR class="even"><td><a href="grupy_plan.php?ID=29183">21H-SP23 Historia / stacjonarne / pierwszego stopnia z tyt. licencjata</a></td></tr>

      <TR class="odd"><td><a href="grupy_plan.php?ID=29184">31H-SP22 Historia / stacjonarne / pierwszego stopnia z tyt. licencjata</a></td></tr>

</TABLE>
"""
import re
import requests
from bs4 import BeautifulSoup

BASE_URL = "https://plan.uz.zgora.pl/"


def fetch_page(url: str) -> str:
    """Pobiera zawartość strony HTML."""
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        print(f"❌ Błąd pobierania strony: {e}")
        return ""


def parse_grupy(html: str, kierunek: str, wydzial: str, kierunek_id: int = None) -> list[dict]:
    """Parsuje HTML strony kierunku i wydobywa grupy."""
    soup = BeautifulSoup(html, "html.parser")
    wynik = []

    grupy_items = soup.find_all("tr", class_=["odd", "even"])
    if not grupy_items:
        print(f"❌ Nie znaleziono grup dla kierunku: {kierunek}")
        return wynik

    for item in grupy_items:
        a_tag = item.find("a")
        if a_tag:
            pelna_nazwa = a_tag.get_text(strip=True)
            kod_grupy = pelna_nazwa.split()[0]

            # Wyodrębnij tryb studiów (część między / /)
            tryb_studiow = "nieznany"
            if "/" in pelna_nazwa:
                parts = pelna_nazwa.split("/")
                if len(parts) > 1:
                    tryb_studiow = parts[1].strip()

            # Określenie semestru na podstawie drugiej cyfry w kodzie grupy
            # np. 11H-SD24 - druga cyfra to 1, co oznacza semestr zimowy
            # np. 12H-SD24 - druga cyfra to 2, co oznacza semestr letni
            semestr = "zimowy"
            if len(kod_grupy) > 1 and kod_grupy[1].isdigit():
                if kod_grupy[1] == "2":
                    semestr = "letni"

            link_grupy = BASE_URL + a_tag["href"]
            grupa_id = a_tag["href"].split("ID=")[1].split("&")[0] if "ID=" in a_tag["href"] else None
            link_grupy_ics = link_grupy.replace("grupy_plan.php?ID=", "grupy_ics.php?ID=") + "&KIND=GG"

            grupa_data = {
                "kod_grupy": kod_grupy,
                "tryb_studiow": tryb_studiow,  # zmieniono z "tryb" na "tryb_studiow"
                "kierunek": kierunek,
                "wydzial": wydzial,
                "link_grupy": link_grupy,  # zmieniono z "link_strona_grupy" na "link_grupy"
                "link_ics_grupy": link_grupy_ics,
                "semestr": semestr  # dodano informację o semestrze
            }

            if kierunek_id:
                grupa_data["kierunek_id"] = kierunek_id

            wynik.append(grupa_data)
            print(f"📌 Dodano grupę: {kod_grupy} ({kierunek})")

    return wynik

def scrape_grupy_for_kierunki(link_kierunku: str) -> list[dict]:
    """Scrapuje grupy dla podanego linku kierunku."""
    wszystkie_grupy = []

    print(f"🔍 Pobieram grupy dla kierunku z linku: {link_kierunku}")
    html = fetch_page(link_kierunku)
    if html:
        # Wyciągamy nazwę kierunku z HTML - jeśli nie ma, używamy domyślnej
        soup = BeautifulSoup(html, "html.parser")
        header = soup.find('h3')
        nazwa_kierunku = "Nieznany kierunek"
        wydzial = "Nieznany wydział"
        if header:
            match = re.search(r'<i>(.*?)</i>', str(header))
            if match:
                nazwa_kierunku = match.group(1)

        grupy = parse_grupy(html, nazwa_kierunku, wydzial)
        wszystkie_grupy.extend(grupy)
        print(f"✅ Pobrano {len(grupy)} grup dla kierunku")

    return wszystkie_grupy

if __name__ == "__main__":
    # Dla samodzielnego testowania
    from kierunki_scraper import scrape_kierunki

    kierunki = scrape_kierunki()
    # Dla szybszego testowania można ograniczyć do kilku kierunków
    grupy = scrape_grupy_for_kierunki(kierunki[:3])

    print(f"\nPobrano {len(grupy)} grup.")