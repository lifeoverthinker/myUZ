# Moduł do scrapowania grup studentów
import re
from utils import get_soup, clean_text, normalize_url, BASE_URL, print_progress
from db import insert_grupa, get_all_kierunki

def extract_grupa_info(text):
    """Wyciąga informacje o grupie z jej nazwy"""
    # Przykładowy format: "21AW-SP Architektura wnętrz / stacjonarne / pierwszego stopnia z tyt. licencjata"
    kod_grupy = None
    tryb_studiow = None

    # Wyciągnięcie kodu grupy (pierwsza część tekstu do spacji)
    if text:
        parts = text.strip().split(' ', 1)
        if len(parts) > 0:
            kod_grupy = parts[0].strip()

        # Wyciągnięcie trybu studiów
        tryb_match = re.search(r'\s/\s(stacjonarne|niestacjonarne)\s/', text)
        if tryb_match:
            tryb_studiow = tryb_match.group(1).strip()

    return kod_grupy, tryb_studiow

def extract_semester_from_plan(soup):
    """Wyciąga informację o semestrze z nagłówka strony planu zajęć"""
    if not soup:
        return None

    # Szukamy nagłówka H3, który zawiera informację o semestrze
    h3_tags = soup.find_all('h3')
    for h3 in h3_tags:
        text = clean_text(h3.get_text())
        # Szukamy informacji o semestrze
        if 'semestr' in text.lower():
            semester_match = re.search(r'semestr\s+(letni|zimowy)', text.lower())
            if semester_match:
                return semester_match.group(1)

    # Jeśli nie znaleziono w H3, szukamy również w innych elementach
    body_text = clean_text(soup.get_text())
    semester_match = re.search(r'semestr\s+(letni|zimowy)', body_text.lower())
    if semester_match:
        return semester_match.group(1)

    return None

def scrape_grupy(kierunki_lista=None):
    """Scrapuje grupy dla podanych kierunków"""
    print("\nRozpoczynam scrapowanie grup...")

    # Jeśli nie podano listy kierunków, pobierz wszystkie kierunki z bazy
    if not kierunki_lista:
        kierunki_lista = get_all_kierunki()

    if not kierunki_lista:
        print("Brak kierunków do scrapowania grup")
        return []

    total_kierunki = len(kierunki_lista)
    all_grupy = []

    for i, kierunek in enumerate(kierunki_lista, 1):
        kierunek_id = kierunek['id'] if isinstance(kierunek, dict) else kierunek.id
        link_grupy = kierunek['link_grupy'] if isinstance(kierunek, dict) else kierunek.link_grupy
        nazwa_kierunku = kierunek['nazwa'] if isinstance(kierunek, dict) and 'nazwa' in kierunek else (
            kierunek['nazwa_kierunku'] if isinstance(kierunek, dict) else kierunek.nazwa_kierunku
        )

        print(f"\n[{i}/{total_kierunki}] Scrapowanie grup dla kierunku: {nazwa_kierunku}")

        # Pobierz stronę z listą grup dla kierunku
        soup = get_soup(link_grupy)
        if not soup:
            print(f"Nie udało się pobrać listy grup dla kierunku: {nazwa_kierunku}")
            continue

        # Znajdujemy wszystkie wiersze w tabeli (odd i even)
        rows = soup.find_all('tr', class_=['odd', 'even'])
        total_grupy = len(rows)

        if not rows:
            print(f"Nie znaleziono grup dla kierunku: {nazwa_kierunku}")
            continue

        for j, row in enumerate(rows, 1):
            try:
                # Znajdź link do planu grupy
                link = row.find('a')
                if not link:
                    print_progress(j, total_grupy, f"Brak linku dla wiersza {j}")
                    continue

                text = clean_text(link.get_text())
                link_href = link.get('href')

                if not link_href:
                    print_progress(j, total_grupy, f"Brak href dla linku: {text}")
                    continue

                # Wyciągnięcie podstawowych informacji o grupie
                kod_grupy, tryb_studiow = extract_grupa_info(text)
                link_planu = normalize_url(link_href)

                # Pobierz stronę z planem grupy, aby wyodrębnić semestr
                plan_soup = get_soup(link_planu)
                semestr = extract_semester_from_plan(plan_soup)

                # Dodanie grupy do bazy danych
                grupa_id = insert_grupa(kod_grupy, tryb_studiow, semestr, kierunek_id, link_planu)

                if grupa_id:
                    # Dodaj grupę do listy
                    all_grupy.append({
                        'id': grupa_id,
                        'kod_grupy': kod_grupy,
                        'tryb_studiow': tryb_studiow,
                        'semestr': semestr,
                        'kierunek_id': kierunek_id,
                        'link_planu': link_planu
                    })
                    print_progress(j, total_grupy, f"Dodano grupę: {kod_grupy}, semestr: {semestr or 'nieznany'}")
                else:
                    print_progress(j, total_grupy, f"Nie udało się dodać grupy: {kod_grupy}")

            except Exception as e:
                print(f"Błąd podczas przetwarzania grupy: {e}")
                print_progress(j, total_grupy, f"Błąd przetwarzania")

    print(f"\nZakończono scrapowanie grup. Pobrano {len(all_grupy)} grup.")
    return all_grupy