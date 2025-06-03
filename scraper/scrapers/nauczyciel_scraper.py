import requests
from bs4 import BeautifulSoup
from icalendar import Calendar
from typing import Dict, Any, List, Optional
import re
from scraper.parsers.nauczyciel_parser import sprawdz_nieregularne_zajecia

BASE_URL = "https://plan.uz.zgora.pl/"

def fetch_page(url: str) -> Optional[str]:
    try:
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
        return resp.text
    except Exception as e:
        print(f"❌ Błąd pobierania strony: {url} — {e}")
        return None

def get_ics_url(nauczyciel_id: str) -> Optional[str]:
    url = f"{BASE_URL}nauczyciel_ics.php?ID={nauczyciel_id}&KIND=NT"
    try:
        resp = requests.head(url, timeout=5)
        ct = resp.headers.get("content-type", "")
        return url if resp.status_code == 200 and "text/calendar" in ct else None
    except Exception:
        return None

def parse_ics_for_nauczyciel(ics_text: str, nauczyciel_id: str) -> List[Dict[str, Any]]:
    cal = Calendar.from_ical(ics_text)
    zajecia = []
    for comp in cal.walk():
        if comp.name != "VEVENT":
            continue
        summary = str(comp.get("SUMMARY"))
        start = comp.get("DTSTART").dt
        end = comp.get("DTEND").dt
        location = comp.get("LOCATION")
        categories = comp.get("CATEGORIES")
        uid = comp.get("UID")
        rz = None
        if categories:
            if isinstance(categories, (list, tuple)):
                rz = ",".join([cat.to_ical().decode(errors="ignore").strip() if hasattr(cat, "to_ical") else str(cat) for cat in categories])
            else:
                rz = categories.to_ical().decode(errors="ignore").strip() if hasattr(categories, "to_ical") else str(categories)
            rz = rz[:10] if rz and len(rz) > 10 else rz
        przedmiot = summary.split("(")[0].strip() if "(" in summary else summary.strip()
        grupy = None
        m = re.search(r":\s*([A-Za-z0-9\-/; ]+)", summary)
        if m:
            grupy = m.group(1).strip()
        zajecia.append({
            "przedmiot": przedmiot,
            "rz": rz,
            "od": start.isoformat() if hasattr(start, "isoformat") else str(start),
            "do_": end.isoformat() if hasattr(end, "isoformat") else str(end),
            "miejsce": location,
            "uid": str(uid) if uid else None,
            "grupy": grupy,
            "nauczyciel_id": nauczyciel_id,
        })
    return zajecia

def scrape_nauczyciel_and_zajecia(nauczyciel_id: str) -> Optional[dict]:
    html = fetch_page(f"{BASE_URL}nauczyciel_plan.php?ID={nauczyciel_id}")
    if not html:
        print(f"Nie udało się pobrać strony nauczyciela {nauczyciel_id}")
        return None
    ma_nieregularne = sprawdz_nieregularne_zajecia(html, f"nauczyciela {nauczyciel_id}")
    soup = BeautifulSoup(html, "html.parser")
    komunikat = soup.find(string=lambda s: s and "nie ma jeszcze zaplanowanych żadnych zajęć" in s.lower())
    # Dane nauczyciela
    h2_tags = soup.find_all("h2")
    nauczyciel_nazwa = None
    for h2 in h2_tags:
        text = h2.get_text(strip=True)
        if text and "Plan zajęć" not in text:
            nauczyciel_nazwa = text.strip()
            break
    instytut = None
    instytuty = []
    for h3 in soup.find_all("h3"):
        sublines = [frag.strip() for frag in h3.stripped_strings if frag.strip()]
        instytuty.extend(sublines)
    if instytuty:
        instytut = " | ".join(instytuty)
    email = None
    for h4 in soup.find_all("h4"):
        a = h4.find("a", href=lambda href: href and "mailto:" in href)
        if a:
            email = a.get_text(strip=True)
            break
    if not email:
        a = soup.find("a", href=lambda href: href and "mailto:" in href)
        if a:
            email = a.get_text(strip=True)
    link_strony_nauczyciela = f"{BASE_URL}nauczyciel_plan.php?ID={nauczyciel_id}"
    link_ics_nauczyciela = get_ics_url(nauczyciel_id)
    nauczyciel = {
        "nazwa": nauczyciel_nazwa,
        "instytut": instytut,
        "email": email,
        "link_strony_nauczyciela": link_strony_nauczyciela,
        "link_ics_nauczyciela": link_ics_nauczyciela,
        "nauczyciel_id": nauczyciel_id,
    }
    zajecia = []
    if link_ics_nauczyciela:
        ics_data = fetch_page(link_ics_nauczyciela)
        if ics_data and "BEGIN:VCALENDAR" in ics_data:
            zajecia = parse_ics_for_nauczyciel(ics_data, nauczyciel_id)
    if not zajecia:
        if ma_nieregularne:
            print(f"Nauczyciel {nauczyciel_id} nie ma zaplanowanych zajęć regularnych – w planie są tylko zajęcia nieregularne (nie są dostępne w pliku ICS).")
        elif komunikat:
            print(f"Nauczyciel {nauczyciel_id} nie ma jeszcze zaplanowanych żadnych zajęć.")
        else:
            print(f"Nauczyciel {nauczyciel_id} nie ma zaplanowanych żadnych zajęć lub plik ICS jest pusty.")
    return {
        "nauczyciel": nauczyciel,
        "zajecia": zajecia
    }
