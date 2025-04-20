# Połączenie i zapis do Supabase

from dotenv import load_dotenv
import os
from supabase import create_client
from scraper.scrapers.kierunki_scraper import scrape_kierunki
from scraper.scrapers.grupy_scraper import scrape_grupy_for_kierunki
from scraper.parsers.nauczyciel_parser import scrape_nauczyciele_from_grupy
import datetime
from tqdm import tqdm
import postgrest.exceptions
from scraper.ics_updater import BASE_URL

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def _utworz_powiazanie_nauczyciel_grupa(nauczyciel_id, grupa_id, uuid_map=None):
    """Tworzy powiązanie nauczyciel-grupa używając poprawnego UUID."""
    try:
        # Sprawdź czy grupa_id to UUID czy oryginalny ID liczbowy
        if uuid_map and grupa_id in uuid_map:
            grupa_uuid = uuid_map[grupa_id]
        else:
            grupa_uuid = grupa_id  # Zakładamy, że to już UUID

        relacja_data = {
            'nauczyciel_id': nauczyciel_id,
            'grupa_id': grupa_uuid
        }

        supabase.table('nauczyciele_grupy').insert(relacja_data).execute()
        return True
    except Exception as e:
        print(f"⚠️ Nie udało się utworzyć powiązania nauczyciel-grupa: {e}")
        return False

def _utworz_powiazania_zajecia(zajecia_data, events):
    """Tworzy powiązania zajęć z grupami i nauczycielami."""
    try:
        for i, zajecie in enumerate(zajecia_data):
            zajecie_id = zajecie['id']
            event = events[i]

            # Powiązanie z grupą
            if 'grupa_id' in event and event['grupa_id']:
                supabase.table('zajecia_grupy').insert({
                    'zajecia_id': zajecie_id,
                    'grupa_id': event['grupa_id']
                }).execute()

            # Powiązanie z nauczycielem
            if 'nauczyciel_id' in event and event['nauczyciel_id']:
                supabase.table('zajecia_nauczyciele').insert({
                    'zajecia_id': zajecie_id,
                    'nauczyciel_id': event['nauczyciel_id']
                }).execute()
    except Exception as e:
        print(f"⚠️ Błąd podczas tworzenia powiązań zajęć: {e}")


def save_kierunki(kierunki):
    """Zapisuje kierunki do bazy danych metodą wsadową."""
    if not kierunki:
        return []

    # Przygotuj dane w formacie do wsadowego dodania
    batch_data = []
    for kierunek in kierunki:
        # Synchronizacja nazw pól
        if 'link_kierunku' in kierunek and 'link_strony_kierunku' not in kierunek:
            kierunek['link_strony_kierunku'] = kierunek.pop('link_kierunku')

        batch_data.append({
            'nazwa_kierunku': kierunek.get('nazwa_kierunku'),
            'wydzial': kierunek.get('wydzial'),
            'link_strony_kierunku': kierunek.get('link_strony_kierunku')
        })

    try:
        # Wsadowe dodanie kierunków
        result = supabase.table('kierunki').insert(batch_data).execute()

        # Przypisz ID z powrotem do obiektów kierunków
        if result.data:
            for i, kierunek_db in enumerate(result.data):
                if i < len(kierunki):
                    kierunki[i]['id'] = kierunek_db['id']

        print(f"✅ Dodano wsadowo {len(batch_data)} kierunków")
        return kierunki
    except Exception as e:
        print(f"❌ Błąd podczas zapisywania kierunków: {e}")
        return []


