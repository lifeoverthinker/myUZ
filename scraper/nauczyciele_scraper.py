# Moduł do scrapowania danych o nauczycielach
import re
import time
from utils import get_soup, clean_text, normalize_url, BASE_URL, print_progress
from db import insert_nauczyciel

def extract_email(text):
    """Wyciąga adres email z tekstu"""
    if not text:
        return None

    # Prosty regex do wyciągania adresów email
    match = re.search(r'[\w\.-]+@[\w\.-]+', text)
    return match.group(0) if match else None

def scrape_nauczyciele():
    """Scrapuje listę nauczycieli z indeksu alfabetycznego"""
    print("\nRozpoczynam scrapowanie nauczycieli...")

    # URL strony z indeksem nauczycieli
    url = BASE_URL + "nauczyciele_lista.php"

    # Pobierz stronę główną z listą nauczycieli
    soup = get_soup(url)
    if not soup:
        print("Nie udało się pobrać listy nauczycieli")
        return []

    # Lista na wszystkich nauczycieli
    all_nauczyciele = []

    # Znajdź wszystkie linki alfabetyczne (A-Z)
    alphabet_links = []
    for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        alphabet_links.append(f"{url}?letter={letter}")

    total_links = len(alphabet_links)

    for i, link in enumerate(alphabet_links, 1):
        letter = link.split('=')[-1]
        print(f"\n[{i}/{total_links}] Scrapowanie nauczycieli - litera: {letter}")

        # Pobierz stronę z nauczycielami dla danej litery
        soup = get_soup(link)
        if not soup:
            print(f"Nie udało się pobrać listy nauczycieli dla litery {letter}")
            continue

        # Znajdź wszystkie wiersze w tabeli (odd i even)
        rows = soup.find_all('tr', class_=['odd', 'even'])
        total_rows = len(rows)

        if not rows:
            print(f"Nie znaleziono nauczycieli dla litery {letter}")
            continue

        for j, row in enumerate(rows, 1):
            try:
                # Znajdujemy wszystkie komórki w wierszu
                cells = row.find_all('td')

                # Sprawdzamy czy wiersz ma odpowiednią liczbę komórek
                if len(cells) < 3:
                    print_progress(j, total_rows, f"Nieprawidłowa liczba komórek w wierszu {j}")
                    continue

                # Pobieramy dane nauczyciela
                name_cell = cells[0]
                instytut_cell = cells[1]
                email_cell = cells[2]

                # Znajdź link do planu nauczyciela
                link = name_cell.find('a')
                if not link:
                    print_progress(j, total_rows, f"Brak linku dla nauczyciela w wierszu {j}")
                    continue

                imie_nazwisko = clean_text(link.get_text())
                link_href = link.get('href')

                if not link_href:
                    print_progress(j, total_rows, f"Brak href dla linku nauczyciela: {imie_nazwisko}")
                    continue

                instytut = clean_text(instytut_cell.get_text()) if instytut_cell else None
                email = extract_email(clean_text(email_cell.get_text())) if email_cell else None

                link_planu = normalize_url(link_href)

                # Dodanie nauczyciela do bazy danych
                nauczyciel_id = insert_nauczyciel(imie_nazwisko, instytut, email, link_planu)

                if nauczyciel_id:
                    # Dodaj nauczyciela do listy
                    all_nauczyciele.append({
                        'id': nauczyciel_id,
                        'imie_nazwisko': imie_nazwisko,
                        'instytut': instytut,
                        'email': email,
                        'link_planu': link_planu
                    })
                    print_progress(j, total_rows, f"Dodano nauczyciela: {imie_nazwisko}")
                else:
                    print_progress(j, total_rows, f"Nie udało się dodać nauczyciela: {imie_nazwisko}")

            except Exception as e:
                print(f"Błąd podczas przetwarzania nauczyciela: {e}")
                print_progress(j, total_rows, "Błąd przetwarzania")

        # Odczekaj chwilę przed następną literą, żeby nie przeciążyć serwera
        time.sleep(1)

    print(f"\nZakończono scrapowanie nauczycieli. Pobrano {len(all_nauczyciele)} nauczycieli.")
    return all_nauczyciele