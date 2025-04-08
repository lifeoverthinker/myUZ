import psycopg2
from psycopg2.extras import execute_values

class Database:
    def __init__(self, connection_string):
        self.connection_string = connection_string
        self.conn = psycopg2.connect(self.connection_string)
        self.conn.autocommit = True

    def save_zajecia(self, zajecia_data):
        with self.conn.cursor() as cur:
            # Zapisz zajęcia
            zajecia_values = [
                (
                    zajecia['id'],
                    zajecia['przedmiot'],
                    zajecia['od'],
                    zajecia['do_'],
                    zajecia['miejsce'],
                    zajecia['rz'],
                    zajecia['link_ics'],
                )
                for zajecia in zajecia_data
            ]
            execute_values(
                cur,
                """
                INSERT INTO public.zajecia (id, przedmiot, od, do_, miejsce, rz, link_ics)
                VALUES %s
                ON CONFLICT (id) DO UPDATE
                SET przedmiot = EXCLUDED.przedmiot,
                    od = EXCLUDED.od,
                    do_ = EXCLUDED.do_,
                    miejsce = EXCLUDED.miejsce,
                    rz = EXCLUDED.rz,
                    link_ics = EXCLUDED.link_ics;
                """,
                zajecia_values,
            )

            # Zapisz powiązania z grupami
            zajecia_grupy_values = [
                (zajecia['id'], grupa_id)
                for zajecia in zajecia_data
                for grupa_id in zajecia['grupy']
            ]
            execute_values(
                cur,
                """
                INSERT INTO public.zajecia_grupy (zajecia_id, grupa_id)
                VALUES %s
                ON CONFLICT DO NOTHING;
                """,
                zajecia_grupy_values,
            )

            # Zapisz powiązania z nauczycielami
            zajecia_nauczyciele_values = [
                (zajecia['id'], nauczyciel_id)
                for zajecia in zajecia_data
                for nauczyciel_id in zajecia['nauczyciele']
            ]
            execute_values(
                cur,
                """
                INSERT INTO public.zajecia_nauczyciele (zajecia_id, nauczyciel_id)
                VALUES %s
                ON CONFLICT DO NOTHING;
                """,
                zajecia_nauczyciele_values,
            )

    def close(self):
        self.conn.close()