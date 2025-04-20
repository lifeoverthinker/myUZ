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
    """Zapisuje wydarzenia (zajęcia) do bazy danych z mechanizmem upsert."""
    if not events:
        return 0

    dodane = 0
    zaktualizowane = 0

    for event in events:
        try:
            # Dane do zapisu
            zajecie_data = {
                'przedmiot': event.get('przedmiot'),
                'od': event.get('od'),
                'do_': event.get('do_'),
                'miejsce': event.get('miejsce'),
                'rz': event.get('rz'),
                'link_ics_zrodlowy': event.get('link_ics_zrodlowy'),
                'podgrupa': event.get('podgrupa'),
                'uid': event.get('uid'),
                'source_type': source_type
            }

            # Najpierw sprawdź po UID
            if event.get('uid'):
                wynik = supabase.table('zajecia').select('id').eq('uid', event['uid']).execute()
                if wynik.data and len(wynik.data) > 0:
                    # Aktualizuj istniejące
                    supabase.table('zajecia').update(zajecie_data).eq('uid', event['uid']).execute()
                    zaktualizowane += 1
                    zajecie_id = wynik.data[0]['id']
                else:
                    # Dodaj nowe
                    wynik = supabase.table('zajecia').insert(zajecie_data).execute()
                    if wynik.data:
                        zajecie_id = wynik.data[0]['id']
                        dodane += 1
                    else:
                        continue
            else:
                # Sprawdź po innych polach
                wynik = supabase.table('zajecia').select('id')\
                    .eq('przedmiot', event.get('przedmiot'))\
                    .eq('od', event.get('od'))\
                    .eq('do_', event.get('do_'))\
                    .eq('miejsce', event.get('miejsce'))\
                    .execute()

                if wynik.data and len(wynik.data) > 0:
                    # Aktualizuj istniejące
                    supabase.table('zajecia').update(zajecie_data).eq('id', wynik.data[0]['id']).execute()
                    zaktualizowane += 1
                    zajecie_id = wynik.data[0]['id']
                else:
                    # Dodaj nowe
                    wynik = supabase.table('zajecia').insert(zajecie_data).execute()
                    if wynik.data:
                        zajecie_id = wynik.data[0]['id']
                        dodane += 1
                    else:
                        continue

            # Dodaj powiązania
            if source_type == 'grupa' and 'grupa_id' in event:
                supabase.table('zajecia_grupy').upsert({
                    'zajecia_id': zajecie_id,
                    'grupa_id': event['grupa_id']
                }).execute()

            elif source_type == 'nauczyciel' and 'nauczyciel_id' in event:
                supabase.table('zajecia_nauczyciele').upsert({
                    'zajecia_id': zajecie_id,
                    'nauczyciel_id': event['nauczyciel_id']
                }).execute()

        except Exception as e:
            print(f"Błąd zapisywania zajęcia: {e}")

    print(f"Dodano {dodane} nowych zajęć, zaktualizowano {zaktualizowane} istniejących\n")
    return dodane + zaktualizowane

def save_events_batch(events, source_type=None, batch_size=200):
    """Wsadowo zapisuje zajęcia do bazy danych."""
    if not events:
        return 0

    saved_count = 0
    batches = [events[i:i+batch_size] for i in range(0, len(events), batch_size)]
    print(f"Zapisywanie {len(events)} zajęć w {len(batches)} partiach...")

    for i, batch in enumerate(batches):
        try:
            # Przygotowanie danych zgodnie ze strukturą tabeli
            zajecia_data = []
            for event in batch:
                zajecia_data.append({
                    'przedmiot': event.get('przedmiot'),
                    'od': event.get('od'),
                    'do_': event.get('do_'),
                    'miejsce': event.get('miejsce'),
                    'rz': event.get('rz'),
                    'podgrupa': event.get('podgrupa'),
                    'uid': event.get('uid'),
                    'link_ics_zrodlowy': event.get('link_ics_zrodlowy'),
                    'source_type': source_type
                })

            # Wsadowy upsert
            wynik = supabase.table('zajecia').upsert(zajecia_data).execute()

            if wynik.data:
                # Przygotowanie relacji grupowych
                relacje_grupy = []
                relacje_nauczyciele = []

                for j, zajecie in enumerate(wynik.data):
                    event = batch[j]
                    zajecie_id = zajecie['id']

                    # Relacja zajęcia-grupy
                    if source_type == 'grupa' and 'grupa_id' in event:
                        relacje_grupy.append({
                            'zajecia_id': zajecie_id,
                            'grupa_id': event['grupa_id']
                        })

                    # Relacja zajęcia-nauczyciele
                    elif source_type == 'nauczyciel' and 'nauczyciel_id' in event:
                        relacje_nauczyciele.append({
                            'zajecia_id': zajecie_id,
                            'nauczyciel_id': event['nauczyciel_id']
                        })

                # Wsadowy zapis relacji
                if relacje_grupy:
                    supabase.table('zajecia_grupy').upsert(relacje_grupy).execute()

                if relacje_nauczyciele:
                    supabase.table('zajecia_nauczyciele').upsert(relacje_nauczyciele).execute()

                saved_count += len(wynik.data)
                print(f"Zapisano partię {i+1}/{len(batches)} ({len(wynik.data)} zajęć)")
        except Exception as e:
            print(f"Błąd zapisywania partii {i+1}: {e}")

    return saved_count