def save_nauczyciele(nauczyciele):
    """Zapisuje nauczycieli do bazy danych metodą wsadową."""
    if not nauczyciele:
        return []

    try:
        # Przygotuj dane nauczycieli
        nauczyciele_data = []
        for nauczyciel in nauczyciele:
            nauczyciele_data.append({
                'imie_nazwisko': nauczyciel.get('imie_nazwisko'),
                'instytut': nauczyciel.get('instytut'),
                'email': nauczyciel.get('email'),
                'link_plan_nauczyciela': nauczyciel.get('link_planu'),  # poprawna nazwa kolumny
                'link_strony_nauczyciela': nauczyciel.get('link_nauczyciela')  # poprawna nazwa kolumny
            })

        # Wsadowe dodanie nauczycieli
        if nauczyciele_data:
            result = supabase.table('nauczyciele').insert(nauczyciele_data).execute()
            for i, n_db in enumerate(result.data):
                if i < len(nauczyciele):
                    nauczyciele[i]['id'] = n_db['id']

        # Przygotuj relacje nauczyciel-grupa
        relacje = []
        for nauczyciel in nauczyciele:
            if 'id' in nauczyciel and 'grupy_id' in nauczyciel:
                for grupa_id in nauczyciel['grupy_id']:
                    relacje.append({
                        'nauczyciel_id': nauczyciel['id'],
                        'grupa_id': grupa_id
                    })

        # Wsadowe dodanie relacji
        if relacje:
            supabase.table('nauczyciele_grupy').insert(relacje).execute()

        print(f"✅ Dodano {len(nauczyciele_data)} nauczycieli i {len(relacje)} relacji")
        return nauczyciele
    except Exception as e:
        print(f"❌ Błąd podczas zapisywania nauczycieli: {e}")
        return []


def save_events(events, source_type=None):
    """Zapisuje wydarzenia (zajęcia) do bazy danych."""
    if not events:
        return

    # Dodanie typu źródła do każdego wydarzenia
    if source_type:
        for event in events:
            event['source_type'] = source_type

    try:
        # Przygotuj dane do wsadowego dodania
        events_data = []

        for event in events:
            # Konwersja datetime na ISO format dla pól od/do
            od = event.get('od')
            do_ = event.get('do_')

            # Skracanie podgrupy do maksymalnie 20 znaków
            podgrupa = event.get('pg')
            if podgrupa and isinstance(podgrupa, str) and len(podgrupa) > 20:
                podgrupa = podgrupa[:17] + '...'

            event_data = {
                'przedmiot': event.get('przedmiot'),
                'od': od.isoformat() if isinstance(od, datetime.datetime) else od,
                'do_': do_.isoformat() if isinstance(do_, datetime.datetime) else do_,
                'miejsce': event.get('miejsce'),
                'rz': event.get('rz'),
                'link_ics_zrodlowy': event.get('link_ics'),
                'podgrupa': podgrupa,
                'uid': event.get('uid'),
                'source_type': event.get('source_type')  # Upewniam się, że source_type trafi do bazy
            }

            events_data.append(event_data)

        # Wsadowe dodanie wydarzeń
        if events_data:
            result = supabase.table('zajecia').insert(events_data).execute()
            print(f"✅ Dodano {len(events_data)} wydarzeń")

            # Tworzenie powiązań z grupami i nauczycielami
            if result.data:
                _utworz_powiazania_zajecia(result.data, events)
            else:
                print("⚠️ Brak danych w odpowiedzi po zapisie wydarzeń")

    except Exception as e:
        print(f"❌ Błąd podczas zapisywania wydarzeń: {e}")
        import traceback
        traceback.print_exc()

