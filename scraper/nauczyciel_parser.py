"""
<H2>Plan zajęć</H2><H2>dr Łukasz Janeczek</H2><H3>Instytut Historii</H3><H4><a href="mailto:l.janeczek@ih.uz.zgora.pl">l.janeczek@ih.uz.zgora.pl</a></H4>
<!-- Nav tabs -->
    <ul class="nav nav-tabs" role="tablist">
      <li class="active">
          <a href="#groups" role="tab" data-toggle="tab">
              Tygodniowy
          </a>
      </li>
      <li><a href="#details" role="tab" data-toggle="tab">
              Szczegółowy
          </a>
      </li>

        <li class="pull-right dropdown">
            <a class="btn btn-success dropdown-toggle" style="margin-top: 4px;"  data-toggle="dropdown" href="#">Pobierz kalendarz (ICS) <span class="caret"></span></a>
            <ul class="dropdown-menu">

              <li class="hz">
                    <a href="https://plan.uz.zgora.pl//nauczyciel_ics.php?ID=37051&KIND=GG" id="idGG" target="_blank">Google</a>
                    <a href="#"  data-toggle="tooltip" data-placement="top"  data-html="true" title="Kopiuj link do schowka" onclick="copyTextToClipboard('idGG');"><i class="fa fa-copy"></i></a>
              </li>
              <li class="divider"></li>
              <li class="hz">
                    <a href="https://plan.uz.zgora.pl//nauczyciel_ics.php?ID=37051&KIND=TB" id="idTB" target="_blank">Thunderbird</a>
                    <a href="#"  data-toggle="tooltip" data-placement="top"  data-html="true" title="Kopiuj link do schowka" onclick="copyTextToClipboard('idTB');"><i class="fa fa-copy"></i></a>
              </li>
              <li class="divider"></li>
              <li class="hz">
                    <a href="https://plan.uz.zgora.pl//nauczyciel_ics.php?ID=37051&KIND=MS" id="idMS" target="_blank">Microsoft / Zimbra</a>
                    <a href="#"  data-toggle="tooltip" data-placement="top"  data-html="true" title="Kopiuj link do schowka" onclick="copyTextToClipboard('idMS');"><i class="fa fa-copy"></i></a>
              </li>
            </ul>
        </li>
    </ul>
	  <div id="filter_div" class="filter_div">
		<b>Filtr: </b>
        <div class="label_main">
			<div class="label">
				<label> Tydzień <input type="checkbox" id="week" name="week" checked onclick="clickWeek()" />: </label>
				<label> <input type="checkbox" id="day1" name="day1" checked onclick="applyFilters()" /> Po </label>
				<label> <input type="checkbox" id="day2" name="day2" checked onclick="applyFilters()" /> Wt </label>
				<label> <input type="checkbox" id="day3" name="day3" checked onclick="applyFilters()" /> Śr </label>
				<label> <input type="checkbox" id="day4" name="day4" checked onclick="applyFilters()" /> Cz </label>
				<label> <input type="checkbox" id="day5" name="day5" checked onclick="applyFilters()" /> Pi </label>
			</div>
			<div class="label">
				<label> Weekend <input type="checkbox" id="weekend" name="weekend" checked onclick="clickWeekEnd()" />: </label>
				<label> <input type="checkbox" id="day6" name="day6" checked onclick="applyFilters()" /> So </label>
				<label> <input type="checkbox" id="day7" name="day7" checked onclick="applyFilters()" /> Ni </label>
			</div>
			<div class="label">
				<label> Nieregularne (Nr) <input type="checkbox" id="dayn" name="dayn" checked onclick="applyFilters()" /> </label>
			</div>
			<div class="label">
				<label> RZ: </label>
				<label> <input type="checkbox" id="rzD" name="rzD" checked onclick="applyFilters()" /> Dydaktyczne </label>
				<label> <input type="checkbox" id="rzR" name="rzR" checked onclick="applyFilters()" /> Rezerwacje </label>
				<label> <input type="checkbox" id="rzE" name="rzE" checked onclick="applyFilters()" /> Egzaminy </label>
			</div>

        </div>
		<p style="margin-top: 6px; padding-top: 6px;  border-top: 1px solid #d0d0d0;"><p>Legenda: <a href="rodzaje_zajec.php">RZ - rodzaj zajęć</a>; jeżeli w rodzaju zajęć pojawi się symbol [X] oznacza to, że osoba uczestniczy w zajęciach jako słuchacz.  <br />
<img class="classroom_icon_stand" /> - zajęcia bezpośrednie (na terenie UZ), <img class="classroom_icon_distant" /> - zajęcia prowadzone zdalnie.</p>
      </div>


<!-- -->
    <div class="tab-content">
      <div class="tab-pane fade active in" id="groups">
<!-- -->

<TABLE id="table_groups" class="table table-bordered table-condensed">
    <tr class="gray">
        <th align="center" width="3%">Od</th>
        <th align="center" width="3%">Do</th>
        <th width="32%">Przedmiot</th>
        <th width="2%">RZ</th>
        <th width="25%">Grupy</th>
        <th width="15%">Miejsce</th>
        <th width="20%">Terminy</th>
    </tr>

          <tr class="gray" id="label_day1">
              <td colspan="7" width="100%" class="gray-day">Poniedziałek</td>
          </tr>

    <TR class="even day1 rzD">
        <td align="center">09:45</td>
        <td align="center">11:15</td>
        <td>Historia regionalna - XIX wiek  <a href="https://classroom.google.com/c/NzY0NzUzNDAwMjg2"><img  data-toggle="tooltip" data-placement="top"  data-html="true" src="img/link-classroom.png"  title="Google Classroom" /></a> </td>
        <td><label  data-toggle="tooltip" data-placement="top"  data-html="true" class="rz" title="Ć - Ćwiczenia">Ć</label></td>
        <td><a href="grupy_plan.php?ID=29183">21H-SP23</a></td>
        <td><img  data-toggle="tooltip" data-placement="top"  data-html="true" title="Zajęcia bezpośrednie" class="classroom_icon_stand" /> <a href="sale_plan.php?ID=3089">217 A-16</a></td>
        <td><a href="kalendarze_lista_szczegoly.php?ID=2428">D</a></td>
    </tr>

          <tr class="gray" id="label_day2">
              <td colspan="7" width="100%" class="gray-day">Wtorek</td>
          </tr>
"""

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


