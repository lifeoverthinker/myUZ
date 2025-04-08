from db import Database

def save_scraped_data(scraper_results, db: Database):
    zajecia_data = []
    for result in scraper_results:
        zajecia_data.append({
            'id': result['id'],
            'przedmiot': result['przedmiot'],
            'od': result['od'],
            'do_': result['do_'],
            'miejsce': result['miejsce'],
            'rz': result['rz'],
            'link_ics': result['link_ics'],
            'grupy': result['grupy_ids'],  # ID powiązanych grup
            'nauczyciele': result['nauczyciele_ids'],  # ID powiązanych nauczycieli
        })

    db.save_zajecia(zajecia_data)
