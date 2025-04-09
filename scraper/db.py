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
        self.supabase = create_client(self.supabase_url, self.supabase_key)

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
                logger.debug("Utworzono nowe połączenie dla wątku {}".format(thread_id))
            return self.thread_connections[thread_id]

    def close(self):
        """Zamyka wszystkie połączenia z bazą danych."""
        self.thread_connections.clear()
        logger.info("Zamknięto wszystkie połączenia z bazą danych")

    # ======= METODY DLA ZAJĘĆ (ZUNIFIKOWANY MODEL) =======

    def get_zajecia_by_grupa(self, grupa_id):
        """Pobiera zajęcia dla konkretnej grupy."""
        response = self.supabase.rpc(
            'get_zajecia_by_grupa',
            params={'p_grupa_id': grupa_id}  # Dodano parametr 'params'
        ).execute()
        return response.data

    def get_zajecia_by_nauczyciel(self, nauczyciel_id):
        """Pobiera zajęcia dla konkretnego nauczyciela."""
        response = self.supabase.rpc(
            'get_zajecia_by_nauczyciel',
            params={'p_nauczyciel_id': nauczyciel_id}  # Dodano parametr 'params'
        ).execute()
        return response.data

    def process_plany_to_zajecia(self):
        """Przetwarza dane z plany_grup i plany_nauczycieli do zunifikowanego modelu zajecia."""
        try:
            # Przykładowy kod wywołania:
            response = self.supabase.rpc('process_plany_to_zajecia',
                                         params={}).execute()  # Dodano pusty słownik params

            if hasattr(response, 'data') and response.data is not None:
                return response.data

            # Jeśli funkcja RPC nie jest dostępna, możemy zwrócić komunikat
            logger.warning(
                "Funkcja process_plany_to_zajecia wymaga implementacji procedury po stronie bazy danych.")
            return 0
        except Exception as e:
            logger.error(
                "Błąd podczas przetwarzania planów do zunifikowanego modelu: {}".format(str(e)))
            return 0
