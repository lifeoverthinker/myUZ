from dotenv import load_dotenv
import os
from supabase import create_client
from dataclasses import asdict, is_dataclass
from typing import Dict, Any, List, Tuple

load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def get_uuid_map(table: str, key_col: str, id_col: str) -> Dict:
    """Pobiera mapowanie kluczy do UUID z bazy."""
    if table == "kierunki":
        result = supabase.table(table).select(f"{key_col}, wydzial, {id_col}").execute()
        return {
            (str(row[key_col]).strip().casefold(), str(row["wydzial"]).strip().casefold()): row[id_col]
            for row in result.data
            if row.get(key_col) and row.get("wydzial")
        }
    else:
        # Dla grup i nauczycieli - bez kolumny wydzial
        result = supabase.table(table).select(f"{key_col}, {id_col}").execute()
        return {
            str(row[key_col]).strip().casefold(): row[id_col]
            for row in result.data
            if row.get(key_col)
        }


def chunks(lst: List[Any], n: int):
    """Dzieli listę na części o rozmiarze n."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]


def save_kierunki(kierunki, batch_size=100):
    """Zapisuje kierunki do bazy z kontrolą duplikatów."""
    if not kierunki:
        return 0

    total = 0
    for batch in chunks(kierunki, batch_size):
        data = []
        for k in batch:
            if is_dataclass(k):
                k = asdict(k)
            if not k.get("nazwa") or not k.get("wydzial"):
                continue
            data.append({
                "nazwa": k["nazwa"],
                "wydzial": k["wydzial"]
            })

        try:
            supabase.table("kierunki").upsert(data, on_conflict="nazwa,wydzial").execute()
            total += len(data)
        except Exception as e:
            print(f"❌ Błąd zapisu kierunków: {e}")

    return total


def save_grupy(grupy, batch_size=500):
    """Zapisuje grupy do bazy z deduplikacją."""
    if not grupy:
        return 0

    seen = set()
    unique_grupy = []
    for g in grupy:
        key = (g.get("kod_grupy"), g.get("kierunek_id"))
        if key not in seen:
            seen.add(key)
            unique_grupy.append(g)

    total = 0
    for batch in chunks(unique_grupy, batch_size):
        data = []
        for g in batch:
            if is_dataclass(g):
                g = asdict(g)
            data.append({
                "kod_grupy": g.get("kod_grupy"),
                "kierunek_id": g.get("kierunek_id"),
                "link_strony_grupy": g.get("link_strony_grupy"),
                "link_ics_grupy": g.get("link_ics_grupy"),
                "tryb_studiow": g.get("tryb_studiow"),
                "grupa_id": g.get("grupa_id")
            })

        try:
            supabase.table("grupy").upsert(data, on_conflict="kod_grupy,kierunek_id").execute()
            total += len(data)
        except Exception as e:
            print(f"❌ Błąd zapisu grup: {e}")

    return total


def save_nauczyciele(nauczyciele, batch_size=500):
    """Zapisuje nauczycieli do bazy z deduplikacją po linku strony."""
    if not nauczyciele:
        return 0

    # Etap 1: Deduplikacja po link_strony_nauczyciela
    nauczyciele_by_link = {}
    for n in nauczyciele:
        if is_dataclass(n):
            n = asdict(n)
        link = n.get('link_strony_nauczyciela')
        if not link:
            continue

        # Aktualizuj tylko brakujące pola w istniejących rekordach
        if link in nauczyciele_by_link:
            existing = nauczyciele_by_link[link]
            for key in ['instytut', 'email', 'link_ics_nauczyciela']:
                if not existing.get(key) and n.get(key):
                    existing[key] = n.get(key)
        else:
            nauczyciele_by_link[link] = {
                'nazwa': n.get('nazwa'),
                'instytut': n.get('instytut'),
                'email': n.get('email'),
                'link_strony_nauczyciela': link,
                'link_ics_nauczyciela': n.get('link_ics_nauczyciela')
            }

    print(f"ℹ️ Znaleziono {len(nauczyciele) - len(nauczyciele_by_link)} duplikatów linków")
    print(f"ℹ️ Po deduplikacji: {len(nauczyciele_by_link)} unikalnych nauczycieli")

    # Etap 2: Konwersja do listy i zapis
    nauczyciele_list = list(nauczyciele_by_link.values())
    total = 0
    for batch in chunks(nauczyciele_list, batch_size):
        try:
            # Upsert z konfliktem na link_strony_nauczyciela
            supabase.table('nauczyciele').upsert(
                batch,
                on_conflict='link_strony_nauczyciela'
            ).execute()
            total += len(batch)
        except Exception as e:
            print(f"❌ Błąd zapisu batcha nauczycieli: {e}")
            if batch:
                print(f"Przykładowy rekord z błędem: {batch[0]}")

    return total


def save_zajecia_grupy(events, grupa_uuid_map, batch_size=500):
    if not events:
        return 0

    # Diagnostyka - sprawdź mapowanie UUID
    if not grupa_uuid_map:
        print("⚠️ UWAGA: grupa_uuid_map jest puste! Najpierw dodaj grupy do bazy.")
        return 0

    print(f"ℹ️ Znaleziono {len(grupa_uuid_map)} grup w mapowaniu UUID")

    total = 0
    pominiete = 0

    # Deduplikacja po (uid, grupa_id)
    seen = set()
    batch_data = []
    for event in events:
        if is_dataclass(event):
            event = asdict(event)
        grupa_id = event.get('grupa_id')
        if not grupa_id:
            pominiete += 1
            continue
        grupa_uuid = grupa_uuid_map.get(str(grupa_id))
        if not grupa_uuid:
            print(f"⚠️ Pomijam zajęcia bez UUID grupy: {grupa_id}")
            pominiete += 1
            continue
        key = (event.get('uid'), grupa_uuid)
        if key in seen:
            continue
        seen.add(key)
        batch_data.append({
            'uid': event.get('uid'),
            'podgrupa': (event.get('podgrupa') or '')[:20],  # Przycinanie do 20 znaków
            'od': event.get('od'),
            'do_': event.get('do_'),
            'przedmiot': event.get('przedmiot'),
            'rz': event.get('rz'),
            'nauczyciel': event.get('nauczyciel_nazwa') or event.get('nauczyciel'),
            'miejsce': event.get('miejsce'),
            'grupa_id': grupa_uuid,
            'link_ics_zrodlowy': event.get('link_ics_zrodlowy')
        })

    print(f"ℹ️ Pominięto {pominiete} zajęć bez UUID grupy")
    print(f"ℹ️ Przygotowano {len(batch_data)} unikalnych zajęć do zapisu")

    # Zapis w batchach
    for batch in chunks(batch_data, batch_size):
        # Deduplikacja w batchu (na wszelki wypadek)
        batch_seen = set()
        dedup_batch = []
        for e in batch:
            key = (e['uid'], e['grupa_id'])
            if key in batch_seen:
                continue
            batch_seen.add(key)
            dedup_batch.append(e)
        if not dedup_batch:
            continue
        try:
            supabase.table('zajecia_grupy').upsert(dedup_batch, on_conflict='uid,grupa_id').execute()
            total += len(dedup_batch)
        except Exception as e:
            print(f"❌ Błąd podczas upsertowania batcha zajęć grup: {e}")
            if dedup_batch:
                print(f"Przykładowy rekord z błędem: {dedup_batch[0]}")
    return total


def save_zajecia_nauczyciela(events, nauczyciel_uuid_map=None, batch_size=1000):
    if not events:
        return 0

    total = 0
    batch_data = []

    for event in events:
        if is_dataclass(event):
            event = asdict(event)

        # nauczyciel_id jest już UUID z bazy!
        uuid = event.get('nauczyciel_id')
        if not uuid:
            continue

        # Sprawdź wymagane pola
        if not (event.get("uid") and event.get("od") and event.get("do_") and event.get("przedmiot")):
            continue

        batch_data.append({
            'uid': event.get('uid'),
            'od': event.get('od'),
            'do_': event.get('do_'),
            'przedmiot': event.get('przedmiot'),
            'rz': event.get('rz'),
            'grupy': event.get('grupy'),
            'miejsce': event.get('miejsce'),
            'nauczyciel_id': uuid,
            'link_ics_zrodlowy': event.get('link_ics_zrodlowy')
        })

    for batch in chunks(batch_data, batch_size):
        if not batch:
            continue
        try:
            supabase.table('zajecia_nauczyciela').upsert(batch, on_conflict='uid,nauczyciel_id').execute()
            total += len(batch)
        except Exception as e:
            print(f"❌ Błąd podczas upsertowania batcha zajęć nauczyciela: {e}")
            if batch:
                print(f"Przykładowy rekord z błędem: {batch[0]}")

    return total
