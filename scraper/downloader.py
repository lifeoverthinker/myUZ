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


def download_ics(url):
    """Pobiera plik ICS i sprawdza czy faktycznie zawiera dane kalendarza."""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'text/calendar,text/plain,*/*'
        }

        response = requests.get(url, headers=headers, timeout=15)

        # Sprawdź czy odpowiedź to faktycznie plik ICS
        if 'BEGIN:VCALENDAR' in response.text:
            return response.text
        else:
            raise ValueError("URL nie zwraca pliku ICS, tylko HTML — prawdopodobnie zły link.")

    except Exception as e:
        # Przechwyć i przekaż dalej błąd
        raise Exception(f"{e}")