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

try:
    from tqdm import tqdm
except ImportError:
    print("⚠️ Pakiet tqdm nie jest zainstalowany. Instalacja: pip install tqdm")
    # Zastępcza funkcja tqdm
    def tqdm(iterable, **kwargs):
        print(kwargs.get("desc", "Przetwarzanie..."))
        return iterable

from scraper.downloader import fetch_page, BASE_URL
from scraper.parsers.grupy_parser import parse_grupy
from scraper.ics_updater import aktualizuj_plany_grup


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
        kierunek_id = kierunek.get('kierunek_id')
        link_kierunku = kierunek.get('link_kierunku')

        print(f"\n🔍 Pobieram grupy dla kierunku: {nazwa_kierunku}")
        html = fetch_page(link_kierunku)
        if html:
            grupy = parse_grupy(html, nazwa_kierunku, wydzial, kierunek_id)
            wszystkie_grupy.extend(grupy)
            print(f"✅ Pobrano {len(grupy)} grup dla kierunku {nazwa_kierunku}")

    return wszystkie_grupy

def pobierz_grupy_rownolegle(kierunki, max_workers=10):
    """Zoptymalizowana wersja z bezpośrednim przetwarzaniem kierunków."""
    wyniki = []

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Tworzenie zadań dla pojedynczych kierunków
        def przetwarzaj_kierunek(kierunek):
            try:
                # Sprawdź typ kierunku przed próbą dostępu do atrybutów
                if isinstance(kierunek, str):
                    print(f"❌ Pominięto kierunek przekazany jako string: {kierunek}")
                    return []

                nazwa_kierunku = kierunek.get('nazwa_kierunku', 'Nieznany kierunek')
                wydzial = kierunek.get('wydzial', 'Nieznany wydział')
                kierunek_id = kierunek.get('kierunek_id')
                link_kierunku = kierunek.get('link_kierunku')

                print(f"🔍 Pobieram grupy dla kierunku: {nazwa_kierunku}")
                html = fetch_page(link_kierunku)
                if not html:
                    return []

                grupy = parse_grupy(html, nazwa_kierunku, wydzial, kierunek_id)
                print(f"✅ Pobrano {len(grupy)} grup dla kierunku {nazwa_kierunku}")
                return grupy
            except Exception as e:
                nazwa = kierunek.get('nazwa_kierunku', 'nieznanego kierunku') if isinstance(kierunek, dict) else 'nieznanego kierunku'
                print(f"❌ Błąd dla {nazwa}: {e}")
                return []

        # Uruchomienie wszystkich zadań i zebranie wyników
        zadania = [executor.submit(przetwarzaj_kierunek, k) for k in kierunki]
        for zadanie in concurrent.futures.as_completed(zadania):
            try:
                wynik = zadanie.result()
                wyniki.extend(wynik)
            except Exception as e:
                print(f"❌ Nieobsłużony błąd: {e}")

    return wyniki

if __name__ == "__main__":
    # Dla samodzielnego testowania
    from scraper.scrapers.kierunki_scraper import scrape_kierunki

    # Testowanie scrapowania grup
    kierunki = scrape_kierunki()[:2]  # Pobieramy tylko 2 kierunki do testów
    grupy = scrape_grupy_for_kierunki(kierunki)

    print(f"\nPobrano {len(grupy)} grup.")

    # Testowanie aktualizacji planów (jeśli mamy jakieś ID)
    if grupy:
        grupa_ids = [g['grupa_id'] for g in grupy[:2] if 'grupa_id' in g]
        if grupa_ids:
            aktualizowane = aktualizuj_plany_grup(grupa_ids)
            print(f"Zaktualizowano {len(aktualizowane)} planów grup.")