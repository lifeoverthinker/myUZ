#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import logging
import json
import uuid
import time
from datetime import datetime

logger = logging.getLogger('UZ_Scraper.DB')

class MockSupabase:
    """Klasa symulująca działanie Supabase Client dla trybu testowego."""

    def __init__(self):
        self.data = {
            'kierunki': [],
            'grupy': [],
            'nauczyciele': [],
            'zajecia': [],
            'zajecia_grupy': [],
            'zajecia_nauczyciele': []
        }
        logger.info("Utworzono symulowaną bazę danych Supabase")

    def table(self, table_name):
        """Zwraca symulowany obiekt tabeli."""
        return MockTable(self, table_name)

class MockTable:
    """Klasa symulująca tabelę Supabase."""

    def __init__(self, client, table_name):
        self.client = client
        self.table_name = table_name
        self._filters = []
        self._select_columns = '*'

    def select(self, columns):
        """Symuluje wybór kolumn."""
        self._select_columns = columns
        return self

    def eq(self, column, value):
        """Symuluje filtrowanie po równości."""
        self._filters.append((column, value))
        return self

    def execute(self):
        """Symuluje wykonanie zapytania."""
        result = []

        for item in self.client.data.get(self.table_name, []):
            # Sprawdzanie filtrów
            matches = True
            for column, value in self._filters:
                if item.get(column) != value:
                    matches = False
                    break

            if matches:
                result.append(item)

        return MockResponse(result)

    def insert(self, data):
        """Symuluje wstawianie danych."""
        data_copy = data.copy()

        # Dodaj ID jeśli nie istnieje
        if 'id' not in data_copy:
            data_copy['id'] = str(uuid.uuid4())

        self.client.data.setdefault(self.table_name, []).append(data_copy)
        logger.debug("Symulacja: Dodano rekord do tabeli %s", self.table_name)
        return MockResponse([data_copy])

    def update(self, data):
        """Symuluje aktualizację danych."""
        return self.insert(data)  # W trybie symulacji po prostu dodajemy dane

class MockResponse:
    """Klasa symulująca odpowiedź z Supabase."""

    def __init__(self, data):
        self.data = data

