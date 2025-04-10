# Moduł do parsowania plików ICS (kalendarz)
import requests
import icalendar
from dateutil import tz
from datetime import datetime
import re

def extract_subject_and_rz(summary):
    """
    Wyciąga czystą nazwę przedmiotu i rodzaj zajęć z tytułu wydarzenia.
    Wyciąga dowolny tekst z nawiasów jako rodzaj zajęć.
    """
    if not summary:
        return None, None

    # Wzorzec: Nazwa przedmiotu (RZ): Prowadzący
    # lub: Nazwa przedmiotu (RZ)
    # Wyciąga dowolny tekst z nawiasów jako RZ
    match = re.search(r'^(.+?)\s*\(([^)]+)\).*$', summary)
    if match:
        subject_name = match.group(1).strip()
        rz = match.group(2).strip()
        return subject_name, rz

    # Jeśli nie znaleźliśmy dopasowania, zwracamy oryginalny tekst i None
    return summary, None

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
                    raw_summary = str(component['SUMMARY'])
                    subject_name, rz_from_summary = extract_subject_and_rz(raw_summary)
                    event['summary'] = raw_summary  # Zachowujemy pełną informację
                    event['subject'] = subject_name  # Czysta nazwa przedmiotu
                    event['rz'] = rz_from_summary  # Rodzaj zajęć z nawiasów

                if 'LOCATION' in component:
                    event['location'] = str(component['LOCATION'])

                if 'DESCRIPTION' in component:
                    event['description'] = str(component['DESCRIPTION'])

                # Daty początku i końca
                if 'DTSTART' in component:
                    dtstart = component['DTSTART'].dt
                    if not isinstance(dtstart, datetime):
                        dtstart = datetime.combine(dtstart, datetime.min.time())
                    if dtstart.tzinfo:
                        dtstart = dtstart.astimezone(tz.UTC)
                    event['dtstart'] = dtstart

                if 'DTEND' in component:
                    dtend = component['DTEND'].dt
                    if not isinstance(dtend, datetime):
                        dtend = datetime.combine(dtend, datetime.min.time())
                    if dtend.tzinfo:
                        dtend = dtend.astimezone(tz.UTC)
                    event['dtend'] = dtend

                # Rodzaj zajęć - jeśli nie znaleziono w tytule, spróbuj z CATEGORIES
                if 'rz' not in event or not event['rz']:
                    if 'CATEGORIES' in component:
                        event['rz'] = str(component['CATEGORIES']).strip()

                events.append(event)

        return events

    except Exception as e:
        print(f"Błąd podczas parsowania pliku ICS: {e}")
        return []