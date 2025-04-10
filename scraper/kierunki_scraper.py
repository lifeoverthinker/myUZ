# Moduł do pobierania danych o kierunkach studiów
from utils import get_soup, clean_text, normalize_url, BASE_URL, print_progress
from db import insert_kierunek

def scrape_kierunki():
    """Scrapuje listę kierunków studiów z hierarchią wydziałów."""
    print("Rozpoczynam scrapowanie kierunków studiów...")
    url = BASE_URL + "grupy_lista_kierunkow.php"

    soup = get_soup(url)
    if not soup:
        print("Nie udało się pobrać listy kierunków")
        return []

    kierunki = []

    # Znajdujemy wszystkie linki do kierunków
    all_links = soup.find_all('a', href=lambda href: href and 'grupy_lista_grup_kierunku.php?ID=' in href)

    print(f"Znaleziono {len(all_links)} linków do kierunków")
    total_links = len(all_links)

    for i, link in enumerate(all_links, 1):
        try:
            nazwa_kierunku = clean_text(link.get_text())
            link_href = link.get('href')

            if not link_href:
                print_progress(i, total_links, f"Brak href dla kierunku: {nazwa_kierunku}")
                continue

            link_grupy = normalize_url(link_href)

            # Próba określenia wydziału
            wydzial_element = link.find_parent('ul', class_='list-group')
            if wydzial_element and wydzial_element.find_parent('li', class_='list-group-item'):
                parent_li = wydzial_element.find_parent('li', class_='list-group-item')
                # Wyciągamy tekst z rodzica, ale usuwamy tekst z linków kierunków
                wydzial_text = clean_text(parent_li.get_text())
                for a_tag in parent_li.find_all('a'):
                    a_text = clean_text(a_tag.get_text())
                    wydzial_text = wydzial_text.replace(a_text, '')
                wydzial_text = clean_text(wydzial_text)
            else:
                wydzial_text = "Nieznany Wydział"

            # Dodaj kierunek do bazy danych
            kierunek_id = insert_kierunek(nazwa_kierunku, wydzial_text, link_grupy)

            if kierunek_id:
                kierunki.append({
                    'id': kierunek_id,
                    'nazwa': nazwa_kierunku,
                    'wydzial': wydzial_text,
                    'link_grupy': link_grupy
                })
                print_progress(i, total_links, f"Dodano kierunek: {nazwa_kierunku} ({wydzial_text})")
            else:
                print_progress(i, total_links, f"Nie udało się dodać kierunku: {nazwa_kierunku}")

        except Exception as e:
            print(f"Błąd podczas przetwarzania kierunku: {e}")
            print_progress(i, total_links, "Błąd przetwarzania kierunku")

    print(f"\nZakończono scrapowanie kierunków studiów. Pobrano {len(kierunki)} kierunków.")
    return kierunki