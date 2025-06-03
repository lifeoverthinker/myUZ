CREATE TABLE public.grupy (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  kod_grupy character varying(50) NOT NULL,
  kierunek_id uuid NOT NULL,
  link_strony_grupy character varying(255) NULL,
  link_ics_grupy character varying(255) NULL,
  tryb_studiow character varying(50) NOT NULL,
  grupa_id text NULL,
  CONSTRAINT grupy_pkey PRIMARY KEY (id),
  CONSTRAINT grupy_kierunek_id_fkey FOREIGN KEY (kierunek_id) REFERENCES kierunki(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS uniq_grupy_kod ON public.grupy USING btree (kod_grupy, kierunek_id);

CREATE TABLE public.kierunki (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  nazwa character varying(255) NOT NULL,
  wydzial character varying(255) NOT NULL,
  CONSTRAINT kierunki_pkey PRIMARY KEY (id),
  CONSTRAINT uniq_kierunki_nazwa_wydzial UNIQUE (nazwa, wydzial)
);

CREATE TABLE public.nauczyciele (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  nazwa character varying(255) NOT NULL,
  instytut character varying(255) NULL,
  email character varying(255) NULL,
  link_strony_nauczyciela character varying(255) NULL,
  link_ics_nauczyciela character varying(255) NULL,
  CONSTRAINT nauczyciele_pkey PRIMARY KEY (id),
  CONSTRAINT uniq_nauczyciele_link UNIQUE (link_strony_nauczyciela)
);

CREATE TABLE public.zajecia_grupy (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  uid character varying(255) NOT NULL,
  podgrupa character varying(20) NULL,
  od timestamp without time zone NOT NULL,
  do_ timestamp without time zone NOT NULL,
  przedmiot character varying(255) NOT NULL,
  rz character varying(10) NULL,
  nauczyciel character varying(255) NULL,
  miejsce character varying(255) NULL,
  grupa_id uuid NOT NULL,
  link_ics_zrodlowy character varying(255) NULL,
  CONSTRAINT zajecia_grupy_pkey PRIMARY KEY (id),
  CONSTRAINT zajecia_grupy_grupa_id_fkey FOREIGN KEY (grupa_id) REFERENCES grupy(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS uniq_zajecia_grupy_uid ON public.zajecia_grupy USING btree (uid, grupa_id);

CREATE TABLE public.zajecia_nauczyciela (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  uid character varying(255) NOT NULL,
  od timestamp without time zone NOT NULL,
  do_ timestamp without time zone NOT NULL,
  przedmiot character varying(255) NOT NULL,
  rz character varying(10) NULL,
  grupy character varying(255) NULL,
  miejsce character varying(255) NULL,
  nauczyciel_id uuid NOT NULL,
  link_ics_zrodlowy character varying(255) NULL,
  CONSTRAINT zajecia_nauczyciela_pkey PRIMARY KEY (id),
  CONSTRAINT zajecia_nauczyciela_nauczyciel_id_fkey FOREIGN KEY (nauczyciel_id) REFERENCES nauczyciele(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS uniq_zajecia_nauczyciela_uid ON public.zajecia_nauczyciela USING btree (uid, nauczyciel_id);