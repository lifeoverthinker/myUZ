import logging
import threading
from supabase import create_client

logger = logging.getLogger('UZ_Scraper.DB')


class DB:
    def __init__(self, supabase_url=None, supabase_key=None, host=None, password=None):
        """
        Inicjalizuje połączenie z bazą danych Supabase.
        """
        # Priorytetowo używaj parametrów Supabase
        if supabase_url and supabase_key:
            self.supabase_url = supabase_url
            self.supabase_key = supabase_key
        # Jeśli podano stare parametry, potraktuj host jako URL Supabase, a password jako klucz
        elif host and password:
            self.supabase_url = host
            self.supabase_key = password
        else:
            raise ValueError("Nie podano wymaganych parametrów połączenia do Supabase")

        # Inicjalizacja klienta Supabase dla głównego wątku
        self.client = create_client(self.supabase_url, self.supabase_key)

        # Słownik do przechowywania połączeń dla poszczególnych wątków
        self.thread_connections = {}
        self.lock = threading.Lock()
        logger.info("Połączono z bazą danych Supabase")

    def get_connection(self):
        """Zwraca połączenie dla aktualnego wątku lub tworzy nowe."""
        thread_id = threading.get_ident()
        with self.lock:
            if thread_id not in self.thread_connections:
                # Tworzymy nowe połączenie dla wątku
                client = create_client(self.supabase_url, self.supabase_key)
                self.thread_connections[thread_id] = client
                # noinspection PyCompatibility
                logger.debug(f"Utworzono nowe połączenie dla wątku {thread_id}")
            return self.thread_connections[thread_id]

    def close(self):
        """Zamyka wszystkie połączenia z bazą danych."""
        self.thread_connections.clear()
        logger.info("Zamknięto wszystkie połączenia z bazą danych")

    # ======= METODY DLA KIERUNKÓW =======

    def get_all_kierunki(self):
        """Pobiera wszystkie kierunki z bazy danych."""
        try:
            response = self.client.table('kierunki').select('*').execute()
            if hasattr(response, 'data'):
                return response.data
            return []
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas pobierania kierunków: {str(e)}")
            return []

    def upsert_kierunek(self, kierunek):
        """Dodaje lub aktualizuje kierunek w bazie danych."""
        try:
            conn = self.get_connection()
            response = conn.table('kierunki').upsert(
                kierunek,
                on_conflict=['nazwa_kierunku']
            ).execute()
            return response.data
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas dodawania/aktualizacji kierunku: {str(e)}")
            return None

    # ======= METODY DLA GRUP =======

    def get_all_grupy(self):
        """Pobiera wszystkie grupy z bazy danych."""
        try:
            response = self.client.table('grupy').select('*').execute()
            if hasattr(response, 'data'):
                return response.data
            return []
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas pobierania grup: {str(e)}")
            return []

    def upsert_grupa(self, grupa):
        """Dodaje lub aktualizuje grupę w bazie danych."""
        try:
            conn = self.get_connection()
            response = conn.table('grupy').upsert(
                grupa,
                on_conflict=['nazwa_grupy', 'kierunek_id']
            ).execute()
            return response.data
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas dodawania/aktualizacji grupy: {str(e)}")
            return None

    # ======= METODY DLA NAUCZYCIELI =======

    def get_all_nauczyciele(self):
        """Pobiera wszystkich nauczycieli z bazy danych."""
        try:
            response = self.client.table('nauczyciele').select('*').execute()
            if hasattr(response, 'data'):
                return response.data
            return []
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas pobierania nauczycieli: {str(e)}")
            return []

    def upsert_nauczyciel(self, nauczyciel):
        """Dodaje lub aktualizuje nauczyciela w bazie danych."""
        try:
            conn = self.get_connection()
            response = conn.table('nauczyciele').upsert(
                nauczyciel,
                on_conflict=['imie_nazwisko']
            ).execute()
            return response.data
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas dodawania/aktualizacji nauczyciela: {str(e)}")
            return None

    # ======= METODY DLA ZAJĘĆ =======

    def upsert_zajecia(self, zajecia):
        """Dodaje lub aktualizuje zajęcia w bazie danych."""
        try:
            conn = self.get_connection()
            response = conn.table('zajecia').upsert(
                zajecia,
                on_conflict=['grupa_id', 'dzien_tygodnia', 'godzina_start', 'nazwa_zajec']
            ).execute()
            return response.data
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas dodawania/aktualizacji zajęć: {str(e)}")
            return None

    def get_zajecia_by_grupa(self, grupa_id):
        """Pobiera zajęcia dla konkretnej grupy."""
        try:
            response = self.client.rpc(
                'get_zajecia_by_grupa',
                params={'p_grupa_id': grupa_id}
            ).execute()
            return response.data
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas pobierania zajęć dla grupy: {str(e)}")
            return []

    def get_zajecia_by_nauczyciel(self, nauczyciel_id):
        """Pobiera zajęcia dla konkretnego nauczyciela."""
        try:
            response = self.client.rpc(
                'get_zajecia_by_nauczyciel',
                params={'p_nauczyciel_id': nauczyciel_id}
            ).execute()
            return response.data
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(f"Błąd podczas pobierania zajęć dla nauczyciela: {str(e)}")
            return []

    def process_plany_to_zajecia(self):
        """Przetwarza dane z plany_grup i plany_nauczycieli do zunifikowanego modelu zajecia."""
        try:
            response = self.client.rpc('process_plany_to_zajecia', params={}).execute()

            if hasattr(response, 'data') and response.data is not None:
                return response.data

            logger.warning(
                "Funkcja process_plany_to_zajecia wymaga implementacji procedury po stronie bazy danych.")
            return 0
        except Exception as e:
            # noinspection PyCompatibility
            logger.error(
                f"Błąd podczas przetwarzania planów do zunifikowanego modelu: {str(e)}")
            return 0
