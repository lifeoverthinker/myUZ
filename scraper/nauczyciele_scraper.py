import re
from tqdm import tqdm
from .utils import get_soup, clean_text, normalize_url, print_progress
from .db import get_all_grupy, insert_nauczyciel

def scrape_nauczyciele():
    """
    Zbiera informacje o nauczycielach z planów grup zamiast nieistniejącej centralnej listy
    """
    print("\n=== Scrapowanie nauczycieli ===")
    print("Rozpoczynam zbieranie informacji o nauczycielach z planów grup...")

    # Pobierz grupy z bazy danych
    grupy = get_all_grupy()
    if not grupy:
        print("Nie znaleziono żadnych grup w bazie danych")
        return []

    nauczyciele_dict = {}  # Używamy słownika, aby uniknąć duplikatów

    for grupa in tqdm(grupy, desc="Zbieranie nauczycieli z planów grup"):
        try:
            # Pobierz link do planu grupy
            link_planu = grupa['link_planu'] if isinstance(grupa, dict) else grupa.link_planu

            # Pobierz stronę z planem
            soup = get_soup(link_planu)
            if not soup:
                continue

            # Znajdź wszystkie linki do nauczycieli na stronie
            teacher_links = soup.find_all('a', href=lambda href: href and 'nauczyciel_plan.php?ID=' in href)

            for link in teacher_links:
                try:
                    # Wyciągnij dane nauczyciela
                    name = clean_text(link.get_text())
                    href = link.get('href')

                    # Wyciągnij ID nauczyciela z URL
                    id_match = re.search(r'ID=(\d+)', href)
                    if not id_match:
                        continue

                    teacher_id = id_match.group(1)
                    full_url = normalize_url(href)

                    # Jeśli już mamy tego nauczyciela, pomijamy
                    if teacher_id in nauczyciele_dict:
                        continue

                    # Dodaj nauczyciela do słownika
                    nauczyciele_dict[teacher_id] = {
                        'id': teacher_id,
                        'imie_nazwisko': name,
                        'link_planu': full_url,
                        'instytut': None,
                        'email': None
                    }

                    # Opcjonalnie: pobierz dodatkowe informacje z profilu nauczyciela
                    teacher_soup = get_soup(full_url)
                    if teacher_soup:
                        # Próba pobrania instytutu
                        h3 = teacher_soup.find('h3')
                        if h3:
                            nauczyciele_dict[teacher_id]['instytut'] = clean_text(h3.get_text())

                        # Próba pobrania emaila
                        email_link = teacher_soup.find('a', href=lambda href: href and 'mailto:' in href)
                        if email_link:
                            nauczyciele_dict[teacher_id]['email'] = clean_text(email_link.get_text())

                    # Zapisz nauczyciela w bazie danych
                    insert_nauczyciel(
                        nauczyciele_dict[teacher_id]['imie_nazwisko'],
                        nauczyciele_dict[teacher_id]['instytut'],
                        nauczyciele_dict[teacher_id]['email'],
                        nauczyciele_dict[teacher_id]['link_planu']
                    )

                except Exception as e:
                    print(f"Błąd przy przetwarzaniu nauczyciela: {e}")

        except Exception as e:
            print(f"Błąd przy przetwarzaniu grupy: {e}")

    nauczyciele_lista = list(nauczyciele_dict.values())
    print(f"Zakończono zbieranie informacji o nauczycielach. Znaleziono {len(nauczyciele_lista)} nauczycieli.")
    return nauczyciele_lista