def update_kierunki(upsert=True):
    """Aktualizuje kierunki z funkcją upsert."""
    try:
        kierunki_data = scrape_kierunki()

        # Synchronizacja nazw pól
        for kierunek in kierunki_data:
            if 'link_kierunku' in kierunek and 'link_strony_kierunku' not in kierunek:
                kierunek['link_strony_kierunku'] = kierunek.pop('link_kierunku')

        if not upsert:
            return save_kierunki(kierunki_data)

        # Pobierz istniejące kierunki
        existing = supabase.table('kierunki').select('id,link_strony_kierunku').execute()
        existing_map = {k['link_strony_kierunku']: k['id'] for k in existing.data if 'link_strony_kierunku' in k}

        to_update = []
        to_insert = []

        for kierunek in kierunki_data:
            link = kierunek.get('link_strony_kierunku')

            if link in existing_map:
                kierunek['id'] = existing_map[link]
                to_update.append({
                    'id': kierunek['id'],
                    'nazwa_kierunku': kierunek.get('nazwa_kierunku'),
                    'wydzial': kierunek.get('wydzial'),
                    'link_strony_kierunku': link
                })
            else:
                to_insert.append({
                    'nazwa_kierunku': kierunek.get('nazwa_kierunku'),
                    'wydzial': kierunek.get('wydzial'),
                    'link_strony_kierunku': link
                })

        # Wykonaj wsadowe operacje
        if to_insert:
            insert_result = supabase.table('kierunki').insert(to_insert).execute()
            if insert_result.data:
                for i, data in enumerate(insert_result.data):
                    if i < len(kierunki_data) and kierunki_data[i]['link_strony_kierunku'] not in existing_map:
                        kierunki_data[i]['id'] = data['id']

        # Aktualizuj istniejące rekordy
        if to_update:
            for item in to_update:
                supabase.table('kierunki').update(item).eq('id', item['id']).execute()

        print(f"✅ Zaktualizowano {len(to_update)} kierunków, dodano {len(to_insert)} nowych")
        return kierunki_data
    except Exception as e:
        print(f"❌ Błąd podczas aktualizacji kierunków: {e}")
        return []


def update_nauczyciele(grupy=None, uuid_map=None):
    """Aktualizuje nauczycieli z funkcją upsert."""
    if not grupy:
        return []

    nauczyciele = scrape_nauczyciele_from_grupy(grupy)

    # Synchronizacja nazw pól
    for nauczyciel in nauczyciele:
        if 'link_planu' in nauczyciel and 'link_plan_nauczyciela' not in nauczyciel:
            nauczyciel['link_plan_nauczyciela'] = nauczyciel.pop('link_planu')
        if 'link_nauczyciela' in nauczyciel and 'link_strony_nauczyciela' not in nauczyciel:
            nauczyciel['link_strony_nauczyciela'] = nauczyciel.pop('link_nauczyciela')

    try:
        # Pobierz istniejących nauczycieli
        existing = supabase.table('nauczyciele').select('id,email,imie_nazwisko').execute()
        email_map = {n['email']: n['id'] for n in existing.data if n['email']}
        nazwa_map = {n['imie_nazwisko']: n['id'] for n in existing.data if n['imie_nazwisko']}

        to_update = []
        to_insert = []

        for nauczyciel in nauczyciele:
            email = nauczyciel.get('email')
            imie_nazwisko = nauczyciel.get('imie_nazwisko')

            if email and email in email_map:
                nauczyciel['id'] = email_map[email]
                to_update.append({
                    'id': nauczyciel['id'],
                    'imie_nazwisko': imie_nazwisko,
                    'instytut': nauczyciel.get('instytut'),
                    'email': email,
                    'link_plan_nauczyciela': nauczyciel.get('link_plan_nauczyciela'),
                    'link_strony_nauczyciela': nauczyciel.get('link_strony_nauczyciela')
                })
            elif imie_nazwisko and imie_nazwisko in nazwa_map:
                nauczyciel['id'] = nazwa_map[imie_nazwisko]
                to_update.append({
                    'id': nauczyciel['id'],
                    'imie_nazwisko': imie_nazwisko,
                    'instytut': nauczyciel.get('instytut'),
                    'email': email,
                    'link_plan_nauczyciela': nauczyciel.get('link_plan_nauczyciela'),
                    'link_strony_nauczyciela': nauczyciel.get('link_strony_nauczyciela')
                })
            else:
                to_insert.append({
                    'imie_nazwisko': imie_nazwisko,
                    'instytut': nauczyciel.get('instytut'),
                    'email': email,
                    'link_plan_nauczyciela': nauczyciel.get('link_plan_nauczyciela'),
                    'link_strony_nauczyciela': nauczyciel.get('link_strony_nauczyciela')
                })

        # Wykonaj wsadowe operacje
        if to_insert:
            insert_result = supabase.table('nauczyciele').insert(to_insert).execute()
            if insert_result.data:
                for i, data in enumerate(insert_result.data):
                    nauczyciel = next((n for n in nauczyciele if
                                      (n.get('email') not in email_map) and
                                      (n.get('imie_nazwisko') not in nazwa_map)), None)
                    if nauczyciel:
                        nauczyciel['id'] = data['id']

        # Aktualizuj istniejące rekordy
        if to_update:
            for item in to_update:
                supabase.table('nauczyciele').update(item).eq('id', item['id']).execute()

        # Tworzenie powiązań nauczyciel-grupa z przekazaniem mapy UUID
        for nauczyciel in nauczyciele:
            if 'id' in nauczyciel and 'grupy_id' in nauczyciel:
                for grupa_id in nauczyciel['grupy_id']:
                    _utworz_powiazanie_nauczyciel_grupa(nauczyciel['id'], grupa_id, uuid_map)

        print(f"✅ Zaktualizowano {len(to_update)} nauczycieli, dodano {len(to_insert)} nowych")
        return nauczyciele
    except Exception as e:
        print(f"❌ Błąd podczas aktualizacji nauczycieli: {e}")
        return []

