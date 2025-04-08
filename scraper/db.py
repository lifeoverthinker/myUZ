"""
Moduł do komunikacji z bazą danych PostgreSQL
Autor: lifeoverthinker
Data: 2025-04-08
"""

import logging
import uuid
import datetime
from typing import Dict, List, Optional, Any, Tuple

import psycopg2
from psycopg2.extras import DictCursor, RealDictCursor
import os
from dotenv import load_dotenv

# Załaduj zmienne środowiskowe z pliku .env
load_dotenv()

# Konfiguracja loggera
logger = logging.getLogger(__name__)

class Database:
    def __init__(self, database_url: str = None):
        """
        Inicjalizuje połączenie z bazą danych

        Args:
            database_url: URL połączenia do bazy danych (opcjonalny, domyślnie z env)
        """
        # Jeśli URL nie podany, spróbuj z env
        if not database_url:
            database_url = os.getenv("DATABASE_URL")

        if not database_url:
            raise ValueError("Brak URL do bazy danych. Ustaw DATABASE_URL w zmiennych środowiskowych lub podaj w konstruktorze.")

        self.database_url = database_url
        self.conn = None
        self.cursor = None

    def connect(self) -> bool:
        """
        Nawiązuje połączenie z bazą danych

        Returns:
            True jeśli udało się połączyć, False w przeciwnym razie
        """
        try:
            self.conn = psycopg2.connect(self.database_url)
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            return True
        except Exception as e:
            logger.error(f"Błąd podczas łączenia z bazą danych: {str(e)}")
            return False

    def disconnect(self) -> None:
        """Zamyka połączenie z bazą danych"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()

    def execute_query(self, query: str, params: tuple = None, commit: bool = False) -> Optional[List[Dict]]:
        """
        Wykonuje zapytanie SQL

        Args:
            query: Zapytanie SQL
            params: Parametry zapytania
            commit: Czy wykonać commit po zapytaniu

        Returns:
            Lista wyników lub None w przypadku błędu/braku wyników
        """
        try:
            if not self.conn or self.conn.closed:
                self.connect()

            self.cursor.execute(query, params)

            if commit:
                self.conn.commit()
                return None

            try:
                results = self.cursor.fetchall()
                return [dict(row) for row in results]
            except psycopg2.ProgrammingError:
                # No results to fetch
                return []

        except Exception as e:
            logger.error(f"Błąd podczas wykonywania zapytania: {str(e)}")
            if commit:
                self.conn.rollback()
            return None

    def get_kierunki(self) -> List[Dict]:
        """
        Pobiera wszystkie kierunki z bazy danych

        Returns:
            Lista kierunków
        """
        query = "SELECT * FROM kierunki"
        return self.execute_query(query) or []

    def get_kierunek_by_id(self, kierunek_id: str) -> Optional[Dict]:
        """
        Pobiera kierunek o podanym ID

        Args:
            kierunek_id: ID kierunku

        Returns:
            Dane kierunku lub None jeśli nie znaleziono
        """
        query = "SELECT * FROM kierunki WHERE id = %s"
        results = self.execute_query(query, (kierunek_id,))
        return results[0] if results else None

    def get_grupy_by_kierunek(self, kierunek_id: str) -> List[Dict]:
        """
        Pobiera grupy dla danego kierunku

        Args:
            kierunek_id: ID kierunku

        Returns:
            Lista grup
        """
        query = "SELECT * FROM grupy WHERE kierunek_id = %s"
        return self.execute_query(query, (kierunek_id,)) or []

    def get_nauczyciele(self) -> List[Dict]:
        """
        Pobiera wszystkich nauczycieli

        Returns:
            Lista nauczycieli
        """
        query = "SELECT * FROM nauczyciele"
        return self.execute_query(query) or []

    def get_events_for_group(self, grupa_id: str) -> List[Dict]:
        """
        Pobiera wydarzenia dla danej grupy

        Args:
            grupa_id: ID grupy

        Returns:
            Lista wydarzeń
        """
        try:
            # Zapytanie uwzględniające strukturę bazy danych
            query = """
            SELECT pg.id, pg.od, pg.do_, pg.przedmiot, pg.rz, pg.miejsce, pg.terminy, 
                   n.imie_nazwisko, n.instytut, n.email, n.link_planu
            FROM plany_grup pg
            LEFT JOIN nauczyciele n ON pg.nauczyciel_id = n.id
            WHERE pg.grupa_id = %s
            """
            events = self.execute_query(query, (grupa_id,))
            return events or []
        except Exception as e:
            logger.error(f"Błąd podczas pobierania wydarzeń dla grupy: {e}")
            return []

    def get_existing_events(self, grupa_id: str = None, nauczyciel_id: str = None) -> List[Dict]:
        """
        Pobiera istniejące wydarzenia dla grupy lub nauczyciela

        Args:
            grupa_id: ID grupy (opcjonalne)
            nauczyciel_id: ID nauczyciela (opcjonalne)

        Returns:
            Lista wydarzeń
        """
        try:
            if grupa_id:
                query = "SELECT * FROM plany_grup WHERE grupa_id = %s"
                params = (grupa_id,)
            elif nauczyciel_id:
                query = "SELECT * FROM plany_nauczycieli WHERE nauczyciel_id = %s"
                params = (nauczyciel_id,)
            else:
                return []

            events = self.execute_query(query, params)
            return events or []
        except Exception as e:
            logger.error(f"Błąd podczas pobierania istniejących wydarzeń: {e}")
            return []

    def save_events_for_group(self, grupa_id: str, events: List[Dict]) -> bool:
        """
        Zapisuje wydarzenia dla grupy

        Args:
            grupa_id: ID grupy
            events: Lista wydarzeń do zapisania

        Returns:
            True jeśli zapisano pomyślnie, False w przeciwnym razie
        """
        if not events:
            return True

        try:
            existing_events = self.get_existing_events(grupa_id=grupa_id)
            if existing_events:
                # Usunięcie istniejących wydarzeń
                self.execute_query("DELETE FROM plany_grup WHERE grupa_id = %s", (grupa_id,), commit=True)

            for event in events:
                nauczyciel_id = self.get_or_create_nauczyciel(event.get('nauczyciel', {}))

                query = """
                INSERT INTO plany_grup (id, grupa_id, link_ics, nauczyciel_id, od, do_, przedmiot, rz, miejsce, terminy)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """
                params = (
                    str(uuid.uuid4()),
                    grupa_id,
                    event.get('link_ics'),
                    nauczyciel_id,
                    event.get('od'),
                    event.get('do'),
                    event.get('przedmiot'),
                    event.get('rz'),
                    event.get('miejsce'),
                    event.get('terminy')
                )
                self.execute_query(query, params, commit=True)

            return True
        except Exception as e:
            logger.error(f"Błąd podczas zapisywania wydarzeń dla grupy: {e}")
            return False

    def save_events_for_nauczyciel(self, nauczyciel_id: str, events: List[Dict]) -> bool:
        """
        Zapisuje wydarzenia dla nauczyciela

        Args:
            nauczyciel_id: ID nauczyciela
            events: Lista wydarzeń do zapisania

        Returns:
            True jeśli zapisano pomyślnie, False w przeciwnym razie
        """
        if not events:
            return True

        try:
            existing_events = self.get_existing_events(nauczyciel_id=nauczyciel_id)
            if existing_events:
                # Usunięcie istniejących wydarzeń
                self.execute_query("DELETE FROM plany_nauczycieli WHERE nauczyciel_id = %s", (nauczyciel_id,), commit=True)

            for event in events:
                query = """
                INSERT INTO plany_nauczycieli (id, nauczyciel_id, link_ics, od, do_, przedmiot, rz, grupy, miejsce, terminy)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """
                params = (
                    str(uuid.uuid4()),
                    nauczyciel_id,
                    event.get('link_ics'),
                    event.get('od'),
                    event.get('do'),
                    event.get('przedmiot'),
                    event.get('rz'),
                    event.get('grupy'),
                    event.get('miejsce'),
                    event.get('terminy')
                )
                self.execute_query(query, params, commit=True)

            return True
        except Exception as e:
            logger.error(f"Błąd podczas zapisywania wydarzeń dla nauczyciela: {e}")
            return False

    def get_or_create_nauczyciel(self, nauczyciel_data: Dict) -> Optional[str]:
        """
        Pobiera lub tworzy nauczyciela

        Args:
            nauczyciel_data: Dane nauczyciela

        Returns:
            ID nauczyciela lub None w przypadku błędu
        """
        if not nauczyciel_data or not nauczyciel_data.get('imie_nazwisko'):
            return None

        try:
            # Sprawdzenie czy nauczyciel już istnieje
            query = "SELECT id FROM nauczyciele WHERE imie_nazwisko = %s"
            results = self.execute_query(query, (nauczyciel_data.get('imie_nazwisko'),))

            if results:
                return results[0]['id']
            else:
                # Stworzenie nowego nauczyciela
                nauczyciel_id = str(uuid.uuid4())
                query = """
                INSERT INTO nauczyciele (id, imie_nazwisko, instytut, email, link_planu)
                VALUES (%s, %s, %s, %s, %s)
                """
                params = (
                    nauczyciel_id,
                    nauczyciel_data.get('imie_nazwisko'),
                    nauczyciel_data.get('instytut'),
                    nauczyciel_data.get('email'),
                    nauczyciel_data.get('link_planu')
                )
                self.execute_query(query, params, commit=True)
                return nauczyciel_id
        except Exception as e:
            logger.error(f"Błąd podczas tworzenia/pobierania nauczyciela: {e}")
            return None

    def save_kierunek(self, nazwa_kierunku: str, wydzial: str, link_grupy: str) -> Optional[str]:
        """
        Zapisuje kierunek do bazy danych

        Args:
            nazwa_kierunku: Nazwa kierunku
            wydzial: Nazwa wydziału
            link_grupy: Link do listy grup

        Returns:
            ID kierunku lub None w przypadku błędu
        """
        try:
            kierunek_id = str(uuid.uuid4())
            query = """
            INSERT INTO kierunki (id, nazwa_kierunku, wydzial, link_grupy)
            VALUES (%s, %s, %s, %s)
            """
            params = (kierunek_id, nazwa_kierunku, wydzial, link_grupy)
            self.execute_query(query, params, commit=True)
            return kierunek_id
        except Exception as e:
            logger.error(f"Błąd podczas zapisywania kierunku: {e}")
            return None

    def save_grupa(self, kod_grupy: str, nazwa_grupy: str, semestr: str, tryb_studiow: str, kierunek_id: str, link_planu: str) -> Optional[str]:
        """
        Zapisuje grupę do bazy danych

        Args:
            kod_grupy: Kod grupy
            nazwa_grupy: Nazwa grupy
            semestr: Semestr
            tryb_studiow: Tryb studiów
            kierunek_id: ID kierunku
            link_planu: Link do planu zajęć

        Returns:
            ID grupy lub None w przypadku błędu
        """
        try:
            grupa_id = str(uuid.uuid4())
            query = """
            INSERT INTO grupy (id, kod_grupy, nazwa_grupy, semestr, tryb_studiow, kierunek_id, link_planu)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            params = (grupa_id, kod_grupy, nazwa_grupy, semestr, tryb_studiow, kierunek_id, link_planu)
            self.execute_query(query, params, commit=True)
            return grupa_id
        except Exception as e:
            logger.error(f"Błąd podczas zapisywania grupy: {e}")
            return None

    def get_grupa_by_id(self, grupa_id: str) -> Optional[Dict]:
        """
        Pobiera grupę o podanym ID

        Args:
            grupa_id: ID grupy

        Returns:
            Dane grupy lub None jeśli nie znaleziono
        """
        query = "SELECT * FROM grupy WHERE id = %s"
        results = self.execute_query(query, (grupa_id,))
        return results[0] if results else None

    def get_nauczyciel_by_id(self, nauczyciel_id: str) -> Optional[Dict]:
        """
        Pobiera nauczyciela o podanym ID

        Args:
            nauczyciel_id: ID nauczyciela

        Returns:
            Dane nauczyciela lub None jeśli nie znaleziono
        """
        query = "SELECT * FROM nauczyciele WHERE id = %s"
        results = self.execute_query(query, (nauczyciel_id,))
        return results[0] if results else None