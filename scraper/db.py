# Połączenie i zapis do Supabase

from dotenv import load_dotenv
import os
from supabase import create_client
from scraper.scrapers.kierunki_scraper import scrape_kierunki
from scraper.scrapers.grupy_scraper import scrape_grupy_for_kierunki
from scraper.parsers.nauczyciel_parser import scrape_nauczyciele_from_grupy

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def save_kierunki(kierunki):
    """Zapisuje kierunki do bazy danych metodą wsadową."""
    if not kierunki:
        return []

    # Przygotuj dane w formacie do wsadowego dodania
    batch_data = []
    for kierunek in kierunki:
        batch_data.append({
            'nazwa': kierunek['nazwa_kierunku'],
            'wydzial': kierunek['wydzial'],
            'link': kierunek['link_kierunku']  # Zmieniono nazwę kolumny z 'link_kierunku' na 'link'
        })

    try:
        # Wsadowe dodanie kierunków
        result = supabase.table('kierunki').insert(batch_data).execute()

        # Przypisz ID z powrotem do obiektów kierunków
        if result.data:
            for i, item in enumerate(result.data):
                if i < len(kierunki):
                    kierunki[i]['id'] = item['id']

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
                'imie': nauczyciel.get('imie', ''),
                'nazwisko': nauczyciel.get('nazwisko', ''),
                'tytul': nauczyciel.get('tytul', ''),
                'email': nauczyciel.get('email', ''),
                'instytut': nauczyciel.get('instytut', ''),
                'link_nauczyciela': nauczyciel.get('link', ''),
                'link_ics': nauczyciel.get('link_ics', '')
            })

        # Wsadowe dodanie nauczycieli
        if nauczyciele_data:
            result = supabase.table('nauczyciele').insert(nauczyciele_data).execute()

            # Przypisz ID z powrotem
            if result.data:
                for i, item in enumerate(result.data):
                    if i < len(nauczyciele):
                        nauczyciele[i]['id'] = item['id']

        # Przygotuj relacje nauczyciel-grupa
        relacje = []
        for nauczyciel in nauczyciele:
            if 'id' in nauczyciel and 'grupa_id' in nauczyciel and nauczyciel['grupa_id']:
                relacje.append({
                    'nauczyciel_id': nauczyciel['id'],
                    'grupa_id': nauczyciel['grupa_id']
                })

        # Wsadowe dodanie relacji
        if relacje:
            supabase.table('nauczyciele_grupy').insert(relacje).execute()

        print(f"✅ Dodano {len(nauczyciele_data)} nauczycieli i {len(relacje)} relacji")
        return nauczyciele
    except Exception as e:
        print(f"❌ Błąd podczas zapisywania nauczycieli: {e}")
        return []


def save_events(events: list[dict], source_type: str) -> None:
    """
    Zapisuje wydarzenia (zajęcia) do bazy danych.

    Args:
        events: Lista wydarzeń do zapisania
        source_type: Typ źródła ('grupa' lub 'nauczyciel')
    """
    if not events:
        return

    try:
        # Przygotuj dane do wsadowego dodania
        events_data = []

        for event in events:
            data = {
                'tytul': event.get('summary', ''),
                'opis': event.get('description', ''),
                'lokalizacja': event.get('location', ''),
                'data_start': event.get('start', ''),
                'data_koniec': event.get('end', ''),
                'uid': event.get('uid', ''),
                'link_ics_zrodlowy': event.get('link_ics', '')  # Zmieniona nazwa kolumny
            }

            # Dodaj klucz obcy w zależności od typu źródła
            if source_type == 'grupa' and 'grupa_id' in event:
                data['grupa_id'] = event['grupa_id']
            elif source_type == 'nauczyciel' and 'nauczyciel_id' in event:
                data['nauczyciel_id'] = event['nauczyciel_id']

            events_data.append(data)

        # Wsadowe dodanie wydarzeń
        if events_data:
            result = supabase.table('zajecia').insert(events_data).execute()
            print(f"✅ Dodano {len(events_data)} wydarzeń")

    except Exception as e:
        print(f"❌ Błąd podczas zapisywania wydarzeń: {e}")

