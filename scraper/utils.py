#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import logging
import requests
import time
from datetime import datetime
import random

logger = logging.getLogger('UZ_Scraper.Utils')

# Konfiguracja requestów
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36'
]

BASE_URL = "https://plan.uz.zgora.pl"

def get_random_user_agent():
    """Zwraca losowego user-agenta."""
    return random.choice(USER_AGENTS)

def make_request(url, max_retries=3, delay=2):
    """
    Wykonuje request HTTP z obsługą błędów i ponawianiem.

    Args:
        url: URL do pobrania
        max_retries: Maksymalna liczba ponowień
        delay: Opóźnienie między ponowieniami (w sekundach)

    Returns:
        Obiekt Response lub None w przypadku błędu
    """
    headers = {
        'User-Agent': get_random_user_agent(),
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'pl,en-US;q=0.7,en;q=0.3',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
    }

    for attempt in range(max_retries):
        try:
            # Upewnij się, że URL jest prawidłowy
            if not url.startswith('http'):
                logger.warning("Naprawiono nieprawidłowy URL: %s", url)
                url = full_url(url)

            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()  # Podnosi wyjątek dla błędów HTTP
            return response
        except requests.RequestException as e:
            logger.warning("Próba %s/%s nieudana dla URL %s: %s",
                           attempt+1, max_retries, url, str(e))
            if attempt < max_retries - 1:
                # Dodanie losowego opóźnienia przed ponowieniem
                sleep_time = delay + random.uniform(0, 2)
                logger.info("Ponowienie za %.2fs...", sleep_time)
                time.sleep(sleep_time)
            else:
                logger.error("Nie udało się pobrać %s po %s próbach", url, max_retries)
                return None

    return None

def normalize_text(text):
    """Normalizuje tekst usuwając nadmiarowe białe znaki."""
    if not text:
        return ""
    # Zastąp nieistotne znaki jedną spacją
    text = re.sub(r'\s+', ' ', text)
    # Usuń białe znaki z początku i końca
    return text.strip()

def full_url(path):
    """Tworzy pełny URL na podstawie ścieżki względnej."""
    if not path:
        return ""

    # Jeśli już mamy pełny URL, zwróć go bez zmian
    if path.startswith('http'):
        return path

    # Dodaj bazowy URL przed ścieżką względną
    if path.startswith('/'):
        return BASE_URL + path
    else:
        return BASE_URL + '/' + path

def parse_datetime(date_str, time_str):
    """Parsuje datę i czas z stringa w formacie UZ."""
    # Format: DD.MM.RRRR oraz HH:MM
    day, month, year = map(int, date_str.split('.'))
    hour, minute = map(int, time_str.split(':'))

    return datetime(year, month, day, hour, minute)

def format_datetime_for_db(dt):
    """Formatuje datetime do formatu PostgreSQL."""
    return dt.strftime('%Y-%m-%d %H:%M:%S')

def extract_teacher_name_from_link(link):
    """Wyciąga nazwisko nauczyciela z linku do planu."""
    match = re.search(r'nazwisko=([^&]+)', link)
    if match:
        name = match.group(1)
        # Dekodowanie URL
        name = name.replace('+', ' ')
        return name
    return None

def get_soup_from_url(url):
    """Pobiera stronę i parsuje ją do obiektu BeautifulSoup."""
    response = make_request(url)
    if not response:
        return None

    from bs4 import BeautifulSoup
    return BeautifulSoup(response.text, 'html.parser')