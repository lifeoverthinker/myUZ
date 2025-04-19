"""
Główny moduł scrapera pobierającego dane z planu Uniwersytetu Zielonogórskiego.
Zbiera informacje o kierunkach, grupach, nauczycielach i zajęciach.
"""

from dotenv import load_dotenv
import os
import concurrent.futures
from supabase import create_client
from tqdm import tqdm

from scraper.downloader import download_ics
from scraper.parsers.grupy_parser import parse_ics
from scraper.db import save_events, update_kierunki, update_grupy, update_nauczyciele
from scraper.ics_updater import aktualizuj_plany_grup, aktualizuj_plany_nauczycieli

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def konwertuj_na_liste(dane):
    """Konwertuje pojedynczy obiekt na listę lub pozostawia listę bez zmian."""
    if dane is None:
        return []
    if not isinstance(dane, list):
        return [dane]
    return dane


def konwertuj_na_slowniki(lista_obiektow):
    """Konwertuje obiekty w liście na słowniki, jeśli są klasami."""
    if not lista_obiektow:
        return []

    # Sprawdź czy elementy mają atrybut __dict__ (są obiektami klas)
    if hasattr(lista_obiektow[0], '__dict__'):
        return [obj.__dict__ for obj in lista_obiektow]
    return lista_obiektow


def main():
    """Główna funkcja scrapera, która sekwencyjnie pobiera dane o kierunkach, grupach,
    nauczycielach i planach zajęć, a następnie zapisuje je do bazy danych."""

    print("🔄 Scraper startuje...")

    try:
        # 1. Scrapuj i zaktualizuj kierunki
        print("\n📚 ETAP 1: Pobieranie wydziałów i kierunków...")
        kierunki = update_kierunki(upsert=True)

        # Konwersja na listę i słowniki
        kierunki = konwertuj_na_liste(kierunki)
        kierunki = konwertuj_na_slowniki(kierunki)

        if not kierunki:
            print("❌ Nie udało się pobrać kierunków. Przerywanie.")
            return

        print(f"✅ Pobrano i zapisano {len(kierunki)} kierunków")

        # 2. Scrapuj i zaktualizuj grupy dla kierunków
        print("\n👥 ETAP 2: Pobieranie grup dla kierunków...")
        grupy = update_grupy(kierunki)

        # Konwersja na listę i słowniki
        grupy = konwertuj_na_liste(grupy)
        grupy = konwertuj_na_slowniki(grupy)

        if not grupy:
            print("❌ Nie udało się pobrać grup. Przerywanie.")
            return

        print(f"✅ Pobrano i zapisano {len(grupy)} grup")

        # 3. Scrapuj i zaktualizuj nauczycieli z grup
        print("\n🧑‍🏫 ETAP 3: Pobieranie nauczycieli...")
        nauczyciele = update_nauczyciele(grupy)

        # Konwersja na listę i słowniki
        nauczyciele = konwertuj_na_liste(nauczyciele)
        nauczyciele = konwertuj_na_slowniki(nauczyciele)

        if not nauczyciele:
            print("⚠️ Nie udało się pobrać nauczycieli. Kontynuowanie bez nauczycieli.")
        else:
            print(f"✅ Pobrano i zapisano {len(nauczyciele)} nauczycieli")

        # 4. Scrapuj plany z plików ICS (równolegle)
        print("\n📅 ETAP 4: Pobieranie planów zajęć...")

        # Przygotowanie list identyfikatorów
        grupa_ids = [grupa['id'] for grupa in grupy if 'id' in grupa]

        # Pobieranie planów grup równolegle
        print(f"🔄 Pobieram plany dla {len(grupa_ids)} grup...")
        plany_grup = aktualizuj_plany_grup(grupa_ids)

        # Parsowanie i zapisywanie wydarzeń z planów grup
        grupa_events = []
        for plan in tqdm(plany_grup, desc="Parsowanie planów grup"):
            try:
                events = parse_ics(plan['ics_data'], grupa_id=plan['grupa_id'])
                grupa_events.extend(events)
            except Exception as e:
                print(f"❌ Błąd parsowania planu grupy {plan['grupa_id']}: {e}")

        if grupa_events:
            save_events(grupa_events, "grupa")
            print(f"✅ Zapisano plany dla {len(plany_grup)} grup ({len(grupa_events)} wydarzeń)")

        # Pobieranie planów nauczycieli równolegle
        if nauczyciele:
            nauczyciel_ids = [n['id'] for n in nauczyciele if 'id' in n]
            print(f"🔄 Pobieram plany dla {len(nauczyciel_ids)} nauczycieli...")
            plany_nauczycieli = aktualizuj_plany_nauczycieli(nauczyciel_ids)

            # Parsowanie i zapisywanie wydarzeń z planów nauczycieli
            nauczyciel_events = []
            for plan in tqdm(plany_nauczycieli, desc="Parsowanie planów nauczycieli"):
                try:
                    events = parse_ics(plan['ics_data'], nauczyciel_id=plan['nauczyciel_id'])
                    nauczyciel_events.extend(events)
                except Exception as e:
                    print(f"❌ Błąd parsowania planu nauczyciela {plan['nauczyciel_id']}: {e}")

            if nauczyciel_events:
                save_events(nauczyciel_events, "nauczyciel")
                print(f"✅ Zapisano plany dla {len(plany_nauczycieli)} nauczycieli ({len(nauczyciel_events)} wydarzeń)")

        print("\n✅ Zakończono cały proces scrapowania i zapisu do bazy danych.")

    except Exception as e:
        print(f"\n❌ Nieoczekiwany błąd podczas wykonywania scrapera: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()