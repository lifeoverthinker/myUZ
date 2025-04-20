# Pobieranie plików .ics
import requests
import time
from functools import lru_cache

BASE_URL = "https://plan.uz.zgora.pl/"

def fetch_page(url: str) -> str:
    """Pobiera zawartość strony HTML."""
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        print(f"❌ Błąd pobierania strony: {e}")
        return ""

@lru_cache(maxsize=500)
def fetch_page_cached(url: str) -> str:
    """Cachowana wersja fetch_page dla zwiększenia wydajności."""
    return fetch_page(url)

def fetch_page_with_retry(url: str, max_retries=3, delay=1) -> str:
    """Pobiera stronę z mechanizmem ponawiania."""
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            return response.text
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"⚠️ Próba {attempt+1}/{max_retries} nieudana: {e}. Ponawianie za {delay}s...")
                time.sleep(delay)
                delay *= 2  # Wykładnicze opóźnienie
            else:
                print(f"❌ Wszystkie próby nieudane: {e}")
                return ""


def download_ics(url, max_retries=3):
    """Pobiera plik ICS z podanego URL z obsługą błędów."""
    retries = 0
    while retries < max_retries:
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                # Sprawdź czy to faktycznie plik ICS, a nie strona HTML
                content = response.text.strip()
                if content.startswith('BEGIN:VCALENDAR'):
                    return content
                else:
                    raise Exception("URL nie zwraca pliku ICS, tylko HTML — prawdopodobnie zły link.")
            else:
                raise Exception(f"Błąd HTTP: {response.status_code}")
        except Exception as e:
            retries += 1
            if retries < max_retries:
                print(f"Próba {retries}/{max_retries} nie powiodła się: {e}. Ponawianie...")
                time.sleep(1)
            else:
                raise Exception(f"Po {max_retries} próbach nie udało się pobrać pliku ICS: {e}")