def update_kierunki(kierunki):
    """Aktualizuje informacje o kierunkach w bazie danych."""
    try:
        # Sprawdź czy otrzymaliśmy listę kierunków
        if not isinstance(kierunki, list):
            print(f"⚠️ Wykryto pojedynczy obiekt Kierunek zamiast listy, konwertuję na listę.")
            kierunki = [kierunki] if kierunki else []

        print(f"Aktualizuję informacje o {len(kierunki)} kierunkach...")

        # Sprawdzenie czy lista jest pusta
        if not kierunki:
            print("Brak kierunków do zapisania.")
            return []

        # Pobierz istniejące kierunki z bazy
        existing_kierunki = supabase.table('kierunki').select('id,nazwa_kierunku,link_strony_kierunku').execute()
        existing_by_name = {k['nazwa_kierunku']: k['id'] for k in existing_kierunki.data if k['nazwa_kierunku']}
        existing_by_link = {k['link_strony_kierunku']: k['id'] for k in existing_kierunki.data if k['link_strony_kierunku']}

        # Przygotuj dane do dodania lub aktualizacji
        to_update = []
        to_insert = []

        for kierunek in kierunki:
            nazwa = kierunek.nazwa
            link = kierunek.link

            # Sprawdź czy kierunek już istnieje
            existing_id = None
            if nazwa in existing_by_name:
                existing_id = existing_by_name[nazwa]
            elif link in existing_by_link:
                existing_id = existing_by_link[link]

            if existing_id:
                # Aktualizuj istniejący rekord
                to_update.append({
                    'id': existing_id,
                    'nazwa_kierunku': nazwa,
                    'wydzial': kierunek.wydzial,
                    'link_strony_kierunku': link
                })
            else:
                # Dodaj nowy rekord
                to_insert.append({
                    'nazwa_kierunku': nazwa,
                    'wydzial': kierunek.wydzial,
                    'link_strony_kierunku': link
                })

        print(f"Do aktualizacji: {len(to_update)}, do dodania: {len(to_insert)}")

        # Wykonaj aktualizacje
        updated_records = []
        if to_update:
            for record in to_update:
                result = supabase.table('kierunki').update(record).eq('id', record['id']).execute()
                if result.data:
                    updated_records.extend(result.data)

        # Wykonaj wstawianie
        inserted_records = []
        if to_insert:
            result = supabase.table('kierunki').insert(to_insert).execute()
            if result.data:
                inserted_records = result.data

        all_records = updated_records + inserted_records

        print(f"Zaktualizowano {len(updated_records)} kierunków, dodano {len(inserted_records)} nowych.")

        return all_records

    except Exception as e:
        print(f"Błąd podczas aktualizacji kierunków: {e}")
        import traceback
        traceback.print_exc()
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

        # Sprawdzenie czy lista jest pusta
        if not grupy:
            print("Brak grup do zapisania.")
            return []

        # Przygotuj dane do dodania zgodnie z nazwami kolumn w bazie
        grupy_do_zapisu = []
        for grupa in grupy:
            grupa_data = {
                'kod_grupy': grupa.get('kod_grupy'),
                'semestr': grupa.get('semestr'),
                'tryb_studiow': grupa.get('tryb_studiow'),
                'kierunek_id': grupa.get('kierunek_id'),
                'link_grupy': grupa.get('link_grupy')
            }

            if grupa.get('grupa_id'):
                grupa_data['link_ics_grupy'] = f"{BASE_URL}grupy_ics.php?ID={grupa.get('grupa_id')}&KIND=GG"

            grupy_do_zapisu.append(grupa_data)

        print(f"Przygotowano {len(grupy_do_zapisu)} grup do zapisu")

        # Zapisz grupy tylko jeśli lista nie jest pusta
        if grupy_do_zapisu:
            wynik = supabase.table('grupy').upsert(grupy_do_zapisu).execute()

            # Utwórz mapowanie oryginalnego ID do nowego UUID
            uuid_map = {}
            if hasattr(wynik, 'data'):
                for grupa_db in wynik.data:
                    if grupa_db.get('kod_grupy'):
                        for grupa in grupy:
                            if grupa.get('kod_grupy') == grupa_db.get('kod_grupy'):
                                uuid_map[grupa.get('grupa_id')] = grupa_db['id']
                                grupa['uuid'] = grupa_db['id']
                                break

            ilosc_zapisanych = len(wynik.data) if hasattr(wynik, 'data') else 0
            print(f"Zapisano {ilosc_zapisanych} grup do bazy danych.")
            print(f"Utworzono {len(uuid_map)} mapowań UUID.")

            return wynik.data if hasattr(wynik, 'data') else []
        else:
            print("Brak danych grup do zapisania.")
            return []

    except Exception as e:
        print(f"Błąd podczas aktualizacji grup: {e}")
        import traceback
        traceback.print_exc()
        return []