def parse_nauczyciele_from_group_page(html: str, grupa_id: str = None) -> list[dict]:
    """Parsuje HTML planu zajęć grupy i wyodrębnia linki do stron nauczycieli."""
    soup = BeautifulSoup(html, "html.parser")
    wynik = []
    znalezieni_nauczyciele = set()  # Zbiór do unikania duplikatów

    # Znajdź wszystkie linki do nauczycieli
    nauczyciel_links = soup.find_all("a", href=lambda href: href and "nauczyciel_plan.php?ID=" in href)

    for link in nauczyciel_links:
        nauczyciel_url = BASE_URL + link["href"]
        nauczyciel_id = link["href"].split("ID=")[1] if "ID=" in link["href"] else None
        nauczyciel_name = link.get_text(strip=True)

        # Sprawdź czy nauczyciel był już dodany
        if nauczyciel_url not in znalezieni_nauczyciele:
            znalezieni_nauczyciele.add(nauczyciel_url)

            nauczyciel_data = {
                "nazwa": nauczyciel_name,
                "link": nauczyciel_url,
                "nauczyciel_id": nauczyciel_id
            }

            # Dodaj ID grupy, jeśli istnieje
            if grupa_id:
                nauczyciel_data["grupa_id"] = grupa_id

            wynik.append(nauczyciel_data)
            print(f"🧑‍🏫 Znaleziono nauczyciela: {nauczyciel_name}")

    return wynik


