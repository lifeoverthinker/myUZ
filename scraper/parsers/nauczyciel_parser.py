from bs4 import BeautifulSoup
from scraper.utils import sanitize_string, fetch_page
from icalendar import Calendar
import re
from typing import List, Dict, Optional, Any

BASE_URL = "https://plan.uz.zgora.pl/"

def sprawdz_nieregularne_zajecia(html: str, identyfikator: str = "") -> bool:
    """
    Sprawdza, czy w planie znajduje się rubryka 'Nieregularne'.
    Zwraca True jeśli tak, False w przeciwnym razie.
    """
    soup = BeautifulSoup(html, "html.parser")
    td = soup.find("td", class_="gray-day")
    if td and "nieregularne" in td.get_text(strip=True).lower():
        print(f"ℹ️ Plan {identyfikator} zawiera zajęcia nieregularne – te zajęcia NIE będą obecne w pliku ICS.")
        return True
    return False

def parse_nauczyciele_from_group_page(html: str, grupa_id: str = None) -> list[dict]:
    """
    Parsuje HTML planu zajęć grupy i wyodrębnia linki do stron nauczycieli.
    """
    if html is None:
        print(f"❌ Strona grupy jest pusta, pomijam parse_nauczyciele_from_group_page")
        return []
    # Sprawdzanie sekcji nieregularnych
    sprawdz_nieregularne_zajecia(html, f"grupy {grupa_id}" if grupa_id else "")
    soup = BeautifulSoup(html, "html.parser")
    wynik = []
    znalezieni_nauczyciele = set()  # Zbiór do unikania duplikatów

    # Znajdź wszystkie linki do nauczycieli
    nauczyciel_links = soup.find_all("a", href=lambda href: href and "nauczyciel_plan.php?ID=" in href)
    for link in nauczyciel_links:
        nauczyciel_url = BASE_URL + link["href"]
        nauczyciel_id = link["href"].split("ID=")[1] if "ID=" in link["href"] else None
        nauczyciel_name = sanitize_string(link.get_text(strip=True))
        # Sprawdź czy nauczyciel był już dodany
        if nauczyciel_url not in znalezieni_nauczyciele:
            znalezieni_nauczyciele.add(nauczyciel_url)
            nauczyciel_data = {
                "nazwa": nauczyciel_name,
                "link": nauczyciel_url,
                "nauczyciel_id": nauczyciel_id
            }
            if grupa_id:
                nauczyciel_data["grupa_id"] = grupa_id
            wynik.append(nauczyciel_data)
    return wynik

def parse_nauczyciel_details(html: str, nauczyciel_id: str = None) -> dict:
    if html is None:
        print(f"❌ Strona nauczyciela jest pusta, pomijam parse_nauczyciel_details")
        return {}
    # Sprawdzanie sekcji nieregularnych
    sprawdz_nieregularne_zajecia(html, f"nauczyciela {nauczyciel_id}" if nauczyciel_id else "")
    soup = BeautifulSoup(html, "html.parser")
    dane = {}

    # Imię i nazwisko (drugi H2 po "Plan zajęć")
    h2_tags = soup.find_all("h2")
    for h2 in h2_tags:
        text = h2.get_text(strip=True)
        if text and "Plan zajęć" not in text:
            dane["nauczyciel_nazwa"] = sanitize_string(text)
            break

    # Instytuty/wydziały (każdy <h3> osobno, obsługa <br>)
    instytuty = []
    h3_tags = soup.find_all("h3")
    for h3 in h3_tags:
        sublines = [frag.strip() for frag in h3.stripped_strings if frag.strip()]
        instytuty.extend(sublines)
    if instytuty:
        dane["instytut"] = " | ".join(instytuty)

    # Email – pierwszy <a href="mailto:..."> w H4 lub ogólnie
    email = None
    h4_tags = soup.find_all("h4")
    for h4 in h4_tags:
        a_mail = h4.find("a", href=lambda href: href and "mailto:" in href)
        if a_mail:
            email = a_mail.get_text(strip=True)
            break
    if not email:
        a_mail = soup.find("a", href=lambda href: href and "mailto:" in href)
        if a_mail:
            email = a_mail.get_text(strip=True)
    if email:
        dane["email"] = email

    # Link do planu nauczyciela
    if nauczyciel_id:
        link = f"{BASE_URL}nauczyciel_plan.php?ID={nauczyciel_id}"
        dane["link_plan_nauczyciela"] = link
        dane["link_strony_nauczyciela"] = link

    return dane

