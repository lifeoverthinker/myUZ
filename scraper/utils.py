"""
Moduł z narzędziami pomocniczymi
Autor: lifeoverthinker
Data: 2025-04-08
"""

import logging
import json
import os
import re
import io
from typing import Dict, Any, Optional
from datetime import datetime, UTC

def setup_logging() -> logging.Logger:
    """
    Konfiguruje i zwraca logger

    Returns:
        Skonfigurowany logger
    """
    # Utwórz katalog logs jeśli nie istnieje
    if not os.path.exists('logs'):
        os.makedirs('logs')

    # Aktualna data do nazwy pliku logu
    current_date = datetime.now().strftime('%Y-%m-%d')
    log_file = f"logs/scraper_{current_date}.log"

    # Konfiguracja loggera
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(name)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file, encoding='utf-8'),
            logging.StreamHandler()
        ]
    )

    # Wycisz niektóre zbyt gadatliwe loggery bibliotek
    logging.getLogger('urllib3').setLevel(logging.WARNING)
    logging.getLogger('requests').setLevel(logging.WARNING)

    return logging.getLogger('scraper')

def save_to_json(data: Dict[str, Any], filepath: str) -> bool:
    """
    Zapisuje dane do pliku JSON

    Args:
        data: Dane do zapisania
        filepath: Ścieżka do pliku

    Returns:
        True jeśli zapis się powiódł, False w przeciwnym razie
    """
    try:
        # Utwórz katalog jeśli nie istnieje
        directory = os.path.dirname(filepath)
        if directory and not os.path.exists(directory):
            os.makedirs(directory)

        with open(filepath, 'w', encoding='utf-8') as file_obj:
            json.dump(data, file_obj, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        logging.error(f"Błąd podczas zapisywania do JSON: {str(e)}")
        return False

def print_stats(stats: Dict[str, Any]) -> None:
    """
    Drukuje statystyki wykonania scrapera w ładnym formacie

    Args:
        stats: Słownik ze statystykami
    """
    print("\n" + "=" * 50)
    print("📊 STATYSTYKI WYKONANIA SCRAPERA")
    print("=" * 50)
    for key, value in stats.items():
        print(f"📌 {key.replace('_', ' ').title()}: {value}")
    print("=" * 50 + "\n")

def extract_id_from_url(url: str, param_name: str = 'ID') -> Optional[str]:
    """
    Wyciąga ID z URL używając wyrażenia regularnego

    Args:
        url: Adres URL zawierający parametr ID
        param_name: Nazwa parametru (domyślnie 'ID')

    Returns:
        Wartość parametru ID lub None jeśli nie znaleziono
    """
    pattern = f"{param_name}=([0-9]+)"
    match = re.search(pattern, url)
    if match:
        return match.group(1)
    return None

def format_timestamp() -> str:
    """
    Zwraca aktualny timestamp w czytelnym formacie

    Returns:
        String z datą i czasem
    """
    return datetime.now(UTC).strftime("%Y-%m-%d %H:%M:%S")