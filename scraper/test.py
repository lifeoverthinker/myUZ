import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scraper.ics_updater import fetch_ics_content, parse_ics_file, BASE_URL

# Przykładowe ID grupy do testu
GRUPA_TEST_ID = "29409"
ICS_TEST_URL = f"{BASE_URL}grupy_ics.php?ID={GRUPA_TEST_ID}&KIND=GG"


def test_parsowania_ics():
    # Pobierz dane ICS
    print(f"Pobieranie danych ICS z: {ICS_TEST_URL}")
    ics_content = fetch_ics_content(ICS_TEST_URL)

    if not ics_content:
        print("Nie udało się pobrać pliku ICS!")
        return

    # Parsuj dane
    print("Parsowanie danych ICS...")
    events = parse_ics_file(ics_content, ICS_TEST_URL)

    print(f"Znaleziono {len(events)} zajęć. Wyświetlam pierwsze 10:")

    # Wyświetl pierwsze 10 zajęć
    for i, event in enumerate(events[:10]):
        print(f"\nZajęcia #{i + 1}:")
        print(f"  Przedmiot: {event['przedmiot']}")
        print(f"  Rodzaj zajęć (RZ): {event['rz']}")
        print(f"  Podgrupa: {event['podgrupa']}")
        print(f"  Nauczyciel: {event['nauczyciel']}")
        print(f"  Miejsce: {event['miejsce']}")
        print(f"  Od: {event['od']}")
        print(f"  Do: {event['do_']}")

    # Test długości pola rz
    print("\nSprawdzenie długości pola RZ dla wszystkich zajęć:")
    for event in events:
        if event['rz'] and len(event['rz']) > 10:
            print(f"UWAGA! Pole RZ za długie: '{event['rz']}' ({len(event['rz'])} znaków)")


if __name__ == "__main__":
    test_parsowania_ics()
