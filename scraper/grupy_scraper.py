#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import re
from utils import get_soup_from_url, normalize_text, full_url

logger = logging.getLogger('UZ_Scraper.Grupy')

class GrupyScraper:
    def __init__(self, db):
        self.db = db

    def scrape_and_save(self):
        """
        Scrapuje grupy dla wszystkich kierunków i zapisuje je do bazy danych.

        Returns:
            int: Liczba zaktualizowanych grup
        """
        logger.info("Rozpoczynam scrapowanie grup studenckich")

        # Pobierz wszystkie kierunki z bazy danych
        kierunki = self.db.get_all_kierunki()

        total_count = 0
        for kierunek in kierunki:
            if not kierunek.get('link_grupy'):
                logger.warning("Kierunek %s nie ma linku do grup", kierunek.get('nazwa_kierunku'))
                continue

            logger.info("Scrapowanie grup dla kierunku: %s", kierunek['nazwa_kierunku'])

            grupy_list = self.scrape_grupy_for_kierunek(kierunek)

            # Zapis do bazy danych
            count = 0
            for grupa in grupy_list:
                self.db.upsert_grupa(grupa)
                count += 1

            logger.info("Zaktualizowano %s grup dla kierunku %s",
                        count, kierunek['nazwa_kierunku'])
            total_count += count

        logger.info("Zakończono scrapowanie grup. Zaktualizowano łącznie %s grup", total_count)
        return total_count

    def scrape_grupy_for_kierunek(self, kierunek):
        """
        Scrapuje dane o grupach dla konkretnego kierunku.

        Args:
            kierunek: Słownik z danymi kierunku

        Returns:
            Lista słowników z danymi grup
        """
        grupy_data = []

        soup = get_soup_from_url(kierunek['link_grupy'])
        if not soup:
            logger.error("Nie udało się pobrać strony grup dla kierunku: %s",
                         kierunek['nazwa_kierunku'])
            return []

        # Znajdź grupy w odpowiedzi
        grupy_links = soup.select('a[href*="plan"]')

        for link in grupy_links:
            grupa_text = normalize_text(link.text)
            plan_link = full_url(link.get('href'))

            if not grupa_text or len(grupa_text) < 2:
                continue

            # Analizujemy tekst grupy, żeby wyciągnąć informacje
            tryb = self.extract_tryb(grupa_text)
            semestr = self.extract_semestr(grupa_text)
            kod_grupy = self.extract_kod_grupy(grupa_text)

            grupy_data.append({
                'kierunek_id': kierunek['id'],
                'tryb_studiow': tryb,
                'semestr': semestr,
                'kod_grupy': kod_grupy,
                'link_planu': plan_link
            })

            logger.debug("Znaleziono grupę: %s", kod_grupy if kod_grupy else grupa_text)

        logger.info("Znaleziono łącznie %s grup dla kierunku %s",
                    len(grupy_data), kierunek['nazwa_kierunku'])
        return grupy_data

    @staticmethod
    def extract_tryb(text):
        """Wyciąga tryb studiów z tekstu grupy."""
        tryby = {
            'stacjonarne': ['stacjonarne', 'dzienne', 'stacjonarny'],
            'niestacjonarne': ['niestacjonarne', 'zaoczne', 'niestacjonarny'],
        }

        text_lower = text.lower()
        for tryb, keywords in tryby.items():
            if any(keyword in text_lower for keyword in keywords):
                return tryb

        return None

    @staticmethod
    def extract_semestr(text):
        """Wyciąga semestr z tekstu grupy."""
        # Szukanie wzorca "sem. X" lub "X semestr"
        sem_pattern = re.compile(r'sem\.?\s*(\d+)|\b(\d+)\s*semestr', re.IGNORECASE)
        match = sem_pattern.search(text)

        if match:
            # Grupa 1 lub 2 zawiera numer semestru, w zależności od tego, który wzorzec zadziałał
            semestr = match.group(1) if match.group(1) else match.group(2)
            return "Semestr %s" % semestr

        return None

    @staticmethod
    def extract_kod_grupy(text):
        """Wyciąga kod grupy z tekstu grupy."""
        # Szukanie wzorca "Grupa X" lub kodu grupy np. "42INF-ISP-..."
        kod_pattern = re.compile(r'grupa\s+([A-Za-z0-9]+)|(\d+[A-Za-z]+-[A-Za-z]+-[\w-]+)', re.IGNORECASE)
        match = kod_pattern.search(text)

        if match:
            kod = match.group(1) if match.group(1) else match.group(2)
            return kod

        # Jeśli nie znaleziono, zwracamy cały tekst jako kod grupy
        return text