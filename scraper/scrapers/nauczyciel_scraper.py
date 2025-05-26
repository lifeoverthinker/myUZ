import requests
from bs4 import BeautifulSoup
from icalendar import Calendar
from typing import Dict, Any, List, Optional
import re
from concurrent.futures import ThreadPoolExecutor, as_completed

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

def get_ics_urls(nauczyciel_id: str) -> Dict[str, Optional[str]]:
    urls = {
        "letni": f"{BASE_URL}nauczyciel_ics.php?ID={nauczyciel_id}&KIND=GG&S=0",
        "zimowy": f"{BASE_URL}nauczyciel_ics.php?ID={nauczyciel_id}&KIND=GG&S=1",
        "fallback": f"{BASE_URL}nauczyciel_ics.php?ID={nauczyciel_id}&KIND=GG"
    }
    result = {}
    for key, url in urls.items():
        try:
            resp = requests.head(url, timeout=5)
            ct = resp.headers.get("content-type", "")
            result[key] = url if resp.status_code == 200 and "text/calendar" in ct else None
        except Exception:
            result[key] = None
    return result

def parse_nauczyciel_details(html: str, nauczyciel_id: str) -> dict:
    soup = BeautifulSoup(html, "html.parser")
    dane = {}
    h2_tags = soup.find_all("h2")
    for h2 in h2_tags:
        text = h2.get_text(strip=True)
        if text and "Plan zajęć" not in text:
            dane["imie_nazwisko"] = text.strip()
            break
    instytuty = []
    for h3 in soup.find_all("h3"):
        sublines = [frag.strip() for frag in h3.stripped_strings if frag.strip()]
        instytuty.extend(sublines)
    if instytuty:
        dane["instytut"] = " | ".join(instytuty)
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
    if email:
        dane["email"] = email
    link = f"{BASE_URL}nauczyciel_plan.php?ID={nauczyciel_id}"
    dane["link_plan_nauczyciela"] = link
    dane["link_strony_nauczyciela"] = link
    return dane

def parse_ics_for_nauczyciel(ics_text: str, nauczyciel_id: str, nauczyciel_nazwa: str, semestr: Optional[str]=None) -> List[Dict[str, Any]]:
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
        kod_grupy = re.search(r":\s*([A-Za-z0-9\-/]+)", summary)
        kod_grupy = kod_grupy.group(1).strip() if kod_grupy else None
        zajecia.append({
            "przedmiot": przedmiot,
            "rz": rz,
            "nauczyciel_nazwa": nauczyciel_nazwa,
            "od": start.isoformat() if hasattr(start, "isoformat") else str(start),
            "do_": end.isoformat() if hasattr(end, "isoformat") else str(end),
            "miejsce": location,
            "uid": str(uid) if uid else None,
            "kod_grupy": kod_grupy,
            "nauczyciel_id": nauczyciel_id,
            "source_type": "ICS_NAUCZYCIEL",
            "semestr": semestr
        })
    return zajecia

def deduplicate_zajecia(zajecia: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    seen = set()
    result = []
    for z in zajecia:
        if z.get("uid") and z["uid"] not in seen:
            seen.add(z["uid"])
            result.append(z)
        elif not z.get("uid"):
            result.append(z)
    return result

def scrape_nauczyciel_and_zajecia(nauczyciel_id: str) -> Optional[dict]:
    html = fetch_page(f"{BASE_URL}nauczyciel_plan.php?ID={nauczyciel_id}")
    if not html:
        print(f"Nie udało się pobrać strony nauczyciela {nauczyciel_id}")
        return None

    # Sprawdź, czy są zajęcia nieregularne
    ma_nieregularne = sprawdz_nieregularne_zajecia(html, f"nauczyciela {nauczyciel_id}")

    # Sprawdź, czy na stronie jest komunikat "nie ma jeszcze zaplanowanych żadnych zajęć"
    soup = BeautifulSoup(html, "html.parser")
    komunikat = soup.find(string=lambda s: s and "nie ma jeszcze zaplanowanych żadnych zajęć" in s.lower())

    nauczyciel = parse_nauczyciel_details(html, nauczyciel_id)
    nauczyciel["nauczyciel_id"] = nauczyciel_id

    ics_urls = get_ics_urls(nauczyciel_id)
    for key, url in ics_urls.items():
        nauczyciel[f"link_ics_nauczyciela_{key}"] = url

    zajecia = []
    for sem, url in ics_urls.items():
        if not url:
            continue
        try:
            ics_data = fetch_page(url)
            if not ics_data or "BEGIN:VCALENDAR" not in ics_data:
                print(f"Nie udało się pobrać lub rozpoznać ICS ({sem}) dla nauczyciela {nauczyciel_id}")
                continue
            result = parse_ics_for_nauczyciel(
                ics_data,
                nauczyciel_id,
                nauczyciel.get("imie_nazwisko", ""),
                semestr=sem if sem in ["letni", "zimowy"] else None
            )
            if not isinstance(result, list):
                print(f"⚠️ Parser ICS zwrócił {type(result)} zamiast listy dla nauczyciela {nauczyciel_id} ({sem})")
                continue
            zajecia += result
        except Exception as e:
            print(f"❌ Błąd pobierania ICS nauczyciela {nauczyciel_id}: {e}")

    if not zajecia:
        if ma_nieregularne:
            print(f"Nauczyciel {nauczyciel_id} nie ma zaplanowanych zajęć regularnych – w planie są tylko zajęcia nieregularne (nie są dostępne w pliku ICS).")
        elif komunikat:
            print(f"Nauczyciel {nauczyciel_id} nie ma jeszcze zaplanowanych żadnych zajęć.")
        else:
            print(f"Nauczyciel {nauczyciel_id} nie ma zaplanowanych żadnych zajęć lub plik ICS jest pusty.")
        return None

    return {
        "nauczyciel": nauczyciel,
        "zajecia": deduplicate_zajecia(zajecia)
    }

def scrape_nauczyciele_parallel(nauczyciel_ids: List[str], max_workers: int = 20) -> List[dict]:
    results = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(scrape_nauczyciel_and_zajecia, nid): nid for nid in nauczyciel_ids}
        for i, future in enumerate(as_completed(futures), 1):
            nid = futures[future]
            try:
                res = future.result()
                if res:
                    results.append(res)
                    print(f"[{i}/{len(nauczyciel_ids)}] OK: {nid}")
                else:
                    print(f"[{i}/{len(nauczyciel_ids)}] Brak danych: {nid}")
            except Exception as e:
                print(f"[{i}/{len(nauczyciel_ids)}] Błąd {nid}: {e}")
    return results
