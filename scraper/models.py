from dataclasses import dataclass
from datetime import datetime
from typing import Optional, List


@dataclass
class Grupa:
    """Model reprezentujący grupę studencką."""
    grupa_id: str
    kod_grupy: str
    kierunek_id: str
    wydzial: str
    tryb_studiow: str
    semestr: str
    link_grupy: str
    link_ics_grupy: str

    @classmethod
    def from_dict(cls, data: dict) -> 'Grupa':
        return cls(**data)


@dataclass
class Zajecia:
    """Model reprezentujący pojedyncze zajęcia."""
    zajecia_id: Optional[int] = None
    grupa_id: Optional[str] = None
    przedmiot: Optional[str] = None
    rz: Optional[str] = None  # rodzaj zajęć (Ć, W, itp.)
    nauczyciel: Optional[str] = None
    pg: Optional[str] = None  # podgrupa
    od: Optional[datetime] = None
    do_: Optional[datetime] = None
    miejsce: Optional[str] = None

    @classmethod
    def from_dict(cls, data: dict) -> 'Zajecia':
        # Konwersja dat do odpowiedniego formatu jeśli potrzeba
        od = data.get('od')
        do_ = data.get('do_')

        if isinstance(od, str):
            od = datetime.fromisoformat(od)
        if isinstance(do_, str):
            do_ = datetime.fromisoformat(do_)

        return cls(
            zajecia_id=data.get('zajecia_id'),
            grupa_id=data.get('grupa_id'),
            przedmiot=data.get('przedmiot'),
            rz=data.get('rz'),
            nauczyciel=data.get('nauczyciel'),
            pg=data.get('pg'),
            od=od,
            do_=do_,
            miejsce=data.get('miejsce')
        )


@dataclass
class Nauczyciel:
    """Model reprezentujący nauczyciela akademickiego."""
    nauczyciel_id: str
    nazwa: str
    imie_nazwisko: Optional[str] = None
    email: Optional[str] = None
    instytut: Optional[str] = None
    link_strony_nauczyciela: Optional[str] = None
    link_plan_nauczyciela: Optional[str] = None

    @classmethod
    def from_dict(cls, data: dict) -> 'Nauczyciel':
        return cls(**data)


@dataclass
class Kierunek:
    """Model reprezentujący kierunek studiów."""
    kierunek_id: str
    nazwa: str
    wydzial: str
    link: str

    @classmethod
    def from_dict(cls, data: dict) -> 'Kierunek':
        return cls(**data)