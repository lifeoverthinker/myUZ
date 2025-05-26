"""
Test parsowania szczegółów nauczyciela oraz ICS dla wybranego nauczyciela.
Użycie: python -m scraper.test <nauczyciel_id>
"""

import sys
from scraper.scrapers.nauczyciel_scraper import fetch_page, parse_nauczyciel_details, get_ics_urls, parse_ics_for_nauczyciel

def print_nauczyciel_details(nauczyciel_id):
    url = f"https://plan.uz.zgora.pl/nauczyciel_plan.php?ID={nauczyciel_id}"
    html = fetch_page(url)
    if not html:
        print(f"❌ Błąd pobierania strony nauczyciela {nauczyciel_id}")
        return
    details = parse_nauczyciel_details(html, nauczyciel_id)
    print(f"\nSzczegóły nauczyciela {nauczyciel_id}:")
    for k, v in details.items():
        print(f"  {k}: {v if v is not None else '<brak>'}")

    # Dodatkowo testuj ICS
    ics_urls = get_ics_urls(nauczyciel_id)
    found_ics = False
    for sem, ics_url in ics_urls.items():
        if ics_url:
            print(f"\nPobieram ICS ({sem}): {ics_url}")
            ics_content = fetch_page(ics_url)
            if ics_content and "BEGIN:VCALENDAR" in ics_content:
                events = parse_ics_for_nauczyciel(ics_content, nauczyciel_id, details.get("imie_nazwisko", ""), semestr=sem)
                print(f"  ✔️ Znalazłem {len(events)} zajęć w ICS ({sem})")
                if events:
                    print(f"  Przykład zajęć:")
                    for k, v in events[0].items():
                        print(f"    {k}: {v}")
                found_ics = True
            else:
                print(f"  ⚠️ Brak poprawnego ICS ({sem}) lub plik uszkodzony.")
    if not found_ics:
        print("❌ Nie znaleziono żadnego poprawnego pliku ICS dla tego nauczyciela.")

def main():
    if len(sys.argv) < 2:
        print("Użycie: python -m scraper.test <nauczyciel_id>")
        sys.exit(1)
    nauczyciel_id = sys.argv[1]
    print_nauczyciel_details(nauczyciel_id)

if __name__ == "__main__":
    main()