def update_zajecia(grupy_data=None, nauczyciele_data=None):
    """Pobiera i aktualizuje plany zajęć dla grup i nauczycieli."""
    from scraper.ics_updater import parse_ics_file, fetch_ics_content
    import concurrent.futures
    from tqdm import tqdm

    zajecia_count = 0
    max_workers = 30  # Zwiększamy liczbę wątków dla szybszego pobierania

    # Funkcja do przetwarzania pojedynczej grupy
    def process_grupa(grupa):
        if not grupa.get('uuid') or not grupa.get('link_ics_grupy'):
            return []

        ics_link = grupa['link_ics_grupy']
        ics_content = fetch_ics_content(ics_link)
        if not ics_content:
            return []

        events = parse_ics_file(ics_content, link_ics_zrodlowy=ics_link)
        for event in events:
            event['grupa_id'] = grupa['uuid']

        return events

    # Funkcja do przetwarzania nauczyciela
    def process_nauczyciel(nauczyciel):
        if not nauczyciel.get('id') or not nauczyciel.get('link_plan_nauczyciela'):
            return []

        nauczyciel_id = nauczyciel['link_plan_nauczyciela'].split('ID=')[1] if 'ID=' in nauczyciel['link_plan_nauczyciela'] else None
        if not nauczyciel_id:
            return []

        ics_link = f"{BASE_URL}nauczyciel_ics.php?ID={nauczyciel_id}&KIND=NT"
        ics_content = fetch_ics_content(ics_link)
        if not ics_content:
            return []

        events = parse_ics_file(ics_content, link_ics_zrodlowy=ics_link)
        for event in events:
            event['nauczyciel_id'] = nauczyciel['id']

        return events

    try:
        # Przetwarzanie grup równolegle w partiach
        if grupy_data:
            print(f"Pobieranie planów zajęć dla {len(grupy_data)} grup...")

            # Dzielimy na mniejsze porcje żeby lepiej zarządzać pamięcią
            batch_size = 100
            for i in range(0, len(grupy_data), batch_size):
                current_batch = grupy_data[i:i+batch_size]
                all_events = []

                with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
                    futures = {executor.submit(process_grupa, grupa): grupa for grupa in current_batch}

                    for future in tqdm(concurrent.futures.as_completed(futures),
                                      total=len(futures),
                                      desc=f"Pobieranie planów grup {i+1}-{i+len(current_batch)} z {len(grupy_data)}"):
                        events = future.result()
                        all_events.extend(events)

                batch_count = save_events_batch(all_events, source_type='grupa')
                zajecia_count += batch_count

        # Przetwarzanie nauczycieli równolegle w partiach
        if nauczyciele_data:
            print(f"Pobieranie planów zajęć dla {len(nauczyciele_data)} nauczycieli...")

            # Dzielimy na mniejsze porcje żeby lepiej zarządzać pamięcią
            batch_size = 100
            for i in range(0, len(nauczyciele_data), batch_size):
                current_batch = nauczyciele_data[i:i+batch_size]
                all_events = []

                with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
                    futures = {executor.submit(process_nauczyciel, n): n for n in current_batch}

                    for future in tqdm(concurrent.futures.as_completed(futures),
                                      total=len(futures),
                                      desc=f"Pobieranie planów nauczycieli {i+1}-{i+len(current_batch)} z {len(nauczyciele_data)}"):
                        events = future.result()
                        all_events.extend(events)

                batch_count = save_events_batch(all_events, source_type='nauczyciel')
                zajecia_count += batch_count

        print(f"Zakończono pobieranie planów zajęć. Zapisano {zajecia_count} zajęć.")
        return zajecia_count

    except Exception as e:
        print(f"Błąd podczas aktualizacji planów zajęć: {e}")
        import traceback
        traceback.print_exc()
        return 0
