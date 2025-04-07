import logging
import os
from scraper import PlanUZScraper
from ics_parser import ICSParser
from db import SupabaseClient

# Konfiguracja logowania
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    """Główna funkcja uruchamiająca cały proces scrapowania i zapisywania danych"""
    logger.info("Rozpoczynanie procesu scrapowania danych z planu UZ")

    # Pobierz dane z zmiennych środowiskowych (GitHub Secrets)
    supabase_url = os.environ.get("SUPABASE_URL")
    supabase_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

    if not supabase_url or not supabase_key:
        logger.error("Brak wymaganych zmiennych środowiskowych SUPABASE_URL lub SUPABASE_SERVICE_ROLE_KEY")
        return

    # Inicjalizacja klientów
    db = SupabaseClient(supabase_url, supabase_key)
    scraper = PlanUZScraper()
    ics_parser = ICSParser()

    # 1. Pobierz kierunki
    kierunki = scraper.get_kierunki()
    db.upsert_kierunki(kierunki)

    # 2. Dla każdego kierunku pobierz grupy
    for kierunek in kierunki:
        grupy = scraper.get_grupy(kierunek['link_grupy'])

        # Dodaj referencję do oryginalnego ID kierunku
        for grupa in grupy:
            grupa['original_kierunek_id'] = kierunek['kierunek_id']

        db.upsert_grupy(grupy)

        # 3. Dla każdej grupy pobierz plan i nauczycieli
        for grupa in grupy:
            plan_info = scraper.get_plan_grupy(grupa['link_planu'])

            # 4. Pobierz i sparsuj plik ICS grupy
            if plan_info['link_ics']:
                ics_content = scraper.download_ics(plan_info['link_ics'])
                wydarzenia = ics_parser.parse_ics_content(ics_content)

                # Dodaj link_ics do każdego wydarzenia
                for wydarzenie in wydarzenia:
                    wydarzenie['link_ics'] = plan_info['link_ics']

                # Zapisz wydarzenia do bazy używając link_planu grupy zamiast ID
                db.upsert_plany_grup(grupa['link_planu'], wydarzenia)

            # 5. Zapisz i przetwórz dane nauczycieli
            for nauczyciel_info in plan_info['nauczyciele']:
                # Sprawdź czy nauczyciel już istnieje w bazie po nazwie
                if not db.nauczyciel_exists(nauczyciel_info['nazwa']):
                    nauczyciel_dane = scraper.get_nauczyciel_info(nauczyciel_info['link'])
                    nauczyciel_dane['imie_nazwisko'] = nauczyciel_info['nazwa']
                    db.upsert_nauczyciele([nauczyciel_dane])

                    # Pobierz i sparsuj plik ICS nauczyciela
                    if nauczyciel_dane['link_ics']:
                        ics_content = scraper.download_ics(nauczyciel_dane['link_ics'])
                        wydarzenia = ics_parser.parse_ics_content(ics_content)

                        # Dodaj link_ics do każdego wydarzenia
                        for wydarzenie in wydarzenia:
                            wydarzenie['link_ics'] = nauczyciel_dane['link_ics']

                        # Zapisz wydarzenia do bazy używając imienia i nazwiska nauczyciela zamiast ID
                        db.upsert_plany_nauczycieli(nauczyciel_info['nazwa'], wydarzenia)

    logger.info("Zakończono proces scrapowania i zapisywania danych")

if __name__ == "__main__":
    main()