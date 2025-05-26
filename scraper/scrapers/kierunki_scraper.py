from bs4 import BeautifulSoup
from scraper.models import Kierunek
from scraper.downloader import fetch_page, BASE_URL

def scrape_kierunki() -> list:
    """
    Pobiera i zwraca listę kierunków studiów z głównej strony planu.
    """
    URL = BASE_URL + "grupy_lista_kierunkow.php"
    print(f"🔍 Pobieram dane z: {URL}")
    html = fetch_page(URL)
    if not html:
        print("❌ Nie udało się pobrać strony z listą kierunków.")
        return []
    return parse_departments_and_courses(html)

def parse_departments_and_courses(html: str) -> list:
    """
    Parsuje HTML z listą wydziałów i kierunków.
    """
    soup = BeautifulSoup(html, "html.parser")
    container = soup.find("div", class_="container main")
    if not container:
        print("❌ Nie znaleziono głównego kontenera.")
        return []
    kierunki = []
    current_wydzial = None
    for element in container.find_all("li", class_="lista-grup-item"):
        # Wydział: li posiada pod-ul z kierunkami
        sub_ul = element.find("ul", class_="lista-grup")
        if sub_ul:
            current_wydzial = element.contents[0].strip()
            continue
        # Kierunek: li posiada anchor z ID
        anchor = element.find("a", href=True)
        if not anchor or "ID=" not in anchor['href']:
            continue
        kierunek_id = anchor['href'].split("ID=")[1].split("&")[0]
        nazwa_kierunku = anchor.text.strip()
        pelny_link = BASE_URL + anchor['href'] if not anchor['href'].startswith("http") else anchor['href']
        # Oznacz studia podyplomowe (ID ujemne lub w linku/nazwie)
        czy_podyplomowe = False
        if kierunek_id.startswith("-") or anchor.find("b") or "podyplomowe" in nazwa_kierunku.lower():
            czy_podyplomowe = True
        kierunek = Kierunek(
            kierunek_id=kierunek_id,
            nazwa_kierunku=nazwa_kierunku,
            wydzial=current_wydzial,
            link_strony_kierunku=pelny_link,
            czy_podyplomowe=czy_podyplomowe
        )
        print(f"📌 Dodano kierunek: {nazwa_kierunku} ({current_wydzial}){' [STUDIA PODYPLOMOWE]' if czy_podyplomowe else ''}")
        kierunki.append(kierunek)
    return kierunki
