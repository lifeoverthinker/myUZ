import logging
from typing import Dict, List, Any
from supabase import create_client, Client
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SupabaseClient:
    def __init__(self, url: str, key: str):
        """Inicjalizacja klienta Supabase"""
        self.client: Client = create_client(url, key)
        logger.info("Zainicjalizowano klienta Supabase")

        # Słowniki do przechowywania mapowań ID
        self._kierunki_map = {}  # link_grupy -> UUID
        self._grupy_map = {}     # link_planu -> UUID
        self._nauczyciele_map = {}  # imie_nazwisko -> UUID

        # Inicjalnie pobierz istniejące rekordy do cache
        self._load_existing_records()

        # Sprawdź czy wymagane kolumny istnieją
        self._check_and_update_schema()

    def _load_existing_records(self):
        """Ładuje istniejące rekordy do pamięci podręcznej, aby uniknąć duplikatów"""
        try:
            # Pobierz mapowania kierunków
            logger.info("Ładowanie istniejących kierunków do cache...")
            kierunki_result = self.client.table('kierunki').select('id, link_grupy').execute()
            for k in kierunki_result.data:
                if 'link_grupy' in k and k['link_grupy']:
                    self._kierunki_map[k['link_grupy']] = k['id']

            # Pobierz mapowania grup
            logger.info("Ładowanie istniejących grup do cache...")
            grupy_result = self.client.table('grupy').select('id, link_planu').execute()
            for g in grupy_result.data:
                if 'link_planu' in g and g['link_planu']:
                    self._grupy_map[g['link_planu']] = g['id']

            # Pobierz mapowania nauczycieli
            logger.info("Ładowanie istniejących nauczycieli do cache...")
            nauczyciele_result = self.client.table('nauczyciele').select('id, imie_nazwisko').execute()
            for n in nauczyciele_result.data:
                if 'imie_nazwisko' in n and n['imie_nazwisko']:
                    self._nauczyciele_map[n['imie_nazwisko']] = n['id']

            logger.info(f"Załadowano do cache: {len(self._kierunki_map)} kierunków, {len(self._grupy_map)} grup, {len(self._nauczyciele_map)} nauczycieli")
        except Exception as e:
            logger.error(f"Błąd podczas ładowania istniejących rekordów: {str(e)}")

    def _check_and_update_schema(self):
        """Sprawdza czy wymagane kolumny istnieją i dodaje brakujące"""
        try:
            # Sprawdź plany_grup
            plany_grup_columns = self._get_table_columns('plany_grup')

            if 'podgrupa' not in plany_grup_columns:
                logger.info("Dodawanie kolumny 'podgrupa' do tabeli plany_grup")
                self._execute_sql("ALTER TABLE plany_grup ADD COLUMN podgrupa VARCHAR(50);")

            if 'rodzaj_zajec' not in plany_grup_columns:
                logger.info("Dodawanie kolumny 'rodzaj_zajec' do tabeli plany_grup")
                self._execute_sql("ALTER TABLE plany_grup ADD COLUMN rodzaj_zajec VARCHAR(500);")

            # Sprawdź plany_nauczycieli
            plany_naucz_columns = self._get_table_columns('plany_nauczycieli')

            if 'podgrupa' not in plany_naucz_columns:
                logger.info("Dodawanie kolumny 'podgrupa' do tabeli plany_nauczycieli")
                self._execute_sql("ALTER TABLE plany_nauczycieli ADD COLUMN podgrupa VARCHAR(50);")

            if 'rodzaj_zajec' not in plany_naucz_columns:
                logger.info("Dodawanie kolumny 'rodzaj_zajec' do tabeli plany_nauczycieli")
                self._execute_sql("ALTER TABLE plany_nauczycieli ADD COLUMN rodzaj_zajec VARCHAR(500);")

            logger.info("Sprawdzanie schematu bazy danych zakończone")
        except Exception as e:
            logger.error(f"Błąd podczas sprawdzania/aktualizacji schematu: {str(e)}")

    def _get_table_columns(self, table_name: str) -> List[str]:
        """Pobiera listę nazw kolumn dla danej tabeli"""
        try:
            result = self._execute_sql(f"""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = '{table_name}' AND table_schema = 'public'
            """)
            return [row['column_name'] for row in result['data']]
        except Exception as e:
            logger.error(f"Błąd podczas pobierania kolumn tabeli {table_name}: {str(e)}")
            return []

    def _execute_sql(self, sql: str) -> Dict[str, Any]:
        """Wykonuje zapytanie SQL"""
        return self.client.rpc('exec_sql', {'sql': sql}).execute()

    def _truncate_value(self, value: str, max_length: int = 255) -> str:
        """Przycina wartość do określonej maksymalnej długości"""
        if not value or not isinstance(value, str):
            return value
        if len(value) > max_length:
            logger.warning(f"Przycinanie zbyt długiej wartości: '{value[:20]}...' ({len(value)} znaków)")
            return value[:max_length]
        return value

    def nauczyciel_exists(self, nazwa: str) -> bool:
        """Sprawdza czy nauczyciel już istnieje w bazie danych"""
        # Najpierw sprawdź cache
        if nazwa in self._nauczyciele_map:
            return True

        # Jeśli nie ma w cache, sprawdź bazę
        result = self.client.table('nauczyciele').select('id').eq('imie_nazwisko', nazwa).execute()
        exists = len(result.data) > 0

        # Jeśli znaleziono, dodaj do cache
        if exists and result.data[0]['id']:
            self._nauczyciele_map[nazwa] = result.data[0]['id']

        return exists

    def upsert_kierunki(self, kierunki: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Wstawia lub aktualizuje kierunki w bazie danych"""
        start_time = time.time()
        logger.info(f"Wstawianie/aktualizacja {len(kierunki)} kierunków")

        # Liczniki statystyk
        count_inserts = 0
        count_updates = 0

        # Przygotuj dane do wstawienia (tylko kolumny istniejące w tabeli)
        prepared_data = []
        for kierunek in kierunki:
            # Sprawdź czy kierunek już istnieje na podstawie link_grupy
            link_grupy = kierunek['link_grupy']

            # Przygotuj dane do wstawienia (tylko kolumny istniejące w tabeli)
            kierunek_data = {
                'nazwa_kierunku': self._truncate_value(kierunek['nazwa_kierunku']),
                'wydzial': self._truncate_value(kierunek['wydzial']),
                'link_grupy': self._truncate_value(link_grupy)
            }

            # Jeśli kierunek już istnieje w cache, użyj jego id
            if link_grupy in self._kierunki_map:
                kierunek_data['id'] = self._kierunki_map[link_grupy]
                count_updates += 1
            else:
                # Dodatkowe sprawdzenie w bazie
                existing = self.client.table('kierunki').select('id').eq('link_grupy', link_grupy).execute()
                if existing.data and len(existing.data) > 0:
                    kierunek_data['id'] = existing.data[0]['id']
                    self._kierunki_map[link_grupy] = existing.data[0]['id']  # Dodaj do cache
                    count_updates += 1
                else:
                    count_inserts += 1

            prepared_data.append(kierunek_data)

        if not prepared_data:
            logger.info("Brak kierunków do zaktualizowania")
            return []

        # Wstaw lub zaktualizuj dane
        result = self.client.table('kierunki').upsert(prepared_data).execute()

        # Zaktualizuj cache z nowymi UUID dla nowo wstawionych rekordów
        for item in result.data:
            self._kierunki_map[item['link_grupy']] = item['id']

        elapsed_time = time.time() - start_time
        logger.info(f"Operacja zakończona w {elapsed_time:.2f}s. Wstawiono: {count_inserts}, Zaktualizowano: {count_updates} kierunków")
        return result.data

    def upsert_grupy(self, grupy: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Wstawia lub aktualizuje grupy w bazie danych"""
        start_time = time.time()
        logger.info(f"Wstawianie/aktualizacja {len(grupy)} grup")

        # Liczniki statystyk
        count_inserts = 0
        count_updates = 0

        # Przygotuj dane do wstawienia
        prepared_data = []
        for grupa in grupy:
            # Sprawdź czy grupa już istnieje na podstawie link_planu
            link_planu = grupa['link_planu']

            # Znajdź UUID kierunku na podstawie original_kierunek_id
            kierunek_id = None
            if 'original_kierunek_id' in grupa:
                # Najpierw sprawdź w cache
                for cache_link, cache_id in self._kierunki_map.items():
                    if f"ID={grupa['original_kierunek_id']}" in cache_link:
                        kierunek_id = cache_id
                        break

                # Jeśli nie znaleziono w cache, sprawdź w bazie
                if not kierunek_id:
                    kierunki_result = self.client.table('kierunki').select('id, link_grupy').execute()
                    for k in kierunki_result.data:
                        if f"ID={grupa['original_kierunek_id']}" in k['link_grupy']:
                            kierunek_id = k['id']
                            break

            # Przygotuj dane do wstawienia (tylko kolumny istniejące w tabeli)
            grupa_data = {
                'nazwa_grupy': self._truncate_value(grupa['nazwa_grupy']),
                'kod_grupy': self._truncate_value(grupa.get('kod_grupy', '')),
                'semestr': self._truncate_value(grupa['semestr']),
                'tryb_studiow': self._truncate_value(grupa['tryb_studiow']),
                'link_planu': self._truncate_value(link_planu)
            }

            # Dodaj referencję do kierunku jeśli znaleziono
            if kierunek_id:
                grupa_data['kierunek_id'] = kierunek_id

            # Jeśli grupa już istnieje w cache, użyj jej id
            if link_planu in self._grupy_map:
                grupa_data['id'] = self._grupy_map[link_planu]
                count_updates += 1
            else:
                # Dodatkowe sprawdzenie w bazie
                existing = self.client.table('grupy').select('id').eq('link_planu', link_planu).execute()
                if existing.data and len(existing.data) > 0:
                    grupa_data['id'] = existing.data[0]['id']
                    self._grupy_map[link_planu] = existing.data[0]['id']  # Dodaj do cache
                    count_updates += 1
                else:
                    count_inserts += 1

            prepared_data.append(grupa_data)

        if not prepared_data:
            logger.info("Brak grup do zaktualizowania")
            return []

        # Wstaw lub zaktualizuj dane
        result = self.client.table('grupy').upsert(prepared_data).execute()

        # Zaktualizuj cache z nowymi UUID dla nowo wstawionych rekordów
        for item in result.data:
            self._grupy_map[item['link_planu']] = item['id']

        elapsed_time = time.time() - start_time
        logger.info(f"Operacja zakończona w {elapsed_time:.2f}s. Wstawiono: {count_inserts}, Zaktualizowano: {count_updates} grup")
        return result.data

    def upsert_nauczyciele(self, nauczyciele: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Wstawia lub aktualizuje nauczycieli w bazie danych"""
        start_time = time.time()
        logger.info(f"Wstawianie/aktualizacja {len(nauczyciele)} nauczycieli")

        # Liczniki statystyk
        count_inserts = 0
        count_updates = 0

        prepared_data = []
        for nauczyciel in nauczyciele:
            # Sprawdź czy nauczyciel już istnieje po imieniu i nazwisku
            imie_nazwisko = nauczyciel['imie_nazwisko']

            # Przygotuj dane do wstawienia (tylko kolumny istniejące w tabeli)
            nauczyciel_data = {
                'imie_nazwisko': self._truncate_value(imie_nazwisko),
                'instytut': self._truncate_value(nauczyciel['instytut']),
                'email': self._truncate_value(nauczyciel['email']),
                'link_planu': self._truncate_value(nauczyciel.get('link_ics', ''))
            }

            # Jeśli nauczyciel już istnieje w cache, użyj jego id
            if imie_nazwisko in self._nauczyciele_map:
                nauczyciel_data['id'] = self._nauczyciele_map[imie_nazwisko]
                count_updates += 1
            else:
                # Dodatkowe sprawdzenie w bazie
                existing = self.client.table('nauczyciele').select('id').eq('imie_nazwisko', imie_nazwisko).execute()
                if existing.data and len(existing.data) > 0:
                    nauczyciel_data['id'] = existing.data[0]['id']
                    self._nauczyciele_map[imie_nazwisko] = existing.data[0]['id']  # Dodaj do cache
                    count_updates += 1
                else:
                    count_inserts += 1

            prepared_data.append(nauczyciel_data)

        if not prepared_data:
            logger.info("Brak nauczycieli do zaktualizowania")
            return []

        # Wstaw lub zaktualizuj dane
        result = self.client.table('nauczyciele').upsert(prepared_data).execute()

        # Zaktualizuj cache z nowymi UUID dla nowo wstawionych rekordów
        for item in result.data:
            self._nauczyciele_map[item['imie_nazwisko']] = item['id']

        elapsed_time = time.time() - start_time
        logger.info(f"Operacja zakończona w {elapsed_time:.2f}s. Wstawiono: {count_inserts}, Zaktualizowano: {count_updates} nauczycieli")
        return result.data

    def upsert_plany_grup(self, grupa_link: str, wydarzenia: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Wstawia lub aktualizuje plan zajęć grupy"""
        start_time = time.time()
        logger.info(f"Wstawianie/aktualizacja planu zajęć dla grupy {grupa_link}")

        # Liczniki statystyk
        count_inserts = 0
        count_updates = 0

        # Znajdź UUID grupy na podstawie link_planu
        grupa_uuid = None

        # Najpierw sprawdź w cache
        if grupa_link in self._grupy_map:
            grupa_uuid = self._grupy_map[grupa_link]
        else:
            # Jeśli nie ma w cache, sprawdź w bazie
            grupa_result = self.client.table('grupy').select('id').eq('link_planu', grupa_link).execute()
            if grupa_result.data and len(grupa_result.data) > 0:
                grupa_uuid = grupa_result.data[0]['id']
                # Dodaj do cache
                self._grupy_map[grupa_link] = grupa_uuid

        if not grupa_uuid:
            logger.warning(f"Nie znaleziono grupy o linku {grupa_link}")
            return []

        # Pobierz istniejące wydarzenia dla grupy
        existing_events = {}
        try:
            result = self.client.table('plany_grup').select('id, od, przedmiot, podgrupa').eq('grupa_id', grupa_uuid).execute()
            for event in result.data:
                # Utwórz klucz składający się z godziny, przedmiotu i podgrupy (jeśli jest)
                key = f"{event.get('od', '')}__{event.get('przedmiot', '')}__{event.get('podgrupa', '')}"
                existing_events[key] = event['id']
        except Exception as e:
            logger.error(f"Błąd podczas pobierania istniejących wydarzeń: {str(e)}")

        # Przygotuj dane do wstawienia
        prepared_data = []
        for wydarzenie in wydarzenia:
            # Stwórz nowy obiekt z wszystkimi wymaganymi polami
            wydarzenie_copy = {
                'grupa_id': grupa_uuid,
                'link_ics': self._truncate_value(wydarzenie.get('link_ics', '')),
                'od': wydarzenie.get('od', None),
                'do_': wydarzenie.get('do', None),
                'przedmiot': self._truncate_value(wydarzenie.get('przedmiot', '')),
                'rz': self._truncate_value(wydarzenie.get('typ_zajec', '')),
                'miejsce': self._truncate_value(wydarzenie.get('miejsce', '')),
                'terminy': self._truncate_value(wydarzenie.get('terminy', ''), 1000),
                'nauczyciel_id': None
            }

            # Sprawdź czy mamy dodatkowe pola
            if 'rodzaj_zajec' in wydarzenie or 'typ_zajec_pelny' in wydarzenie:
                wydarzenie_copy['rodzaj_zajec'] = self._truncate_value(
                    wydarzenie.get('rodzaj_zajec', wydarzenie.get('typ_zajec_pelny', '')), 500
                )

            if 'podgrupa' in wydarzenie:
                wydarzenie_copy['podgrupa'] = self._truncate_value(wydarzenie.get('podgrupa', ''), 50)

            # Znajdź nauczyciela po imieniu i nazwisku
            if 'prowadzacy' in wydarzenie and wydarzenie['prowadzacy']:
                prowadzacy = wydarzenie['prowadzacy']

                # Sprawdź w cache
                if prowadzacy in self._nauczyciele_map:
                    wydarzenie_copy['nauczyciel_id'] = self._nauczyciele_map[prowadzacy]
                else:
                    # Jeśli nie ma w cache, sprawdź w bazie
                    nauczyciel_result = self.client.table('nauczyciele').select('id').ilike('imie_nazwisko', f"%{prowadzacy}%").execute()
                    if nauczyciel_result.data and len(nauczyciel_result.data) > 0:
                        wydarzenie_copy['nauczyciel_id'] = nauczyciel_result.data[0]['id']
                        # Dodaj do cache
                        self._nauczyciele_map[prowadzacy] = nauczyciel_result.data[0]['id']

            # Sprawdź czy wydarzenie już istnieje
            if wydarzenie_copy['od'] and wydarzenie_copy['przedmiot']:
                # Utwórz klucz do sprawdzenia w istniejących wydarzeniach
                event_key = f"{wydarzenie_copy['od']}__{wydarzenie_copy['przedmiot']}__{wydarzenie_copy.get('podgrupa', '')}"

                if event_key in existing_events:
                    wydarzenie_copy['id'] = existing_events[event_key]
                    count_updates += 1
                else:
                    count_inserts += 1

            prepared_data.append(wydarzenie_copy)

        if not prepared_data:
            logger.info(f"Brak wydarzeń do zaktualizowania dla grupy {grupa_link}")
            return []

        # Wstaw lub zaktualizuj dane
        result = self.client.table('plany_grup').upsert(prepared_data).execute()

        elapsed_time = time.time() - start_time
        logger.info(f"Operacja zakończona w {elapsed_time:.2f}s. Wstawiono: {count_inserts}, Zaktualizowano: {count_updates} wydarzeń")
        return result.data