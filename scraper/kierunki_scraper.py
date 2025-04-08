#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
from utils import get_soup_from_url, normalize_text, full_url

logger = logging.getLogger('UZ_Scraper.Kierunki')

class KierunkiScraper:
    def __init__(self, db):
        self.db = db
        self.start_url = "https://plan.uz.zgora.pl/"

    def scrape_and_save(self):
        """
        Scrapuje kierunki studiów i zapisuje je do bazy danych.

        Returns:
            int: Liczba zaktualizowanych kierunków
        """
        logger.info("Rozpoczynam scrapowanie kierunków studiów")

        kierunki_list = self.scrape_kierunki()

        # Zapis do bazy danych
        count = 0
        for kierunek in kierunki_list:
            self.db.upsert_kierunek(kierunek)
            count += 1

        logger.info("Zakończono scrapowanie kierunków. Zaktualizowano %s kierunków", count)
        return count

    def scrape_kierunki(self):
        """
        Scrapuje dane o kierunkach studiów.

        Returns:
            Lista słowników z danymi kierunków
        """
        soup = get_soup_from_url(self.start_url)
        if not soup:
            logger.error("Nie udało się pobrać strony głównej planów UZ")
            return []

        kierunki_data = []

        # Znajdź listę wydziałów
        wydzialy_options = soup.select('select[name="wydzial"] option')

        for wydzial_option in wydzialy_options:
            wydzial_value = wydzial_option.get('value')
            wydzial_name = normalize_text(wydzial_option.text)

            # Pomijamy opcję "wybierz wydział"
            if not wydzial_value or wydzial_value == "0" or "wybierz" in wydzial_name.lower():
                continue

            logger.info("Przetwarzanie wydziału: %s", wydzial_name)

            # Pobieramy kierunki dla tego wydziału
            kierunki_url = "%s?wydzial=%s" % (self.start_url, wydzial_value)
            kierunki_soup = get_soup_from_url(kierunki_url)

            if not kierunki_soup:
                logger.warning("Nie udało się pobrać listy kierunków dla wydziału: %s", wydzial_name)
                continue

            # Znajdź kierunki w odpowiedzi
            kierunki_links = kierunki_soup.select('a[href*="grupy"]')

            for link in kierunki_links:
                kierunek_name = normalize_text(link.text)
                # Upewniamy się, że używamy pełnego URL
                href = link.get('href')
                kierunek_link = full_url(href)

                if not kierunek_name or "wybierz" in kierunek_name.lower():
                    continue

                kierunki_data.append({
                    'nazwa_kierunku': kierunek_name,
                    'wydzial': wydzial_name,
                    'link_grupy': kierunek_link
                })
                logger.debug("Znaleziono kierunek: %s (%s)", kierunek_name, wydzial_name)

        logger.info("Znaleziono łącznie %s kierunków", len(kierunki_data))
        return kierunki_data