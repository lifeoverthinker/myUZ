import logging
import os
import argparse
import sys
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
    parser.add_argument('--db-host', default=os.environ.get('DB_HOST', 'localhost'),
                        help='Database host')
    parser.add_argument('--db-name', default=os.environ.get('DB_NAME', 'myuz'),
                        help='Database name')
    parser.add_argument('--db-user', default=os.environ.get('DB_USER', 'postgres'),
                        help='Database user')
    parser.add_argument('--db-password', default=os.environ.get('DB_PASSWORD', 'postgres'),
                        help='Database password')
    parser.add_argument('--base-url', default=os.environ.get('BASE_URL', 'http://plan.uz.zgora.pl'),
                        help='Base URL for scraping')
    parser.add_argument('--threads', type=int, default=os.environ.get('THREADS', 8),
                        help='Number of threads to use')

    args = parser.parse_args()

    # Inicjalizacja połączenia z bazą danych
    try:
        db = DB(
            host=args.db_host,
            dbname=args.db_name,
            user=args.db_user,
            password=args.db_password
        )
    except Exception as e:
        logger.error("Błąd połączenia z bazą danych: {}".format(str(e)))
        sys.exit(1)

    base_url = args.base_url
    max_threads = args.threads

    logger.info("Używam base_url: {}".format(base_url))
    logger.info("Liczba wątków: {}".format(max_threads))

    # Inicjalizacja scraperów z przekazaniem base_url
    kierunki_scraper = KierunkiScraper(db, base_url)
    kierunki_scraper.max_threads = max_threads

    grupy_scraper = GrupyScraper(db, base_url)
    grupy_scraper.max_threads = max_threads

    nauczyciele_scraper = NauczycieleScraper(db, base_url)
    nauczyciele_scraper.max_threads = max_threads

    plany_scraper = PlanyScraper(db, base_url)
    plany_scraper.max_threads = max_threads * 2  # więcej wątków dla planów

    try:
        # Uruchomienie scraperów
        logger.info("Scrapowanie kierunków...")
        kierunki_count = kierunki_scraper.scrape_and_save()
        logger.info("Zaktualizowano {} kierunków.".format(kierunki_count))

        logger.info("Scrapowanie grup...")
        grupy_count = grupy_scraper.scrape_and_save()
        logger.info("Zaktualizowano {} grup.".format(grupy_count))

        logger.info("Scrapowanie nauczycieli...")
        nauczyciele_count = nauczyciele_scraper.scrape_and_save()
        logger.info("Zaktualizowano {} nauczycieli.".format(nauczyciele_count))

        logger.info("Scrapowanie planów...")
        plany_count = plany_scraper.scrape_and_save()
        logger.info("Zaktualizowano {} wpisów w planach.".format(plany_count))

        # Opcjonalne przetwarzanie do zunifikowanego modelu
        logger.info("Przetwarzanie planów do zunifikowanego modelu...")
        zajecia_count = db.process_plany_to_zajecia()
        logger.info("Przetworzono {} zajęć w zunifikowanym modelu.".format(zajecia_count))

        logger.info("Scrapowanie zakończone pomyślnie!")
    except Exception as e:
        logger.error("Wystąpił błąd: {}".format(str(e)))
    finally:
        db.close()

if __name__ == "__main__":
    main()