def update_grupy(grupy):
    """Aktualizuje informacje o grupach w bazie danych."""
    try:
        print(f"Aktualizuję informacje o {len(grupy)} grupach...")

        # Sprawdź pierwsze kilka elementów do debugowania
        if grupy:
            print(f"Próbka danych grupy: {grupy[0]}")

        # Przygotuj dane do dodania zgodnie z nazwami kolumn w bazie
        grupy_do_zapisu = []
        for grupa in grupy:
            # Użyj jednolitych nazw pól zgodnych z bazą danych
            grupa_data = {
                'kod_grupy': grupa.get('kod_grupy'),
                'semestr': grupa.get('semestr'),
                'tryb_studiow': grupa.get('tryb_studiow'),
                'kierunek_id': grupa.get('kierunek_id'),
                'link_grupy': grupa.get('link_grupy')
            }

            # Link do ICS na podstawie oryginalnego ID
            if grupa.get('grupa_id'):
                grupa_data['link_ics_grupy'] = f"{BASE_URL}grupy_ics.php?ID={grupa.get('grupa_id')}&KIND=GG"

            grupy_do_zapisu.append(grupa_data)

        # Dodaj szczegółowe logowanie
        print(f"Przygotowano {len(grupy_do_zapisu)} grup do zapisu")

        # Zapisz wszystkie grupy
        wynik = supabase.table('grupy').upsert(grupy_do_zapisu).execute()

        # Utwórz mapowanie oryginalnego ID do nowego UUID
        uuid_map = {}
        if hasattr(wynik, 'data'):
            for grupa_db in wynik.data:
                if grupa_db.get('kod_grupy'):
                    # Znajdź oryginalną grupę z tym kodem
                    for grupa in grupy:
                        if grupa.get('kod_grupy') == grupa_db.get('kod_grupy'):
                            uuid_map[grupa.get('grupa_id')] = grupa_db['id']
                            grupa['uuid'] = grupa_db['id']  # Dodaj UUID do oryginalnych obiektów
                            break

        ilosc_zapisanych = len(wynik.data) if hasattr(wynik, 'data') else 0
        print(f"Zapisano {ilosc_zapisanych} grup do bazy danych.")
        print(f"Utworzono {len(uuid_map)} mapowań UUID.")

        return wynik.data if hasattr(wynik, 'data') else []

    except Exception as e:
        print(f"Błąd podczas aktualizacji grup: {e}")
        import traceback
        traceback.print_exc()
        return []