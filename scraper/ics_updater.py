import datetime
import requests
import concurrent.futures
from tqdm import tqdm
from icalendar import Calendar
import re
import time

BASE_URL = "https://plan.uz.zgora.pl/"

def create_session(max_retries: int = 3, backoff_factor: float = 0.3) -> requests.Session:
    """Tworzy sesję HTTP z mechanizmem ponownych prób i wykładniczym opóźnieniem."""
    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry

    session = requests.Session()
    retry_strategy = Retry(
        total=max_retries,
        backoff_factor=backoff_factor,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"]
    )
    adapter = HTTPAdapter(
        max_retries=retry_strategy,
        pool_connections=20,
        pool_maxsize=20
    )
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    return session

_session = None
def get_session() -> requests.Session:
    """Zwraca globalną sesję HTTP lub tworzy nową, jeśli nie istnieje."""
    global _session
    if _session is None:
        _session = create_session()
    return _session

def fetch_ics_content(url: str, max_retries: int = 3, retry_delay: int = 5) -> str | None:
    """Pobiera zawartość pliku ICS z podanego URL z mechanizmem ponownych prób."""
    session = get_session()
    for attempt in range(max_retries):
        try:
            response = session.get(url, timeout=30)
            if response.status_code == 200:
                return response.text
            elif response.status_code == 404:
                print(f"Brak pliku ICS: {url}")
                return None
            else:
                print(f"Błąd pobierania pliku ICS: {response.status_code} - {url}")
        except Exception as e:
            print(f"Próba {attempt + 1}/{max_retries}: Błąd pobierania ICS ({url}): {e}")
            if attempt < max_retries - 1:
                print(f"Ponowna próba za {retry_delay} sekund...")
                time.sleep(retry_delay)
                retry_delay *= 2
            # Resetuj sesję po błędzie
            global _session
            _session = create_session()
            session = _session
    return None

def parse_ics_file(ics_content: str, link_ics_zrodlowy: str = None) -> list[dict]:
    """Parsuje plik ICS i zwraca listę wydarzeń (zajęć)."""
    if not ics_content:
        return []
    events = []
    try:
        cal = Calendar.from_ical(ics_content)
        for component in cal.walk('VEVENT'):
            start_time = component.get('dtstart').dt
            end_time = component.get('dtend').dt
            summary = str(component.get('summary', ''))
            location = str(component.get('location', ''))
            uid = str(component.get('uid', ''))
            # Rodzaj zajęć (rz)
            rz = None
            categories = component.get('categories')
            if categories:
                if hasattr(categories, 'decoded'):
                    rz = str(categories.decoded())
                elif isinstance(categories, list):
                    rz = str(categories[0]) if categories else None
                else:
                    rz = str(categories)
                if rz and len(rz) > 10:
                    rz = rz[:10]
            else:
                # Wyciągnij z nawiasów w SUMMARY
                rz_match = re.search(r'\((W|C|Ć|L|P|S|E|I|T|K|X|Z)\)', summary)
                rz = rz_match.group(1) if rz_match else None
            # Przedmiot
            przedmiot = summary
            match_przedmiot = re.match(r'^([^(]+)', summary)
            if match_przedmiot:
                przedmiot = match_przedmiot.group(1).strip()
            # Wyciągnięcie nauczyciela z SUMMARY (po dwukropku)
            nauczyciel = None
            if ': ' in summary:
                parts = summary.split(': ', 1)
                nauczyciel = parts[1].strip() if len(parts) > 1 else None
            # Usuń fragment z podgrupą
            if nauczyciel and '(PG:' in nauczyciel:
                nauczyciel = nauczyciel.split('(PG:')[0].strip()
            # Wyciągnięcie podgrupy
            podgrupa = None
            podgrupa_match = re.search(r'\(PG:\s*([^)]+)\)', summary)
            if podgrupa_match:
                podgrupa = podgrupa_match.group(1).strip()
            event = {
                'przedmiot': przedmiot,
                'od': start_time.isoformat() if hasattr(start_time, 'isoformat') else start_time,
                'do_': end_time.isoformat() if hasattr(end_time, 'isoformat') else end_time,
                'miejsce': location,
                'rz': rz,
                'link_ics_zrodlowy': link_ics_zrodlowy,
                'podgrupa': podgrupa,
                'uid': uid,
                'nauczyciel': nauczyciel
            }
            events.append(event)
    except Exception as e:
        print(f"Błąd podczas parsowania pliku ICS: {e}")
    return events

def pobierz_plan_ics_grupy(grupa_id: str) -> dict:
    """Pobiera plan grupy w formacie ICS."""
    ics_link = f"{BASE_URL}grupy_ics.php?ID={grupa_id}&KIND=GG"
    ics_content = fetch_ics_content(ics_link)
    return {
        'grupa_id': grupa_id,
        'ics_content': ics_content,
        'link_ics_zrodlowy': ics_link,
        'data_aktualizacji': datetime.datetime.now().isoformat(),
        'status': 'success' if ics_content else 'error'
    }

