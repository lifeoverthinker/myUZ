import os
import sys
import requests
from bs4 import BeautifulSoup

# Importujemy funkcje z istniejących plików
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from scraper.ics_updater import BASE_URL



def test_parsowania_grupy(grupa_id):
    """Testuje parsowanie informacji o grupie."""
    url = f"{BASE_URL}grupy_plan.php?ID={grupa_id}"  # Poprawiony URL

    print(f"🔍 Pobieranie i parsowanie informacji o grupie {grupa_id}")
    print(f"URL: {url}")

    try:
        response = requests.get(url)
        response.raise_for_status()

        info_grupy = parsuj_html_grupa(response.text)

        print("\n=== INFORMACJE O GRUPIE ===")
        print(f"Kod grupy: {info_grupy['kod_grupy']}")
        print(f"Tryb studiów: {info_grupy['tryb_studiow']}")
        print(f"Semestr: {info_grupy['semestr']}")

        return info_grupy
    except Exception as e:
        print(f"❌ Błąd podczas pobierania/parsowania informacji o grupie: {e}")
        return None


if __name__ == "__main__":
    # Domyślne ID grupy do testów
    grupa_id = "29294"  # Można zmienić na rzeczywiste ID

    # Jeśli podano argument w linii poleceń, użyj go
    if len(sys.argv) > 1:
        grupa_id = sys.argv[1]

    test_parsowania_grupy(grupa_id)
