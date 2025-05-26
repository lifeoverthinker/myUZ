from dataclasses import dataclass
from datetime import datetime
from typing import Optional, List

@dataclass
class Kierunek:
    """Model reprezentujący kierunek studiów."""
    kierunek_id: str
    nazwa_kierunku: str
    wydzial: str
    link_strony_kierunku: str
    czy_podyplomowe: bool = False  # Dodane pole: czy to studia podyplomowe

    @classmethod
    def from_dict(cls, data: dict) -> 'Kierunek':
        return cls(**data)

@dataclass
class Grupa:
    """Model reprezentujący grupę studencką."""
    grupa_id: str
    kod_grupy: str
    kierunek_id: str
    semestr: Optional[str]
    tryb_studiow: Optional[str]
    link_grupy: str
    link_ics_grupy: Optional[str]

    @classmethod
    def from_dict(cls, data: dict) -> 'Grupa':
        return cls(**data)

@dataclass
class Nauczyciel:
    """Model reprezentujący nauczyciela akademickiego."""
    nauczyciel_id: str
    nauczyciel_nazwa: Optional[str] = None
    instytut: Optional[str] = None
    email: Optional[str] = None
    link_plan_nauczyciela: Optional[str] = None
    link_strony_nauczyciela: Optional[str] = None

    @classmethod
    def from_dict(cls, data: dict) -> 'Nauczyciel':
        return cls(**data)

@dataclass
class Zajecia:
    """Model reprezentujący pojedyncze zajęcia."""
    zajecia_id: Optional[str] = None
    przedmiot: Optional[str] = None
    od: Optional[datetime] = None
    do_: Optional[datetime] = None
    miejsce: Optional[str] = None
    rz: Optional[str] = None  # rodzaj zajęć
    link_ics_zrodlowy: Optional[str] = None
    podgrupa: Optional[str] = None
    uid: Optional[str] = None
    source_type: Optional[str] = None
    nauczyciel_nazwa: Optional[str] = None
    kod_grupy: Optional[str] = None
    kierunek_nazwa: Optional[str] = None
    grupa_id: Optional[str] = None
    nauczyciel_id: Optional[str] = None

    @classmethod
    def from_dict(cls, data: dict) -> 'Zajecia':
        # Konwersja dat do odpowiedniego formatu jeśli potrzeba
        od = data.get('od')
        do_ = data.get('do_')
        if isinstance(od, str):
            od = datetime.fromisoformat(od)
        if isinstance(do_, str):
            do_ = datetime.fromisoformat(do_)
        data = dict(data)
        data['od'] = od
        data['do_'] = do_
        return cls(**data)