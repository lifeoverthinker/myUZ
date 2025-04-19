"""
Moduł do pobierania i aktualizacji planów zajęć w formacie ICS.
"""
import concurrent.futures
import datetime
from tqdm import tqdm

from scraper.downloader import BASE_URL, download_ics


def pobierz_plan_ics_grupy(grupa_id):
    """Pobiera plan grupy w formacie ICS."""
    ics_link = f"{BASE_URL}grupy_ics.php?ID={grupa_id}&KIND=GG"

    try:
        ics_data = download_ics(ics_link)
        return {
            'grupa_id': grupa_id,
            'ics_data': ics_data,
            'aktualizacja_data': datetime.datetime.now().isoformat()
        }
    except Exception as e:
        print(f"❌ Błąd pobierania planu ICS dla grupy {grupa_id}: {e}")
        return None


def pobierz_plan_ics_nauczyciela(nauczyciel_id):
    """Pobiera plan nauczyciela w formacie ICS."""
    ics_link = f"{BASE_URL}nauczyciel_ics.php?ID={nauczyciel_id}&KIND=GG"

    try:
        ics_data = download_ics(ics_link)
        return {
            'nauczyciel_id': nauczyciel_id,
            'ics_data': ics_data,
            'aktualizacja_data': datetime.datetime.now().isoformat()
        }
    except Exception as e:
        print(f"❌ Błąd pobierania planu ICS dla nauczyciela {nauczyciel_id}: {e}")
        return None


def aktualizuj_plany_grup(grupa_ids, max_workers=10):
    """
    Aktualizuje plany grup bezpośrednio poprzez pobranie plików ICS.

    Args:
        grupa_ids: Lista identyfikatorów grup do aktualizacji
        max_workers: Liczba równoległych wątków

    Returns:
        Lista słowników z danymi ics dla każdej grupy
    """
    aktualizowane_plany = []

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        zadania = {executor.submit(pobierz_plan_ics_grupy, gid): gid for gid in grupa_ids}

        # Używanie tqdm dla paska postępu
        for zadanie in tqdm(concurrent.futures.as_completed(zadania),
                            total=len(zadania),
                            desc="Aktualizacja planów grup"):
            grupa_id = zadania[zadanie]
            try:
                wynik = zadanie.result()
                if wynik:
                    aktualizowane_plany.append(wynik)
            except Exception as e:
                print(f"❌ Błąd dla grupy {grupa_id}: {e}")

    return aktualizowane_plany


def aktualizuj_plany_nauczycieli(nauczyciel_ids, max_workers=10) -> list[dict]:
    """
    Aktualizuje plany nauczycieli bezpośrednio poprzez pobranie plików ICS.

    Args:
        nauczyciel_ids: Lista identyfikatorów nauczycieli do aktualizacji
        max_workers: Liczba równoległych wątków

    Returns:
        Lista słowników z danymi ics dla każdego nauczyciela
    """
    aktualizowane_plany = []

    print(f"🔄 Aktualizuję plany dla {len(nauczyciel_ids)} nauczycieli...")

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        przyszle_wyniki = {executor.submit(pobierz_plan_ics_nauczyciela, nauczyciel_id): nauczyciel_id
                           for nauczyciel_id in nauczyciel_ids}

        for przyszly_wynik in concurrent.futures.as_completed(przyszle_wyniki):
            nauczyciel_id = przyszle_wyniki[przyszly_wynik]
            try:
                wynik = przyszly_wynik.result()
                if wynik:
                    aktualizowane_plany.append(wynik)
                    print(f"✅ Zaktualizowano plan nauczyciela: {nauczyciel_id}")
            except Exception as e:
                print(f"❌ Błąd podczas aktualizacji planu dla nauczyciela {nauczyciel_id}: {e}")

    return aktualizowane_plany
