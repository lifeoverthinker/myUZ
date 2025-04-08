#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import time
import os
from datetime import datetime

from db import Database
from kierunki_scraper import KierunkiScraper
from grupy_scraper import GrupyScraper
from nauczyciele_scraper import NauczycieleScraper
from plany_scraper import PlanyScraper

# Konfiguracja logowania
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger('UZ_Scraper')

def main():
    start_time = time.time()
    logger.info("Rozpoczęcie scrapowania planów UZ: %s",
                datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    # Sprawdź, czy zmienne środowiskowe są dostępne
    supabase_url = os.environ.get("SUPABASE_URL")
    supabase_key = os.environ.get("SUPABASE_KEY")
    supabase_service_role_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

    if not (supabase_url and (supabase_key or supabase_service_role_key)):
        logger.warning(
            "!!! UWAGA: Uruchamiasz skrypt w trybie testowym, bez połączenia z rzeczywistą bazą danych !!!\n"
            "Dane NIE zostaną zapisane w bazie. Aby połączyć się z rzeczywistą bazą, ustaw zmienne środowiskowe:\n"
            "SUPABASE_URL i SUPABASE_KEY lub SUPABASE_SERVICE_ROLE_KEY\n"
            "Można je zdefiniować w wierszu poleceń przed uruchomieniem skryptu, np.:\n"
            "  set SUPABASE_URL=https://twoj-projekt.supabase.co\n"
            "  set SUPABASE_KEY=twoj-klucz\n"
            "  python scraper/main.py\n"
            "Kontynuuję w trybie testowym...\n"
        )

    # Inicjalizacja połączenia z bazą danych
    db = Database()

    try:
        # 1. Scrapowanie kierunków
        kierunki_scraper = KierunkiScraper(db)
        kierunki_count = kierunki_scraper.scrape_and_save()
        logger.info("Zaktualizowano %s kierunków", kierunki_count)

        # 2. Scrapowanie grup dla każdego kierunku
        grupy_scraper = GrupyScraper(db)
        grupy_count = grupy_scraper.scrape_and_save()
        logger.info("Zaktualizowano %s grup", grupy_count)

        # 3. Scrapowanie nauczycieli
        nauczyciele_scraper = NauczycieleScraper(db)
        nauczyciele_count = nauczyciele_scraper.scrape_and_save()
        logger.info("Zaktualizowano %s nauczycieli", nauczyciele_count)

        # 4. Scrapowanie planów zajęć dla grup i nauczycieli
        plany_scraper = PlanyScraper(db)
        zajecia_count = plany_scraper.scrape_and_save()
        logger.info("Zaktualizowano %s zajęć", zajecia_count)

        # Podsumowanie
        elapsed_time = time.time() - start_time
        logger.info("Scrapowanie zakończone w %.2f sekund", elapsed_time)
        logger.info("Zescrapowano: %s kierunków, %s grup, %s nauczycieli, %s zajęć",
                    kierunki_count, grupy_count, nauczyciele_count, zajecia_count)

    except Exception as e:
        logger.error("Wystąpił błąd podczas scrapowania: %s", str(e))
        raise
    finally:
        # Zamknięcie połączenia z bazą danych
        db.close()

if __name__ == "__main__":
    main()