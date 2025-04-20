"""
Moduł do pobierania informacji o grupach studenckich z planu UZ.
"""
import concurrent.futures
import datetime
import requests
from bs4 import BeautifulSoup

try:
    from tqdm import tqdm
except ImportError:
    print("⚠️ Pakiet tqdm nie jest zainstalowany. Instalacja: pip install tqdm")
    def tqdm(iterable, **kwargs):
        print(kwargs.get("desc", "Przetwarzanie..."))
        return iterable

from scraper.downloader import fetch_page, BASE_URL
from scraper.parsers.grupy_parser import parsuj_html_grupa  # Używamy aliasu zamiast parse_grupa_details
from scraper.ics_updater import aktualizuj_plany_grup

def parse_grupy(html, nazwa_kierunku, wydzial, kierunek_id):
    """Parsuje grupy z HTML strony kierunku."""
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

def scrape_grupy_for_kierunki(kierunki, verbose=True):
    """Scrapuje grupy dla podanych kierunków."""
    wszystkie_grupy = []

    for kierunek in kierunki:
        if verbose:
            print(f"Pobieranie grup dla kierunku: {kierunek.get('nazwa_kierunku')}")

        link_kierunku = kierunek.get('link_strony_kierunku')
        if not link_kierunku:
            continue

        try:
            response = requests.get(link_kierunku)
            response.raise_for_status()
            soup = BeautifulSoup(response.text, 'html.parser')

            # Znajdujemy linki do grup
            grupy_links = soup.find_all('a', href=lambda href: href and 'grupy_plan.php?ID=' in href)

            for link in grupy_links:
                href = link.get('href', '')
                link_text = link.text.strip()

                # Wyciągamy tryb studiów bezpośrednio z tekstu linku
                tryb_studiow = "nieznany"
                if "niestacjonarne" in link_text.lower():
                    tryb_studiow = "niestacjonarne"
                elif "stacjonarne" in link_text.lower():
                    tryb_studiow = "stacjonarne"

                if 'ID=' in href:
                    grupa_id = href.split('ID=')[1].split('&')[0]
                else:
                    continue

                grupa_url = f"{BASE_URL}{href}"
                try:
                    grupa_response = requests.get(grupa_url)
                    grupa_response.raise_for_status()
                    grupa_info = parsuj_html_grupa(grupa_response.text)

                    grupa_data = {
                        'grupa_id': grupa_id,
                        'kod_grupy': grupa_info['kod_grupy'],
                        'link_grupy': grupa_url,
                        'kierunek_id': kierunek.get('id'),
                        'semestr': grupa_info['semestr'],
                        'tryb_studiow': tryb_studiow if tryb_studiow != "nieznany" else grupa_info['tryb_studiow'],
                        'link_ics_grupy': f"{BASE_URL}grupy_ics.php?ID={grupa_id}&KIND=GG"
                    }
                    wszystkie_grupy.append(grupa_data)

                except Exception as e:
                    if verbose:
                        print(f"  Błąd pobierania szczegółów grupy {grupa_id}: {e}")
                    # Awaryjnie użyj podstawowych danych
                    grupa_data = {
                        'grupa_id': grupa_id,
                        'kod_grupy': link_text,
                        'link_grupy': grupa_url,
                        'kierunek_id': kierunek.get('id'),
                        'tryb_studiow': tryb_studiow,
                        'link_ics_grupy': f"{BASE_URL}grupy_ics.php?ID={grupa_id}&KIND=GG"
                    }
                    wszystkie_grupy.append(grupa_data)

        except Exception as e:
            print(f"Błąd podczas pobierania grup dla kierunku: {e}")

    if verbose:
        print(f"Znaleziono łącznie {len(wszystkie_grupy)} grup")

    return wszystkie_grupy