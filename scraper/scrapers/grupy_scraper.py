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
from typing import List

try:
    from tqdm import tqdm
except ImportError:
    print("⚠️ Pakiet tqdm nie jest zainstalowany. Instalacja: pip install tqdm")
    def tqdm(iterable, **kwargs):
        print(kwargs.get("desc", "Przetwarzanie..."))
        return iterable

from scraper.downloader import fetch_page, BASE_URL
from scraper.models import Grupa, Kierunek
from scraper.parsers.grupy_parser import parse_grupy as parse_grupy_parser
from scraper.ics_updater import aktualizuj_plany_grup

def parse_grupy_html(html, nazwa_kierunku, wydzial, kierunek_id) -> List[Grupa]:
    """Parsuje grupy z HTML."""
    soup = BeautifulSoup(html, 'html.parser')
    grupy = []

    try:
        # Znajdź informację o semestrze w nagłówku H3
        semestr = "nieznany"
        h3_tags = soup.find_all("h3")
        for h3 in h3_tags:
            text = h3.text.lower()
            if "semestr letni" in text:
                semestr = "letni"
                break
            elif "semestr zimowy" in text:
                semestr = "zimowy"
                break

        # Znajdź wszystkie wiersze tabeli z linkami do grup
        rows = soup.select("tr.odd td a, tr.even td a")

        for row in rows:
            link = row.get('href')
            kod_grupy = row.text.strip()

            if not link or not kod_grupy:
                continue

            # Tryb studiów - potrzebujemy go wyciągnąć z nagłówka H3
            tryb_studiow = "nieznany"
            for h3 in h3_tags:
                text = h3.text.lower()
                if "stacjonarne" in text:
                    tryb_studiow = "stacjonarne"
                    break
                elif "niestacjonarne" in text:
                    tryb_studiow = "niestacjonarne"
                    break

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
                grupa = Grupa(
                    grupa_id=grupa_id,
                    kod_grupy=kod_grupy,
                    kierunek_id=kierunek_id,
                    wydzial=wydzial,
                    tryb_studiow=tryb_studiow,
                    semestr=semestr,
                    link_grupy=full_link,
                    link_ics_grupy=ics_link
                )
                grupy.append(grupa)

        return grupy
    except Exception as e:
        print(f"❌ Błąd parsowania grup: {e}")
        return []

def scrape_grupy_for_kierunki(kierunki: list) -> List[Grupa]:
    """Scrapuje grupy dla listy kierunków."""
    wszystkie_grupy = []

    for kierunek in kierunki:
        # Sprawdź typ kierunku przed próbą dostępu do atrybutów
        if isinstance(kierunek, str):
            print(f"❌ Pominięto kierunek przekazany jako string: {kierunek}")
            continue

        # Obsługa zarówno obiektu Kierunek jak i słownika
        if isinstance(kierunek, Kierunek):
            nazwa_kierunku = kierunek.nazwa_kierunku
            wydzial = kierunek.wydzial
            kierunek_id = kierunek.kierunek_id
            link_kierunku = kierunek.link_strony_kierunku
        else:
            nazwa_kierunku = kierunek.get('nazwa_kierunku', 'Nieznany kierunek')
            wydzial = kierunek.get('wydzial', 'Nieznany wydział')
            kierunek_id = kierunek.get('id') or kierunek.get('kierunek_id')
            link_kierunku = kierunek.get('link_kierunku') or kierunek.get('link_strony_kierunku')

        print(f"\n🔍 Pobieram grupy dla kierunku: {nazwa_kierunku}")
        html = fetch_page(link_kierunku)
        if html:
            grupy = parse_grupy_html(html, nazwa_kierunku, wydzial, kierunek_id)
            wszystkie_grupy.extend(grupy)
            print(f"✅ Pobrano {len(grupy)} grup dla kierunku {nazwa_kierunku}")

    return wszystkie_grupy