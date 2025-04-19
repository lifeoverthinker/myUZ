"""
<H2>Plan zajęć</H2><H2>31H-SP22</H2><H3>Historia<br />stacjonarne / pierwszego stopnia z tyt. licencjata<br />semestr letni 2024/2025</H3>
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
                    <a href="https://plan.uz.zgora.pl//grupy_ics.php?ID=29184&KIND=GG" id="idGG" target="_blank">Google</a>
                    <a href="#"  data-toggle="tooltip" data-placement="top"  data-html="true" title="Kopiuj link do schowka" onclick="copyTextToClipboard('idGG');"><i class="fa fa-copy"></i></a>
              </li>
              <li class="divider"></li>
              <li class="hz">
                    <a href="https://plan.uz.zgora.pl//grupy_ics.php?ID=29184&KIND=TB" id="idTB" target="_blank">Thunderbird</a>
                    <a href="#"  data-toggle="tooltip" data-placement="top"  data-html="true" title="Kopiuj link do schowka" onclick="copyTextToClipboard('idTB');"><i class="fa fa-copy"></i></a>
              </li>
              <li class="divider"></li>
              <li class="hz">
                    <a href="https://plan.uz.zgora.pl//grupy_ics.php?ID=29184&KIND=MS" id="idMS" target="_blank">Microsoft / Zimbra</a>
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
		<p style="margin-top: 6px; padding-top: 6px;  border-top: 1px solid #d0d0d0;"><p>Legenda: PG - Pogrupy. <a href="rodzaje_zajec.php">RZ - rodzaj zajęć</a>. <img class="classroom_icon_stand" /> - zajęcia bezpośrednie (na terenie UZ), <img class="classroom_icon_distant" /> - zajęcia prowadzone zdalnie.</p>
      </div>


<!-- -->
    <div class="tab-content">
      <div class="tab-pane fade active in" id="groups">
<!-- -->

<TABLE id="table_groups" class="table table-bordered table-condensed">
    <tr class="gray">
        <th align="center" width="2%">PG</th>
        <th align="center" width="2%">Od</th>
        <th align="center" width="2%">Do</th>
        <th width="32%">Przedmiot</th>
        <th width="2%">RZ</th>
        <th width="25%">Nauczyciel</th>
        <th width="15%">Miejsce</th>
        <th width="20%">Terminy</th>
    </tr>

          <tr class="gray" id="label_day2">
              <td colspan="8" width="100%" class="gray-day">Wtorek</td>
          </tr>

    <TR class="even day2 rzD">
        <td class="PG">&nbsp;</td>
        <td align="center">08:00</td>
        <td align="center">09:30</td>
        <td>Przedmiot do wyboru - Znaczenie gospodarki w architekturze bezpieczeństwa narodowego  <a href="https://classroom.google.com/c/NzM4NTczOTg3NzM1"><img  data-toggle="tooltip" data-placement="top"  data-html="true" src="img/link-classroom.png"  title="Google Classroom" /></a> </td>
        <td><label  data-toggle="tooltip" data-placement="top"  data-html="true" class="rz" title="Ć - Ćwiczenia">Ć</label></td>
        <td><a href="nauczyciel_plan.php?ID=37051">dr Łukasz Janeczek</a></td>
        <td><img  data-toggle="tooltip" data-placement="top"  data-html="true" title="Zajęcia bezpośrednie" class="classroom_icon_stand" /> <a href="sale_plan.php?ID=3304">117 A-20</a></td>
        <td><a href="kalendarze_lista_szczegoly.php?ID=2428">D</a></td>
    </tr>
"""

"""
Moduł do parsowania danych dotyczących grup studenckich.
"""
from bs4 import BeautifulSoup
from icalendar import Calendar
import re

from scraper.downloader import fetch_page, BASE_URL