class Database:
    def __init__(self):
        """Inicjalizacja połączenia z bazą Supabase lub tworzenie symulacji."""
        self.url = os.environ.get("SUPABASE_URL")
        self.key = os.environ.get("SUPABASE_KEY")
        self.service_role_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

        # Sprawdzamy, czy działamy w trybie GitHub Actions (zmienne środowiskowe są ustawione)
        if self.url and (self.key or self.service_role_key):
            # Rzeczywiste połączenie z Supabase
            try:
                from supabase import create_client
                if self.service_role_key:
                    logger.info("Łączenie z bazą Supabase używając Service Role Key")
                    self.supabase = create_client(self.url, self.service_role_key)
                else:
                    logger.info("Łączenie z bazą Supabase używając standardowego klucza")
                    self.supabase = create_client(self.url, self.key)

                self._test_mode = False
                logger.info("Połączono z bazą Supabase")
            except ImportError:
                logger.error("Nie znaleziono modułu supabase. Zainstaluj go używając: pip install supabase")
                raise
        else:
            # Tryb testowy/symulacyjny - używamy lokalnej symulacji bazy danych
            logger.warning(
                "Zmienne środowiskowe SUPABASE_URL lub SUPABASE_KEY nie są ustawione. "
                "Uruchamiam w trybie testowym z symulowaną bazą danych."
            )
            self.supabase = MockSupabase()
            self._test_mode = True
            logger.info("Uruchomiono w trybie testowym. Dane NIE będą zapisywane w rzeczywistej bazie.")

    def close(self):
        """Zamknięcie połączenia z bazą danych."""
        if self._test_mode:
            # W trybie testowym zapisujemy dane do pliku dla celów debugowania
            logger.info("Tryb testowy: Symulowana baza danych zostanie zamknięta.")
            try:
                with open('test_db_dump.json', 'w') as f:
                    json.dump(self.supabase.data, f, indent=2)
                logger.info("Zapisano symulowane dane do pliku test_db_dump.json dla analizy.")
            except Exception as e:
                logger.warning("Nie udało się zapisać danych testowych: %s", str(e))
        else:
            # Supabase client nie ma metody close, ale możemy zresetować zmienne
            self.supabase = None
            logger.info("Zamknięto połączenie z bazą Supabase")

    # KIERUNKI
    def get_all_kierunki(self):
        """Pobiera wszystkie kierunki z bazy danych."""
        response = self.supabase.table('kierunki').select('*').execute()
        return response.data

    def get_kierunek_by_nazwa(self, nazwa):
        """Pobiera kierunek po nazwie."""
        response = self.supabase.table('kierunki').select('*').eq('nazwa_kierunku', nazwa).execute()
        if response.data:
            return response.data[0]
        return None

    def upsert_kierunek(self, kierunek):
        """Wstawia lub aktualizuje kierunek."""
        existing = self.get_kierunek_by_nazwa(kierunek['nazwa_kierunku'])
        if existing:
            response = self.supabase.table('kierunki').update(kierunek).eq('id', existing['id']).execute()
            logger.debug("Zaktualizowano kierunek: %s", kierunek['nazwa_kierunku'])
        else:
            response = self.supabase.table('kierunki').insert(kierunek).execute()
            logger.debug("Dodano nowy kierunek: %s", kierunek['nazwa_kierunku'])

        return response.data[0]

    # GRUPY
    def get_all_grupy(self):
        """Pobiera wszystkie grupy z bazy danych."""
        response = self.supabase.table('grupy').select('*').execute()
        return response.data

    def get_grupy_by_kierunek_id(self, kierunek_id):
        """Pobiera grupy dla danego kierunku."""
        response = self.supabase.table('grupy').select('*').eq('kierunek_id', kierunek_id).execute()
        return response.data

    def get_grupa_by_kod(self, kod_grupy):
        """Pobiera grupę po kodzie."""
        response = self.supabase.table('grupy').select('*').eq('kod_grupy', kod_grupy).execute()
        if response.data:
            return response.data[0]
        return None

    def upsert_grupa(self, grupa):
        """Wstawia lub aktualizuje grupę."""
        existing = self.get_grupa_by_kod(grupa['kod_grupy']) if 'kod_grupy' in grupa and grupa['kod_grupy'] else None

        if existing:
            response = self.supabase.table('grupy').update(grupa).eq('id', existing['id']).execute()
            logger.debug("Zaktualizowano grupę: %s", grupa.get('kod_grupy', 'bez kodu'))
        else:
            response = self.supabase.table('grupy').insert(grupa).execute()
            logger.debug("Dodano nową grupę: %s", grupa.get('kod_grupy', 'bez kodu'))

        return response.data[0]

    # NAUCZYCIELE
    def get_all_nauczyciele(self):
        """Pobiera wszystkich nauczycieli z bazy danych."""
        response = self.supabase.table('nauczyciele').select('*').execute()
        return response.data

    def get_nauczyciel_by_name(self, imie_nazwisko):
        """Pobiera nauczyciela po imieniu i nazwisku."""
        response = self.supabase.table('nauczyciele').select('*').eq('imie_nazwisko', imie_nazwisko).execute()
        if response.data:
            return response.data[0]
        return None

    def upsert_nauczyciel(self, nauczyciel):
        """Wstawia lub aktualizuje nauczyciela."""
        existing = self.get_nauczyciel_by_name(nauczyciel['imie_nazwisko'])

        if existing:
            response = self.supabase.table('nauczyciele').update(nauczyciel).eq('id', existing['id']).execute()
            logger.debug("Zaktualizowano nauczyciela: %s", nauczyciel['imie_nazwisko'])
        else:
            response = self.supabase.table('nauczyciele').insert(nauczyciel).execute()
            logger.debug("Dodano nowego nauczyciela: %s", nauczyciel['imie_nazwisko'])

        return response.data[0]

    # ZAJĘCIA
    def get_matching_zajecia(self, przedmiot, od, do_, miejsce):
        """Sprawdza czy istnieją zajęcia o podanych parametrach."""
        response = self.supabase.table('zajecia').select('*') \
            .eq('przedmiot', przedmiot) \
            .eq('od', od) \
            .eq('do_', do_) \
            .eq('miejsce', miejsce).execute()

        if response.data:
            return response.data[0]
        return None

    def insert_zajecia(self, zajecia):
        """Wstawia nowe zajęcia do bazy danych."""
        response = self.supabase.table('zajecia').insert(zajecia).execute()
        logger.debug("Dodano nowe zajęcia: %s (%s - %s)",
                     zajecia['przedmiot'], zajecia['od'], zajecia['do_'])
        return response.data[0]

    def upsert_zajecia(self, zajecia):
        """Wstawia lub aktualizuje zajęcia oraz zwraca informację czy były dodane (True) czy zaktualizowane (False)."""
        existing = self.get_matching_zajecia(
            zajecia['przedmiot'],
            zajecia['od'],
            zajecia['do_'],
            zajecia['miejsce']
        )

        if existing:
            # Aktualizacja istniejących zajęć
            zajecia['data_aktualizacji'] = 'now()'
            response = self.supabase.table('zajecia').update(zajecia).eq('id', existing['id']).execute()
            logger.debug("Zaktualizowano zajęcia: %s (%s - %s)",
                         zajecia['przedmiot'], zajecia['od'], zajecia['do_'])
            return response.data[0], False
        else:
            # Dodanie nowych zajęć
            zajecia['data_utworzenia'] = 'now()'
            zajecia['data_aktualizacji'] = 'now()'
            response = self.supabase.table('zajecia').insert(zajecia).execute()
            logger.debug("Dodano nowe zajęcia: %s (%s - %s)",
                         zajecia['przedmiot'], zajecia['od'], zajecia['do_'])
            return response.data[0], True

    def link_zajecia_to_grupa(self, zajecia_id, grupa_id):
        """Tworzy powiązanie między zajęciami a grupą."""
        try:
            self.supabase.table('zajecia_grupy').insert({
                'zajecia_id': zajecia_id,
                'grupa_id': grupa_id
            }).execute()
            logger.debug("Powiązano zajęcia %s z grupą %s", zajecia_id, grupa_id)
        except Exception as e:
            # Ignorujemy błędy duplikacji (constraint violation)
            if "duplicate key value violates unique constraint" not in str(e):
                raise

    def link_zajecia_to_nauczyciel(self, zajecia_id, nauczyciel_id):
        """Tworzy powiązanie między zajęciami a nauczycielem."""
        try:
            self.supabase.table('zajecia_nauczyciele').insert({
                'zajecia_id': zajecia_id,
                'nauczyciel_id': nauczyciel_id
            }).execute()
            logger.debug("Powiązano zajęcia %s z nauczycielem %s", zajecia_id, nauczyciel_id)
        except Exception as e:
            # Ignorujemy błędy duplikacji (constraint violation)
            if "duplicate key value violates unique constraint" not in str(e):
                raise