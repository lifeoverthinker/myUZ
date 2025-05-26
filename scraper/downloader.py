import aiohttp
import asyncio
import time

from scraper.utils import fetch_page

BASE_URL = "https://plan.uz.zgora.pl/"

async def fetch_ics_with_fallback(session: aiohttp.ClientSession, grupa_id: str, max_retries: int = 3) -> dict:
    """
    Próbuj pobrać ICS dla grupy w kolejności:
    1. ...&S=0 (zimowy)
    2. ...&S=1 (letni)
    3. bez &S (aktualny lub ogólny)
    Zwraca dict: {'status', 'ics_content', 'link_ics_zrodlowy', 'grupa_id'}
    """
    urls = [
        f"{BASE_URL}grupy_ics.php?ID={grupa_id}&KIND=GG&S=0",
        f"{BASE_URL}grupy_ics.php?ID={grupa_id}&KIND=GG&S=1",
        f"{BASE_URL}grupy_ics.php?ID={grupa_id}&KIND=GG"
    ]
    for url in urls:
        for attempt in range(max_retries):
            try:
                async with session.get(url, timeout=15) as resp:
                    if resp.status == 200:
                        text = await resp.text()
                        if text.strip().startswith("BEGIN:VCALENDAR"):
                            return {
                                'status': 'success',
                                'ics_content': text,
                                'link_ics_zrodlowy': url,
                                'grupa_id': grupa_id
                            }
                        else:
                            break  # To nie jest plik ICS
                    elif resp.status == 404:
                        break  # przejdź do kolejnego url
                    else:
                        await asyncio.sleep(1)
            except Exception as e:
                if attempt < max_retries - 1:
                    await asyncio.sleep(1)
                else:
                    continue
    # Jeśli żaden nie istnieje:
    return {
        'status': 'not_found',
        'ics_content': None,
        'link_ics_zrodlowy': urls[-1],
        'grupa_id': grupa_id
    }

async def fetch_all_ics(grupa_ids: list[str], max_concurrent: int = 20) -> list[dict]:
    """
    Asynchronicznie pobiera ICSy dla wszystkich grup.
    """
    results = []
    sema = asyncio.Semaphore(max_concurrent)
    async with aiohttp.ClientSession() as session:
        async def limited_fetch(grupa_id):
            async with sema:
                return await fetch_ics_with_fallback(session, grupa_id)
        tasks = [limited_fetch(grupa_id) for grupa_id in grupa_ids]
        for fut in asyncio.as_completed(tasks):
            result = await fut
            results.append(result)
    return results

def download_ics_for_groups_async(grupa_ids: list[str]) -> list[dict]:
    """
    Wywołuje asynchroniczny fetch dla wszystkich grup.
    """
    return asyncio.run(fetch_all_ics(grupa_ids))
