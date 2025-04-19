from scraper.downloader import fetch_page
from scraper.parsers.grupy_parser import parse_grupy
from scraper.models import Grupa


def test_grupa_parsing():
    # URL do testowania
    url = "https://plan.uz.zgora.pl/grupy_plan.php?ID=29041"

    # Pobierz stronę
    html = fetch_page(url)

    if not html:
        print("❌ Nie udało się pobrać strony")
        return

    # Testowe wartości dla pozostałych parametrów
    nazwa_kierunku = "Test kierunek"
    wydzial = "Test wydział"
    kierunek_id = "test_id"

    # Parsowanie grupy
    grupy = parse_grupy(html, nazwa_kierunku, wydzial, kierunek_id)

    if not grupy:
        print("❌ Nie znaleziono żadnych grup")
        return

    # Wyświetlenie wyników (teraz używamy atrybutów obiektu)
    grupa = grupy[0]
    print("\n📊 Wyniki parsowania:")
    print(f"• Kod grupy: {grupa.kod_grupy}")
    print(f"• Semestr: {grupa.semestr}")
    print(f"• Tryb studiów: {grupa.tryb_studiow}")
    print(f"• Grupa ID: {grupa.grupa_id}")
    print(f"• Link ICS: {grupa.link_ics_grupy}")


if __name__ == "__main__":
    test_grupa_parsing()