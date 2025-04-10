# Moduł do scrapowania planów zajęć
import re
import time
from tqdm import tqdm
from utils import get_soup, clean_text, normalize_url, BASE_URL, print_progress, extract_teacher_from_description
from db import insert_zajecia, link_zajecia_grupa, link_zajecia_nauczyciel, get_all_grupy, get_all_nauczyciele
from db import insert_nauczyciel, insert_grupa_zajecia, insert_nauczyciel_zajecia
from ics_parser import parse_ics_file

def get_ics_link(soup):
    """Pobiera link do pliku ICS z planu zajęć"""
    if not soup:
        return None

    # Szukamy linków do ICS (preferujemy Microsoft/Zimbra jako najbardziej standardowy format)
    links = soup.find_all('a', href=lambda href: href and 'ics.php' in href)

    if not links:
        return None

    # Priorytet dla Microsoft/Zimbra
    for link in links:
        href = link.get('href')
        if 'KIND=MS' in href:
            return normalize_url(href)

    # Jeśli nie ma Microsoft/Zimbra, bierzemy pierwszy dostępny
    return normalize_url(links[0].get('href'))

def scrape_plany_grup(grupy_lista=None, collect_teachers=True):
    """
    Scrapuje plany zajęć dla grup

    Args:
        grupy_lista: Lista grup do scrapowania
        collect_teachers: Czy zbierać informacje o nauczycielach podczas scrapowania planów
    """
    print("\nRozpoczynam scrapowanie planów zajęć grup...")

    # Jeśli nie podano listy grup, pobierz wszystkie grupy z bazy
    if not grupy_lista:
        grupy_lista = get_all_grupy()

    if not grupy_lista:
        print("Brak grup do scrapowania planów")
        return

    total_grupy = len(grupy_lista)
    processed = 0
    teachers_found = set()  # Zbiór znalezionych nauczycieli (unikalne ID)

    # Używamy tqdm dla ładnego paska postępu
    for grupa in tqdm(grupy_lista, desc="Scrapowanie planów grup", total=total_grupy):
        try:
            grupa_id = grupa['id'] if isinstance(grupa, dict) else grupa.id
            link_planu = grupa['link_planu'] if isinstance(grupa, dict) else grupa.link_planu
            kod_grupy = grupa['kod_grupy'] if isinstance(grupa, dict) else grupa.kod_grupy

            # Pobierz stronę z planem zajęć
            soup = get_soup(link_planu)
            if not soup:
                continue

            # Jeśli chcemy zbierać nauczycieli
            if collect_teachers:
                # Znajdź wszystkie linki do nauczycieli w planie zajęć
                teacher_links = soup.find_all('a', href=lambda href: href and 'nauczyciel_plan.php' in href)

                for teacher_link in teacher_links:
                    try:
                        teacher_name = clean_text(teacher_link.get_text())
                        teacher_href = teacher_link.get('href')

                        if not teacher_href:
                            continue

                        teacher_link = normalize_url(teacher_href)

                        # Pobierz stronę nauczyciela, aby zebrać więcej informacji
                        teacher_soup = get_soup(teacher_link)
                        if not teacher_soup:
                            continue

                        # Próbujemy znaleźć instytut
                        instytut = None
                        h3_tags = teacher_soup.find_all('h3')
                        for h3 in h3_tags:
                            if 'Instytut' in h3.get_text():
                                instytut = clean_text(h3.get_text())

                        # Próbujemy znaleźć email
                        email = None
                        h4_tags = teacher_soup.find_all('h4')
                        for h4 in h4_tags:
                            a_tag = h4.find('a', href=lambda href: href and 'mailto:' in href)
                            if a_tag:
                                email = a_tag.get_text().strip()

                        # Dodaj nauczyciela do bazy danych
                        teacher_id = insert_nauczyciel(teacher_name, instytut, email, teacher_link)
                        if teacher_id:
                            teachers_found.add(teacher_id)
                    except Exception as e:
                        print(f"Błąd podczas przetwarzania nauczyciela: {e}")
                        continue

            # Pobierz link do pliku ICS
            ics_link = get_ics_link(soup)
            if not ics_link:
                continue

            # Sparsuj plik ICS i pobierz zdarzenia
            events = parse_ics_file(ics_link)

            # Zapisz każde zdarzenie do bazy danych
            for event in events:
                try:
                    # Wyciągnij dane z wydarzenia
                    raw_summary = event.get('summary', '')

                    # Wyciągnij czystą nazwę przedmiotu i rodzaj zajęć z tytułu
                    przedmiot, rz = extract_subject_and_rz(raw_summary)
                    if not przedmiot:
                        przedmiot = raw_summary

                    od = event.get('dtstart', None)
                    do = event.get('dtend', None)
                    lokalizacja = event.get('location', '')
                    opis = event.get('description', '')

                    # Jeśli nie znaleźliśmy RZ z tytułu, spróbuj z CATEGORIES lub opisu
                    if not rz and 'categories' in event:
                        rz = event.get('categories')

                    if not rz:
                        rz_match = re.search(r'\bRZ:\s*([A-Za-zĆ]+)', opis)
                        if rz_match:
                            rz = rz_match.group(1)

                    # Dodaj zajęcia do bazy danych
                    zajecia_id = insert_zajecia(przedmiot, od, do, lokalizacja, rz, ics_link)

                    # Powiąż zajęcia z grupą
                    if zajecia_id:
                        link_zajecia_grupa(zajecia_id, grupa_id)

                        # Jeśli collect_teachers, spróbuj znaleźć nauczyciela w opisie lub tytule
                        if collect_teachers:
                            # Szukanie prowadzącego w formacie "Przedmiot: Prowadzący"
                            teacher_name = None
                            teacher_match = re.search(r':\s+(.+?)$', raw_summary)
                            if teacher_match:
                                teacher_name = teacher_match.group(1).strip()

                            # Alternatywnie, szukaj w opisie
                            if not teacher_name:
                                teacher_match = re.search(r'Prowadzący:\s+(.+?)(\n|$)', opis)
                                if teacher_match:
                                    teacher_name = teacher_match.group(1).strip()

                            if teacher_name:
                                teacher_id = insert_nauczyciel(teacher_name, None, None, None)
                                if teacher_id:
                                    link_zajecia_nauczyciel(zajecia_id, teacher_id)
                except Exception as e:
                    print(f"Błąd podczas przetwarzania wydarzenia dla grupy {kod_grupy}: {e}")
                    continue

            processed += 1
            # Odczekaj chwilę między żądaniami, żeby nie przeciążyć serwera
            time.sleep(0.5)

        except Exception as e:
            print(f"Błąd podczas przetwarzania planu grupy: {e}")
            continue

    print(f"\nZakończono scrapowanie planów zajęć grup. Przetworzono {processed}/{total_grupy} grup.")
    if collect_teachers:
        print(f"Znaleziono {len(teachers_found)} unikalnych nauczycieli podczas scrapowania planów.")

