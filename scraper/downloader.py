# Pobieranie plików .ics
import requests

def download_ics(url: str) -> bytes:
    response = requests.get(url)
    response.raise_for_status()

    if response.text.strip().startswith("<!DOCTYPE HTML>"):
        raise ValueError("URL nie zwraca pliku ICS, tylko HTML — prawdopodobnie zły link.")

    return response.content
