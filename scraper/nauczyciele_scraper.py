#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import re
from utils import get_soup_from_url, normalize_text, full_url

logger = logging.getLogger('UZ_Scraper.Nauczyciele')

class NauczycieleScraper:
    def __init__(self, db):
        self.db = db
        self.start_url = "https://plan.uz.zgora.pl/plan_nauczyciel.php"

    def scrape_and_save(self):
        """
        Scrapuje dane o nauczycielach i zapisuje je do bazy danych.

        Returns:
            int: Liczba zaktualizowanych nauczycieli
        """
        logger.info("Rozpoczynam scrapowanie nauczycieli")

        nauczyciele_list = self.scrape_nauczyciele()

        # Zapis do bazy danych
        count = 0
        for nauczyciel in nauczyciele_list:
            self.db.upsert_nauczyciel(nauczyciel)
            count += 1

        logger.info("Zakończono scrapowanie nauczycieli. Zaktualizowano %s nauczycieli", count)
        return count

    def scrape_nauczyciele(self):
        """
        Scrapuje dane o nauczycielach.

        Returns:
            Lista słowników z danymi nauczycieli
        """
        # Najpierw pobieramy stronę z wyborem instytutu
        soup = get_soup_from_url(self.start_url)
        if not soup:
            logger.error("Nie udało się pobrać strony z wyborem instytutu")
            return []

        nauczyciele_data = []

        # Znajdź listę instytutów
        instytuty_options = soup.select('select[name="instytut"] option')

        for instytut_option in instytuty_options:
            instytut_value = instytut_option.get('value')
            instytut_name = normalize_text(instytut_option.text)

            # Pomijamy opcję "wybierz instytut"
            if not instytut_value or instytut_value == "0" or "wybierz" in instytut_name.lower():
                continue

            logger.info("Przetwarzanie instytutu: %s", instytut_name)

            # Pobieramy nauczycieli dla tego instytutu
            nauczyciele_url = "%s?instytut=%s" % (self.start_url, instytut_value)
            nauczyciele_soup = get_soup_from_url(nauczyciele_url)

            if not nauczyciele_soup:
                logger.warning("Nie udało się pobrać listy nauczycieli dla instytutu: %s", instytut_name)
                continue

            # Znajdź nauczycieli w odpowiedzi
            nauczyciele_links = nauczyciele_soup.select('a[href*="nazwisko="]')

            for link in nauczyciele_links:
                nauczyciel_name = normalize_text(link.text)
                plan_link = full_url(link.get('href'))

                if not nauczyciel_name:
                    continue

                # Próba wyciągnięcia emaila (może nie być dostępny)
                email = self.extract_email(nauczyciel_name, plan_link)

                nauczyciele_data.append({
                    'imie_nazwisko': nauczyciel_name,
                    'instytut': instytut_name,
                    'email': email,
                    'link_planu': plan_link
                })
                logger.debug("Znaleziono nauczyciela: %s (%s)", nauczyciel_name, instytut_name)

        logger.info("Znaleziono łącznie %s nauczycieli", len(nauczyciele_data))
        return nauczyciele_data

    @staticmethod
    def extract_email(name, plan_link):
        """
        Próbuje pobrać stronę planu nauczyciela i wyciągnąć email.
        """
        # Czasami email jest dostępny na stronie planu
        soup = get_soup_from_url(plan_link)
        if not soup:
            return None

        # Szukamy adresu email w treści strony
        email_pattern = re.compile(r'[\w\.-]+@[\w\.-]+\.\w+')
        page_text = soup.get_text()
        match = email_pattern.search(page_text)

        if match:
            return match.group(0)

        # Jeśli nie znaleziono, próbujemy zgadnąć na podstawie nazwiska
        # (opcjonalnie - może nie działać dla wszystkich)
        try:
            # Rozdzielamy imię i nazwisko
            parts = name.split()
            if len(parts) >= 2:
                surname = parts[-1].lower()
                first_name_initial = parts[0][0].lower()
                # Typowy format UZ: j.kowalski@uz.zgora.pl
                return "%s.%s@uz.zgora.pl" % (first_name_initial, surname)
        except Exception:
            pass

        return None