def extract_subject_and_rz(summary):
    """
    Wyciąga czystą nazwę przedmiotu i rodzaj zajęć z tytułu wydarzenia.
    Wyciąga dowolny tekst z nawiasów jako rodzaj zajęć.
    """
    if not summary:
        return None, None

    # Wzorzec: Nazwa przedmiotu (RZ): Prowadzący
    # lub: Nazwa przedmiotu (RZ)
    # Wyciąga dowolny tekst z nawiasów jako RZ
    match = re.search(r'^(.+?)\s*\(([^)]+)\).*$', summary)
    if match:
        subject_name = match.group(1).strip()
        rz = match.group(2).strip()
        return subject_name, rz

    # Jeśli nie znaleźliśmy dopasowania, zwracamy oryginalny tekst i None
    return summary, None

def scrape_plany_nauczycieli(nauczyciele_lista=None):
    """Scrapuje plany zajęć dla nauczycieli"""
    print("\nRozpoczynam scrapowanie planów zajęć nauczycieli...")

    # Jeśli nie podano listy nauczycieli, pobierz wszystkich nauczycieli z bazy
    if not nauczyciele_lista:
        nauczyciele_lista = get_all_nauczyciele()

    if not nauczyciele_lista:
        print("Brak nauczycieli do scrapowania planów")
        return

    total_nauczyciele = len(nauczyciele_lista)
    processed = 0

    # Używamy tqdm dla ładnego paska postępu
    for nauczyciel in tqdm(nauczyciele_lista, desc="Scrapowanie planów nauczycieli", total=total_nauczyciele):
        try:
            nauczyciel_id = nauczyciel['id'] if isinstance(nauczyciel, dict) else nauczyciel.id
            link_planu = nauczyciel['link_planu'] if isinstance(nauczyciel, dict) else nauczyciel.link_planu
            imie_nazwisko = nauczyciel['imie_nazwisko'] if isinstance(nauczyciel, dict) else nauczyciel.imie_nazwisko

            if not link_planu:
                continue

            # Pobierz stronę z planem zajęć
            soup = get_soup(link_planu)
            if not soup:
                continue

            # Pobierz link do pliku ICS
            ics_link = get_ics_link(soup)
            if not ics_link:
                continue

            # Sparsuj plik ICS i pobierz zdarzenia
            events = parse_ics_file(ics_link)

            # Zapisz każde zdarzenie do bazy danych
            for event in events:
                try:
                    # Wyciągnij dane z wydarzenia
                    przedmiot = event.get('summary', '')
                    od = event.get('dtstart', None)
                    do = event.get('dtend', None)
                    lokalizacja = event.get('location', '')
                    opis = event.get('description', '')

                    # Pobierz bezpośrednio rodzaj zajęć z wydarzenia ICS
                    rz = event.get('rz')

                    # Jeśli nie ma, próba wyciągnięcia z opisu (fallback)
                    if not rz:
                        rz_match = re.search(r'\bRZ:\s*([A-Za-zĆ]+)', opis)
                        if rz_match:
                            rz = rz_match.group(1)
                        else:
                            # Spróbuj wyciągnąć z kategorii lub podsumowania
                            if 'categories' in event:
                                rz = event['categories']
                            else:
                                # Szukanie RZ w podsumowaniu (np. "Przedmiot (W): Wykładowca")
                                rz_match = re.search(r'\(([WĆLSEP])\)', przedmiot)
                                if rz_match:
                                    rz = rz_match.group(1)

                    # Dodaj zajęcia do bazy danych
                    zajecia_id = insert_zajecia(przedmiot, od, do, lokalizacja, rz, ics_link)

                    # Powiąż zajęcia z nauczycielem
                    if zajecia_id:
                        insert_nauczyciel_zajecia(nauczyciel_id, zajecia_id)
                except Exception as e:
                    print(f"Błąd podczas przetwarzania wydarzenia dla nauczyciela {imie_nazwisko}: {e}")
                    continue

            processed += 1
            # Odczekaj chwilę między żądaniami, żeby nie przeciążyć serwera
            time.sleep(0.5)

        except Exception as e:
            print(f"Błąd podczas przetwarzania planu nauczyciela: {e}")
            continue

    print(f"\nZakończono scrapowanie planów zajęć nauczycieli. Przetworzono {processed}/{total_nauczyciele} nauczycieli.")