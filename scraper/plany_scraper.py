#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import re
from utils import get_soup_from_url, normalize_text, full_url
from ics_parser import ICSParser

logger = logging.getLogger('UZ_Scraper.Plany')

class PlanyScraper:
    def __init__(self, db):
        self.db = db
        self.ics_parser = ICSParser()

    def scrape_and_save(self):
        """
        Scrapuje plany zajęć dla grup i nauczycieli, zapisuje je do bazy danych.

        Returns:
            int: Liczba zaktualizowanych zajęć
        """
        logger.info("Rozpoczynam scrapowanie planów zajęć")

        # 1. Scrapowanie planów grup
        grupy_count = self.scrape_plany_grup()

        # 2. Scrapowanie planów nauczycieli
        nauczyciele_count = self.scrape_plany_nauczycieli()

        total_count = grupy_count + nauczyciele_count
        logger.info("Zakończono scrapowanie planów. Zaktualizowano łącznie %s zajęć", total_count)
        return total_count

    def scrape_plany_grup(self):
        """
        Scrapuje plany zajęć dla wszystkich grup.

        Returns:
            int: Liczba zaktualizowanych zajęć
        """
        logger.info("Scrapowanie planów zajęć dla grup studenckich")

        grupy = self.db.get_all_grupy()

        count = 0
        for grupa in grupy:
            if not grupa.get('link_planu'):
                logger.warning("Grupa %s nie ma linku do planu", grupa.get('kod_grupy', 'bez kodu'))
                continue

            grupa_id = grupa['id']
            plan_link = grupa['link_planu']

            # Pobieramy stronę z planem zajęć
            soup = get_soup_from_url(plan_link)
            if not soup:
                logger.warning("Nie udało się pobrać planu dla grupy %s", grupa.get('kod_grupy', 'bez kodu'))
                continue

            # Szukamy linku do pliku ICS (kalendarz)
            ics_link = self.find_ics_link(soup)
            if not ics_link:
                logger.warning("Nie znaleziono linku ICS dla grupy %s", grupa.get('kod_grupy', 'bez kodu'))
                continue

            # Parsujemy zawartość pliku ICS
            logger.info("Przetwarzanie planu ICS dla grupy %s", grupa.get('kod_grupy', 'bez kodu'))
            events = self.ics_parser.parse_ics_url(ics_link)

            # Dla każdego wydarzenia w kalendarzu, zapisujemy je do bazy
            event_count = 0
            for event in events:
                # Zapisujemy zajęcia
                zajecia_data = {
                    'przedmiot': event['summary'],
                    'od': event['start'],
                    'do_': event['end'],
                    'miejsce': event.get('location', ''),
                    'rz': event.get('description', '').strip(),
                    'link_ics': ics_link
                }

                # Zapisujemy zajęcia i powiązanie z grupą
                zajecia, is_new = self.db.upsert_zajecia(zajecia_data)
                self.db.link_zajecia_to_grupa(zajecia['id'], grupa_id)

                # Jeśli zajęcia są prowadzone przez nauczyciela, dodajemy powiązanie
                nauczyciel_imie = self.extract_teacher_from_event(event)
                if nauczyciel_imie:
                    nauczyciel = self.db.get_nauczyciel_by_name(nauczyciel_imie)
                    if nauczyciel:
                        self.db.link_zajecia_to_nauczyciel(zajecia['id'], nauczyciel['id'])

                event_count += 1
                if is_new:
                    count += 1

            logger.info("Przetworzono %s zajęć dla grupy %s",
                        event_count, grupa.get('kod_grupy', 'bez kodu'))

        logger.info("Zakończono scrapowanie planów grup. Dodano %s nowych zajęć", count)
        return count

    def scrape_plany_nauczycieli(self):
        """
        Scrapuje plany zajęć dla wszystkich nauczycieli.

        Returns:
            int: Liczba zaktualizowanych zajęć
        """
        logger.info("Scrapowanie planów zajęć dla nauczycieli")

        nauczyciele = self.db.get_all_nauczyciele()

        count = 0
        for nauczyciel in nauczyciele:
            if not nauczyciel.get('link_planu'):
                logger.warning("Nauczyciel %s nie ma linku do planu", nauczyciel.get('imie_nazwisko'))
                continue

            nauczyciel_id = nauczyciel['id']
            plan_link = nauczyciel['link_planu']

            # Pobieramy stronę z planem zajęć
            soup = get_soup_from_url(plan_link)
            if not soup:
                logger.warning("Nie udało się pobrać planu dla nauczyciela %s",
                               nauczyciel.get('imie_nazwisko'))
                continue

            # Szukamy linku do pliku ICS (kalendarz)
            ics_link = self.find_ics_link(soup)
            if not ics_link:
                logger.warning("Nie znaleziono linku ICS dla nauczyciela %s",
                               nauczyciel.get('imie_nazwisko'))
                continue

            # Parsujemy zawartość pliku ICS
            logger.info("Przetwarzanie planu ICS dla nauczyciela %s",
                        nauczyciel.get('imie_nazwisko'))
            events = self.ics_parser.parse_ics_url(ics_link)

            # Dla każdego wydarzenia w kalendarzu, zapisujemy je do bazy
            event_count = 0
            for event in events:
                # Zapisujemy zajęcia
                zajecia_data = {
                    'przedmiot': event['summary'],
                    'od': event['start'],
                    'do_': event['end'],
                    'miejsce': event.get('location', ''),
                    'rz': event.get('description', '').strip(),
                    'link_ics': ics_link
                }

                # Zapisujemy zajęcia i powiązanie z nauczycielem
                zajecia, is_new = self.db.upsert_zajecia(zajecia_data)
                self.db.link_zajecia_to_nauczyciel(zajecia['id'], nauczyciel_id)

                # Jeśli zajęcia są dla grup, dodajemy powiązania
                grupy_kody = self.extract_groups_from_event(event)
                for kod_grupy in grupy_kody:
                    grupa = self.db.get_grupa_by_kod(kod_grupy)
                    if grupa:
                        self.db.link_zajecia_to_grupa(zajecia['id'], grupa['id'])

                event_count += 1
                if is_new:
                    count += 1

            logger.info("Przetworzono %s zajęć dla nauczyciela %s",
                        event_count, nauczyciel.get('imie_nazwisko'))

        logger.info("Zakończono scrapowanie planów nauczycieli. Dodano %s nowych zajęć", count)
        return count

    @staticmethod
    def find_ics_link(soup):
        """Znajduje link do pliku ICS na stronie z planem."""
        ics_links = soup.select('a[href*=".ics"]')
        if ics_links:
            return full_url(ics_links[0].get('href'))
        return None

    @staticmethod
    def extract_teacher_from_event(event):
        """Wyciąga imię i nazwisko nauczyciela z wydarzenia w kalendarzu."""
        description = event.get('description', '')

        # Szukanie wzorca "Prowadzący: Nazwisko Imię"
        teacher_pattern = re.compile(r'prowadz[ąa]cy:?\s*([^,\n]+)', re.IGNORECASE)
        match = teacher_pattern.search(description)

        if match:
            return normalize_text(match.group(1))

        return None

    @staticmethod
    def extract_groups_from_event(event):
        """Wyciąga kody grup z wydarzenia w kalendarzu."""
        description = event.get('description', '')
        result = []

        # Szukanie wzorca "grupy: xxxxx, yyyy"
        groups_pattern = re.compile(r'grupy:?\s*([^,\n]+(?:,[^,\n]+)*)', re.IGNORECASE)
        match = groups_pattern.search(description)

        if match:
            groups_text = match.group(1)
            groups = [normalize_text(g) for g in groups_text.split(',')]
            result.extend(groups)

        # Szukanie wzorców kodów grup
        kod_pattern = re.compile(r'\b\d+[A-Za-z]+-[A-Za-z]+-[\w-]+\b')
        kod_matches = kod_pattern.findall(description)

        if kod_matches:
            result.extend(kod_matches)

        return list(set(result))  # Usuwamy duplikaty