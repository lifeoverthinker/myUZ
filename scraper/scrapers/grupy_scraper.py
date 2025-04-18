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
"""
Moduł do pobierania informacji o grupach studenckich z planu UZ.
"""
import concurrent.futures
import datetime
from bs4 import BeautifulSoup

try:
    from tqdm import tqdm
except ImportError:
    print("⚠️ Pakiet tqdm nie jest zainstalowany. Instalacja: pip install tqdm")
    def tqdm(iterable, **kwargs):
        print(kwargs.get("desc", "Przetwarzanie..."))
        return iterable

from scraper.downloader import fetch_page, BASE_URL
from scraper.parsers.grupy_parser import parse_grupy
from scraper.ics_updater import aktualizuj_plany_grup

def parse_grupy(html, nazwa_kierunku, wydzial, kierunek_id):
    """Parsuje grupy z HTML."""
    soup = BeautifulSoup(html, 'html.parser')
    grupy = []

    try:
        # Znajdź wszystkie wiersze tabeli z linkami do grup
        rows = soup.select("tr.odd td a, tr.even td a")

        for row in rows:
            link = row.get('href')
            kod_grupy = row.text.strip()

            if not link or not kod_grupy:
                continue

            # Ekstrakcja informacji o trybie studiów
            parts = kod_grupy.split('/')
            tryb_studiow = parts[1].strip() if len(parts) > 1 else "nieznany"

            # Ekstrakcja semestru (np. "21H-SD23" -> "2")
            semestr = kod_grupy.split('-')[0][0] if '-' in kod_grupy else ""

            # Przygotuj pełne URL do planu grupy
            full_link = f"{BASE_URL}{link}" if link and not link.startswith('http') else link

            # Wydobycie ID grupy z linku
            grupa_id = None
            if "ID=" in link:
                try:
                    grupa_id = link.split("ID=")[1].split("&")[0]
                except (IndexError, ValueError):
                    pass

            # Generuj link do pliku ICS
            ics_link = f"{BASE_URL}grupy_ics.php?ID={grupa_id}&KIND=GG" if grupa_id else None

            if grupa_id:
                grupa = {
                    'grupa_id': grupa_id,
                    'kod_grupy': kod_grupy,
                    'kierunek_id': kierunek_id,
                    'wydzial': wydzial,
                    'tryb_studiow': tryb_studiow,
                    'semestr': semestr,
                    'link_grupy': full_link,
                    'link_ics_grupy': ics_link
                }
                grupy.append(grupa)

        return grupy
    except Exception as e:
        print(f"❌ Błąd parsowania grup: {e}")
        return []

def scrape_grupy_for_kierunki(kierunki: list) -> list[dict]:
    """Scrapuje grupy dla listy kierunków."""
    wszystkie_grupy = []

    for kierunek in kierunki:
        # Sprawdź typ kierunku przed próbą dostępu do atrybutów
        if isinstance(kierunek, str):
            print(f"❌ Pominięto kierunek przekazany jako string: {kierunek}")
            continue

        nazwa_kierunku = kierunek.get('nazwa_kierunku', 'Nieznany kierunek')
        wydzial = kierunek.get('wydzial', 'Nieznany wydział')
        kierunek_id = kierunek.get('id')
        link_kierunku = kierunek.get('link_kierunku') or kierunek.get('link_strony_kierunku')

        print(f"\n🔍 Pobieram grupy dla kierunku: {nazwa_kierunku}")
        html = fetch_page(link_kierunku)
        if html:
            grupy = parse_grupy(html, nazwa_kierunku, wydzial, kierunek_id)
            wszystkie_grupy.extend(grupy)
            print(f"✅ Pobrano {len(grupy)} grup dla kierunku {nazwa_kierunku}")

    return wszystkie_grupy