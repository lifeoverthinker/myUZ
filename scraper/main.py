#!/usr/bin/env python3
"""
Główny skrypt uruchamiający proces scrapowania planów zajęć UZ
Autor: lifeoverthinker
Data: 2025-04-08
"""

import time
import argparse
import sys
from datetime import datetime, UTC

# Importy lokalnych modułów
from kierunki_scraper import KierunkiScraper
from grupy_scraper import GrupyScraper
from plany_scraper import PlanyScraper
from nauczyciele_scraper import NauczycieleScraper
from ics_parser import IcsParser
from db import Database
from utils import setup_logging, save_to_json, print_stats

# Konfiguracja logowania
logger = setup_logging()

def main():
    # Parsowanie argumentów wiersza poleceń
    parser = argparse.ArgumentParser(description="Scraper planów zajęć UZ")
    parser.add_argument("--kierunek", help="ID kierunku do pobrania")
    parser.add_argument("--grupa", help="ID grupy do pobrania")
    parser.add_argument("--nauczyciel", help="ID nauczyciela do pobrania")
    parser.add_argument("--save", help="Ścieżka do zapisu danych w formacie JSON", default="")
    parser.add_argument("--no-db", help="Nie zapisuj danych do bazy", action="store_true")
    args = parser.parse_args()

    # Pomiar czasu wykonania
    start_time = time.time()
    logger.info("Rozpoczynanie procesu scrapowania planów zajęć UZ")

    # Inicjalizacja scraperów
    kierunki_scraper = KierunkiScraper()
    grupy_scraper = GrupyScraper()
    plany_scraper = PlanyScraper()
    nauczyciele_scraper = NauczycieleScraper()

    # Połączenie z bazą danych (jeśli wymagane)
    db = None
    if not args.no_db:
        db = Database()
        if not db.connect():
            logger.error("Nie można połączyć się z bazą danych. Kończenie...")
            sys.exit(1)

    try:
        # 1. Pobieranie kierunków
        if args.kierunek:
            # Pobierz tylko konkretny kierunek
            logger.info(f"Pobieranie danych dla kierunku o ID: {args.kierunek}")
            link_kierunku = f"grupy_lista_grup_kierunku.php?ID={args.kierunek}"
            kierunki = [{"kierunek_id": args.kierunek, "link_grupy": link_kierunku}]
        else:
            # Pobierz wszystkie kierunki
            logger.info("Pobieranie wszystkich kierunków")
            kierunki = kierunki_scraper.get_kierunki()
            logger.info(f"Pobrano {len(kierunki)} kierunków")

            # Zapisz kierunki do bazy danych
            if db and not args.no_db:
                for kierunek in kierunki:
                    db.save_kierunek(
                        kierunek.get('nazwa_kierunku', ''),
                        kierunek.get('wydzial', ''),
                        kierunek.get('link_grupy', '')
                    )
                logger.info(f"Zapisano {len(kierunki)} kierunków do bazy danych")

        # 2. Pobieranie grup dla kierunków
        if args.grupa:
            # Pobierz tylko konkretną grupę
            logger.info(f"Pobieranie danych dla grupy o ID: {args.grupa}")
            grupy = [{"grupa_id": args.grupa, "link_planu": f"grupy_plan.php?ID={args.grupa}"}]
        else:
            # Pobierz grupy dla wszystkich lub wybranego kierunku
            wszystkie_grupy = []
            for kierunek in kierunki:
                grupy_kierunku = grupy_scraper.get_grupy(kierunek.get('link_grupy', ''))
                for grupa in grupy_kierunku:
                    grupa['kierunek_id'] = kierunek.get('kierunek_id', '')
                wszystkie_grupy.extend(grupy_kierunku)
                logger.info(f"Pobrano {len(grupy_kierunku)} grup dla kierunku {kierunek.get('kierunek_id', '')}")

            grupy = wszystkie_grupy
            logger.info(f"Łącznie pobrano {len(grupy)} grup")

            # Zapisz grupy do bazy danych
            if db and not args.no_db:
                for grupa in grupy:
                    db.save_grupa(
                        grupa.get('kod_grupy', ''),
                        grupa.get('nazwa_grupy', ''),
                        grupa.get('semestr', ''),
                        grupa.get('tryb_studiow', ''),
                        grupa.get('kierunek_id', ''),
                        grupa.get('link_planu', '')
                    )
                logger.info(f"Zapisano {len(grupy)} grup do bazy danych")

        # 3. Pobieranie planów zajęć dla grup
        plany = {}
        nauczyciele_do_pobrania = set()

        for grupa in grupy:
            plan = plany_scraper.get_plan_grupy(grupa.get('link_planu', ''))
            plany[grupa.get('grupa_id', '')] = plan

            # Zbierz nauczycieli do pobrania
            for nauczyciel in plan.get('nauczyciele', []):
                nauczyciele_do_pobrania.add((nauczyciel.get('nauczyciel_id', ''), nauczyciel.get('link', '')))

            # Pobierz plik ICS i sparsuj wydarzenia
            if plan.get('link_ics'):
                ics_content = plany_scraper.download_ics(plan.get('link_ics', ''))
                if ics_content:
                    events = IcsParser.parse_ics_content(ics_content)

                    # Dodaj wydarzenia do planu zajęć
                    for event in events:
                        # Znajdź pasujące wydarzenie w planie i uzupełnij termin
                        for wydarzenie in plan.get('wydarzenia', []):
                            # Sprawdź czy to samo wydarzenie (ten sam przedmiot i godzina)
                            if (wydarzenie.get('przedmiot') in event.get('przedmiot', '') and
                                    wydarzenie.get('od') == event.get('start_time', '')):
                                wydarzenie['terminy'] = f"{event.get('start_date', '')} {event.get('start_time', '')}-{event.get('end_time', '')}"

            # Zapisz plan zajęć do bazy danych
            if db and not args.no_db:
                wydarzenia_do_zapisu = []
                for wydarzenie in plan.get('wydarzenia', []):
                    # Znajdź nauczyciela
                    nauczyciel_info = {}
                    for n in plan.get('nauczyciele', []):
                        if n.get('nazwa', '') == wydarzenie.get('prowadzacy', ''):
                            nauczyciel_info = {
                                'imie_nazwisko': n.get('nazwa', ''),
                                'link_planu': n.get('link', ''),
                                'id': n.get('nauczyciel_id', '')
                            }

                    wydarzenia_do_zapisu.append({
                        'przedmiot': wydarzenie.get('przedmiot', ''),
                        'nauczyciel': nauczyciel_info,
                        'rz': wydarzenie.get('typ_zajec', ''),
                        'miejsce': wydarzenie.get('miejsce', ''),
                        'terminy': wydarzenie.get('terminy', ''),
                        'od': wydarzenie.get('od', ''),
                        'do': wydarzenie.get('do', '')
                    })

                db.save_events_for_group(grupa.get('grupa_id', ''), wydarzenia_do_zapisu)

        # 4. Pobieranie danych nauczycieli
        nauczyciele = {}

        for nauczyciel_id, nauczyciel_link in nauczyciele_do_pobrania:
            if args.nauczyciel and args.nauczyciel != nauczyciel_id:
                continue  # Pomiń nauczycieli, którzy nie pasują do filtru

            info = nauczyciele_scraper.get_nauczyciel_info(nauczyciel_link)
            nauczyciele[nauczyciel_id] = info

            # Zapisz nauczyciela do bazy danych
            if db and not args.no_db:
                db.get_or_create_nauczyciel({
                    'id': nauczyciel_id,
                    'imie_nazwisko': info.get('imie_nazwisko', ''),
                    'instytut': info.get('instytut', ''),
                    'email': info.get('email', ''),
                    'link_planu': nauczyciel_link
                })

        logger.info(f"Pobrano informacje o {len(nauczyciele)} nauczycielach")

        # Zapisz wszystkie dane do pliku JSON jeśli podano ścieżkę
        if args.save:
            dane = {
                'kierunki': kierunki,
                'grupy': grupy,
                'plany': plany,
                'nauczyciele': nauczyciele,
                'statystyki': {
                    'data_pobrania': datetime.now(UTC).isoformat(),
                    'liczba_kierunkow': len(kierunki),
                    'liczba_grup': len(grupy),
                    'liczba_planow': len(plany),
                    'liczba_nauczycieli': len(nauczyciele)
                }
            }
            save_to_json(dane, args.save)
            logger.info(f"Zapisano dane do pliku {args.save}")

        # Pokaż statystyki
        elapsed_time = time.time() - start_time
        print_stats({
            'liczba_kierunkow': len(kierunki),
            'liczba_grup': len(grupy),
            'liczba_planow': len(plany),
            'liczba_nauczycieli': len(nauczyciele),
            'czas_wykonania': f"{elapsed_time:.2f} s"
        })

    except Exception as e:
        logger.error(f"Wystąpił błąd podczas scrapowania: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
    finally:
        # Zamknij połączenie z bazą danych
        if db:
            db.disconnect()

        logger.info(f"Zakończono proces scrapowania w {time.time() - start_time:.2f} sekund")

if __name__ == "__main__":
    main()