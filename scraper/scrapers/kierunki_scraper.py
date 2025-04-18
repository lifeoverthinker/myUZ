import requests
from bs4 import BeautifulSoup

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


def parse_departments_and_courses(html: str) -> list[dict]:
    """
    Parsuje HTML i wyodrębnia wydziały oraz kierunki.
    """
    soup = BeautifulSoup(html, "html.parser")
    wynik = []

    main_container = soup.find("div", class_="container main")
    if not main_container:
        print("❌ Nie znaleziono głównego kontenera.")
        return wynik

    wydzialy_items = main_container.find_all("li", class_="list-group-item")
    wydzial = None

    for item in wydzialy_items:
        item_text = item.get_text(strip=True)

        # Jeśli to nagłówek wydziału
        if ("Wydział" in item_text or "Szkoły" in item_text) and not item.find("a", recursive=False):
            # Pobierz tylko pierwszy węzeł tekstowy, bez zagnieżdżonych elementów
            text_nodes = [n for n in item.contents if isinstance(n, str)]
            if text_nodes:
                wydzial = text_nodes[0].strip()
            else:
                wydzial = item_text.split()[0]

            print(f"\n🔎 Wydział: {wydzial}\n")

        # Jeśli to kierunek i mamy aktywny wydział
        elif item.find("a") and wydzial:
            a_tag = item.find("a")
            kierunek = a_tag.get_text(strip=True)
            link = BASE_URL + a_tag["href"]

            # Pomiń studia podyplomowe
            if "Studia podyplomowe" not in kierunek:
                wynik.append({
                    "wydzial": wydzial,
                    "nazwa_kierunku": kierunek,
                    "link_kierunku": link
                })
                print(f"📌 Dodano kierunek: {kierunek}")

    return wynik


def scrape_kierunki() -> list[dict]:
    """Scrapuje kierunki i wydziały."""
    url = BASE_URL + "grupy_lista_kierunkow.php"
    print(f"🔍 Pobieram dane z: {url}")
    html = fetch_page(url)

    if not html:
        print("❌ Nie udało się pobrać strony.")
        return []

    return parse_departments_and_courses(html)


if __name__ == "__main__":
    kierunki = scrape_kierunki()
    print(f"\nPobrano {len(kierunki)} kierunków.")