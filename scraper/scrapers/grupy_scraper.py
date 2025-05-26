from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor, as_completed
from scraper.downloader import fetch_page, BASE_URL
from scraper.parsers.grupy_parser import parsuj_html_grupa

try:
    from tqdm import tqdm
except ImportError:
    def tqdm(iterable, **kwargs):
        return iterable

def find_semester_ics_links(html_grupy, allow_fallback_gg=True):
    """
    Zwraca listę krotek (link_ics, semestr), gdzie semestr to "letni", "zimowy" lub None.
    Jeśli allow_fallback_gg=True, dopuszcza link bez &S=, ale TYLKO gdy nie ma żadnego semestralnego.
    """
    soup = BeautifulSoup(html_grupy, "html.parser")
    links = []
    # Najpierw zbierz semestralne linki
    for a in soup.find_all('a', href=True):
        href = a['href']
        if 'grupy_ics.php' in href and ('&S=0' in href or '&S=1' in href):
            full_link = href if href.startswith('http') else BASE_URL + href.lstrip('/')
            # Spróbuj znaleźć semestr
            semestr = None
            parent_li = a.find_parent('li')
            if parent_li:
                header = parent_li.find_previous('li', class_="dropdown-header")
                if header and "letni" in header.text.lower():
                    semestr = "letni"
                elif header and "zimowy" in header.text.lower():
                    semestr = "zimowy"
            if not semestr:
                if '&S=0' in href:
                    semestr = "letni"
                elif '&S=1' in href:
                    semestr = "zimowy"
            links.append((full_link, semestr))
    # Jeśli nie znalazłeś żadnego semestralnego, użyj fallback tylko GG (bez &S=)
    if allow_fallback_gg and not links:
        for a in soup.find_all('a', href=True):
            href = a['href']
            if 'grupy_ics.php' in href and '&KIND=GG' in href and '&S=' not in href:
                full_link = href if href.startswith('http') else BASE_URL + href.lstrip('/')
                links.append((full_link, None)) # None = nieznany semestr
                print("⚠️ Tymczasowy fallback: dodano link ICS bez S=0/S=1 (tylko GG), do usunięcia w przyszłości!")
                break
    return links


def parse_grupa_with_fetch(link, nazwa_kierunku, wydzial, kierunek_id):
    html_grupy = fetch_page(link)
    if not html_grupy:
        return []
    szczegoly = parsuj_html_grupa(html_grupy)
    kod_grupy = szczegoly.get('kod_grupy', '')
    tryb_studiow = szczegoly.get('tryb_studiow')
    sem_ics_links = find_semester_ics_links(html_grupy)
    if not sem_ics_links:
        return []

    # WYCIĄGNIJ grupa_id Z LINKU!
    import re
    m = re.search(r'ID=(\d+)', link)
    grupa_id = m.group(1) if m else None

    grupy = []
    for ics_link, semestr in sem_ics_links:
        if kod_grupy and (semestr in ("letni", "zimowy") or semestr is None):
            grupy.append({
                'grupa_id': grupa_id,  # <-- DODANE!
                'kod_grupy': kod_grupy,
                'kierunek_id': kierunek_id,
                'semestr': semestr,
                'tryb_studiow': tryb_studiow,
                'link_grupy': link,
                'link_ics_grupy': ics_link,
                'kierunek_nazwa': nazwa_kierunku
            })
    return grupy

def parse_grupy(html, nazwa_kierunku, wydzial, kierunek_id, max_workers=10):
    soup = BeautifulSoup(html, 'html.parser')
    table = soup.find("table", class_="table-bordered")
    if not table:
        print(f"⚠️ Brak grup na stronie kierunku: {nazwa_kierunku}")
        return []
    all_links = []
    for row in table.find_all("tr"):
        td = row.find("td")
        if not td:
            continue
        a = td.find("a")
        if not a:
            continue
        grupa_href = a.get("href")
        if not grupa_href:
            continue
        full_link = f"{BASE_URL}{grupa_href}" if not grupa_href.startswith('http') else grupa_href
        all_links.append(full_link)
    grupy = []
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = [
            executor.submit(parse_grupa_with_fetch, link, nazwa_kierunku, wydzial, kierunek_id)
            for link in all_links
        ]
        for future in tqdm(as_completed(futures), total=len(futures), desc="Grupy"):
            grupy.extend(future.result())
    return grupy

def remove_duplicates(grupy):
    seen = set()
    unique = []
    for g in grupy:
        key = (g['kod_grupy'], g['kierunek_id'], g['semestr'])
        if key not in seen:
            unique.append(g)
            seen.add(key)
    return unique

def scrape_grupy_for_kierunki(kierunki, verbose=True, max_workers=10):
    wszystkie_grupy = []
    for kierunek in tqdm(kierunki, desc="Kierunki"):
        if verbose:
            print(f"Pobieram grupy dla kierunku: {getattr(kierunek, 'nazwa_kierunku', None) or kierunek.get('nazwa_kierunku')}")
        link_kierunku = getattr(kierunek, 'link_strony_kierunku', None) or kierunek.get('link_strony_kierunku')
        wydzial = getattr(kierunek, 'wydzial', None) or kierunek.get('wydzial')
        nazwa_kierunku = getattr(kierunek, 'nazwa_kierunku', None) or kierunek.get('nazwa_kierunku')
        kierunek_id = getattr(kierunek, 'kierunek_id', None) or kierunek.get('kierunek_id') or kierunek.get('id')
        if not link_kierunku:
            continue
        html = fetch_page(link_kierunku)
        if not html:
            continue
        grupy = parse_grupy(html, nazwa_kierunku, wydzial, kierunek_id, max_workers=max_workers)
        wszystkie_grupy.extend(grupy)
    if verbose:
        print(f"Znaleziono łącznie {len(wszystkie_grupy)} grup")
    wszystkie_grupy = remove_duplicates(wszystkie_grupy)
    return wszystkie_grupy