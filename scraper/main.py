# Główny skrypt uruchamiający cały proces scrapowania
import argparse
import time
import traceback
import sys
import requests
from db import Database
from kierunki_scraper import scrape_kierunki
from grupy_scraper import scrape_grupy
from nauczyciele_scraper import scrape_nauczyciele
from plany_scraper import scrape_plany_grup, scrape_plany_nauczycieli

def main():
    """Główna funkcja uruchamiająca cały proces scrapowania"""
    parser = argparse.ArgumentParser(description='Scraper planów zajęć UZ')
    parser.add_argument('--all', action='store_true', help='Scrapuj wszystkie dane')
    parser.add_argument('--kierunki', action='store_true', help='Scrapuj tylko kierunki')
    parser.add_argument('--grupy', action='store_true', help='Scrapuj tylko grupy')
    parser.add_argument('--nauczyciele', action='store_true', help='Scrapuj tylko nauczycieli')
    parser.add_argument('--plany-grup', action='store_true', help='Scrapuj tylko plany grup')
    parser.add_argument('--plany-nauczycieli', action='store_true', help='Scrapuj tylko plany nauczycieli')
    parser.add_argument('--debug', action='store_true', help='Włącz dodatkowe komunikaty diagnostyczne')
    parser.add_argument('--sequential', action='store_true', help='Wykonaj scrapowanie sekwencyjnie, zgodnie z zależnościami')

    args = parser.parse_args()

    # Jeśli nie podano żadnych opcji, scrapuj wszystko
    if not (args.kierunki or args.grupy or args.nauczyciele or args.plany_grup or args.plany_nauczycieli or args.sequential):
        args.all = True

    # Jeśli wybrano sequential, ignorujemy inne opcje i wykonujemy wszystko w odpowiedniej kolejności
    if args.sequential:
        args.all = False
        args.kierunki = args.grupy = args.plany_grup = args.nauczyciele = args.plany_nauczycieli = False

    # Inicjalizacja połączenia z bazą danych
    start_time = time.time()
    print("Inicjalizacja połączenia z bazą danych...")

    try:
        Database.initialize()

        # Scrapowanie danych
        kierunki_lista = []
        grupy_lista = []
        nauczyciele_lista = []

        # Wykonanie scrapowania sekwencyjnie z wykorzystaniem wyników poprzednich etapów
        if args.sequential:
            print("\n=== Sekwencyjne scrapowanie danych ===")

            # Krok 1: Scrapowanie kierunków
            print("\n=== Krok 1: Scrapowanie kierunków ===")
            try:
                kierunki_lista = scrape_kierunki()
            except Exception as e:
                print(f"Błąd podczas scrapowania kierunków: {e}")
                if args.debug:
                    traceback.print_exc()
                return

            # Krok 2: Scrapowanie grup dla uzyskanych kierunków
            print("\n=== Krok 2: Scrapowanie grup ===")
            try:
                grupy_lista = scrape_grupy(kierunki_lista)
            except Exception as e:
                print(f"Błąd podczas scrapowania grup: {e}")
                if args.debug:
                    traceback.print_exc()
                return

            # Krok 3: Scrapowanie planów grup
            print("\n=== Krok 3: Scrapowanie planów grup ===")
            try:
                scrape_plany_grup(grupy_lista)
            except Exception as e:
                print(f"Błąd podczas scrapowania planów grup: {e}")
                if args.debug:
                    traceback.print_exc()
                return

            # Krok 4: Scrapowanie nauczycieli z planów grup (implementacja tego kroku w plany_scraper.py)
            print("\n=== Krok 4: Scrapowanie nauczycieli ===")
            try:
                nauczyciele_lista = scrape_nauczyciele()
            except Exception as e:
                print(f"Błąd podczas scrapowania nauczycieli: {e}")
                if args.debug:
                    traceback.print_exc()
                return

            # Krok 5: Scrapowanie planów nauczycieli
            print("\n=== Krok 5: Scrapowanie planów nauczycieli ===")
            try:
                scrape_plany_nauczycieli(nauczyciele_lista)
            except Exception as e:
                print(f"Błąd podczas scrapowania planów nauczycieli: {e}")
                if args.debug:
                    traceback.print_exc()
                return

        # Standardowe wykonanie scrapowania według wybranych opcji
        else:
            if args.all or args.kierunki:
                print("\n=== Scrapowanie kierunków ===")
                try:
                    kierunki_lista = scrape_kierunki()
                except Exception as e:
                    print(f"Błąd podczas scrapowania kierunków: {e}")
                    if args.debug:
                        traceback.print_exc()

            if args.all or args.grupy:
                print("\n=== Scrapowanie grup ===")
                try:
                    grupy_lista = scrape_grupy(kierunki_lista if kierunki_lista else None)
                except Exception as e:
                    print(f"Błąd podczas scrapowania grup: {e}")
                    if args.debug:
                        traceback.print_exc()

            if args.all or args.nauczyciele:
                print("\n=== Scrapowanie nauczycieli ===")
                try:
                    nauczyciele_lista = scrape_nauczyciele()
                except Exception as e:
                    print(f"Błąd podczas scrapowania nauczycieli: {e}")
                    if args.debug:
                        traceback.print_exc()

            if args.all or args.plany_grup:
                print("\n=== Scrapowanie planów grup ===")
                try:
                    scrape_plany_grup(grupy_lista if grupy_lista else None)
                except Exception as e:
                    print(f"Błąd podczas scrapowania planów grup: {e}")
                    if args.debug:
                        traceback.print_exc()

            if args.all or args.plany_nauczycieli:
                print("\n=== Scrapowanie planów nauczycieli ===")
                try:
                    scrape_plany_nauczycieli(nauczyciele_lista if nauczyciele_lista else None)
                except Exception as e:
                    print(f"Błąd podczas scrapowania planów nauczycieli: {e}")
                    if args.debug:
                        traceback.print_exc()

        end_time = time.time()
        print(f"\nZakończono cały proces scrapowania. Czas wykonania: {end_time - start_time:.2f} sekund")

    except Exception as e:
        print(f"Krytyczny błąd podczas scrapowania: {e}")
        traceback.print_exc()

    finally:
        # Zamknięcie połączeń z bazą danych
        try:
            Database.close_all()
        except Exception:
            pass

if __name__ == "__main__":
    main()