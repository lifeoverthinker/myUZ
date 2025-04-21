import datetime
import requests
import concurrent.futures
from tqdm import tqdm
from icalendar import Calendar
import re
import time
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Adres bazowy do API planów zajęć
BASE_URL = "https://plan.uz.zgora.pl/"


def create_session(max_retries=3, backoff_factor=0.3):
    """Tworzy sesję HTTP z mechanizmem ponownych prób i wykładniczym opóźnieniem."""
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


# Singleton sesji HTTP
_session = None


def get_session():
    """Zwraca globalną sesję HTTP lub tworzy nową, jeśli nie istnieje."""
    global _session
    if _session is None:
        _session = create_session()
    return _session


def bezpieczny_log(tekst):
    """Wypisuje logi, filtrując potencjalne znaki binarne/HTML."""
    # Jeśli to obiekt odpowiedzi HTTP, nie wyświetlaj treści
    if isinstance(tekst, requests.Response):
        return f"[Odpowiedź HTTP: {tekst.status_code}]"

    # Konwersja do stringa z obsługą błędów kodowania
    try:
        tekstowy = str(tekst)
    except Exception:
        return "[Nieczytelna zawartość]"

    # Usuń tagi HTML i znaki niedrukowalne
    filtrowany_tekst = re.sub(r'<[^>]*>', '', tekstowy)
    filtrowany_tekst = ''.join(c if c.isprintable() else ' ' for c in filtrowany_tekst)

    # Limit długości loga
    if len(filtrowany_tekst) > 500:
        filtrowany_tekst = filtrowany_tekst[:500] + "..."

    return filtrowany_tekst


def fetch_ics_content(url, max_retries=3, retry_delay=5):
    """Pobiera zawartość pliku ICS z podanego URL z mechanizmem ponownych prób."""
    session = get_session()

    for attempt in range(max_retries):
        try:
            response = session.get(url, timeout=30)
            response.encoding = 'utf-8'  # Ustaw kodowanie

            if response.status_code == 200:
                content = response.text.strip()

                # Sprawdź czy odpowiedź to faktycznie plik ICS
                if content.startswith("BEGIN:VCALENDAR"):
                    return content
                elif content.lower().startswith("<!doctype html") or content.lower().startswith("<html"):
                    print(f"Zwrócony HTML zamiast ICS: {url}\n")
                    return None
                else:
                    # Jeśli to ani ICS, ani HTML, zapisz pierwsze 100 znaków
                    print(f"Nieznany format odpowiedzi: {bezpieczny_log(content[:100])} - {url}")
                    return None
            elif response.status_code == 404:
                print(f"Brak pliku ICS: {url}")
                return None
            else:
                print(f"Błąd pobierania pliku ICS: {response.status_code} - {url}")
                if attempt < max_retries - 1:
                    print(f"Ponowna próba za {retry_delay} sekund...")
                    time.sleep(retry_delay)
                    retry_delay *= 2  # Zwiększaj opóźnienie przy każdej próbie
        except Exception as e:
            print(f"Próba {attempt + 1}/{max_retries}: Błąd pobierania ICS ({url}): {bezpieczny_log(e)}")
            if attempt < max_retries - 1:
                print(f"Ponowna próba za {retry_delay} sekund...")
                time.sleep(retry_delay)
                retry_delay *= 2  # Zwiększaj opóźnienie przy każdej próbie
                # Resetuj sesję po błędzie
                global _session
                _session = create_session()
                session = _session

    return None

def parse_ics_file(ics_content, link_ics_zrodlowy=None):
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
            description = str(component.get('description', ''))
            uid = str(component.get('uid', ''))

            # Poprawna obsługa kategorii/rodzaju zajęć
            rz = None
            categories = component.get('categories')
            if categories:
                # Dla biblioteki icalendar v4+
                if hasattr(categories, 'decoded'):
                    rz = str(categories.decoded())
                # Dla starszych wersji biblioteki
                elif isinstance(categories, list):
                    rz = str(categories[0]) if categories else None
                else:
                    # Wyciągnij z nawiasów w SUMMARY
                    rz_match = re.search(r'\((W|C|Ć|L|P|S|E|I|T|K|X|Z)\)', summary)
                    rz = rz_match.group(1) if rz_match else None
            else:
                # Wyciągnij z nawiasów w SUMMARY
                rz_match = re.search(r'\((W|C|Ć|L|P|S|E|I|T|K|X|Z)\)', summary)
                rz = rz_match.group(1) if rz_match else None

            # Ograniczenie długości rz do 10 znaków
            if rz and len(rz) > 10:
                rz = rz[:10]

            # Wyciągnięcie nazwy przedmiotu - tylko do pierwszego nawiasu
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


