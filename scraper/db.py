from dotenv import load_dotenv
import os
from supabase import create_client
from dataclasses import asdict, is_dataclass
from typing import Dict, Any, List, Optional, Set, Tuple

# Wczytaj zmienne środowiskowe
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

def get_uuid_map(table: str, key_col: str, id_col: str) -> Dict[str, str]:
    """
    Uniwersalna funkcja mapująca wartości kluczowe na UUID z dowolnej tabeli.
    """
    result = supabase.table(table).select(f"{key_col}, {id_col}").execute()
    return {row[key_col]: row[id_col] for row in result.data}

def chunks(lst: List[Any], n: int):
    """Dzieli listę na kawałki po n elementów."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

def save_kierunki(kierunki):
    if not kierunki:
        return []
    batch_data = []
    for kierunek in kierunki:
        if is_dataclass(kierunek):
            kierunek = asdict(kierunek)
        batch_data.append({
            'kierunek_id': kierunek.get('kierunek_id'),
            'nazwa_kierunku': kierunek.get('nazwa_kierunku'),
            'wydzial': kierunek.get('wydzial'),
            'link_strony_kierunku': kierunek.get('link_strony_kierunku'),
            'czy_podyplomowe': kierunek.get('czy_podyplomowe', False)
        })
    try:
        supabase.table('kierunki').upsert(batch_data, on_conflict='kierunek_id').execute()
        print(f"✅ Upsertowano {len(batch_data)} kierunków")
        return kierunki
    except Exception as e:
        print(f"❌ Błąd podczas upsertowania kierunków: {e}")
        return []

def remove_duplicates_grupy(grupy):
    seen = set()
    unique = []
    for g in grupy:
        key = (g.get('kod_grupy'), g.get('kierunek_id'))
        if key not in seen:
            seen.add(key)
            unique.append(g)
    return unique

def save_grupy(grupy, kierunek_uuid_map, batch_size=1000):
    if not grupy:
        return []
    grupy = remove_duplicates_grupy(grupy)
    total = 0
    for batch_i, batch in enumerate(chunks(grupy, batch_size), 1):
        data = []
        for g in batch:
            if is_dataclass(g):
                g = asdict(g)
            uuid_for_kierunek = kierunek_uuid_map.get(str(g.get('kierunek_id')))
            data.append({
                'grupa_id': g.get('grupa_id'),
                'kod_grupy': g.get('kod_grupy'),
                'semestr': g.get('semestr'),
                'tryb_studiow': g.get('tryb_studiow'),
                'kierunek_id': uuid_for_kierunek,
                'link_grupy': g.get('link_grupy'),
                'link_ics_grupy': g.get('link_ics_grupy')
            })
        try:
            supabase.table('grupy').upsert(data, on_conflict='kod_grupy,kierunek_id').execute()
            total += len(data)
            print(f"✅ Upsertowano batch {batch_i}: {len(data)} grup (razem: {total})")
        except Exception as e:
            print(f"❌ Błąd podczas upsertowania batcha grup: {e}")
    return total

def save_nauczyciele(nauczyciele, grupa_uuid_map, batch_size=1000):
    if not nauczyciele:
        return []
    total = 0
    for batch_i, batch in enumerate(chunks(nauczyciele, batch_size), 1):
        nauczyciele_data = []
        relacje = []
        for nauczyciel in batch:
            if is_dataclass(nauczyciel):
                nauczyciel = asdict(nauczyciel)
            record = {
                'nauczyciel_id': nauczyciel.get('nauczyciel_id'),
                'nauczyciel_nazwa': nauczyciel.get('nauczyciel_nazwa') or nauczyciel.get('nazwa') or nauczyciel.get('imie_nazwisko')
            }
            if nauczyciel.get('instytut'): record['instytut'] = nauczyciel['instytut']
            if nauczyciel.get('email'): record['email'] = nauczyciel['email']
            if nauczyciel.get('link_plan_nauczyciela'): record['link_plan_nauczyciela'] = nauczyciel['link_plan_nauczyciela']
            if nauczyciel.get('link_strony_nauczyciela'): record['link_strony_nauczyciela'] = nauczyciel['link_strony_nauczyciela']
            nauczyciele_data.append(record)
            # Relacja nauczyciel-grupa
            if 'nauczyciel_id' in nauczyciel and 'grupy_id' in nauczyciel and nauczyciel['grupy_id']:
                for grupa_id_UZ in nauczyciel['grupy_id']:
                    g_uuid = grupa_uuid_map.get(str(grupa_id_UZ))
                    if g_uuid:
                        relacje.append({'nauczyciel_id': nauczyciel['nauczyciel_id'], 'grupa_id': g_uuid})
        try:
            supabase.table('nauczyciele').upsert(nauczyciele_data, on_conflict='nauczyciel_id').execute()
            total += len(nauczyciele_data)
            print(f"✅ Upsertowano batch {batch_i}: {len(nauczyciele_data)} nauczycieli (razem: {total})")
            if relacje:
                supabase.table('nauczyciele_grupy').upsert(relacje, on_conflict='nauczyciel_id,grupa_id').execute()
                print(f"✅ Upsertowano {len(relacje)} relacji nauczyciel-grupa w batchu {batch_i}")
        except Exception as e:
            print(f"❌ Błąd podczas upsertowania batcha nauczycieli: {e}")
    return total

def truncate_fields(event):
    return {
        'uid': event.get('uid'),
        'przedmiot': event.get('przedmiot'),
        'od': event.get('od'),
        'do_': event.get('do_'),
        'miejsce': (event.get('miejsce')[:255] if isinstance(event.get('miejsce'), str) else event.get('miejsce')),
        'rz': (event.get('rz')[:10] if isinstance(event.get('rz'), str) else event.get('rz')),
        'link_ics_zrodlowy': (event.get('link_ics_zrodlowy')[:255] if isinstance(event.get('link_ics_zrodlowy'), str) else event.get('link_ics_zrodlowy')),
        'podgrupa': (event.get('podgrupa')[:20] if isinstance(event.get('podgrupa'), str) else event.get('podgrupa')),
        'source_type': event.get('source_type'),
        'nauczyciel_nazwa': (event.get('nauczyciel_nazwa')[:255] if isinstance(event.get('nauczyciel_nazwa'), str) else event.get('nauczyciel_nazwa')),
        'kod_grupy': (event.get('kod_grupy')[:50] if isinstance(event.get('kod_grupy'), str) else event.get('kod_grupy')),
        'kierunek_nazwa': (event.get('kierunek_nazwa')[:255] if isinstance(event.get('kierunek_nazwa'), str) else event.get('kierunek_nazwa')),
        'grupa_id': event.get('grupa_id'),
        'nauczyciel_id': event.get('nauczyciel_id')
    }

def zajecie_key(event: dict) -> Tuple:
    uid = event.get('uid')
    if uid:
        return ('UID', uid)
    return (
        'HEUR',
        event.get('od'),
        event.get('do_'),
        event.get('miejsce'),
        event.get('kod_grupy'),
        event.get('przedmiot')
    )

def deduplicate_events(events: List[dict]) -> List[dict]:
    seen: Set[Tuple] = set()
    deduped = []
    for event in events:
        key = zajecie_key(event)
        if key not in seen:
            seen.add(key)
            deduped.append(event)
    return deduped

def save_zajecia(events, grupa_uuid_map, nauczyciel_uuid_map, batch_size=1000):
    if not events:
        return 0
    events = deduplicate_events(events)
    total = 0
    for batch_i, batch in enumerate(chunks(events, batch_size), 1):
        batch_data = []
        for event in batch:
            if is_dataclass(event):
                event = asdict(event)
            grupa_uuid = grupa_uuid_map.get(str(event.get('grupa_id'))) or grupa_uuid_map.get(str(event.get('kod_grupy')))
            nauczyciel_id = event.get('nauczyciel_id')  # KLUCZOWA ZMIANA: po nauczyciel_id!
            nauczyciel_uuid = nauczyciel_uuid_map.get(nauczyciel_id) if nauczyciel_id else None
            event['grupa_id'] = grupa_uuid
            event['nauczyciel_id'] = nauczyciel_uuid
            batch_data.append(truncate_fields(event))
        try:
            supabase.table('zajecia').upsert(batch_data, on_conflict='uid').execute()
            total += len(batch_data)
            print(f"✅ Upsertowano batch {batch_i}: {len(batch_data)} zajęć (razem: {total})")
        except Exception as e:
            print(f"❌ Błąd podczas upsertowania batcha zajęć: {e}")

    # Po upsercie zajęć pobierz mapę UID -> ID (UUID)
    result = supabase.table('zajecia').select('uid, id').execute()
    uid_to_id_map = {row['uid']: row['id'] for row in result.data}

    relacje_grupy = []
    relacje_nauczyciele = []
    for event in events:
        uuid_id = uid_to_id_map.get(event.get('uid'))
        if not uuid_id:
            continue
        grupa_uuid = grupa_uuid_map.get(str(event.get('grupa_id'))) or grupa_uuid_map.get(str(event.get('kod_grupy')))
        nauczyciel_id = event.get('nauczyciel_id')
        nauczyciel_uuid = nauczyciel_uuid_map.get(nauczyciel_id) if nauczyciel_id else None
        if grupa_uuid:
            relacje_grupy.append({'zajecia_id': uuid_id, 'grupa_id': grupa_uuid})
        if nauczyciel_uuid:
            relacje_nauczyciele.append({'zajecia_id': uuid_id, 'nauczyciel_id': nauczyciel_uuid})

    if relacje_grupy:
        try:
            supabase.table('zajecia_grupy').upsert(relacje_grupy, on_conflict='zajecia_id,grupa_id').execute()
        except Exception as e:
            print(f"❌ Błąd podczas upsertowania relacji zajecia_grupy: {e}")
    if relacje_nauczyciele:
        try:
            supabase.table('zajecia_nauczyciele').upsert(relacje_nauczyciele, on_conflict='zajecia_id,nauczyciel_id').execute()
        except Exception as e:
            print(f"❌ Błąd podczas upsertowania relacji zajecia_nauczyciele: {e}")

    return total