def update_kierunki(upsert=True):
    """Aktualizuje kierunki z funkcją upsert."""
    try:
        kierunki_data = scrape_kierunki()

        if not upsert:
            return save_kierunki(kierunki_data)

        # Pobierz istniejące kierunki
        existing = supabase.table('kierunki').select('id,link_strony_kierunku').execute()
        existing_map = {k['link_strony_kierunku']: k['id'] for k in existing.data if 'link_strony_kierunku' in k}

        to_update = []
        to_insert = []

        for kierunek in kierunki_data:
            link = kierunek.get('link_kierunku')  # Pole z funkcji scrape_kierunki

            if link in existing_map:
                # Do aktualizacji
                kierunek['id'] = existing_map[link]
                to_update.append({
                    'id': kierunek['id'],
                    'nazwa_kierunku': kierunek['nazwa_kierunku'],  # Poprawna nazwa kolumny
                    'wydzial': kierunek['wydzial']
                })
            else:
                # Do dodania
                to_insert.append({
                    'nazwa_kierunku': kierunek['nazwa_kierunku'],  # Poprawna nazwa kolumny
                    'wydzial': kierunek['wydzial'],
                    'link_strony_kierunku': link
                })

        # Wykonaj wsadowe operacje
        if to_insert:
            insert_result = supabase.table('kierunki').insert(to_insert).execute()
            if insert_result.data:
                insert_idx = 0
                for kierunek in kierunki_data:
                    if kierunek.get('id') is None:
                        kierunek['id'] = insert_result.data[insert_idx]['id']
                        insert_idx += 1

        # Aktualizuj istniejące rekordy
        if to_update:
            for item in to_update:
                supabase.table('kierunki').update(item).eq('id', item['id']).execute()

        print(f"✅ Zaktualizowano {len(to_update)} kierunków, dodano {len(to_insert)} nowych")
        return kierunki_data
    except Exception as e:
        print(f"❌ Błąd podczas aktualizacji kierunków: {e}")
        return []

def update_nauczyciele(grupy=None):
    """Aktualizuje nauczycieli z funkcją upsert."""
    if not grupy:
        return []

    nauczyciele = scrape_nauczyciele_from_grupy(grupy)

    try:
        # Pobierz istniejących nauczycieli
        existing = supabase.table('nauczyciele').select('id,email').execute()
        existing_map = {n['email']: n['id'] for n in existing.data if n['email']}

        to_update = []
        to_insert = []
        relacje = []

        for nauczyciel in nauczyciele:
            email = nauczyciel.get('email', '')
            if email and email in existing_map:
                # Do aktualizacji
                nauczyciel['id'] = existing_map[email]
                to_update.append({
                    'id': nauczyciel['id'],
                    'imie_nazwisko': nauczyciel.get('imie_nazwisko', ''),
                    'tytul': nauczyciel.get('tytul', ''),
                    'instytut': nauczyciel.get('instytut', ''),
                    'link_nauczyciela': nauczyciel.get('link_nauczyciela', ''),
                    'link_ics': nauczyciel.get('link_ics', '')
                })

                # Zapisz relację
                if 'grupa_id' in nauczyciel and nauczyciel['grupa_id']:
                    relacje.append({
                        'nauczyciel_id': nauczyciel['id'],
                        'grupa_id': nauczyciel['grupa_id']
                    })
            else:
                # Do dodania
                to_insert.append({
                    'imie_nazwisko': nauczyciel.get('imie_nazwisko', ''),
                    'tytul': nauczyciel.get('tytul', ''),
                    'email': email,
                    'instytut': nauczyciel.get('instytut', ''),
                    'link_nauczyciela': nauczyciel.get('link_nauczyciela', ''),
                    'link_ics': nauczyciel.get('link_ics', '')
                })

        # Wykonaj wsadowe operacje
        if to_insert:
            insert_result = supabase.table('nauczyciele').insert(to_insert).execute()
            if insert_result.data:
                insert_idx = 0
                for i, nauczyciel in enumerate(nauczyciele):
                    if nauczyciel.get('id') is None:
                        nauczyciel['id'] = insert_result.data[insert_idx]['id']
                        insert_idx += 1

                        # Dodaj relację dla nowo utworzonych nauczycieli
                        if 'grupa_id' in nauczyciel and nauczyciel['grupa_id']:
                            relacje.append({
                                'nauczyciel_id': nauczyciel['id'],
                                'grupa_id': nauczyciel['grupa_id']
                            })

        # Aktualizuj istniejących nauczycieli
        if to_update:
            for item in to_update:
                supabase.table('nauczyciele').update(item).eq('id', item['id']).execute()

        # Zapisz relacje nauczyciel-grupa
        if relacje:
            supabase.table('nauczyciele_grupy').insert(relacje).execute()

        print(f"✅ Zaktualizowano {len(to_update)} nauczycieli, dodano {len(to_insert)} nowych")
        return nauczyciele
    except Exception as e:
        print(f"❌ Błąd podczas aktualizacji nauczycieli: {e}")
        return []