def parse_ics(content: str, grupa_id=None) -> list[dict]:
    """Parsuje plik ICS i wydobywa wydarzenia."""
    events = []
    cal = Calendar.from_ical(content)

    for component in cal.walk():
        if component.name != "VEVENT":
            continue

        summary = component.get("SUMMARY")
        start = component.get("DTSTART").dt
        end = component.get("DTEND").dt
        location = component.get("LOCATION")
        categories = component.get("CATEGORIES", "")  # Pobierz rodzaj zajęć z CATEGORIES

        # Domyślne wartości
        przedmiot = summary
        rz = categories if categories else None  # Użyj CATEGORIES jako rodzaj zajęć
        nauczyciel = None
        pg = "CAŁY KIERUNEK"

        # Szukamy głównego nawiasu z typem zajęć (Ć, W, K, etc.)
        match = re.search(r"\(([^():]+)\):\s+(.+)", summary)
        if match:
            przedmiot = summary[:match.start()].strip()
            nauczyciel = match.group(2).strip()

        # Szukamy podgrupy PG w nawiasie, np. (PG: SN)
        pg_match = re.search(r"\(PG:\s*([^)]+)\)", summary)
        if pg_match:
            pg = pg_match.group(1).strip()
            # Ograniczenie długości podgrupy do 20 znaków
            if len(pg) > 20:
                pg = pg[:20]
            # Usuwamy ten fragment z nauczyciela
            nauczyciel = re.sub(r"\(PG:.*?\)", "", nauczyciel).strip() if nauczyciel else None

        event_data = {
            "przedmiot": przedmiot,
            "rz": rz,
            "nauczyciel": nauczyciel,
            "pg": pg,
            "od": start,
            "do_": end,
            "miejsce": location
        }

        # Dodaj grupa_id jeśli podano
        if grupa_id is not None:
            event_data["grupa_id"] = grupa_id

        events.append(event_data)

    return events

def fetch_grupa_semestr(url: str) -> str:
    """Pobiera informację o semestrze z podstrony grupy."""
    html = fetch_page(url)
    if not html:
        return "nieznany"

    soup = BeautifulSoup(html, "html.parser")
    h3_tag = soup.find('h3')

    if not h3_tag or not h3_tag.text:
        return "nieznany"

    text = h3_tag.text.lower()

    # Szukaj tylko słowa "letni" lub "zimowy"
    if "semestr letni" in text:
        return "letni"
    elif "semestr zimowy" in text:
        return "zimowy"

    return "nieznany"


def parse_grupy(html, nazwa_kierunku, wydzial, kierunek_id):
    """Parsuje grupy z HTML."""
    soup = BeautifulSoup(html, 'html.parser')
    grupy = []

    try:
        # Znajdź kod grupy z drugiego tagu H2
        h2_tags = soup.find_all("h2")
        kod_grupy_ogolny = None
        if len(h2_tags) >= 2:  # Sprawdź czy istnieje drugi tag H2
            kod_grupy_ogolny = h2_tags[1].text.strip()
        else:
            kod_grupy_ogolny = "nieznany"

        # Znajdź informację o semestrze i trybie studiów w nagłówku H3
        semestr = "nieznany"
        tryb_studiow_ogolny = "nieznany"

        h3_tags = soup.find_all("h3")
        for h3 in h3_tags:
            text = h3.text.lower()
            # Wykrywanie semestru - szukaj tylko słowa "letni" lub "zimowy"
            if "semestr letni" in text:
                semestr = "letni"
            elif "semestr zimowy" in text:
                semestr = "zimowy"

            # Wykrywanie trybu studiów
            if "stacjonarne" in text and "niestacjonarne" not in text:
                tryb_studiow_ogolny = "stacjonarne"
            elif "niestacjonarne" in text:
                tryb_studiow_ogolny = "niestacjonarne"

        # Znajdź wszystkie wiersze tabeli z linkami do grup
        rows = soup.select("tr.odd td a, tr.even td a")

        for row in rows:
            link = row.get('href')

            if not link:
                continue

            # Przygotuj pełne URL do planu grupy
            full_link = f"{BASE_URL}{link}" if link and not link.startswith('http') else link

            # Wydobycie ID grupy z linku
            grupa_id = None
            if "ID=" in link:
                try:
                    grupa_id = link.split("ID=")[1].split("&")[0]
                except (IndexError, ValueError):
                    pass

            # Generuj link do pliku ICS
            ics_link = f"{BASE_URL}grupy_ics.php?ID={grupa_id}&KIND=GG" if grupa_id else None

            if grupa_id:
                grupa = {
                    'grupa_id': grupa_id,
                    'kod_grupy': kod_grupy_ogolny,
                    'kierunek_id': kierunek_id,
                    'wydzial': wydzial,
                    'tryb_studiow': tryb_studiow_ogolny,
                    'semestr': semestr,
                    'link_grupy': full_link,
                    'link_ics_grupy': ics_link
                }
                grupy.append(grupa)

        return grupy
    except Exception as e:
        print(f"❌ Błąd parsowania grup: {e}")
        return []