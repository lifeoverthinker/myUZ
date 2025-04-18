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


def _utworz_powiazanie_nauczyciel_grupa(nauczyciel_id, grupa_id):
    """Tworzy powiązanie nauczyciel-grupa poprzez tabelę nauczyciele_grupy."""
    try:
        # Użyj bezpośredniego powiązania przez tabelę nauczyciele_grupy
        relacja_data = {
            'nauczyciel_id': nauczyciel_id,
            'grupa_id': grupa_id
        }

        supabase.table('nauczyciele_grupy').insert(relacja_data).execute()
        return True
    except Exception as e:
        print(f"⚠️ Nie udało się utworzyć powiązania dla nauczyciela {nauczyciel_id}: {e}")
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

def save_events(events: list[dict]) -> None:
    """Zapisuje wydarzenia (zajęcia) do bazy danych."""
    if not events:
        return

    try:
        # Przygotuj dane do wsadowego dodania
        events_data = []

        for event in events:
            events_data.append({
                'przedmiot': event.get('przedmiot'),
                'od': event.get('od'),
                'do_': event.get('do_'),
                'miejsce': event.get('miejsce'),
                'rz': event.get('rz'),
                'link_ics_zrodlowy': event.get('link_ics'),  # poprawna nazwa kolumny
                'podgrupa': event.get('pg'),
                'uid': event.get('uid')
            })

        # Wsadowe dodanie wydarzeń
        if events_data:
            result = supabase.table('zajecia').insert(events_data).execute()
            print(f"✅ Dodano {len(events_data)} wydarzeń")

            # Tworzenie powiązań z grupami i nauczycielami
            if result.data:
                _utworz_powiazania_zajecia(result.data, events)

    except Exception as e:
        print(f"❌ Błąd podczas zapisywania wydarzeń: {e}")

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

def update_nauczyciele(grupy=None):
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

        # Tworzenie powiązań nauczyciel-grupa
        for nauczyciel in nauczyciele:
            if 'id' in nauczyciel and 'grupy_id' in nauczyciel:
                for grupa_id in nauczyciel['grupy_id']:
                    _utworz_powiazanie_nauczyciel_grupa(nauczyciel['id'], grupa_id)

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
            link_kierunku = kierunek.get('link_strony_kierunku')
            id_kierunku = kierunek.get('id')
            wydzial = kierunek.get('wydzial', 'Nieznany wydział')

            if not id_kierunku:
                print(f"⚠️ Brak ID dla kierunku: {nazwa_kierunku}")
                continue

            if not link_kierunku:
                print(f"⚠️ Brak poprawnego linku dla kierunku: {nazwa_kierunku}")
                continue

            print(f"🔍 Pobieram grupy dla kierunku: {nazwa_kierunku}")
            print(f"🔗 Link kierunku: {link_kierunku}")

            # Przygotuj obiekt dla scrapera - uwaga na nazwy pól!
            kierunek_obj = {
                'id': id_kierunku,
                'nazwa_kierunku': nazwa_kierunku,
                'link_kierunku': link_kierunku,  # Dla scrapera potrzebne jako link_kierunku
                'wydzial': wydzial
            }

            grupy = scrape_grupy_for_kierunki([kierunek_obj])

            if not grupy:
                print(f"❌ Brak grup dla kierunku: {nazwa_kierunku}")
                continue

            if not isinstance(grupy, list):
                print(f"❌ Nieprawidłowy format danych grup dla {nazwa_kierunku}")
                continue

            valid_grupy = []
            for grupa in grupy:
                if isinstance(grupa, dict) and 'kierunek_id' not in grupa:
                    grupa['kierunek_id'] = id_kierunku
                valid_grupy.append(grupa)

            if not valid_grupy:
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
            # Skracanie zgodnie z limitami w bazie danych
            if isinstance(grupa.get('kod_grupy'), str) and len(grupa['kod_grupy']) > 50:
                grupa['kod_grupy'] = grupa['kod_grupy'][:47] + '...'

            if isinstance(grupa.get('tryb_studiow'), str) and len(grupa['tryb_studiow']) > 50:
                grupa['tryb_studiow'] = grupa['tryb_studiow'][:47] + '...'

            if isinstance(grupa.get('link_ics_grupy'), str) and len(grupa['link_ics_grupy']) > 255:
                grupa['link_ics_grupy'] = grupa['link_ics_grupy'][:252] + '...'

            if isinstance(grupa.get('link_grupy'), str) and len(grupa['link_grupy']) > 255:
                grupa['link_grupy'] = grupa['link_grupy'][:252] + '...'

            if isinstance(grupa.get('semestr'), str) and len(grupa['semestr']) > 255:
                grupa['semestr'] = grupa['semestr'][:252] + '...'

            link_ics = grupa.get('link_ics_grupy')

            if link_ics in existing_map:
                grupa['id'] = existing_map[link_ics]
                to_update.append({
                    'id': grupa['id'],
                    'kod_grupy': grupa.get('kod_grupy'),
                    'tryb_studiow': grupa.get('tryb_studiow'),
                    'kierunek_id': grupa.get('kierunek_id'),
                    'link_grupy': grupa.get('link_grupy'),
                    'link_ics_grupy': link_ics,
                    'semestr': grupa.get('semestr')
                })
            else:
                to_insert.append({
                    'kod_grupy': grupa.get('kod_grupy'),
                    'tryb_studiow': grupa.get('tryb_studiow'),
                    'kierunek_id': grupa.get('kierunek_id'),
                    'link_grupy': grupa.get('link_grupy'),
                    'link_ics_grupy': link_ics,
                    'semestr': grupa.get('semestr')
                })

        # Wykonaj wsadowe operacje
        if to_insert:
            insert_result = supabase.table('grupy').insert(to_insert).execute()
            if insert_result.data:
                for i, data in enumerate(insert_result.data):
                    if i < len(wszystkie_grupy):
                        if 'link_ics_grupy' in wszystkie_grupy[i] and wszystkie_grupy[i]['link_ics_grupy'] not in existing_map:
                            wszystkie_grupy[i]['id'] = data['id']

        # Aktualizuj istniejące rekordy
        if to_update:
            for item in to_update:
                supabase.table('grupy').update(item).eq('id', item['id']).execute()

        print(f"✅ Zaktualizowano {len(to_update)} grup, dodano {len(to_insert)} nowych")
        return wszystkie_grupy

    except Exception as e:
        print(f"❌ Błąd podczas aktualizacji grup: {e}")
        return []