from dotenv import load_dotenv
import os
from supabase import create_client
from scraper.downloader import download_ics
from scraper.parsers.grupy_parser import parse_ics
from scraper.db import save_events, update_kierunki, update_grupy, update_nauczyciele

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def main():
    print("🔄 Scraper startuje...")

    try:
        # 1. Scrapuj i zaktualizuj kierunki
        print("\n📚 ETAP 1: Pobieranie wydziałów i kierunków...")
        kierunki = update_kierunki(upsert=True)
        if not kierunki:
            print("❌ Nie udało się pobrać kierunków. Przerywanie.")
            return
        print(f"✅ Pobrano i zapisano {len(kierunki)} kierunków")

        # 2. Scrapuj i zaktualizuj grupy dla kierunków
        print("\n👥 ETAP 2: Pobieranie grup dla kierunków...")
        grupy = update_grupy(kierunki)
        if not grupy:
            print("❌ Nie udało się pobrać grup. Przerywanie.")
            return

        print(f"✅ Pobrano i zapisano {len(grupy)} grup")

        # 3. Scrapuj i zaktualizuj nauczycieli z grup
        print("\n🧑‍🏫 ETAP 3: Pobieranie nauczycieli...")
        nauczyciele = update_nauczyciele(grupy)
        if not nauczyciele:
            print("⚠️ Nie udało się pobrać nauczycieli. Kontynuowanie bez nauczycieli.")
        else:
            print(f"✅ Pobrano i zapisano {len(nauczyciele)} nauczycieli")

        # 4. Scrapuj plany z plików ICS
        print("\n📅 ETAP 4: Pobieranie planów zajęć...")

        # Optymalizacja: przygotuj zbiorcze listy wydarzeń
        grupa_events = []
        nauczyciel_events = []

        # Najpierw plany grup
        grupy_count = 0
        for grupa in grupy:
            # Sprawdzamy dostępność linku ICS w nowej strukturze
            ics_link = grupa.get('link_ics_grupy')

            if ics_link and 'id' in grupa:
                print(f"📥 Pobieram plan dla grupy {grupa['kod_grupy']}...")
                try:
                    ics_data = download_ics(ics_link)
                    events = parse_ics(ics_data, grupa_id=grupa['id'])
                    grupa_events.extend(events)
                    grupy_count += 1
                except Exception as e:
                    print(f"❌ Błąd podczas pobierania planu grupy {grupa['kod_grupy']}: {e}")

        # Zapisz zbiorczo wydarzenia grup
        if grupa_events:
            save_events(grupa_events, "grupa")
            print(f"✅ Zapisano plany dla {grupy_count} grup ({len(grupa_events)} wydarzeń)")

        # Potem plany nauczycieli
        naucz_count = 0
        if nauczyciele:
            for nauczyciel in nauczyciele:
                # Zaktualizowana nazwa kolumny - popraw na link_plan_nauczyciela
                ics_link = nauczyciel.get('link_plan_nauczyciela')

                if ics_link and 'id' in nauczyciel:
                    print(f"📥 Pobieram plan dla nauczyciela {nauczyciel.get('imie_nazwisko', 'bez nazwiska')}...")
                    try:
                        ics_data = download_ics(ics_link)
                        events = parse_ics(ics_data, nauczyciel_id=nauczyciel['id'])
                        nauczyciel_events.extend(events)
                        naucz_count += 1
                    except Exception as e:
                        print(
                            f"❌ Błąd pobierania planu nauczyciela {nauczyciel.get('imie_nazwisko', 'bez nazwiska')}: {e}")            # Zapisz zbiorczo wydarzenia nauczycieli
            if nauczyciel_events:
                save_events(nauczyciel_events, "nauczyciel")
                print(f"✅ Zapisano plany dla {naucz_count} nauczycieli ({len(nauczyciel_events)} wydarzeń)")

        print("\n✅ Zakończono cały proces scrapowania i zapisu do bazy danych.")

    except Exception as e:
        print(f"\n❌ Nieoczekiwany błąd podczas wykonywania scrapera: {e}")


if __name__ == "__main__":
    main()