def parse_nauczyciel_details(html: str) -> dict:
    """Parsuje stronę nauczyciela, aby wydobyć dodatkowe informacje."""
    soup = BeautifulSoup(html, "html.parser")
    dane = {}

    # Imię i nazwisko
    name_tag = soup.find("h2", string=lambda s: s and "Plan zajęć" not in s)
    if name_tag:
        pelne_imie = name_tag.get_text(strip=True)
        dane["pelne_imie"] = pelne_imie

        # Próba wyodrębnienia tytułu, imienia i nazwiska
        parts = pelne_imie.split()
        if len(parts) >= 2:
            # Zakładamy, że ostatni element to nazwisko
            dane["nazwisko"] = parts[-1]

            # Jeśli jest więcej elementów, pierwszy może być imieniem lub tytułem
            if len(parts) > 2:
                dane["tytul"] = ' '.join(parts[:-2])
                dane["imie"] = parts[-2]
            else:
                dane["imie"] = parts[0]

    # Wydział/Instytut
    instytut_tag = soup.find("h3")
    if instytut_tag:
        dane["instytut"] = instytut_tag.get_text(strip=True)

    # Email
    email_tag = soup.find("a", href=lambda href: href and "mailto:" in href)
    if email_tag:
        dane["email"] = email_tag.get_text(strip=True)

    # Link do ICS
    ics_link = soup.find("a", href=lambda href: href and "nauczyciel_ics.php" in href)
    if ics_link:
        dane["link_ics_nauczyciela"] = BASE_URL + ics_link["href"]

    return dane


def fetch_and_parse_nauczyciel(nauczyciel_data: dict) -> dict:
    """Pobiera i parsuje stronę nauczyciela, uzupełniając dane."""
    link = nauczyciel_data["link"]
    html = fetch_page(link)

    if not html:
        print(f"❌ Nie udało się pobrać strony nauczyciela: {nauczyciel_data['nazwa']}")
        return nauczyciel_data

    szczegoly = parse_nauczyciel_details(html)

    # Połącz dane
    return {**nauczyciel_data, **szczegoly}


def scrape_nauczyciele_from_grupy(grupy: list[dict]) -> list[dict]:
    """Scrapuje nauczycieli z planów zajęć podanych grup."""
    wszystkie_linki_nauczycieli = []
    wszyscy_nauczyciele = []

    # Zbiór do przechowywania już znalezionych nauczycieli
    znalezieni_nauczyciele = set()

    for i, grupa in enumerate(grupy):
        kod_grupy = grupa['kod_grupy']
        link_grupy = grupa['link_strona_grupy']  # Link do planu zajęć w HTML
        grupa_id = grupa.get('grupa_id') or grupa.get('id')

        print(f"\n🔎 [{i + 1}/{len(grupy)}] Pobieram nauczycieli dla grupy: {kod_grupy}")
        html = fetch_page(link_grupy)

        if html:
            nauczyciele = parse_nauczyciele_from_group_page(html, grupa_id)
            wszystkie_linki_nauczycieli.extend(nauczyciele)
            print(f"✅ Znaleziono {len(nauczyciele)} nauczycieli w grupie {kod_grupy}")

    print(f"\n🔍 Znaleziono {len(wszystkie_linki_nauczycieli)} łącznie nauczycieli, pobieram szczegóły...")

    # Pobierz szczegóły każdego nauczyciela
    for i, n in enumerate(wszystkie_linki_nauczycieli):
        # Sprawdź czy nauczyciel jest już w zbiorze znalezionych
        if n["nauczyciel_id"] not in znalezieni_nauczyciele:
            znalezieni_nauczyciele.add(n["nauczyciel_id"])

            print(f"🧪 [{i + 1}/{len(wszystkie_linki_nauczycieli)}] Pobieram szczegóły nauczyciela: {n['nazwa']}")
            nauczyciel_z_szczegolami = fetch_and_parse_nauczyciel(n)
            wszyscy_nauczyciele.append(nauczyciel_z_szczegolami)

    return wszyscy_nauczyciele


if __name__ == "__main__":
    # Dla samodzielnego testowania
    from kierunki_scraper import scrape_kierunki
    from grupy_scraper import scrape_grupy_for_kierunki

    kierunki = scrape_kierunki()
    # Testujemy tylko na kilku pierwszych kierunkach
    grupy = scrape_grupy_for_kierunki(kierunki[:1])
    # Testujemy tylko na kilku pierwszych grupach
    nauczyciele = scrape_nauczyciele_from_grupy(grupy[:3])

    print(f"\nPobrano {len(nauczyciele)} nauczycieli.")
    for n in nauczyciele:
        print(f"Nauczyciel: {n.get('pelne_imie', n.get('nazwa'))}, Email: {n.get('email', 'brak')}")
