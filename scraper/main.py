from concurrent.futures import ThreadPoolExecutor, as_completed

from scraper.scrapers.kierunki_scraper import scrape_kierunki
from scraper.scrapers.grupy_scraper import scrape_grupy_for_kierunki
from scraper.parsers.grupy_parser import parse_ics
from scraper.db import (
    save_kierunki,
    save_grupy,
    save_zajecia,
    get_uuid_map,
    save_nauczyciele
)
from scraper.downloader import download_ics_for_groups_async
from scraper.utils import zajecia_to_serializable
from scraper.parsers.nauczyciel_parser import scrape_nauczyciele_from_grupy, parse_nauczyciel_details, fetch_page
from scraper.scrapers.nauczyciel_scraper import scrape_nauczyciel_and_zajecia

def enrich_nauczyciele_with_details(nauczyciele: list[dict]) -> list[dict]:
    enriched = []
    for n in nauczyciele:
        nauczyciel_id = n.get("nauczyciel_id")
        if not nauczyciel_id:
            enriched.append(n)
            continue
        html = fetch_page(f"https://plan.uz.zgora.pl/nauczyciel_plan.php?ID={nauczyciel_id}")
        if html:
            details = parse_nauczyciel_details(html, nauczyciel_id)
            n.update(details)
        enriched.append(n)
    return enriched

def fetch_nauczyciele_and_zajecia_parallel(nauczyciele, max_workers=20):
    results = []
    nauczyciel_ids = [n.get("nauczyciel_id") for n in nauczyciele if n.get("nauczyciel_id")]
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(scrape_nauczyciel_and_zajecia, nid): nid for nid in nauczyciel_ids}
        for future in as_completed(futures):
            nid = futures[future]
            try:
                dane = future.result()
                if dane and "zajecia" in dane:
                    for z in dane["zajecia"]:
                        z["nauczyciel_id"] = nid
                    results.append(dane)
                    print(f"Pobrano {len(dane['zajecia'])} zajęć dla nauczyciela {nid}")
                else:
                    print(f"Nie udało się pobrać żadnych zajęć dla nauczyciela {nid}")
            except Exception as e:
                print(f"❌ Błąd pobierania ICS nauczyciela {nid}: {e}")
    return results

def main() -> None:
    print("ETAP 1: Pobieranie kierunków studiów...")
    kierunki = scrape_kierunki()
    save_kierunki(kierunki)
    print(f"Przetworzono {len(kierunki)} kierunków\n")
    kierunek_uuid_map = get_uuid_map("kierunki", "kierunek_id", "id")

    print("ETAP 2: Pobieranie grup dla kierunków...")
    wszystkie_grupy = scrape_grupy_for_kierunki(kierunki)
    save_grupy(wszystkie_grupy, kierunek_uuid_map)
    print(f"Przetworzono {len(wszystkie_grupy)} grup z {len(kierunki)} kierunków\n")
    grupa_uuid_map = get_uuid_map("grupy", "grupa_id", "id")

    print("ETAP 2.5: Pobieranie nauczycieli z planów grup + szczegóły")
    nauczyciele = scrape_nauczyciele_from_grupy(wszystkie_grupy)
    nauczyciele = enrich_nauczyciele_with_details(nauczyciele)
    save_nauczyciele(nauczyciele, grupa_uuid_map)
    print(f"Przetworzono {len(nauczyciele)} nauczycieli\n")
    nauczyciel_uuid_map = get_uuid_map("nauczyciele", "nauczyciel_id", "id")

    # KLUCZOWA MAPA: kod_grupy -> grupa_id
    kod_grupy_to_grupa_id = {g["kod_grupy"]: g["grupa_id"] for g in wszystkie_grupy if g.get("kod_grupy") and g.get("grupa_id")}

    print("ETAP 3: Pobieranie i zapisywanie zajęć do bazy...")
    wszystkie_grupa_ids = [grupa["grupa_id"] for grupa in wszystkie_grupy if grupa.get("grupa_id")]
    grupa_map = {g["grupa_id"]: g for g in wszystkie_grupy if g.get("grupa_id")}

    wyniki = download_ics_for_groups_async(wszystkie_grupa_ids)
    wszystkie_zajecia = []

    # Zajęcia z ICS grup
    for w in wyniki:
        if w["status"] == "success":
            grupa_id = w["grupa_id"]
            grupa = grupa_map.get(grupa_id, {})
            zajecia = parse_ics(
                w["ics_content"],
                grupa_id=grupa_id,
                ics_url=w["link_ics_zrodlowy"],
                kod_grupy=grupa.get("kod_grupy"),
                kierunek_nazwa=grupa.get("kierunek_nazwa"),
                grupa_map=grupa_map
            )
            wszystkie_zajecia.extend(zajecia)
            print(f"Pobrano {len(zajecia)} zajęć dla grupy {w['grupa_id']}")
        else:
            print(f"❌ Błąd pobierania ICS: {w['link_ics_zrodlowy']}")

    # Zajęcia z ICS nauczycieli (równolegle)
    print("ETAP 3.1: Pobieranie zajęć z ICS nauczycieli (równolegle)...")
    nauczyciel_results = fetch_nauczyciele_and_zajecia_parallel(nauczyciele, max_workers=20)
    for dane in nauczyciel_results:
        for z in dane["zajecia"]:
            # Mapowanie kod_grupy -> grupa_id (dla relacji grupowej)
            if not z.get("grupa_id") and z.get("kod_grupy"):
                z["grupa_id"] = kod_grupy_to_grupa_id.get(z["kod_grupy"])
            wszystkie_zajecia.append(z)

    print(f"Łącznie pobrano {len(wszystkie_zajecia)} zajęć.")

    wszystkie_zajecia = zajecia_to_serializable(wszystkie_zajecia)
    save_zajecia(wszystkie_zajecia, grupa_uuid_map, nauczyciel_uuid_map)
    print("Zajęcia zapisane do bazy!")
    print("\nZakończono proces testowy.")

if __name__ == "__main__":
    main()
