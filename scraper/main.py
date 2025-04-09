import logging
import os
import argparse
from db import DB
from kierunki_scraper import KierunkiScraper
from grupy_scraper import GrupyScraper
from nauczyciele_scraper import NauczycieleScraper
from plany_scraper import PlanyScraper

# Konfiguracja logowania
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("scraper.log"),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger('UZ_Scraper')


def main():
    parser = argparse.ArgumentParser(description='UZ Scraper')

    # Parametry dla Supabase
    parser.add_argument('--supabase-url', default=os.environ.get('SUPABASE_URL', ''),
                        help='URL Supabase')
    parser.add_argument('--supabase-key', default=os.environ.get('SUPABASE_SERVICE_ROLE_KEY', ''),
                        help='Klucz Service Role Supabase')
    parser.add_argument('--base-url', default=os.environ.get('BASE_URL', 'http://plan.uz.zgora.pl'),
                        help='Base URL for scraping')

    args = parser.parse_args()

    # Sprawdzanie dostępności kluczy Supabase
    if not args.supabase_url:
        logger.error("Brak URL Supabase. Ustaw zmienną środowiskową SUPABASE_URL.")
        return

    if not args.supabase_key:
        logger.error(
            "Brak klucza Service Role Supabase. Ustaw zmienną środowiskową SUPABASE_SERVICE_ROLE_KEY.")
        return

    # Pokaż informacje o połączeniu (bez klucza)
    # noinspection PyCompatibility
    logger.info(f"Łączenie z bazą danych Supabase: {args.supabase_url}")

    # Inicjalizacja połączenia z bazą danych
    try:
        db = DB(
            supabase_url=args.supabase_url,
            supabase_key=args.supabase_key
        )
    except Exception as e:
        # noinspection PyCompatibility
        logger.error(f"Błąd połączenia z bazą danych: {str(e)}")
        raise

    base_url = args.base_url
    # noinspection PyCompatibility
    logger.info(f"Używam base_url: {base_url}")

    # Inicjalizacja scraperów z przekazaniem base_url
    kierunki_scraper = KierunkiScraper(db, base_url)
    grupy_scraper = GrupyScraper(db, base_url)
    nauczyciele_scraper = NauczycieleScraper(db, base_url)
    plany_scraper = PlanyScraper(db, base_url)

    try:
        # Uruchomienie scraperów
        logger.info("Scrapowanie kierunków...")
        kierunki_count = kierunki_scraper.scrape_and_save()
        # noinspection PyCompatibility
        logger.info(f"Zaktualizowano {kierunki_count} kierunków.")

        logger.info("Scrapowanie grup...")
        grupy_count = grupy_scraper.scrape_and_save()
        # noinspection PyCompatibility
        logger.info(f"Zaktualizowano {grupy_count} grup.")

        logger.info("Scrapowanie nauczycieli...")
        nauczyciele_count = nauczyciele_scraper.scrape_and_save()
        # noinspection PyCompatibility
        logger.info(f"Zaktualizowano {nauczyciele_count} nauczycieli.")

        logger.info("Scrapowanie planów...")
        plany_count = plany_scraper.scrape_and_save()
        # noinspection PyCompatibility
        logger.info(f"Zaktualizowano {plany_count} wpisów w planach.")

        logger.info("Scrapowanie zakończone pomyślnie!")
    except Exception as e:
        # noinspection PyCompatibility
        logger.error(f"Wystąpił błąd: {str(e)}")
    finally:
        db.close_connections()


if __name__ == "__main__":
    main()
