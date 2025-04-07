import logging
from typing import Dict, List, Any

from supabase import create_client, Client

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# noinspection PyTypeChecker
class SupabaseClient:
    def __init__(self, url: str, key: str):
        """Inicjalizacja klienta Supabase"""
        self.client: Client = create_client(url, key)
        logger.info("Zainicjalizowano klienta Supabase")
        # Słowniki do przechowywania mapowań ID
        self._kierunki_map = {}  # link_grupy -> UUID
        self._grupy_map = {}     # link_planu -> UUID
        self._nauczyciele_map = {}  # imie_nazwisko -> UUID

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
        result = self.client.table('nauczyciele').select('id').eq('imie_nazwisko', nazwa).execute()
        return len(result.data) > 0

    def upsert_kierunki(self, kierunki: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Wstawia lub aktualizuje kierunki w bazie danych"""
        logger.info(f"Wstawianie/aktualizacja {len(kierunki)} kierunków")

        # Przygotuj dane do wstawienia (tylko kolumny istniejące w tabeli)
        prepared_data = []
        for kierunek in kierunki:
            # Sprawdź czy kierunek już istnieje na podstawie link_grupy
            existing = self.client.table('kierunki').select('id').eq('link_grupy', kierunek['link_grupy']).execute()

            # Przygotuj dane do wstawienia (tylko kolumny istniejące w tabeli)
            kierunek_data = {
                'nazwa_kierunku': self._truncate_value(kierunek['nazwa_kierunku']),
                'wydzial': self._truncate_value(kierunek['wydzial']),
                'link_grupy': self._truncate_value(kierunek['link_grupy'])
            }

            # Jeśli kierunek już istnieje, użyj jego id
            if existing.data and len(existing.data) > 0:
                kierunek_data['id'] = existing.data[0]['id']
                # Zapisz mapowanie link_grupy -> UUID
                self._kierunki_map[kierunek['link_grupy']] = existing.data[0]['id']

            prepared_data.append(kierunek_data)

        # Wstaw lub zaktualizuj dane
        result = self.client.table('kierunki').upsert(prepared_data).execute()

        # Zapisz mapowanie link_grupy -> UUID dla nowo wstawionych rekordów
        for item in result.data:
            self._kierunki_map[item['link_grupy']] = item['id']

        return result.data

    def upsert_grupy(self, grupy: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Wstawia lub aktualizuje grupy w bazie danych"""
        logger.info(f"Wstawianie/aktualizacja {len(grupy)} grup")

        # Przygotuj dane do wstawienia
        prepared_data = []
        for grupa in grupy:
            # Sprawdź czy grupa już istnieje na podstawie link_planu
            existing = self.client.table('grupy').select('id').eq('link_planu', grupa['link_planu']).execute()

            # Znajdź UUID kierunku na podstawie original_kierunek_id
            kierunek_id = None
            if 'original_kierunek_id' in grupa:
                # Pobierz wszystkie kierunki i ich link_grupy
                kierunki_result = self.client.table('kierunki').select('id, link_grupy').execute()

                # Znajdź kierunek z pasującym ID w oryginalnym link_grupy
                for k in kierunki_result.data:
                    if f"ID={grupa['original_kierunek_id']}" in k['link_grupy']:
                        kierunek_id = k['id']
                        break

            # Przygotuj dane do wstawienia (tylko kolumny istniejące w tabeli)
            grupa_data = {
                'nazwa_grupy': self._truncate_value(grupa['nazwa_grupy']),
                'kod_grupy': self._truncate_value(grupa.get('kod_grupy', '')),  # Dodane nowe pole z kodem grupy
                'semestr': self._truncate_value(grupa['semestr']),
                'tryb_studiow': self._truncate_value(grupa['tryb_studiow']),
                'link_planu': self._truncate_value(grupa['link_planu'])
            }

            # Dodaj referencję do kierunku jeśli znaleziono
            if kierunek_id:
                grupa_data['kierunek_id'] = kierunek_id

            # Jeśli grupa już istnieje, użyj jej id
            if existing.data and len(existing.data) > 0:
                grupa_data['id'] = existing.data[0]['id']
                # Zapisz mapowanie link_planu -> UUID
                self._grupy_map[grupa['link_planu']] = existing.data[0]['id']

            prepared_data.append(grupa_data)

        # Wstaw lub zaktualizuj dane
        result = self.client.table('grupy').upsert(prepared_data).execute()

        # Zapisz mapowanie link_planu -> UUID dla nowo wstawionych rekordów
        for item in result.data:
            self._grupy_map[item['link_planu']] = item['id']

        return result.data

    def upsert_nauczyciele(self, nauczyciele: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Wstawia lub aktualizuje nauczycieli w bazie danych"""
        logger.info(f"Wstawianie/aktualizacja {len(nauczyciele)} nauczycieli")

        prepared_data = []
        for nauczyciel in nauczyciele:
            # Sprawdź czy nauczyciel już istnieje po imieniu i nazwisku
            existing = self.client.table('nauczyciele').select('id').eq('imie_nazwisko', nauczyciel['imie_nazwisko']).execute()

            # Przygotuj dane do wstawienia (tylko kolumny istniejące w tabeli)
            nauczyciel_data = {
                'imie_nazwisko': self._truncate_value(nauczyciel['imie_nazwisko']),
                'instytut': self._truncate_value(nauczyciel['instytut']),
                'email': self._truncate_value(nauczyciel['email']),
                'link_planu': self._truncate_value(nauczyciel.get('link_ics', ''))  # Zamieniamy link_ics na link_planu
            }

            # Jeśli nauczyciel już istnieje, użyj jego id
            if existing.data and len(existing.data) > 0:
                nauczyciel_data['id'] = existing.data[0]['id']
                # Zapisz mapowanie imie_nazwisko -> UUID
                self._nauczyciele_map[nauczyciel['imie_nazwisko']] = existing.data[0]['id']

            prepared_data.append(nauczyciel_data)

        # Wstaw lub zaktualizuj dane
        result = self.client.table('nauczyciele').upsert(prepared_data).execute()

        # Zapisz mapowanie imie_nazwisko -> UUID dla nowo wstawionych rekordów
        for item in result.data:
            self._nauczyciele_map[item['imie_nazwisko']] = item['id']

        return result.data

    def upsert_plany_grup(self, grupa_link: str, wydarzenia: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Wstawia lub aktualizuje plan zajęć grupy"""
        logger.info(f"Wstawianie/aktualizacja planu zajęć dla grupy {grupa_link}")

        # Znajdź UUID grupy na podstawie link_planu
        grupa_result = self.client.table('grupy').select('id').eq('link_planu', grupa_link).execute()
        if not grupa_result.data or len(grupa_result.data) == 0:
            logger.warning(f"Nie znaleziono grupy o linku {grupa_link}")
            return []

        grupa_uuid = grupa_result.data[0]['id']

        # Przygotuj dane do wstawienia
        prepared_data = []
        for wydarzenie in wydarzenia:
            # Stwórz nowy obiekt z wszystkimi wymaganymi polami, nawet jeśli niektóre są puste
            wydarzenie_copy = {
                'grupa_id': grupa_uuid,
                'link_ics': self._truncate_value(wydarzenie.get('link_ics', '')),
                'od': wydarzenie.get('od', None),
                'do_': wydarzenie.get('do', None),
                'przedmiot': self._truncate_value(wydarzenie.get('przedmiot', '')),
                'rz': self._truncate_value(wydarzenie.get('typ_zajec', '')),
                'miejsce': self._truncate_value(wydarzenie.get('miejsce', '')),
                'terminy': '',  # Dodajemy puste terminy
                'nauczyciel_id': None  # Domyślnie None, zostanie zaktualizowane poniżej
            }

            # Znajdź nauczyciela po imieniu i nazwisku
            if 'prowadzacy' in wydarzenie and wydarzenie['prowadzacy']:
                nauczyciel_result = self.client.table('nauczyciele').select('id').ilike('imie_nazwisko', f"%{wydarzenie['prowadzacy']}%").execute()
                if nauczyciel_result.data and len(nauczyciel_result.data) > 0:
                    wydarzenie_copy['nauczyciel_id'] = nauczyciel_result.data[0]['id']

            # Sprawdź czy wydarzenie już istnieje
            if wydarzenie_copy['od'] and wydarzenie_copy['przedmiot']:
                query = self.client.table('plany_grup').select('id') \
                    .eq('grupa_id', wydarzenie_copy['grupa_id']) \
                    .eq('od', wydarzenie_copy['od']) \
                    .eq('przedmiot', wydarzenie_copy['przedmiot'])

                existing = query.execute()
                if existing.data and len(existing.data) > 0:
                    wydarzenie_copy['id'] = existing.data[0]['id']

            prepared_data.append(wydarzenie_copy)

        if prepared_data:
            result = self.client.table('plany_grup').upsert(prepared_data).execute()
            return result.data
        return []

    def upsert_plany_nauczycieli(self, nauczyciel_name: str, wydarzenia: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Wstawia lub aktualizuje plan zajęć nauczyciela"""
        logger.info(f"Wstawianie/aktualizacja planu zajęć dla nauczyciela {nauczyciel_name}")

        # Znajdź UUID nauczyciela po imieniu i nazwisku
        nauczyciel_result = self.client.table('nauczyciele').select('id').eq('imie_nazwisko', nauczyciel_name).execute()
        if not nauczyciel_result.data or len(nauczyciel_result.data) == 0:
            logger.warning(f"Nie znaleziono nauczyciela o nazwie {nauczyciel_name}")
            return []

        nauczyciel_uuid = nauczyciel_result.data[0]['id']

        # Przygotuj dane do wstawienia
        prepared_data = []
        for wydarzenie in wydarzenia:
            # Stwórz nowy obiekt z wszystkimi wymaganymi polami, nawet jeśli niektóre są puste
            wydarzenie_copy = {
                'nauczyciel_id': nauczyciel_uuid,
                'link_ics': self._truncate_value(wydarzenie.get('link_ics', '')),
                'od': wydarzenie.get('od', None),
                'do_': wydarzenie.get('do', None),
                'przedmiot': self._truncate_value(wydarzenie.get('przedmiot', '')),
                'rz': self._truncate_value(wydarzenie.get('typ_zajec', '')),
                'miejsce': self._truncate_value(wydarzenie.get('miejsce', '')),
                'grupy': self._truncate_value(wydarzenie.get('grupy', '')),
                'terminy': ''  # Dodajemy puste terminy
            }

            # Sprawdź czy wydarzenie już istnieje
            if wydarzenie_copy['od'] and wydarzenie_copy['przedmiot']:
                query = self.client.table('plany_nauczycieli').select('id') \
                    .eq('nauczyciel_id', wydarzenie_copy['nauczyciel_id']) \
                    .eq('od', wydarzenie_copy['od']) \
                    .eq('przedmiot', wydarzenie_copy['przedmiot'])

                existing = query.execute()
                if existing.data and len(existing.data) > 0:
                    wydarzenie_copy['id'] = existing.data[0]['id']

            prepared_data.append(wydarzenie_copy)

        if prepared_data:
            result = self.client.table('plany_nauczycieli').upsert(prepared_data).execute()
            return result.data
        return []