def pobierz_plan_ics_nauczyciela(nauczyciel_id: str) -> dict:
    """
    Pobiera plan nauczyciela w formacie ICS,
    najpierw sprawdzając czy plan HTML istnieje.
    """
    html_link = f"{BASE_URL}nauczyciel_plan.php?ID={nauczyciel_id}"
    session = get_session()
    ics_link = f"{BASE_URL}nauczyciel_ics.php?ID={nauczyciel_id}&KIND=NT"
    try:
        html_response = session.get(html_link, timeout=10)
        if html_response.status_code == 404:
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_content': None,
                'link_ics_zrodlowy': ics_link,
                'status': 'not_found',
                'data_aktualizacji': datetime.datetime.now().isoformat()
            }
        if "Plan nauczyciela" not in html_response.text:
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_content': None,
                'link_ics_zrodlowy': ics_link,
                'status': 'no_plan',
                'data_aktualizacji': datetime.datetime.now().isoformat()
            }
        ics_content = fetch_ics_content(ics_link)
        if not ics_content or not ics_content.strip():
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_content': None,
                'link_ics_zrodlowy': ics_link,
                'status': 'ics_not_found',
                'data_aktualizacji': datetime.datetime.now().isoformat()
            }
        return {
            'nauczyciel_id': nauczyciel_id,
            'ics_content': ics_content,
            'link_ics_zrodlowy': ics_link,
            'status': 'success',
            'data_aktualizacji': datetime.datetime.now().isoformat()
        }
    except Exception as e:
        return {
            'nauczyciel_id': nauczyciel_id,
            'ics_content': None,
            'link_ics_zrodlowy': ics_link,
            'status': 'error',
            'error': str(e),
            'data_aktualizacji': datetime.datetime.now().isoformat()
        }

def aktualizuj_plany_grup(grupa_ids: list[str], max_workers: int = 20) -> list[dict]:
    """Aktualizuje plany grup z równoległym przetwarzaniem."""
    aktualizowane_plany = []
    batch_size = 100
    all_batches = [grupa_ids[i:i + batch_size] for i in range(0, len(grupa_ids), batch_size)]
    for batch_num, batch in enumerate(all_batches):
        print(f"Przetwarzanie partii {batch_num + 1}/{len(all_batches)} ({len(batch)} grup)")
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            zadania = {executor.submit(pobierz_plan_ics_grupy, gid): gid for gid in batch}
            for zadanie in tqdm(concurrent.futures.as_completed(zadania),
                                total=len(zadania),
                                desc=f"Partia {batch_num + 1}"):
                grupa_id = zadania[zadanie]
                try:
                    wynik = zadanie.result()
                    if wynik and wynik.get('status') == 'success':
                        aktualizowane_plany.append(wynik)
                except Exception as e:
                    print(f"❌ Błąd dla grupy {grupa_id}: {e}")
        if batch_num < len(all_batches) - 1:
            time.sleep(1)
    print(f"✅ Zaktualizowano plany dla {len(aktualizowane_plany)} z {len(grupa_ids)} grup")
    return aktualizowane_plany

def aktualizuj_plany_nauczycieli(nauczyciel_ids: list[str], max_workers: int = 20) -> list[dict]:
    """Aktualizuje plany nauczycieli z równoległym przetwarzaniem."""
    aktualizowane_plany = []
    print(f"🔄 Aktualizuję plany dla {len(nauczyciel_ids)} nauczycieli...")
    batch_size = 100
    all_batches = [nauczyciel_ids[i:i + batch_size] for i in range(0, len(nauczyciel_ids), batch_size)]
    for batch_num, batch in enumerate(all_batches):
        print(f"Przetwarzanie partii {batch_num + 1}/{len(all_batches)} ({len(batch)} nauczycieli)")
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            przyszle_wyniki = {executor.submit(pobierz_plan_ics_nauczyciela, nauczyciel_id): nauczyciel_id
                               for nauczyciel_id in batch}
            for przyszly_wynik in tqdm(concurrent.futures.as_completed(przyszle_wyniki),
                                      total=len(przyszle_wyniki),
                                      desc=f"Partia {batch_num + 1}"):
                nauczyciel_id = przyszle_wyniki[przyszly_wynik]
                try:
                    wynik = przyszly_wynik.result()
                    if wynik and wynik.get('status') == 'success':
                        aktualizowane_plany.append(wynik)
                except Exception as e:
                    print(f"❌ Błąd podczas aktualizacji planu dla nauczyciela {nauczyciel_id}: {e}")
        if batch_num < len(all_batches) - 1:
            time.sleep(1)
    print(f"✅ Zaktualizowano plany dla {len(aktualizowane_plany)} z {len(nauczyciel_ids)} nauczycieli")
    return aktualizowane_plany