def scrape_nauczyciele_from_grupy(grupy: list[dict]) -> list[dict]:
    """
    Dla każdej grupy pobiera nauczycieli z jej planu.
    """
    nauczyciele = []
    for grupa in grupy:
        link = grupa.get("link_grupy")
        grupa_id = grupa.get("grupa_id")
        if not link:
            continue
        html = fetch_page(link)
        if not html:
            print(f"❌ Nie udało się pobrać strony grupy {link}")
            continue
        nauczyciele_z_grupy = parse_nauczyciele_from_group_page(html, grupa_id=grupa_id)
        nauczyciele.extend(nauczyciele_z_grupy)
    # Usuwanie duplikatów po nauczyciel_id
    nauczyciele_unikalni = {n["nauczyciel_id"]: n for n in nauczyciele if n.get("nauczyciel_id")}
    return list(nauczyciele_unikalni.values())

def wyodrebnij_dane_z_summary_nauczyciel(summary: str):
    """
    Ekstrahuje przedmiot, kod_grupy i podgrupę (PG) z opisu ICS NAUCZYCIELA.
    """
    przedmiot = summary
    kod_grupy = None
    pg = None
    # Przykład: "Budownictwo i materiałoznawstwo II (L): 11ARCH-SJ/A"
    match = re.search(r"^(.*?)\s*\([^\)]+\):\s*([A-Za-z0-9\-_/]+)(?:/([A-Za-z0-9]+))?", summary)
    if match:
        przedmiot = match.group(1).strip()
        kod_grupy = match.group(2).strip()
        if match.group(3):
            pg = match.group(3).strip()
    else:
        przedmiot = summary.strip()
    return przedmiot, kod_grupy, pg

def parse_ics_nauczyciel(
        ics_content: str,
        nauczyciel_nazwa: str,
        ics_url: Optional[str] = None,
        kierunek_nazwa: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """
    Parsuje plik ICS nauczyciela i zwraca listę wydarzeń (zajęć).
    """
    if not ics_content:
        return []
    events = []
    try:
        cal = Calendar.from_ical(ics_content)
        vevents = [component for component in cal.walk('VEVENT')]
        if not vevents:
            # Pusty kalendarz – brak wydarzeń
            return []
        for component in vevents:
            summary = str(component.get('summary', ''))
            categories = component.get('categories')
            start_time = component.get('dtstart').dt
            end_time = component.get('dtend').dt
            location = str(component.get('location', ''))
            uid = str(component.get('uid', ''))
            # RZ z kategorii (jeśli są)
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
            # Ekstrakcja z summary
            przedmiot, kod_grupy_ev, podgrupa = wyodrebnij_dane_z_summary_nauczyciel(summary)
            event = {
                "przedmiot": przedmiot,
                "od": start_time.isoformat() if hasattr(start_time, "isoformat") else start_time,
                "do_": end_time.isoformat() if hasattr(end_time, "isoformat") else end_time,
                "miejsce": location,
                "rz": rz,
                "link_ics_zrodlowy": ics_url,
                "podgrupa": podgrupa,
                "uid": uid,
                "nauczyciel_nazwa": nauczyciel_nazwa,
                "kod_grupy": kod_grupy_ev,
                "kierunek_nazwa": kierunek_nazwa,
                "grupa_id": None,
                "source_type": "ICS_NAUCZYCIEL"
            }
            events.append(event)
    except Exception as e:
        print(f"Błąd podczas parsowania pliku ICS nauczyciela: {e}")
    return events

def wyodrebnij_dane_z_summary_grupa(summary: str) -> tuple[str, Optional[str], Optional[str]]:
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
