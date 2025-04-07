from datetime import datetime
import re
from typing import List, Dict, Any

class ICSParser:
    def __init__(self):
        pass

    def parse_ics_content(self, ics_content: str) -> List[Dict[str, Any]]:
        """Parsuje zawartość pliku ICS i zwraca listę wydarzeń"""
        events = []
        current_event = None

        for line in ics_content.splitlines():
            line = line.strip()

            if line == "BEGIN:VEVENT":
                current_event = {}
            elif line == "END:VEVENT" and current_event:
                events.append(current_event)
                current_event = None
            elif current_event is not None:
                if ":" in line:
                    key, value = line.split(":", 1)

                    # Przetwarzanie daty i czasu
                    if key == "DTSTART":
                        # Format: 20250402T104000
                        dt = datetime.strptime(value, "%Y%m%dT%H%M%S")
                        current_event["od"] = dt.strftime("%H:%M:%S")
                        current_event["data"] = dt.strftime("%Y-%m-%d")
                    elif key == "DTEND":
                        dt = datetime.strptime(value, "%Y%m%dT%H%M%S")
                        current_event["do"] = dt.strftime("%H:%M:%S")
                    elif key == "UID":
                        current_event["uid"] = value
                    elif key == "SUMMARY":
                        # Przykład: "Animacja obrazu graficznego (Ć): mgr Joanna Fuczko"
                        self._parse_summary(current_event, value)
                    elif key == "LOCATION":
                        current_event["miejsce"] = value
                    elif key == "CATEGORIES":
                        current_event["typ_zajec"] = value

        return events

    @staticmethod
    def _parse_summary(event: Dict[str, Any], summary: str) -> None:
        """Parsuje pole SUMMARY i wypełnia odpowiednie pola w event"""
        # Przykład: "Animacja obrazu graficznego (Ć): mgr Joanna Fuczko"

        # Próbuje wyodrębnić przedmiot, typ zajęć i prowadzącego
        match = re.match(r"(.*?)\s*(\([^)]+\))?\s*:?\s*(.*)", summary)

        if match:
            przedmiot, typ_zajec, prowadzacy = match.groups()

            event["przedmiot"] = przedmiot.strip() if przedmiot else ""

            if typ_zajec:
                # Usunięcie nawiasów
                event["typ_zajec"] = typ_zajec.strip("() ")

            event["prowadzacy"] = prowadzacy.strip() if prowadzacy else ""
        else:
            # Jeśli nie udało się sparsować, zachowaj oryginalne SUMMARY
            event["przedmiot"] = summary