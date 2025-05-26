from bs4 import BeautifulSoup
from icalendar import Calendar
import re
from typing import Tuple, List, Dict, Optional, Any

def wyodrebnij_dane_z_summary_grupa(summary: str) -> Tuple[str, Optional[str], Optional[str]]:
    """
    Ekstrahuje przedmiot, nauczyciela i podgrupę (PG) z opisu ICS GRUPY.
    """
    przedmiot = summary
    nauczyciel = None
    pg = None

    match = re.search(r"^(.*?)\s*\([^\)]+\):\s*(.+?)(?:\s*\(PG:.*\))?$", summary)
    if match:
        przedmiot = match.group(1).strip()
        nauczyciel = match.group(2).strip()
    else:
        przedmiot = summary.strip()
    pg_match = re.search(r"\(PG:\s*([^)]+)\)", summary)
    if pg_match:
        pg = pg_match.group(1).strip()
        if nauczyciel:
            nauczyciel = re.sub(r"\(PG:.*?\)", "", nauczyciel).strip()
    return przedmiot, nauczyciel, pg

def parse_ics(
    ics_content: str,
    grupa_id: Optional[str] = None,
    ics_url: Optional[str] = None,
    kod_grupy: Optional[str] = None,
    kierunek_nazwa: Optional[str] = None,
    grupa_map: Optional[Dict[str, Any]] = None,
) -> List[Dict[str, Any]]:
    """
    Parsuje plik ICS grupy i zwraca listę wydarzeń (zajęć).
    """
    if not ics_content:
        return []
    events = []
    try:
        cal = Calendar.from_ical(ics_content)
        for component in cal.walk('VEVENT'):
            summary = str(component.get('summary', ''))
            categories = component.get('categories')
            start_time = component.get('dtstart').dt
            end_time = component.get('dtend').dt
            location = str(component.get('location', ''))
            uid = str(component.get('uid', ''))
            # RZ z kategorii
            rz = None
            if categories:
                try:
                    if hasattr(categories, 'to_ical'):
                        rz = categories.to_ical().decode(errors="ignore").strip()
                    else:
                        rz = str(categories).strip()
                    if rz and len(rz) > 10:
                        rz = rz[:10]
                except Exception:
                    rz = None
            przedmiot, nauczyciel, podgrupa = wyodrebnij_dane_z_summary_grupa(summary)
            event = {
                "przedmiot": przedmiot,
                "od": start_time.isoformat() if hasattr(start_time, "isoformat") else start_time,
                "do_": end_time.isoformat() if hasattr(end_time, "isoformat") else end_time,
                "miejsce": location,
                "rz": rz,
                "link_ics_zrodlowy": ics_url,
                "podgrupa": podgrupa,
                "uid": uid,
                "nauczyciel_nazwa": nauczyciel,
                "kod_grupy": kod_grupy,
                "kierunek_nazwa": kierunek_nazwa,
                "grupa_id": grupa_id,
                "source_type": "ICS_GRUPA"
            }
            events.append(event)
    except Exception as e:
        print(f"Błąd podczas parsowania pliku ICS: {e}")
    return events

def parse_grupa_details(html_content: str) -> Dict[str, Any]:
    """
    Parsuje HTML planu zajęć grupy, wyciągając kod grupy, tryb studiów, semestr i nazwę kierunku.
    """
    soup = BeautifulSoup(html_content, 'html.parser')
    h2_elements = soup.find_all('h2')
    kod_grupy = h2_elements[1].text.strip() if len(h2_elements) > 1 else "Nieznany"
    h3 = soup.find('h3')
    kierunek_nazwa = None
    tryb_studiow = None
    semestr = None

    if h3:
        # Pobierz wszystkie linie z <h3>, rozdzielone <br>
        lines = [line.strip() for line in h3.stripped_strings if line.strip()]
        if lines:
            kierunek_nazwa = lines[0]
            # Szukaj trybu studiów w drugiej linii (np. "stacjonarne / pierwszego stopnia z tyt. inżyniera")
            if len(lines) > 1:
                tryb_studiow = lines[1].split("/")[0].strip().lower()
            # Szukaj semestru w trzeciej linii (np. "semestr letni 2024/2025")
            if len(lines) > 2:
                sem_line = lines[2].lower()
                if "letni" in sem_line:
                    semestr = "letni"
                elif "zimowy" in sem_line:
                    semestr = "zimowy"

    return {
        "kod_grupy": kod_grupy,
        "kierunek_nazwa": kierunek_nazwa,
        "tryb_studiow": tryb_studiow,
        "semestr": semestr
    }

def parsuj_html_grupa(html_content: str) -> Dict[str, Any]:
    """
    Wrapper do wyciągania szczegółów grupy z HTML (dla scraperów).
    """
    return parse_grupa_details(html_content)
