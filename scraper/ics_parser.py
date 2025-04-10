# Moduł do parsowania plików ICS (kalendarz)
import requests
import icalendar
from dateutil import tz
from datetime import datetime
import re

def extract_rz_from_summary(summary):
    """Wyciąga rodzaj zajęć z podsumowania wydarzenia"""
    if not summary:
        return None

    # Szukanie wzorca: "Nazwa przedmiotu (RZ):"
    rz_match = re.search(r'\(([WĆLSEP])\)', summary)
    if rz_match:
        return rz_match.group(1)
    return None

def parse_ics_file(url):
    """Parsuje plik ICS z podanego URL i zwraca listę wydarzeń (zajęć)"""
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()

        # Parsowanie kalendarza
        calendar = icalendar.Calendar.from_ical(response.text)

        # Lista na wydarzenia
        events = []

        for component in calendar.walk():
            if component.name == "VEVENT":
                event = {}

                # Podstawowe informacje
                if 'SUMMARY' in component:
                    event['summary'] = str(component['SUMMARY'])

                if 'LOCATION' in component:
                    event['location'] = str(component['LOCATION'])

                if 'DESCRIPTION' in component:
                    event['description'] = str(component['DESCRIPTION'])

                # Daty początku i końca
                if 'DTSTART' in component:
                    dtstart = component['DTSTART'].dt
                    # Konwersja do datetime, jeśli to data
                    if not isinstance(dtstart, datetime):
                        dtstart = datetime.combine(dtstart, datetime.min.time())
                    # Konwersja do UTC jeśli ma strefę czasową
                    if dtstart.tzinfo:
                        dtstart = dtstart.astimezone(tz.UTC)
                    event['dtstart'] = dtstart

                if 'DTEND' in component:
                    dtend = component['DTEND'].dt
                    # Konwersja do datetime, jeśli to data
                    if not isinstance(dtend, datetime):
                        dtend = datetime.combine(dtend, datetime.min.time())
                    # Konwersja do UTC jeśli ma strefę czasową
                    if dtend.tzinfo:
                        dtend = dtend.astimezone(tz.UTC)
                    event['dtend'] = dtend

                # Rodzaj zajęć - najbardziej wiarygodne źródło to CATEGORIES
                if 'CATEGORIES' in component:
                    event['rz'] = str(component['CATEGORIES'])
                    # Czyszczenie kategorii (pozbycie się niewidocznych znaków)
                    event['rz'] = re.sub(r'[^\w\s]', '', event['rz']).strip()
                else:
                    # Próba wyciągnięcia RZ z tytułu
                    summary = event.get('summary', '')
                    event['rz'] = extract_rz_from_summary(summary)

                events.append(event)

        return events

    except Exception as e:
        print(f"Błąd podczas parsowania pliku ICS: {e}")
        return []