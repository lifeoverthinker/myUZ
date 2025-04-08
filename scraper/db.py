import logging
import psycopg2
import psycopg2.extras
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import threading

logger = logging.getLogger('UZ_Scraper.DB')

class DB:
    def __init__(self, host, dbname, user, password):
        """Inicjalizuje połączenie z bazą danych."""
        self.connection_params = {
            'host': host,
            'dbname': dbname,
            'user': user,
            'password': password
        }
        # Główne połączenie dla wątku głównego
        self.conn = psycopg2.connect(**self.connection_params)
        self.conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        self.cursor = self.conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
        # Słownik do przechowywania połączeń dla poszczególnych wątków
        self.thread_connections = {}
        self.lock = threading.Lock()
        logger.info("Połączono z bazą danych")

    def get_connection(self):
        """Zwraca połączenie dla aktualnego wątku lub tworzy nowe."""
        thread_id = threading.get_ident()
        with self.lock:
            if thread_id not in self.thread_connections:
                conn = psycopg2.connect(**self.connection_params)
                conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
                cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
                self.thread_connections[thread_id] = (conn, cursor)
                logger.debug("Utworzono nowe połączenie dla wątku {}".format(thread_id))
            return self.thread_connections[thread_id]

    def close(self):
        """Zamyka wszystkie połączenia z bazą danych."""
        # Zamknij główne połączenie
        if self.conn:
            self.cursor.close()
            self.conn.close()

        # Zamknij połączenia wątków
        with self.lock:
            for thread_id, (conn, cursor) in self.thread_connections.items():
                cursor.close()
                conn.close()
            self.thread_connections.clear()

        logger.info("Zamknięto wszystkie połączenia z bazą danych")

    # ======= METODY DLA KIERUNKÓW =======

    def get_kierunki(self):
        """Pobiera wszystkie kierunki z bazy danych."""
        query = "SELECT * FROM kierunki"
        self.cursor.execute(query)
        return self.cursor.fetchall()

    def get_kierunek_by_id(self, kierunek_id):
        """Pobiera kierunek po ID."""
        query = "SELECT * FROM kierunki WHERE id = %s"
        self.cursor.execute(query, (kierunek_id,))
        result = self.cursor.fetchone()
        return dict(result) if result else None

    def upsert_kierunek(self, kierunek):
        """Dodaje lub aktualizuje kierunek w bazie danych."""
        conn, cursor = self.get_connection()

        query = """
        INSERT INTO kierunki (nazwa_kierunku, wydzial, link_grupy)
        VALUES (%s, %s, %s)
        ON CONFLICT (nazwa_kierunku, wydzial) 
        DO UPDATE SET
        link_grupy = EXCLUDED.link_grupy
        RETURNING id
        """
        values = (
            kierunek['nazwa_kierunku'],
            kierunek['wydzial'],
            kierunek['link_grupy']
        )

        try:
            cursor.execute(query, values)
            result_id = cursor.fetchone()[0]
            return result_id
        except psycopg2.Error as e:
            logger.error("Błąd podczas dodawania kierunku: {}".format(str(e)))

            # Sprawdź czy ograniczenie już istnieje
            try:
                cursor.execute("""
                    SELECT COUNT(*) FROM pg_constraint 
                    WHERE conname = 'unique_kierunek'
                """)
                constraint_exists = cursor.fetchone()[0] > 0

                if not constraint_exists:
                    # Dodaj ograniczenie jeśli nie istnieje
                    cursor.execute("""
                        ALTER TABLE kierunki ADD CONSTRAINT unique_kierunek 
                        UNIQUE (nazwa_kierunku, wydzial)
                    """)

                    # Spróbuj ponownie
                    cursor.execute(query, values)
                    result_id = cursor.fetchone()[0]
                    return result_id
            except Exception as add_constraint_error:
                logger.error("Błąd podczas dodawania ograniczenia: {}".format(str(add_constraint_error)))

            # Ostatnia próba - dodaj bez klauzuli ON CONFLICT
            try:
                fallback_query = """
                INSERT INTO kierunki (nazwa_kierunku, wydzial, link_grupy)
                VALUES (%s, %s, %s)
                RETURNING id
                """
                cursor.execute(fallback_query, values)
                result_id = cursor.fetchone()[0]
                return result_id
            except Exception as inner_e:
                logger.error("Nie udało się dodać kierunku: {}".format(str(inner_e)))
                return None

    # ======= METODY DLA GRUP =======

    def get_grupy(self):
        """Pobiera wszystkie grupy z bazy danych."""
        query = "SELECT * FROM grupy"
        self.cursor.execute(query)
        return self.cursor.fetchall()

    def get_grupa_by_id(self, grupa_id):
        """Pobiera grupę po ID."""
        query = "SELECT * FROM grupy WHERE id = %s"
        self.cursor.execute(query, (grupa_id,))
        result = self.cursor.fetchone()
        return dict(result) if result else None

    def get_grupy_by_kierunek(self, kierunek_id):
        """Pobiera grupy dla danego kierunku."""
        query = "SELECT * FROM grupy WHERE kierunek_id = %s"
        self.cursor.execute(query, (kierunek_id,))
        return self.cursor.fetchall()

    def upsert_grupa(self, grupa):
        """Dodaje lub aktualizuje grupę w bazie danych."""
        conn, cursor = self.get_connection()

        query = """
        INSERT INTO grupy (kod_grupy, kierunek_id, link_planu, tryb_studiow, semestr)
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (kod_grupy, kierunek_id) 
        DO UPDATE SET
        link_planu = EXCLUDED.link_planu,
        tryb_studiow = EXCLUDED.tryb_studiow,
        semestr = EXCLUDED.semestr
        RETURNING id
        """
        values = (
            grupa['kod_grupy'],
            grupa['kierunek_id'],
            grupa['link_planu'],
            grupa['tryb_studiow'],
            grupa['semestr']
        )

        try:
            cursor.execute(query, values)
            result_id = cursor.fetchone()[0]
            return result_id
        except psycopg2.Error as e:
            logger.error("Błąd podczas dodawania grupy: {}".format(str(e)))

            # Sprawdź czy ograniczenie już istnieje
            try:
                cursor.execute("""
                    SELECT COUNT(*) FROM pg_constraint 
                    WHERE conname = 'unique_grupa'
                """)
                constraint_exists = cursor.fetchone()[0] > 0

                if not constraint_exists:
                    # Dodaj ograniczenie jeśli nie istnieje
                    cursor.execute("""
                        ALTER TABLE grupy ADD CONSTRAINT unique_grupa 
                        UNIQUE (kod_grupy, kierunek_id)
                    """)

                    # Spróbuj ponownie
                    cursor.execute(query, values)
                    result_id = cursor.fetchone()[0]
                    return result_id
            except Exception as add_constraint_error:
                logger.error("Błąd podczas dodawania ograniczenia: {}".format(str(add_constraint_error)))

            # Ostatnia próba - dodaj bez klauzuli ON CONFLICT
            try:
                fallback_query = """
                INSERT INTO grupy (kod_grupy, kierunek_id, link_planu, tryb_studiow, semestr)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
                """
                cursor.execute(fallback_query, values)
                result_id = cursor.fetchone()[0]
                return result_id
            except Exception as inner_e:
                logger.error("Nie udało się dodać grupy: {}".format(str(inner_e)))
                return None

    # ======= METODY DLA NAUCZYCIELI =======

    def get_nauczyciele(self):
        """Pobiera wszystkich nauczycieli z bazy danych."""
        query = "SELECT * FROM nauczyciele"
        self.cursor.execute(query)
        return self.cursor.fetchall()

    def get_nauczyciel_by_id(self, nauczyciel_id):
        """Pobiera nauczyciela po ID."""
        query = "SELECT * FROM nauczyciele WHERE id = %s"
        self.cursor.execute(query, (nauczyciel_id,))
        result = self.cursor.fetchone()
        return dict(result) if result else None

    def get_nauczyciel_by_name(self, imie_nazwisko):
        """Pobiera nauczyciela po imieniu i nazwisku."""
        query = "SELECT * FROM nauczyciele WHERE imie_nazwisko = %s"
        self.cursor.execute(query, (imie_nazwisko,))
        result = self.cursor.fetchone()
        return dict(result) if result else None

    def get_nauczyciel_by_external_id(self, external_id):
        """Pobiera nauczyciela na podstawie zewnętrznego ID ze strony."""
        query = """
        SELECT * FROM nauczyciele
        WHERE link_planu LIKE %s
        """
        self.cursor.execute(query, ('%{}%'.format(external_id),))
        result = self.cursor.fetchone()

        if result:
            return dict(result)
        return None

    def upsert_nauczyciel(self, nauczyciel):
        """Dodaje lub aktualizuje nauczyciela w bazie danych."""
        conn, cursor = self.get_connection()

        query = """
        INSERT INTO nauczyciele (imie_nazwisko, instytut, email, link_planu)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (imie_nazwisko, instytut) 
        DO UPDATE SET
        email = EXCLUDED.email,
        link_planu = EXCLUDED.link_planu
        RETURNING id
        """
        values = (
            nauczyciel['imie_nazwisko'],
            nauczyciel['instytut'],
            nauczyciel.get('email'),
            nauczyciel.get('link_planu')
        )

        try:
            cursor.execute(query, values)
            result_id = cursor.fetchone()[0]
            return result_id
        except psycopg2.Error as e:
            logger.error("Błąd podczas dodawania nauczyciela: {}".format(str(e)))

            # Sprawdź czy ograniczenie już istnieje
            try:
                cursor.execute("""
                    SELECT COUNT(*) FROM pg_constraint 
                    WHERE conname = 'unique_nauczyciel'
                """)
                constraint_exists = cursor.fetchone()[0] > 0

                if not constraint_exists:
                    # Dodaj ograniczenie jeśli nie istnieje
                    cursor.execute("""
                        ALTER TABLE nauczyciele ADD CONSTRAINT unique_nauczyciel 
                        UNIQUE (imie_nazwisko, instytut)
                    """)

                    # Spróbuj ponownie
                    cursor.execute(query, values)
                    result_id = cursor.fetchone()[0]
                    return result_id
            except Exception as add_constraint_error:
                logger.error("Błąd podczas dodawania ograniczenia: {}".format(str(add_constraint_error)))

            # Ostatnia próba - dodaj bez klauzuli ON CONFLICT
            try:
                fallback_query = """
                INSERT INTO nauczyciele (imie_nazwisko, instytut, email, link_planu)
                VALUES (%s, %s, %s, %s)
                RETURNING id
                """
                cursor.execute(fallback_query, values)
                result_id = cursor.fetchone()[0]
                return result_id
            except Exception as inner_e:
                logger.error("Nie udało się dodać nauczyciela: {}".format(str(inner_e)))
                return None

    # ======= METODY DLA PLANÓW GRUP =======

    def get_plany_grup(self):
        """Pobiera wszystkie plany grup z bazy danych."""
        query = "SELECT * FROM plany_grup"
        self.cursor.execute(query)
        return self.cursor.fetchall()

    def get_plan_grupy_by_id(self, plan_id):
        """Pobiera plan grupy po ID."""
        query = "SELECT * FROM plany_grup WHERE id = %s"
        self.cursor.execute(query, (plan_id,))
        result = self.cursor.fetchone()
        return dict(result) if result else None

    def get_plan_by_grupa_id(self, grupa_id):
        """Pobiera plan dla konkretnej grupy."""
        query = "SELECT * FROM plany_grup WHERE grupa_id = %s ORDER BY od"
        self.cursor.execute(query, (grupa_id,))
        return self.cursor.fetchall()

    def upsert_plan_grupy(self, plan_entry):
        """Dodaje lub aktualizuje wpis w planie grupy."""
        conn, cursor = self.get_connection()

        # Definiujemy query i values na początku funkcji
        query = """
        INSERT INTO plany_grup 
        (grupa_id, link_ics, nauczyciel_id, od, do_, przedmiot, rz, miejsce)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (grupa_id, od, do_, przedmiot) 
        DO UPDATE SET
        link_ics = EXCLUDED.link_ics,
        nauczyciel_id = EXCLUDED.nauczyciel_id,
        rz = EXCLUDED.rz,
        miejsce = EXCLUDED.miejsce
        RETURNING id
        """
        values = (
            plan_entry['grupa_id'],
            plan_entry['link_ics'],
            plan_entry['nauczyciel_id'],
            plan_entry['od'],
            plan_entry['do_'],
            plan_entry['przedmiot'],
            plan_entry['rz'],
            plan_entry['miejsce']
        )

        try:
            cursor.execute(query, values)
            result_id = cursor.fetchone()[0]
            return result_id
        except psycopg2.Error as e:
            logger.error("Błąd podczas zapisywania planu grupy: {}".format(str(e)))

            # Sprawdź czy ograniczenie już istnieje
            try:
                cursor.execute("""
                    SELECT COUNT(*) FROM pg_constraint 
                    WHERE conname = 'unique_plan_grupy'
                """)
                constraint_exists = cursor.fetchone()[0] > 0

                if not constraint_exists:
                    # Dodaj ograniczenie jeśli nie istnieje
                    cursor.execute("""
                        ALTER TABLE plany_grup ADD CONSTRAINT unique_plan_grupy 
                        UNIQUE (grupa_id, od, do_, przedmiot)
                    """)

                    # Spróbuj ponownie
                    cursor.execute(query, values)
                    result_id = cursor.fetchone()[0]
                    return result_id
            except Exception as add_constraint_error:
                logger.error("Błąd podczas dodawania ograniczenia: {}".format(str(add_constraint_error)))

            # Ostatnia próba - dodaj bez klauzuli ON CONFLICT
            try:
                fallback_query = """
                INSERT INTO plany_grup 
                (grupa_id, link_ics, nauczyciel_id, od, do_, przedmiot, rz, miejsce)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """
                cursor.execute(fallback_query, values)
                result_id = cursor.fetchone()[0]
                return result_id
            except Exception as inner_e:
                logger.error("Nie udało się dodać planu grupy: {}".format(str(inner_e)))
                return None

    # ======= METODY DLA PLANÓW NAUCZYCIELI =======

    def get_plany_nauczycieli(self):
        """Pobiera wszystkie plany nauczycieli z bazy danych."""
        query = "SELECT * FROM plany_nauczycieli"
        self.cursor.execute(query)
        return self.cursor.fetchall()

    def get_plan_nauczyciela_by_id(self, plan_id):
        """Pobiera plan nauczyciela po ID."""
        query = "SELECT * FROM plany_nauczycieli WHERE id = %s"
        self.cursor.execute(query, (plan_id,))
        result = self.cursor.fetchone()
        return dict(result) if result else None

    def get_plan_by_nauczyciel_id(self, nauczyciel_id):
        """Pobiera plan dla konkretnego nauczyciela."""
        query = "SELECT * FROM plany_nauczycieli WHERE nauczyciel_id = %s ORDER BY od"
        self.cursor.execute(query, (nauczyciel_id,))
        return self.cursor.fetchall()

    def upsert_plan_nauczyciela(self, plan_entry):
        """Dodaje lub aktualizuje wpis w planie nauczyciela."""
        conn, cursor = self.get_connection()

        # Definiujemy query i values na początku funkcji
        query = """
        INSERT INTO plany_nauczycieli 
        (nauczyciel_id, link_ics, od, do_, przedmiot, rz, grupy, miejsce)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (nauczyciel_id, od, do_, przedmiot) 
        DO UPDATE SET
        link_ics = EXCLUDED.link_ics,
        rz = EXCLUDED.rz,
        grupy = EXCLUDED.grupy,
        miejsce = EXCLUDED.miejsce
        RETURNING id
        """
        values = (
            plan_entry['nauczyciel_id'],
            plan_entry['link_ics'],
            plan_entry['od'],
            plan_entry['do_'],
            plan_entry['przedmiot'],
            plan_entry['rz'],
            plan_entry['grupy'],
            plan_entry['miejsce']
        )

        try:
            cursor.execute(query, values)
            result_id = cursor.fetchone()[0]
            return result_id
        except psycopg2.Error as e:
            logger.error("Błąd podczas zapisywania planu nauczyciela: {}".format(str(e)))

            # Sprawdź czy ograniczenie już istnieje
            try:
                cursor.execute("""
                    SELECT COUNT(*) FROM pg_constraint 
                    WHERE conname = 'unique_plan_nauczyciela'
                """)
                constraint_exists = cursor.fetchone()[0] > 0

                if not constraint_exists:
                    # Dodaj ograniczenie jeśli nie istnieje
                    cursor.execute("""
                        ALTER TABLE plany_nauczycieli ADD CONSTRAINT unique_plan_nauczyciela 
                        UNIQUE (nauczyciel_id, od, do_, przedmiot)
                    """)

                    # Spróbuj ponownie
                    cursor.execute(query, values)
                    result_id = cursor.fetchone()[0]
                    return result_id
            except Exception as add_constraint_error:
                logger.error("Błąd podczas dodawania ograniczenia: {}".format(str(add_constraint_error)))

            # Ostatnia próba - dodaj bez klauzuli ON CONFLICT
            try:
                fallback_query = """
                INSERT INTO plany_nauczycieli 
                (nauczyciel_id, link_ics, od, do_, przedmiot, rz, grupy, miejsce)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """
                cursor.execute(fallback_query, values)
                result_id = cursor.fetchone()[0]
                return result_id
            except Exception as inner_e:
                logger.error("Nie udało się dodać planu nauczyciela: {}".format(str(inner_e)))
                return None

    # ======= METODY DLA ZAJĘĆ (ZUNIFIKOWANY MODEL) =======

    def get_zajecia(self):
        """Pobiera wszystkie zajęcia z bazy danych."""
        query = """
        SELECT z.*, 
               array_agg(DISTINCT g.kod_grupy) as grupy_kody,
               array_agg(DISTINCT n.imie_nazwisko) as nauczyciele_nazwiska
        FROM zajecia z
        LEFT JOIN zajecia_grupy zg ON z.id = zg.zajecia_id
        LEFT JOIN grupy g ON zg.grupa_id = g.id
        LEFT JOIN zajecia_nauczyciele zn ON z.id = zn.zajecia_id
        LEFT JOIN nauczyciele n ON zn.nauczyciel_id = n.id
        GROUP BY z.id
        ORDER BY z.od
        """
        self.cursor.execute(query)
        return self.cursor.fetchall()

    def get_zajecia_by_id(self, zajecia_id):
        """Pobiera zajęcia po ID."""
        query = """
        SELECT z.*, 
               array_agg(DISTINCT g.kod_grupy) as grupy_kody,
               array_agg(DISTINCT n.imie_nazwisko) as nauczyciele_nazwiska
        FROM zajecia z
        LEFT JOIN zajecia_grupy zg ON z.id = zg.zajecia_id
        LEFT JOIN grupy g ON zg.grupa_id = g.id
        LEFT JOIN zajecia_nauczyciele zn ON z.id = zn.zajecia_id
        LEFT JOIN nauczyciele n ON zn.nauczyciel_id = n.id
        WHERE z.id = %s
        GROUP BY z.id
        """
        self.cursor.execute(query, (zajecia_id,))
        result = self.cursor.fetchone()
        return dict(result) if result else None

    def get_zajecia_by_grupa(self, grupa_id):
        """Pobiera zajęcia dla konkretnej grupy."""
        query = """
        SELECT z.*, 
               array_agg(DISTINCT n.imie_nazwisko) as nauczyciele_nazwiska
        FROM zajecia z
        JOIN zajecia_grupy zg ON z.id = zg.zajecia_id
        LEFT JOIN zajecia_nauczyciele zn ON z.id = zn.zajecia_id
        LEFT JOIN nauczyciele n ON zn.nauczyciel_id = n.id
        WHERE zg.grupa_id = %s
        GROUP BY z.id
        ORDER BY z.od
        """
        self.cursor.execute(query, (grupa_id,))
        return self.cursor.fetchall()

    def get_zajecia_by_nauczyciel(self, nauczyciel_id):
        """Pobiera zajęcia dla konkretnego nauczyciela."""
        query = """
        SELECT z.*, 
               array_agg(DISTINCT g.kod_grupy) as grupy_kody
        FROM zajecia z
        JOIN zajecia_nauczyciele zn ON z.id = zn.zajecia_id
        LEFT JOIN zajecia_grupy zg ON z.id = zg.zajecia_id
        LEFT JOIN grupy g ON zg.grupa_id = g.id
        WHERE zn.nauczyciel_id = %s
        GROUP BY z.id
        ORDER BY z.od
        """
        self.cursor.execute(query, (nauczyciel_id,))
        return self.cursor.fetchall()

    def upsert_zajecia(self, zajecia_data):
        """Dodaje lub aktualizuje zajęcia w bazie danych."""
        conn, cursor = self.get_connection()

        # Definiujemy query i values na początku funkcji
        query = """
        INSERT INTO zajecia (przedmiot, od, do_, miejsce, rz, link_ics)
        VALUES (%s, %s, %s, %s, %s, %s)
        ON CONFLICT (przedmiot, od, do_, miejsce) 
        DO UPDATE SET
        rz = EXCLUDED.rz,
        link_ics = EXCLUDED.link_ics,
        data_aktualizacji = CURRENT_TIMESTAMP
        RETURNING id
        """
        values = (
            zajecia_data['przedmiot'],
            zajecia_data['od'],
            zajecia_data['do_'],
            zajecia_data['miejsce'],
            zajecia_data['rz'],
            zajecia_data.get('link_ics')
        )

        try:
            cursor.execute(query, values)
            result_id = cursor.fetchone()[0]

            # Powiąż z grupami, jeśli podano
            if 'grupy_ids' in zajecia_data and zajecia_data['grupy_ids']:
                for grupa_id in zajecia_data['grupy_ids']:
                    self.add_grupa_to_zajecia(result_id, grupa_id)

            # Powiąż z nauczycielami, jeśli podano
            if 'nauczyciele_ids' in zajecia_data and zajecia_data['nauczyciele_ids']:
                for nauczyciel_id in zajecia_data['nauczyciele_ids']:
                    self.add_nauczyciel_to_zajecia(result_id, nauczyciel_id)

            return result_id
        except psycopg2.Error as e:
            logger.error("Błąd podczas zapisywania zajęć: {}".format(str(e)))

            # Sprawdź czy ograniczenie już istnieje
            try:
                cursor.execute("""
                    SELECT COUNT(*) FROM pg_constraint 
                    WHERE conname = 'unique_zajecia'
                """)
                constraint_exists = cursor.fetchone()[0] > 0

                if not constraint_exists:
                    # Dodaj ograniczenie jeśli nie istnieje
                    cursor.execute("""
                        ALTER TABLE zajecia ADD CONSTRAINT unique_zajecia 
                        UNIQUE (przedmiot, od, do_, miejsce)
                    """)

                    # Spróbuj ponownie
                    cursor.execute(query, values)
                    result_id = cursor.fetchone()[0]
                    return result_id
            except Exception as add_constraint_error:
                logger.error("Błąd podczas dodawania ograniczenia: {}".format(str(add_constraint_error)))

            # Ostatnia próba - dodaj bez klauzuli ON CONFLICT
            try:
                fallback_query = """
                INSERT INTO zajecia (przedmiot, od, do_, miejsce, rz, link_ics)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id
                """
                cursor.execute(fallback_query, values)
                result_id = cursor.fetchone()[0]
                return result_id
            except Exception as inner_e:
                logger.error("Nie udało się dodać zajęć: {}".format(str(inner_e)))
                return None

    def add_grupa_to_zajecia(self, zajecia_id, grupa_id):
        """Dodaje powiązanie między zajęciami a grupą."""
        conn, cursor = self.get_connection()

        query = """
        INSERT INTO zajecia_grupy (zajecia_id, grupa_id)
        VALUES (%s, %s)
        ON CONFLICT (zajecia_id, grupa_id) DO NOTHING
        """
        try:
            cursor.execute(query, (zajecia_id, grupa_id))
            return True
        except Exception as e:
            logger.error("Błąd podczas dodawania grupy do zajęć: {}".format(str(e)))
            return False

    def add_nauczyciel_to_zajecia(self, zajecia_id, nauczyciel_id):
        """Dodaje powiązanie między zajęciami a nauczycielem."""
        conn, cursor = self.get_connection()

        query = """
        INSERT INTO zajecia_nauczyciele (zajecia_id, nauczyciel_id)
        VALUES (%s, %s)
        ON CONFLICT (zajecia_id, nauczyciel_id) DO NOTHING
        """
        try:
            cursor.execute(query, (zajecia_id, nauczyciel_id))
            return True
        except Exception as e:
            logger.error("Błąd podczas dodawania nauczyciela do zajęć: {}".format(str(e)))
            return False

    # ======= METODY PRZETWARZANIA PLANÓW DO MODELU ZUNIFIKOWANEGO =======

    def process_plany_to_zajecia(self):
        """Przetwarza dane z plany_grup i plany_nauczycieli do zunifikowanego modelu zajecia."""
        try:
            # Krok 1: Przenieś dane z plany_grup do zajecia
            query_grupy = """
            WITH inserted AS (
                INSERT INTO zajecia (przedmiot, od, do_, miejsce, rz, link_ics, data_utworzenia, data_aktualizacji)
                SELECT DISTINCT
                    przedmiot, od, do_, miejsce, rz, link_ics, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                FROM plany_grup
                ON CONFLICT (przedmiot, od, do_, miejsce) DO UPDATE SET
                    rz = EXCLUDED.rz,
                    link_ics = EXCLUDED.link_ics,
                    data_aktualizacji = CURRENT_TIMESTAMP
                RETURNING id, przedmiot, od, do_, miejsce
            )
            INSERT INTO zajecia_grupy (zajecia_id, grupa_id)
            SELECT i.id, pg.grupa_id
            FROM inserted i
            JOIN plany_grup pg ON 
                i.przedmiot = pg.przedmiot AND
                i.od = pg.od AND
                i.do_ = pg.do_ AND
                i.miejsce = pg.miejsce
            ON CONFLICT (zajecia_id, grupa_id) DO NOTHING
            RETURNING 1
            """
            self.cursor.execute(query_grupy)
            result_grupy = self.cursor.rowcount

            # Krok 2: Przenieś powiązania nauczyciel-zajęcia z plany_grup
            query_nauczyciele_grupy = """
            WITH zajecia_data AS (
                SELECT z.id AS zajecia_id, pg.nauczyciel_id
                FROM zajecia z
                JOIN plany_grup pg ON 
                    z.przedmiot = pg.przedmiot AND
                    z.od = pg.od AND
                    z.do_ = pg.do_ AND
                    z.miejsce = pg.miejsce
                WHERE pg.nauczyciel_id IS NOT NULL
            )
            INSERT INTO zajecia_nauczyciele (zajecia_id, nauczyciel_id)
            SELECT zajecia_id, nauczyciel_id
            FROM zajecia_data
            ON CONFLICT (zajecia_id, nauczyciel_id) DO NOTHING
            RETURNING 1
            """
            self.cursor.execute(query_nauczyciele_grupy)
            result_nauczyciele_grupy = self.cursor.rowcount

            # Krok 3: Przenieś dane z plany_nauczycieli do zajecia
            query_nauczyciele = """
            WITH inserted AS (
                INSERT INTO zajecia (przedmiot, od, do_, miejsce, rz, link_ics, data_utworzenia, data_aktualizacji)
                SELECT DISTINCT
                    przedmiot, od, do_, miejsce, rz, link_ics, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                FROM plany_nauczycieli
                ON CONFLICT (przedmiot, od, do_, miejsce) DO UPDATE SET
                    rz = EXCLUDED.rz,
                    link_ics = EXCLUDED.link_ics,
                    data_aktualizacji = CURRENT_TIMESTAMP
                RETURNING id, przedmiot, od, do_, miejsce
            )
            INSERT INTO zajecia_nauczyciele (zajecia_id, nauczyciel_id)
            SELECT i.id, pn.nauczyciel_id
            FROM inserted i
            JOIN plany_nauczycieli pn ON 
                i.przedmiot = pn.przedmiot AND
                i.od = pn.od AND
                i.do_ = pn.do_ AND
                i.miejsce = pn.miejsce
            ON CONFLICT (zajecia_id, nauczyciel_id) DO NOTHING
            RETURNING 1
            """
            self.cursor.execute(query_nauczyciele)
            result_nauczyciele = self.cursor.rowcount

            logger.info("Przetworzono plany zajęć do zunifikowanego modelu. Dodano/zaktualizowano: {} zajęć z grup, {} powiązań nauczyciel-zajęcia z grup, {} zajęć nauczycieli.".format(
                result_grupy, result_nauczyciele_grupy, result_nauczyciele
            ))

            return result_grupy + result_nauczyciele
        except Exception as e:
            logger.error("Błąd podczas przetwarzania planów do zunifikowanego modelu: {}".format(str(e)))
            self.conn.rollback()
            return 0