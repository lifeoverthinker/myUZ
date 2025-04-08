"""
Moduł do parsowania plików ICS
Autor: lifeoverthinker
Data: 2025-04-08
"""

import re
import logging
from datetime import datetime
from typing import Dict, List

logger = logging.getLogger(__name__)

class IcsParser:
    """Klasa do parsowania plików ICS z planami zajęć"""

    @staticmethod
    def parse_ics_content(ics_content: str) -> List[Dict]:
        """
        Parsuje zawartość pliku ICS i zwraca listę wydarzeń

        Args:
            ics_content: Zawartość pliku ICS jako tekst

        Returns:
            Lista wydarzeń wyekstrahowanych z pliku ICS
        """
        events = []
        event = None

        for line in ics_content.split('\n'):
            line = line.strip()

            if line == 'BEGIN:VEVENT':
                event = {}
            elif line == 'END:VEVENT':
                if event:
                    events.append(event)
                event = None
            elif event is not None:
                if ':' in line:
                    key, value = line.split(':', 1)
                    if key == 'DTSTART':
                        # Konwersja daty i czasu z formatu ICS na format czytelny
                        try:
                            dt = datetime.strptime(value, '%Y%m%dT%H%M%S')
                            event['start_date'] = dt.strftime('%Y-%m-%d')
                            event['start_time'] = dt.strftime('%H:%M')
                        except ValueError:
                            logger.error(f"Błąd parsowania daty: {value}")
                    elif key == 'DTEND':
                        try:
                            dt = datetime.strptime(value, '%Y%m%dT%H%M%S')
                            event['end_date'] = dt.strftime('%Y-%m-%d')
                            event['end_time'] = dt.strftime('%H:%M')
                        except ValueError:
                            logger.error(f"Błąd parsowania daty: {value}")
                    elif key == 'SUMMARY':
                        # Parsowanie nazwy przedmiotu i nauczyciela
                        summary_parts = value.split(':', 1)
                        if len(summary_parts) > 1:
                            przedmiot_z_typem = summary_parts[0].strip()
                            nauczyciel = summary_parts[1].strip()

                            # Wydzielenie typu zajęć (W, Ć, L, itp.)
                            przedmiot_match = re.match(r'(.*?)\s*\((.*?)\)', przedmiot_z_typem)
                            if przedmiot_match:
                                przedmiot = przedmiot_match.group(1).strip()
                                typ_zajec = przedmiot_match.group(2).strip()
                                event['przedmiot'] = przedmiot
                                event['typ_zajec'] = typ_zajec
                            else:
                                event['przedmiot'] = przedmiot_z_typem
                                event['typ_zajec'] = ""

                            # Wyciągnięcie danych nauczyciela
                            event['nauczyciel'] = nauczyciel.replace('mgr ', '').replace('dr ', '').replace('prof. ', '').strip()
                        else:
                            event['przedmiot'] = value
                    elif key == 'LOCATION':
                        event['miejsce'] = value
                    elif key == 'UID':
                        # Wyciągnięcie identyfikatora wydarzenia
                        event['uid'] = value
                    elif key == 'CATEGORIES':
                        # Dodatkowe informacje o typie zajęć
                        event['kategoria'] = value

        return events

    @staticmethod
    def format_event_for_db(event: Dict) -> Dict:
        """
        Formatuje wydarzenie z ICS do formatu używanego w bazie danych

        Args:
            event: Wydarzenie sparsowane z pliku ICS

        Returns:
            Wydarzenie sformatowane do zapisu w bazie danych
        """
        formatted_event = {
            'przedmiot': event.get('przedmiot', ''),
            'rz': event.get('typ_zajec', event.get('kategoria', '')),
            'miejsce': event.get('miejsce', ''),
            'od': event.get('start_time', ''),
            'do': event.get('end_time', ''),
            'terminy': f"{event.get('start_date', '')} {event.get('start_time', '')}-{event.get('end_time', '')}"
        }

        # Dodaj nauczyciela jeśli jest dostępny
        if 'nauczyciel' in event:
            formatted_event['nauczyciel'] = {
                'imie_nazwisko': event['nauczyciel']
            }

        return formatted_event