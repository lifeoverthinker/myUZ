CREATE TABLE public.grupy (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  semestr character varying(255) NULL,
  tryb_studiow character varying(50) NULL,
  kierunek_id uuid NULL,
  link_planu character varying(255) NULL,
  kod_grupy character varying(50) NULL,
  CONSTRAINT grupy_pkey PRIMARY KEY (id),
  CONSTRAINT grupy_kierunek_id_fkey FOREIGN KEY (kierunek_id) REFERENCES kierunki(id)
);
CREATE INDEX IF NOT EXISTS idx_grupy_kod ON public.grupy USING btree (kod_grupy);

CREATE TABLE public.kierunki (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  nazwa_kierunku character varying(255) NULL,
  wydzial character varying(255) NULL,
  link_grupy character varying(255) NULL,
  CONSTRAINT kierunki_pkey PRIMARY KEY (id)
);

CREATE TABLE public.nauczyciele (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  imie_nazwisko character varying(255) NULL,
  instytut character varying(255) NULL,
  email character varying(255) NULL,
  link_planu character varying(255) NULL,
  CONSTRAINT nauczyciele_pkey PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_nauczyciele_nazwisko ON public.nauczyciele USING btree (imie_nazwisko);

CREATE TABLE public.plany_grup (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  grupa_id uuid NULL,
  link_ics character varying(255) NULL,
  nauczyciel_id uuid NULL,
  od timestamp without time zone NULL,
  do_ timestamp without time zone NULL,
  przedmiot character varying(255) NULL,
  rz character varying(10) NULL,
  miejsce character varying(255) NULL,
  CONSTRAINT plany_grup_pkey PRIMARY KEY (id),
  CONSTRAINT plany_grup_grupa_id_fkey FOREIGN KEY (grupa_id) REFERENCES grupy(id),
  CONSTRAINT plany_grup_nauczyciel_id_fkey FOREIGN KEY (nauczyciel_id) REFERENCES nauczyciele(id)
);
CREATE INDEX IF NOT EXISTS idx_plany_grup_nauczyciel ON public.plany_grup USING btree (nauczyciel_id);

CREATE TABLE public.plany_nauczycieli (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  nauczyciel_id uuid NULL,
  link_ics character varying(255) NULL,
  od timestamp without time zone NULL,
  do_ timestamp without time zone NULL,
  przedmiot character varying(255) NULL,
  rz character varying(10) NULL,
  grupy character varying(255) NULL,
  miejsce character varying(255) NULL,
  CONSTRAINT plany_nauczycieli_pkey PRIMARY KEY (id),
  CONSTRAINT plany_nauczycieli_nauczyciel_id_fkey FOREIGN KEY (nauczyciel_id) REFERENCES nauczyciele(id)
);

CREATE TABLE public.zajecia (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  przedmiot character varying(255) NULL,
  od timestamp without time zone NULL,
  do_ timestamp without time zone NULL,
  miejsce character varying(255) NULL,
  rz character varying(10) NULL,
  link_ics character varying(255) NULL,
  data_utworzenia timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP,
  data_aktualizacji timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT zajecia_pkey PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_zajecia_czas ON public.zajecia USING btree (od, do_);
CREATE INDEX IF NOT EXISTS idx_zajecia_miejsce ON public.zajecia USING btree (miejsce);
CREATE INDEX IF NOT EXISTS idx_zajecia_przedmiot ON public.zajecia USING btree (przedmiot);

CREATE TABLE public.zajecia_grupy (
  zajecia_id uuid NOT NULL,
  grupa_id uuid NOT NULL,
  CONSTRAINT zajecia_grupy_pkey PRIMARY KEY (zajecia_id, grupa_id),
  CONSTRAINT uniq_zajecia_grupy UNIQUE (zajecia_id, grupa_id),
  CONSTRAINT zajecia_grupy_grupa_id_fkey FOREIGN KEY (grupa_id) REFERENCES grupy(id),
  CONSTRAINT zajecia_grupy_zajecia_id_fkey FOREIGN KEY (zajecia_id) REFERENCES zajecia(id)
);
CREATE INDEX IF NOT EXISTS idx_zajecia_grupy_grupa ON public.zajecia_grupy USING btree (grupa_id);

CREATE TABLE public.zajecia_nauczyciele (
  zajecia_id uuid NOT NULL,
  nauczyciel_id uuid NOT NULL,
  CONSTRAINT zajecia_nauczyciele_pkey PRIMARY KEY (zajecia_id, nauczyciel_id),
  CONSTRAINT uniq_zajecia_nauczyciele UNIQUE (zajecia_id, nauczyciel_id),
  CONSTRAINT zajecia_nauczyciele_nauczyciel_id_fkey FOREIGN KEY (nauczyciel_id) REFERENCES nauczyciele(id),
  CONSTRAINT zajecia_nauczyciele_zajecia_id_fkey FOREIGN KEY (zajecia_id) REFERENCES zajecia(id)
);
CREATE INDEX IF NOT EXISTS idx_zajecia_nauczyciele_nauczyciel ON public.zajecia_nauczyciele USING btree (nauczyciel_id);