def pobierz_plan_ics_grupy(grupa_id):
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


def pobierz_plan_ics_nauczyciela(nauczyciel_id):
    """
    Pobiera plan nauczyciela w formacie ICS,
    najpierw sprawdzając czy plan HTML istnieje.
    """
    html_link = f"{BASE_URL}nauczyciel_plan.php?ID={nauczyciel_id}"
    session = get_session()
    ics_link = f"{BASE_URL}nauczyciel_ics.php?ID={nauczyciel_id}&KIND=NT"

    try:
        html_response = session.get(html_link, timeout=10)
        html_response.encoding = 'utf-8'  # Ustaw kodowanie

        if html_response.status_code == 404:
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_content': None,
                'link_ics_zrodlowy': ics_link,
                'status': 'not_found',
                'data_aktualizacji': datetime.datetime.now().isoformat()
            }

        # Sprawdź nagłówek strony - bezpieczniejsze sprawdzenie
        page_start = html_response.text[:200] if html_response.text else ""

        if "<title>Plan zajęć nauczyciela" not in page_start:
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_content': None,
                'link_ics_zrodlowy': ics_link,
                'status': 'no_plan',
                'data_aktualizacji': datetime.datetime.now().isoformat()
            }

        # Sprawdź czy strona zawiera plan (szukaj nagłówka z planem)
        if "Plan nauczyciela" not in html_response.text:
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_content': None,
                'link_ics_zrodlowy': ics_link,
                'status': 'no_plan',
                'data_aktualizacji': datetime.datetime.now().isoformat()
            }

        # Jeśli HTML istnieje, próbuj pobrać ICS
        ics_content = fetch_ics_content(ics_link)

        if not ics_content:
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_content': None,
                'link_ics_zrodlowy': ics_link,
                'status': 'ics_not_found',
                'data_aktualizacji': datetime.datetime.now().isoformat()
            }

        # Sprawdź poprawność formatu ICS
        if not ics_content.strip():
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_content': None,
                'link_ics_zrodlowy': ics_link,
                'status': 'empty',
                'data_aktualizacji': datetime.datetime.now().isoformat()
            }

        # Dodatkowe sprawdzenie czy to na pewno ICS a nie HTML
        if not ics_content.startswith('BEGIN:VCALENDAR'):
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_content': None,
                'link_ics_zrodlowy': ics_link,
                'status': 'invalid_ics',
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
        safe_error = bezpieczny_log(e)
        return {
            'nauczyciel_id': nauczyciel_id,
            'ics_content': None,
            'link_ics_zrodlowy': ics_link,
            'status': 'error',
            'error': safe_error,
            'data_aktualizacji': datetime.datetime.now().isoformat()
        }


def aktualizuj_plany_grup(grupa_ids, max_workers=20):
    """Aktualizuje plany grup z równoległym przetwarzaniem i przerywaniem po błędach."""
    aktualizowane_plany = []

    # Podziel na batche po 100 grup, aby uniknąć przeciążenia ale przyspieszyć proces
    batch_size = 100
    all_batches = [grupa_ids[i:i + batch_size] for i in range(0, len(grupa_ids), batch_size)]

    for batch_num, batch in enumerate(all_batches):
        print(f"Przetwarzanie partii {batch_num + 1}/{len(all_batches)} ({len(batch)} grup)")

        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            zadania = {executor.submit(pobierz_plan_ics_grupy, gid): gid for gid in batch}

            # Używanie tqdm dla paska postępu
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

        # Mniejsza przerwa między partiami
        if batch_num < len(all_batches) - 1:
            time.sleep(1)

    print(f"✅ Zaktualizowano plany dla {len(aktualizowane_plany)} z {len(grupa_ids)} grup")
    return aktualizowane_plany


def aktualizuj_plany_nauczycieli(nauczyciel_ids, max_workers=20) -> list[dict]:
    """Aktualizuje plany nauczycieli z równoległym przetwarzaniem i przerywaniem po błędach."""
    aktualizowane_plany = []

    print(f"🔄 Aktualizuję plany dla {len(nauczyciel_ids)} nauczycieli...")

    # Podziel na batche po 100 nauczycieli dla szybszego wykonania
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

        # Mniejsza przerwa między partiami
        if batch_num < len(all_batches) - 1:
            time.sleep(1)

    print(f"✅ Zaktualizowano plany dla {len(aktualizowane_plany)} z {len(nauczyciel_ids)} nauczycieli")
    return aktualizowane_plany
