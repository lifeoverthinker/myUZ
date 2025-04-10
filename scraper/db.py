# Moduł do obsługi bazy danych Supabase
import os
import time
from supabase import create_client, Client

class Database:
    """Klasa do komunikacji z bazą danych Supabase"""
    _client = None
    _max_retries = 3

    @classmethod
    def initialize(cls):
        """Inicjalizacja klienta Supabase"""
        if cls._client is None:
            try:
                # Pobierz URL i klucz Supabase z zmiennych środowiskowych
                supabase_url = os.getenv("SUPABASE_URL")
                supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

                if not supabase_url or not supabase_key:
                    raise ValueError("Brak wymaganych zmiennych środowiskowych: SUPABASE_URL i SUPABASE_SERVICE_ROLE_KEY")

                cls._client = create_client(supabase_url, supabase_key)
                print("Utworzono połączenie z bazą danych Supabase")
            except Exception as e:
                print("Błąd podczas inicjalizacji połączenia z bazą danych: {}".format(e))
                raise

    @classmethod
    def close_all(cls):
        """Zamknij połączenie"""
        if cls._client:
            cls._client = None
            print("Zamknięto połączenie z bazą danych Supabase")

def insert_kierunek(nazwa, wydzial, link_grupy):
    """Dodaje kierunek do bazy danych"""
    # Implementacja dodawania kierunku
    # (w rzeczywistym kodzie byłoby tu dodawanie do Supabase)
    print(f"Dodano kierunek: {nazwa} ({wydzial})")
    return 1  # Symulacja zwracania ID

def get_all_kierunki():
    """Pobiera wszystkie kierunki z bazy danych"""
    # Symulacja pobierania kierunków
    return [
        {"id": 1, "nazwa": "Informatyka", "wydzial": "Wydział Informatyki", "link_grupy": "https://example.com"}
    ]

def insert_grupa(kod_grupy, tryb_studiow, semestr, kierunek_id, link_planu):
    """Dodaje grupę do bazy danych"""
    # Implementacja dodawania grupy
    print(f"Dodano grupę: {kod_grupy}")
    return 2  # Symulacja zwracania ID

def get_all_grupy():
    """Pobiera wszystkie grupy z bazy danych"""
    # Symulacja pobierania grup
    return [
        {"id": 2, "kod_grupy": "23INF", "tryb_studiow": "stacjonarne", "semestr": "letni", "kierunek_id": 1, "link_planu": "https://example.com"}
    ]

def insert_nauczyciel(imie_nazwisko, instytut, email, link_planu):
    """Dodaje nauczyciela do bazy danych"""
    # Implementacja dodawania nauczyciela
    print(f"Dodano nauczyciela: {imie_nazwisko}")
    return 3  # Symulacja zwracania ID

def get_all_nauczyciele():
    """Pobiera wszystkich nauczycieli z bazy danych"""
    # Symulacja pobierania nauczycieli
    return [
        {"id": 3, "imie_nazwisko": "dr Jan Kowalski", "instytut": "Instytut Informatyki", "email": "j.kowalski@uz.zgora.pl", "link_planu": "https://example.com"}
    ]

def insert_zajecia(przedmiot, od, do, lokalizacja, rz, ics_link):
    """Dodaje zajęcia do bazy danych"""
    # Implementacja dodawania zajęć
    print(f"Dodano zajęcia: {przedmiot}, RZ: {rz}")
    return 4  # Symulacja zwracania ID

def link_zajecia_grupa(zajecia_id, grupa_id):
    """Łączy zajęcia z grupą"""
    # Implementacja łączenia zajęć z grupą
    print(f"Połączono zajęcia {zajecia_id} z grupą {grupa_id}")
    return True

def link_zajecia_nauczyciel(zajecia_id, nauczyciel_id):
    """Łączy zajęcia z nauczycielem"""
    # Implementacja łączenia zajęć z nauczycielem
    print(f"Połączono zajęcia {zajecia_id} z nauczycielem {nauczyciel_id}")
    return True

def insert_grupa_zajecia(grupa_id, zajecia_id):
    """Łączy grupę z zajęciami (alias dla link_zajecia_grupa)"""
    return link_zajecia_grupa(zajecia_id, grupa_id)

def insert_nauczyciel_zajecia(nauczyciel_id, zajecia_id):
    """Łączy nauczyciela z zajęciami (alias dla link_zajecia_nauczyciel)"""
    return link_zajecia_nauczyciel(zajecia_id, nauczyciel_id)