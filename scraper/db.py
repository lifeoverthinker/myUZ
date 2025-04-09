import logging
from supabase import create_client
import uuid
import datetime

logger = logging.getLogger('UZ_Scraper.DB')


class DB:
    ### INICJALIZACJA I POŁĄCZENIE ###

    def __init__(self, supabase_url, supabase_key):
        """Inicjalizacja połączenia z bazą danych Supabase."""
        try:
            self.supabase = create_client(supabase_url, supabase_key)
            logger.info("Połączono z bazą danych Supabase")
        except Exception as e:
            logger.error(f"Błąd podczas łączenia z bazą Supabase: {str(e)}")
            raise e

    def close_connections(self):
        """Zamykanie połączeń z bazą danych."""
        logger.info("Zamknięto wszystkie połączenia z bazą danych")

    ### METODY POBIERAJĄCE DANE ###

    def get_kierunki(self):
        """Pobiera wszystkie kierunki z bazy danych."""
        try:
            response = self.supabase.table('kierunki').select('*').execute()
            return response.data
        except Exception as e:
            logger.error(f"Błąd podczas pobierania kierunków: {str(e)}")
            return []

    def get_grupy(self):
        """Pobiera wszystkie grupy z bazy danych."""
        try:
            response = self.supabase.table('grupy').select('*').execute()
            return response.data
        except Exception as e:
            logger.error(f"Błąd podczas pobierania grup: {str(e)}")
            return []

    def get_all_grupy(self):
        """Alias dla get_grupy()."""
        return self.get_grupy()

    def get_nauczyciele(self):
        """Pobiera wszystkich nauczycieli z bazy danych."""
        try:
            response = self.supabase.table('nauczyciele').select('*').execute()
            return response.data
        except Exception as e:
            logger.error(f"Błąd podczas pobierania nauczycieli: {str(e)}")
            return []

    ### METODY AKTUALIZUJĄCE DANE ###

    def update_grupa_semestr(self, grupa_id, semestr):
        """Aktualizuje informację o semestrze dla danej grupy."""
        try:
            self.supabase.table('grupy').update({"semestr": semestr}).eq('id', grupa_id).execute()
            return True
        except Exception as e:
            logger.error(f"Błąd podczas aktualizacji semestru dla grupy {grupa_id}: {str(e)}")
            return False

    ### METODY DODAJĄCE/AKTUALIZUJĄCE PODSTAWOWE ENCJE ###

    def upsert_kierunek(self, kierunek_data):
        """Dodaje lub aktualizuje kierunek studiów."""
        try:
            nazwa = kierunek_data.get('nazwa_kierunku')
            wydzial = kierunek_data.get('wydzial')
            link = kierunek_data.get('link_grupy')

            # Sprawdź czy kierunek już istnieje
            existing = self.supabase.table('kierunki') \
                .select('*') \
                .eq('nazwa_kierunku', nazwa) \
                .eq('wydzial', wydzial) \
                .execute()

            if existing.data:
                # Aktualizacja istniejącego
                kierunek_id = existing.data[0]['id']
                self.supabase.table('kierunki') \
                    .update(kierunek_data) \
                    .eq('id', kierunek_id) \
                    .execute()
                return kierunek_id
            else:
                # Dodanie nowego
                result = self.supabase.table('kierunki') \
                    .insert(kierunek_data) \
                    .execute()
                return result.data[0]['id'] if result.data else None
        except Exception as e:
            logger.error(
                f"Błąd podczas dodawania/aktualizacji kierunku {kierunek_data.get('nazwa_kierunku')}: {str(e)}")
            return None

    def upsert_grupa(self, grupa_data):
        """Dodaje lub aktualizuje grupę zajęciową."""
        try:
            kod_grupy = grupa_data.get('kod_grupy')
            kierunek_id = grupa_data.get('kierunek_id')

            # Sprawdź czy grupa już istnieje
            existing = self.supabase.table('grupy') \
                .select('*') \
                .eq('kod_grupy', kod_grupy) \
                .eq('kierunek_id', kierunek_id) \
                .execute()

            if existing.data:
                # Aktualizacja istniejącej
                grupa_id = existing.data[0]['id']
                self.supabase.table('grupy') \
                    .update(grupa_data) \
                    .eq('id', grupa_id) \
                    .execute()
                return grupa_id
            else:
                # Dodanie nowej
                result = self.supabase.table('grupy') \
                    .insert(grupa_data) \
                    .execute()
                return result.data[0]['id'] if result.data else None
        except Exception as e:
            logger.error(
                f"Błąd podczas dodawania/aktualizacji grupy {grupa_data.get('kod_grupy')}: {str(e)}")
            return None

    def upsert_nauczyciel(self, nauczyciel_data):
        """Dodaje lub aktualizuje nauczyciela."""
        try:
            imie_nazwisko = nauczyciel_data.get('imie_nazwisko')

            # Sprawdź czy nauczyciel już istnieje
            existing = self.supabase.table('nauczyciele') \
                .select('*') \
                .eq('imie_nazwisko', imie_nazwisko) \
                .execute()

            if existing.data:
                # Aktualizacja istniejącego
                nauczyciel_id = existing.data[0]['id']
                self.supabase.table('nauczyciele') \
                    .update(nauczyciel_data) \
                    .eq('id', nauczyciel_id) \
                    .execute()
                return nauczyciel_id
            else:
                # Dodanie nowego
                result = self.supabase.table('nauczyciele') \
                    .insert(nauczyciel_data) \
                    .execute()
                return result.data[0]['id'] if result.data else None
        except Exception as e:
            logger.error(
                f"Błąd podczas dodawania/aktualizacji nauczyciela {nauczyciel_data.get('imie_nazwisko')}: {str(e)}")
            return None

    ### METODY DODAJĄCE/AKTUALIZUJĄCE PLANY ###

    def upsert_plan_grupy(self, plan_data):
        """Dodaje lub aktualizuje plan grupy."""
        try:
            grupa_id = plan_data.get('grupa_id')
            przedmiot = plan_data.get('przedmiot')
            od = plan_data.get('od')
            do_ = plan_data.get('do_')
            miejsce = plan_data.get('miejsce')

            # Sprawdź czy wpis już istnieje
            existing = self.supabase.table('plany_grup') \
                .select('*') \
                .eq('grupa_id', grupa_id) \
                .eq('przedmiot', przedmiot) \
                .eq('od', od) \
                .eq('do_', do_) \
                .eq('miejsce', miejsce) \
                .execute()

            if existing.data:
                # Aktualizacja istniejącego
                plan_id = existing.data[0]['id']
                self.supabase.table('plany_grup') \
                    .update(plan_data) \
                    .eq('id', plan_id) \
                    .execute()
                return plan_id
            else:
                # Dodanie nowego
                result = self.supabase.table('plany_grup') \
                    .insert(plan_data) \
                    .execute()
                return result.data[0]['id'] if result.data else None
        except Exception as e:
            logger.error(f"Błąd podczas dodawania/aktualizacji planu grupy: {str(e)}")
            return None

    def upsert_plan_nauczyciela(self, plan_data):
        """Dodaje lub aktualizuje plan nauczyciela."""
        try:
            nauczyciel_id = plan_data.get('nauczyciel_id')
            przedmiot = plan_data.get('przedmiot')
            od = plan_data.get('od')
            do_ = plan_data.get('do_')
            miejsce = plan_data.get('miejsce')

            # Sprawdź czy wpis już istnieje
            existing = self.supabase.table('plany_nauczycieli') \
                .select('*') \
                .eq('nauczyciel_id', nauczyciel_id) \
                .eq('przedmiot', przedmiot) \
                .eq('od', od) \
                .eq('do_', do_) \
                .eq('miejsce', miejsce) \
                .execute()

            if existing.data:
                # Aktualizacja istniejącego
                plan_id = existing.data[0]['id']
                self.supabase.table('plany_nauczycieli') \
                    .update(plan_data) \
                    .eq('id', plan_id) \
                    .execute()
                return plan_id
            else:
                # Dodanie nowego
                result = self.supabase.table('plany_nauczycieli') \
                    .insert(plan_data) \
                    .execute()
                return result.data[0]['id'] if result.data else None
        except Exception as e:
            logger.error(f"Błąd podczas dodawania/aktualizacji planu nauczyciela: {str(e)}")
            return None

    ### METODY DODAJĄCE/AKTUALIZUJĄCE ZAJĘCIA I RELACJE ###

    def upsert_zajecia(self, zajecia_data, grupy_ids=None, nauczyciele_ids=None):
        """Dodaje lub aktualizuje zajęcia i powiązania z grupami/nauczycielami."""
        try:
            przedmiot = zajecia_data.get('przedmiot')
            od = zajecia_data.get('od')
            do_ = zajecia_data.get('do_')
            miejsce = zajecia_data.get('miejsce')

            # Dodaj datę aktualizacji
            zajecia_data['data_aktualizacji'] = datetime.datetime.now().isoformat()

            # Sprawdź czy zajęcia już istnieją
            existing = self.supabase.table('zajecia') \
                .select('*') \
                .eq('przedmiot', przedmiot) \
                .eq('od', od) \
                .eq('do_', do_) \
                .eq('miejsce', miejsce) \
                .execute()

            zajecia_id = None

            if existing.data:
                # Aktualizacja istniejących
                zajecia_id = existing.data[0]['id']
                self.supabase.table('zajecia') \
                    .update(zajecia_data) \
                    .eq('id', zajecia_id) \
                    .execute()
            else:
                # Dodanie nowych
                zajecia_data['data_utworzenia'] = datetime.datetime.now().isoformat()
                result = self.supabase.table('zajecia') \
                    .insert(zajecia_data) \
                    .execute()
                zajecia_id = result.data[0]['id'] if result.data else None

            # Powiązania z grupami
            if zajecia_id and grupy_ids:
                for grupa_id in grupy_ids:
                    self.upsert_zajecia_grupa(zajecia_id, grupa_id)

            # Powiązania z nauczycielami
            if zajecia_id and nauczyciele_ids:
                for nauczyciel_id in nauczyciele_ids:
                    self.upsert_zajecia_nauczyciel(zajecia_id, nauczyciel_id)

            return zajecia_id
        except Exception as e:
            logger.error(f"Błąd podczas dodawania/aktualizacji zajęć: {str(e)}")
            return None

    def upsert_zajecia_grupa(self, zajecia_id, grupa_id):
        """Dodaje powiązanie zajęć z grupą."""
        try:
            data = {
                'zajecia_id': zajecia_id,
                'grupa_id': grupa_id
            }

            # Sprawdź czy powiązanie już istnieje
            existing = self.supabase.table('zajecia_grupy') \
                .select('*') \
                .eq('zajecia_id', zajecia_id) \
                .eq('grupa_id', grupa_id) \
                .execute()

            if not existing.data:
                # Dodaj nowe powiązanie
                self.supabase.table('zajecia_grupy') \
                    .insert(data) \
                    .execute()

            return True
        except Exception as e:
            logger.error(f"Błąd podczas dodawania powiązania zajęć z grupą: {str(e)}")
            return False

    def upsert_zajecia_nauczyciel(self, zajecia_id, nauczyciel_id):
        """Dodaje powiązanie zajęć z nauczycielem."""
        try:
            data = {
                'zajecia_id': zajecia_id,
                'nauczyciel_id': nauczyciel_id
            }

            # Sprawdź czy powiązanie już istnieje
            existing = self.supabase.table('zajecia_nauczyciele') \
                .select('*') \
                .eq('zajecia_id', zajecia_id) \
                .eq('nauczyciel_id', nauczyciel_id) \
                .execute()

            if not existing.data:
                # Dodaj nowe powiązanie
                self.supabase.table('zajecia_nauczyciele') \
                    .insert(data) \
                    .execute()

            return True
        except Exception as e:
            logger.error(f"Błąd podczas dodawania powiązania zajęć z nauczycielem: {str(e)}")
            return False
