from scraper.scrapers.kierunki_scraper import scrape_kierunki
from scraper.scrapers.grupy_scraper import scrape_grupy_for_kierunki
from scraper.parsers.nauczyciel_parser import (
    parse_nauczyciele_from_group_page,
    parse_nauczyciel_details,
    fetch_page,
)
from scraper.db import (
    save_kierunki,
    save_grupy,
    save_nauczyciele,
    save_zajecia_grupy,
    save_zajecia_nauczyciela,
    get_uuid_map,
)
from scraper.downloader import download_ics_for_groups_async
from scraper.ics_updater import pobierz_plan_ics_nauczyciela, parse_ics_file


def main():
    print("ETAP 1: Pobieranie kierunków studiów...")
    kierunki = scrape_kierunki()
    save_kierunki(kierunki)
    print(f"Przetworzono {len(kierunki)} kierunków\n")

    print("ETAP 2: Pobieranie grup dla kierunków...")
    wszystkie_grupy = scrape_grupy_for_kierunki(kierunki)

    # Sekcja: Mapowanie UUID kierunków do grup (Figma: Kierunek, Wydział)
    kierunek_uuid_map = get_uuid_map("kierunki", "nazwa", "id")
    for g in wszystkie_grupy:
        # Dodaj brakujące pola kierunek_nazwa i wydzial jeśli nie istnieją
        if not g.get("kierunek_nazwa") or not g.get("wydzial"):
            # Znajdź kierunek na podstawie przekazanych danych
            kierunek = next((k for k in kierunki if k.get("nazwa")), None)
            if kierunek:
                g["kierunek_nazwa"] = kierunek.get("nazwa", "")
                g["wydzial"] = kierunek.get("wydzial", "")

        # Mapowanie UUID z case-insensitive
        key = (
            (g.get("kierunek_nazwa") or "").strip().casefold(),
            (g.get("wydzial") or "").strip().casefold()
        )
        g["kierunek_id"] = kierunek_uuid_map.get(key)

        # Usuń tymczasowe pola
        g.pop("kierunek_nazwa", None)
        g.pop("wydzial", None)

    save_grupy(wszystkie_grupy)
    print(f"Przetworzono {len(wszystkie_grupy)} grup\n")

    grupa_uuid_map = get_uuid_map("grupy", "grupa_id", "id")

    print("ETAP 3: Pobieranie nauczycieli z planów grup...")
    nauczyciele_dict = {}
    for grupa in wszystkie_grupy:
        html = fetch_page(grupa.get("link_strony_grupy"))
        nauczyciele = parse_nauczyciele_from_group_page(html, grupa_id=grupa.get("grupa_id"))
        for n in nauczyciele:
            link = n.get("link")
            if link and link not in nauczyciele_dict:
                html_n = fetch_page(link)
                details = parse_nauczyciel_details(html_n, n.get("nauczyciel_id")) if html_n else {}
                nauczyciele_dict[link] = {
                    "nazwa": n.get("nazwa"),
                    "instytut": details.get("instytut"),
                    "email": details.get("email"),
                    "link_strony_nauczyciela": link,
                    "link_ics_nauczyciela": details.get("link_ics_nauczyciela"),
                    "nauczyciel_id": n.get("nauczyciel_id"),
                }
    nauczyciele_final = list(nauczyciele_dict.values())
    save_nauczyciele(nauczyciele_final)
    print(f"Przetworzono {len(nauczyciele_final)} nauczycieli\n")

    nauczyciel_uuid_map = get_uuid_map("nauczyciele", "link_strony_nauczyciela", "id")

    print("ETAP 4: Pobieranie i zapisywanie zajęć grup...")
    wszystkie_id_grup = [g["grupa_id"] for g in wszystkie_grupy if g.get("grupa_id")]
    grupa_map = {g["grupa_id"]: g for g in wszystkie_grupy if g.get("grupa_id")}
    wyniki = download_ics_for_groups_async(wszystkie_id_grup)
    wszystkie_zajecia_grupy = []
    for w in wyniki:
        if w["status"] == "success":
            grupa_id = w["grupa_id"]
            grupa = grupa_map.get(grupa_id, {})
            zajecia = parse_ics_file(
                w["ics_content"],
                link_ics_zrodlowy=w["link_ics_zrodlowy"],
            )
            for z in zajecia:
                z["grupa_id"] = grupa_id
            wszystkie_zajecia_grupy.extend(zajecia)
            print(f"Pobrano {len(zajecia)} zajęć dla grupy {grupa_id}")
        else:
            print(f"❌ Błąd pobierania ICS: {w['link_ics_zrodlowy']}")
    save_zajecia_grupy(wszystkie_zajecia_grupy, grupa_uuid_map)
    print(f"Zapisano {len(wszystkie_zajecia_grupy)} zajęć grup\n")

    print("ETAP 5: Pobieranie i zapisywanie zajęć nauczycieli...")
    wszystkie_zajecia_nauczyciela = []
    for n in nauczyciele_final:
        link = n.get("link_ics_nauczyciela")
        nauczyciel_id = nauczyciel_uuid_map.get(n.get("link_strony_nauczyciela"))
        if not link or not nauczyciel_id:
            continue
        plan = pobierz_plan_ics_nauczyciela(nauczyciel_id)
        if plan["status"] == "success" and plan["ics_content"]:
            zajecia = parse_ics_file(plan["ics_content"], link_ics_zrodlowy=plan["link_ics_zrodlowy"])
            for z in zajecia:
                z["nauczyciel_id"] = nauczyciel_id
            wszystkie_zajecia_nauczyciela.extend(zajecia)
            print(f"Pobrano {len(zajecia)} zajęć dla nauczyciela {nauczyciel_id}")
    save_zajecia_nauczyciela(wszystkie_zajecia_nauczyciela, nauczyciel_uuid_map)
    print(f"Zapisano {len(wszystkie_zajecia_nauczyciela)} zajęć nauczycieli\n")

    print("Zakończono proces MVP.")


if __name__ == "__main__":
    main()