def update_grupy(kierunki, upsert=True):
    """Aktualizuje grupy dla podanych kierunków."""
    try:
        wszystkie_grupy = []

        for kierunek in kierunki:
            nazwa_kierunku = kierunek.get('nazwa_kierunku')
            link_kierunku = kierunek.get('link_kierunku')
            id_kierunku = kierunek.get('id')

            if not id_kierunku or not link_kierunku:
                continue

            print(f"🔍 Pobieram grupy dla kierunku: {nazwa_kierunku}")
            # Pobieranie grup
            grupy = scrape_grupy_for_kierunki(link_kierunku)

            # Sprawdzamy czy grupy są listą słowników
            if not grupy:
                print(f"⚠️ Brak grup dla kierunku {nazwa_kierunku}")
                continue

            if not isinstance(grupy, list):
                print(f"⚠️ Nieprawidłowy format danych grup: {type(grupy)}. Oczekiwano listy.")
                continue

            valid_grupy = []
            for grupa in grupy:
                if isinstance(grupa, dict):
                    grupa['kierunek_id'] = id_kierunku
                    valid_grupy.append(grupa)
                else:
                    print(f"⚠️ Pomijam nieprawidłowy format grupy: {type(grupa)}")

            if not valid_grupy:
                print(f"⚠️ Brak prawidłowych grup dla kierunku {nazwa_kierunku}")
                continue

            print(f"📌 Znaleziono {len(valid_grupy)} grup dla kierunku {nazwa_kierunku}")
            wszystkie_grupy.extend(valid_grupy)

        if not upsert:
            return wszystkie_grupy

        # Pobierz istniejące grupy
        existing = supabase.table('grupy').select('id,link_ics_grupy').execute()
        existing_map = {g['link_ics_grupy']: g['id'] for g in existing.data if 'link_ics_grupy' in g}

        to_update = []
        to_insert = []

        for grupa in wszystkie_grupy:
            link_ics = grupa.get('link_ics_grupy')

            if link_ics in existing_map:
                # Do aktualizacji
                grupa['id'] = existing_map[link_ics]
                to_update.append({
                    'id': grupa['id'],
                    'kod_grupy': grupa['kod_grupy'],
                    'kierunek_id': grupa['kierunek_id'],
                    'semestr': grupa.get('semestr', ''),
                    'tryb_studiow': grupa.get('tryb_studiow', ''),
                    'link_grupy': grupa.get('link_grupy', ''),
                })
            else:
                # Do dodania
                to_insert.append({
                    'kod_grupy': grupa['kod_grupy'],
                    'kierunek_id': grupa['kierunek_id'],
                    'link_ics_grupy': link_ics,
                    'semestr': grupa.get('semestr', ''),
                    'tryb_studiow': grupa.get('tryb_studiow', ''),
                    'link_grupy': grupa.get('link_grupy', '')
                })

        # Wykonaj wsadowe operacje
        if to_insert:
            insert_result = supabase.table('grupy').insert(to_insert).execute()
            if insert_result.data:
                insert_idx = 0
                for grupa in wszystkie_grupy:
                    if grupa.get('id') is None:
                        grupa['id'] = insert_result.data[insert_idx]['id']
                        insert_idx += 1

        # Aktualizuj istniejące rekordy
        if to_update:
            for item in to_update:
                supabase.table('grupy').update(item).eq('id', item['id']).execute()

        print(f"✅ Zaktualizowano {len(to_update)} grup, dodano {len(to_insert)} nowych")
        return wszystkie_grupy

    except Exception as e:
        print(f"❌ Błąd podczas aktualizacji grup: {e}")
        return []