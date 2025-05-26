CREATE TABLE public.grupy (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  semestr character varying(255) NULL,
  tryb_studiow character varying(50) NULL,
  kierunek_id uuid NULL,
  link_grupy character varying(255) NULL,
  kod_grupy character varying(50) NULL,
  link_ics_grupy character varying(255) NULL,
  grupa_id character varying(50) NULL,
  CONSTRAINT grupy_pkey PRIMARY KEY (id),
  CONSTRAINT uniq_grupa UNIQUE (kod_grupy, kierunek_id),
  CONSTRAINT grupy_kierunek_id_fkey FOREIGN KEY (kierunek_id) REFERENCES kierunki(id)
);
CREATE UNIQUE INDEX IF NOT EXISTS uniq_grupa_id ON public.grupy USING btree (grupa_id);

CREATE TABLE public.kierunki (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  nazwa_kierunku character varying(255) NULL,
  wydzial character varying(255) NULL,
  link_strony_kierunku character varying(255) NULL,
  kierunek_id character varying(50) NULL,
  czy_podyplomowe boolean NULL,
  CONSTRAINT kierunki_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;
CREATE UNIQUE INDEX IF NOT EXISTS uniq_kierunek_id ON public.kierunki USING btree (kierunek_id) TABLESPACE pg_default;

CREATE TABLE public.nauczyciele (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  nauczyciel_nazwa character varying(255) NULL,
  instytut character varying(255) NULL,
  email character varying(255) NULL,
  link_plan_nauczyciela character varying(255) NULL,
  link_strony_nauczyciela character varying(255) NULL,
  nauczyciel_id character varying(50) NULL,
  CONSTRAINT nauczyciele_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;
CREATE UNIQUE INDEX IF NOT EXISTS uniq_nauczyciel_id ON public.nauczyciele USING btree (nauczyciel_id) TABLESPACE pg_default;

CREATE TABLE public.nauczyciele_grupy (
  nauczyciel_id uuid NOT NULL,
  grupa_id uuid NOT NULL,
  CONSTRAINT nauczyciele_grupy_pkey PRIMARY KEY (nauczyciel_id, grupa_id),
  CONSTRAINT nauczyciele_grupy_grupa_id_fkey FOREIGN KEY (grupa_id) REFERENCES grupy(id),
  CONSTRAINT nauczyciele_grupy_nauczyciel_id_fkey FOREIGN KEY (nauczyciel_id) REFERENCES nauczyciele(id)
) TABLESPACE pg_default;

CREATE TABLE public.zajecia (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  przedmiot text NULL,
  od timestamp without time zone NULL,
  do_ timestamp without time zone NULL,
  miejsce character varying(255) NULL,
  rz character varying(10) NULL,
  link_ics_zrodlowy character varying(255) NULL,
  data_utworzenia timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP,
  data_aktualizacji timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP,
  podgrupa character varying(20) NULL,
  uid character varying(255) NULL,
  source_type text NULL,
  nauczyciel_nazwa character varying(255) NULL,
  kod_grupy character varying(50) NULL,
  kierunek_nazwa character varying(255) NULL,
  grupa_id uuid NULL,
  nauczyciel_id uuid NULL,
  CONSTRAINT zajecia_pkey PRIMARY KEY (id),
  CONSTRAINT zajecia_grupa_id_fkey FOREIGN KEY (grupa_id) REFERENCES grupy(id),
  CONSTRAINT zajecia_nauczyciel_id_fkey FOREIGN KEY (nauczyciel_id) REFERENCES nauczyciele(id)
);
CREATE UNIQUE INDEX IF NOT EXISTS uniq_uid ON public.zajecia USING btree (uid);

CREATE TABLE public.zajecia_grupy (
  zajecia_id uuid NOT NULL,
  grupa_id uuid NOT NULL,
  CONSTRAINT zajecia_grupy_pkey PRIMARY KEY (zajecia_id, grupa_id),
  CONSTRAINT zajecia_grupy_grupa_id_fkey FOREIGN KEY (grupa_id) REFERENCES grupy(id),
  CONSTRAINT zajecia_grupy_zajecia_id_fkey FOREIGN KEY (zajecia_id) REFERENCES zajecia(id)
) TABLESPACE pg_default;

CREATE TABLE public.zajecia_nauczyciele (
  zajecia_id uuid NOT NULL,
  nauczyciel_id uuid NOT NULL,
  CONSTRAINT zajecia_nauczyciele_pkey PRIMARY KEY (zajecia_id, nauczyciel_id),
  CONSTRAINT zajecia_nauczyciele_nauczyciel_id_fkey FOREIGN KEY (nauczyciel_id) REFERENCES nauczyciele(id),
  CONSTRAINT zajecia_nauczyciele_zajecia_id_fkey FOREIGN KEY (zajecia_id) REFERENCES zajecia(id)
) TABLESPACE pg_default;

CREATE VIEW public.plany_grup_view AS
SELECT z.id,
       z.przedmiot,
       z.od,
       z.do_,
       z.miejsce,
       z.rz,
       z.podgrupa,
       g.id AS grupa_id,
       g.kod_grupy,
       k.nazwa_kierunku AS kierunek_nazwa,
       string_agg(DISTINCT n.nauczyciel_nazwa::text, ', '::text) AS nauczyciele_lista
FROM zajecia z
JOIN zajecia_grupy zg ON z.id = zg.zajecia_id
JOIN grupy g ON zg.grupa_id = g.id
JOIN kierunki k ON g.kierunek_id = k.id
LEFT JOIN zajecia_nauczyciele zn ON z.id = zn.zajecia_id
LEFT JOIN nauczyciele n ON zn.nauczyciel_id = n.id
GROUP BY z.id, z.przedmiot, z.od, z.do_, z.miejsce, z.rz, z.podgrupa, g.id, g.kod_grupy, k.nazwa_kierunku;

CREATE VIEW public.plany_nauczycieli_view AS
SELECT z.id,
       z.przedmiot,
       z.od,
       z.do_,
       z.miejsce,
       z.rz,
       z.podgrupa,
       n.id AS nauczyciel_id,
       n.nauczyciel_nazwa,
       string_agg(DISTINCT g.kod_grupy::text, ', '::text) AS kody_grup,
       string_agg(DISTINCT k.nazwa_kierunku::text, ', '::text) AS kierunki_nazwy
FROM zajecia z
JOIN zajecia_nauczyciele zn ON z.id = zn.zajecia_id
JOIN nauczyciele n ON zn.nauczyciel_id = n.id
LEFT JOIN zajecia_grupy zg ON z.id = zg.zajecia_id
LEFT JOIN grupy g ON zg.grupa_id = g.id
LEFT JOIN kierunki k ON g.kierunek_id = k.id
GROUP BY z.id, z.przedmiot, z.od, z.do_, z.miejsce, z.rz, z.podgrupa, n.id, n.nauczyciel_nazwa;