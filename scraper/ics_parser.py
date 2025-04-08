#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import re
from utils import make_request, format_datetime_for_db
from datetime import datetime

logger = logging.getLogger('UZ_Scraper.ICS')

class ICSParser:
    def __init__(self):
        pass

    def parse_ics_url(self, url):
        """
        Pobiera i parsuje plik ICS (iCalendar) z podanego URL.

        Args:
            url: URL do pliku ICS

        Returns:
            Lista słowników zawierających wydarzenia z kalendarza
        """
        logger.info("Pobieranie pliku ICS z: %s", url)

        response = make_request(url)
        if not response:
            logger.error("Nie udało się pobrać pliku ICS z %s", url)
            return []

        ics_content = response.text
        return self.parse_ics_content(ics_content)

    def parse_ics_content(self, ics_content):
        """
        Parsuje zawartość pliku ICS (iCalendar).

        Args:
            ics_content: Zawartość pliku ICS

        Returns:
            Lista słowników zawierających wydarzenia z kalendarza
        """
        events = []
        current_event = None

        lines = ics_content.splitlines()

        for line in lines:
            line = line.strip()

            # Początek wydarzenia
            if line == "BEGIN:VEVENT":
                current_event = {}

            # Koniec wydarzenia - dodajemy do listy
            elif line == "END:VEVENT" and current_event:
                events.append(current_event)
                current_event = None

            # Parsowanie właściwości wydarzenia
            elif current_event is not None and ":" in line:
                key, value = line.split(":", 1)

                # Obsługa linii kontynuacji
                if key.startswith(" ") and current_event:
                    # Dodanie do poprzedniej wartości
                    last_key = list(current_event.keys())[-1]
                    current_event[last_key] += value
                    continue

                # Obsługa parametrów (np. DTSTART;TZID=...)
                if ";" in key:
                    key = key.split(";")[0]

                # Konwersja kluczy
                if key == "SUMMARY":
                    current_event["summary"] = value
                elif key == "LOCATION":
                    current_event["location"] = value
                elif key == "DESCRIPTION":
                    current_event["description"] = value
                elif key == "DTSTART":
                    current_event["start"] = self.convert_ics_datetime(value)
                elif key == "DTEND":
                    current_event["end"] = self.convert_ics_datetime(value)

        logger.info("Znaleziono %s wydarzeń w pliku ICS", len(events))
        return events

    @staticmethod
    def convert_ics_datetime(ics_datetime):
        """
        Konwertuje format daty i czasu z ICS na format używany w bazie danych.

        Args:
            ics_datetime: Data i czas w formacie ICS (np. 20220105T083000Z)

        Returns:
            Data i czas w formacie PostgreSQL (np. 2022-01-05 08:30:00)
        """
        # Usuwamy 'Z' z końca jeśli istnieje
        if ics_datetime.endswith('Z'):
            ics_datetime = ics_datetime[:-1]

        # Format ICS: YYYYMMDDTHHMMSS
        pattern = r'(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})'
        match = re.match(pattern, ics_datetime)

        if match:
            year, month, day, hour, minute, second = map(int, match.groups())
            dt = datetime(year, month, day, hour, minute, second)
            return format_datetime_for_db(dt)

        # W przypadku błędu, zwracamy oryginalny string
        logger.warning("Nie udało się sparsować daty ICS: %s", ics_datetime)
        return ics_datetime