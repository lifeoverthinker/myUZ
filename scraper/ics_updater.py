import datetime
import requests
import concurrent.futures
from tqdm import tqdm

# Adres bazowy do API planów zajęć
BASE_URL = "https://plan.uz.zgora.pl/"

def pobierz_plan_ics_grupy(grupa_id):
    """Pobiera plan grupy w formacie ICS."""
    ics_link = f"{BASE_URL}grupy_ics.php?ID={grupa_id}&KIND=GG"

    try:
        response = requests.get(ics_link)
        response.raise_for_status()
        return {
            'grupa_id': grupa_id,
            'ics_data': response.text,
            'aktualizacja_data': datetime.datetime.now().isoformat()
        }
    except requests.exceptions.RequestException as e:
        print(f"❌ Błąd pobierania planu ICS dla grupy {grupa_id}: {e}")
        return None

def pobierz_plan_ics_nauczyciela(nauczyciel_id):
    """
    Pobiera plan nauczyciela w formacie ICS,
    najpierw sprawdzając czy plan HTML istnieje.
    """
    # Najpierw sprawdź czy istnieje plan HTML
    html_link = f"{BASE_URL}nauczyciel_plan.php?ID={nauczyciel_id}"

    try:
        html_response = requests.get(html_link, timeout=5)

        # Jeśli plan HTML nie istnieje, nie ma sensu próbować pobierać ICS
        if html_response.status_code == 404:
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_data': None,
                'status': 'not_found',
                'aktualizacja_data': datetime.datetime.now().isoformat()
            }

        # Sprawdź czy strona zawiera plan (szukaj nagłówka z planem)
        if "Plan nauczyciela" not in html_response.text:
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_data': None,
                'status': 'no_plan',
                'aktualizacja_data': datetime.datetime.now().isoformat()
            }

        # Jeśli HTML istnieje, próbuj pobrać ICS
        ics_link = f"{BASE_URL}nauczyciel_ics.php?ID={nauczyciel_id}&KIND=GG"
        ics_response = requests.get(ics_link, timeout=10)

        # Weryfikuj odpowiedź ICS
        if ics_response.status_code == 404:
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_data': None,
                'status': 'ics_not_found',
                'aktualizacja_data': datetime.datetime.now().isoformat()
            }

        ics_response.raise_for_status()

        # Sprawdź treść
        if not ics_response.text.strip():
            return {
                'nauczyciel_id': nauczyciel_id,
                'ics_data': None,
                'status': 'empty',
                'aktualizacja_data': datetime.datetime.now().isoformat()
            }

        return {
            'nauczyciel_id': nauczyciel_id,
            'ics_data': ics_response.text,
            'status': 'success',
            'aktualizacja_data': datetime.datetime.now().isoformat()
        }

    except requests.exceptions.RequestException as e:
        return {
            'nauczyciel_id': nauczyciel_id,
            'ics_data': None,
            'status': 'error',
            'error': str(e),
            'aktualizacja_data': datetime.datetime.now().isoformat()
        }

def aktualizuj_plany_grup(grupa_ids, max_workers=10):
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
    aktualizowane_plany = []

    print(f"🔄 Aktualizuję plany dla {len(nauczyciel_ids)} nauczycieli...")

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        przyszle_wyniki = {executor.submit(pobierz_plan_ics_nauczyciela, nauczyciel_id): nauczyciel_id
                           for nauczyciel_id in nauczyciel_ids}

        for przyszly_wynik in tqdm(concurrent.futures.as_completed(przyszle_wyniki),
                                 total=len(przyszle_wyniki),
                                 desc="Aktualizacja planów nauczycieli"):
            nauczyciel_id = przyszle_wyniki[przyszly_wynik]
            try:
                wynik = przyszly_wynik.result()
                if wynik:
                    aktualizowane_plany.append(wynik)
            except Exception as e:
                print(f"❌ Błąd podczas aktualizacji planu dla nauczyciela {nauczyciel_id}: {e}")

    return aktualizowane_plany