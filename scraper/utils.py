# Moduł z funkcjami pomocniczymi do scrapowania
import re
import sys
import requests
from bs4 import BeautifulSoup
import time

# Podstawowy URL dla systemu planów UZ
BASE_URL = "https://plan.uz.zgora.pl/"

def get_soup(url, max_retries=3):
    """Pobiera stronę i zwraca obiekt BeautifulSoup"""
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    }

    for attempt in range(max_retries):
        try:
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()  # Zgłosi wyjątek dla statusów HTTP 4XX/5XX

            # Wykrywanie kodowania
            if 'charset' in response.headers.get('content-type', '').lower():
                response.encoding = response.apparent_encoding
            else:
                # Jeśli serwer nie określa kodowania, używamy wykrytego
                response.encoding = response.apparent_encoding

            return BeautifulSoup(response.text, 'lxml')

        except requests.exceptions.RequestException as e:
            print(f"Błąd pobierania {url}: {e}. Próba {attempt + 1}/{max_retries}")
            time.sleep(2)  # Odczekaj przed ponowną próbą

    print(f"Nie udało się pobrać strony po {max_retries} próbach: {url}")
    return None

def clean_text(text):
    """Czyści tekst ze zbędnych białych znaków"""
    if not text:
        return ""

    # Usuń znaczniki HTML jeśli są
    text = re.sub(r'<[^>]*>', ' ', str(text))

    # Normalizacja białych znaków
    text = re.sub(r'\s+', ' ', text)

    return text.strip()

def normalize_url(url):
    """Normalizuje URL, dodając BASE_URL jeśli jest to ścieżka względna"""
    if not url:
        return None

    if url.startswith('http'):
        return url
    elif url.startswith('/'):
        return BASE_URL + url[1:]
    else:
        return BASE_URL + url

def print_progress(current, total, message=""):
    """Wyświetla pasek postępu w konsoli"""
    bar_length = 30
    progress = float(current) / float(total)
    arrow = '=' * int(round(progress * bar_length))
    spaces = ' ' * (bar_length - len(arrow))

    sys.stdout.write(f"\r[{arrow}{spaces}] {int(progress * 100)}% ({current}/{total}) {message}")
    sys.stdout.flush()

    if current == total:
        print()  # Nowa linia po zakończeniu

def extract_teacher_from_description(description):
    """Wyciąga nauczyciela z opisu wydarzenia"""
    if not description:
        return None

    # Szukanie wzorca: "mgr Jan Kowalski" lub "dr hab. Jan Kowalski, prof. UZ" itp.
    teacher_match = re.search(r'(mgr|dr|prof\.)\s+[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]+(\s+[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]+)+', description)
    if teacher_match:
        return teacher_match.group(0)

    # Szukanie w formacie podsumowania: "Przedmiot: mgr Jan Kowalski"
    teacher_match = re.search(r':\s+(mgr|dr|prof\.)\s+[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]+(\s+[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]+)+', description)
    if teacher_match:
        return teacher_match.group(1).strip()

    return None