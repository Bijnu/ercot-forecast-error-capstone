#!/usr/bin/env python3
"""Download ERCOT hourly actual demand and day-ahead demand forecasts from EIA API v2."""

import argparse
import csv
import json
import os
import time
import urllib.parse
import urllib.request
import urllib.error
from pathlib import Path

API_URL = "https://api.eia.gov/v2/electricity/rto/region-data/data/"
FIELDS = ["period", "respondent", "respondent-name", "type", "type-name", "value", "value-units"]


def request_page(api_key: str, start: str, end: str, offset: int, length: int = 5000):
    params = [
        ("api_key", api_key),
        ("frequency", "hourly"),
        ("data[0]", "value"),
        ("facets[respondent][]", "ERCO"),
        ("facets[type][]", "D"),
        ("facets[type][]", "DF"),
        ("start", start),
        ("end", end),
        ("sort[0][column]", "period"),
        ("sort[0][direction]", "asc"),
        ("offset", str(offset)),
        ("length", str(length)),
    ]
    url = API_URL + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": "WGU-ERCOT-capstone/1.0"})
    last_error = None
    for attempt in range(7):
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                return json.load(response)["response"]
        except urllib.error.HTTPError as exc:
            last_error = exc
            if exc.code == 429 and attempt < 6:
                retry_after = int(exc.headers.get("Retry-After", "15"))
                time.sleep(min(max(retry_after, 5), 60))
                continue
            raise
        except Exception as exc:
            last_error = exc
            if attempt < 6:
                time.sleep(2**attempt)
    raise RuntimeError(f"EIA request failed after retries: {last_error}")


def download(api_key: str, first_year: int, last_year: int):
    rows = []
    for year in range(first_year, last_year + 1):
        start, end, offset = f"{year}-01-01T00", f"{year}-12-31T23", 0
        while True:
            response = request_page(api_key, start, end, offset)
            page = response.get("data", [])
            total = int(response.get("total", 0))
            rows.extend(page)
            offset += len(page)
            print(f"{year}: downloaded {offset:,} of {total:,} rows")
            if not page or offset >= total:
                break
            time.sleep(1)
    return rows


def validate(rows, first_year: int, last_year: int):
    keys = [(r.get("period"), r.get("respondent"), r.get("type")) for r in rows]
    unique_keys = set(keys)
    type_counts = {kind: sum(r.get("type") == kind for r in rows) for kind in ("D", "DF")}
    periods = sorted({r.get("period") for r in rows if r.get("period")})
    paired = {}
    for row in rows:
        paired.setdefault(row.get("period"), set()).add(row.get("type"))
    missing_pairs = sum(types != {"D", "DF"} for types in paired.values())
    unexpected = [r for r in rows if r.get("respondent") != "ERCO" or r.get("type") not in {"D", "DF"}]
    if unexpected:
        raise ValueError(f"Found {len(unexpected)} unexpected respondent/type rows")
    if periods and not (periods[0].startswith(str(first_year)) and periods[-1].startswith(str(last_year))):
        raise ValueError("Downloaded date coverage does not match requested years")
    return {
        "rows": len(rows),
        "unique_rows": len(unique_keys),
        "duplicate_keys": len(rows) - len(unique_keys),
        "actual_demand_rows": type_counts["D"],
        "forecast_rows": type_counts["DF"],
        "unique_hourly_periods": len(periods),
        "periods_missing_D_or_DF": missing_pairs,
        "first_period": periods[0] if periods else None,
        "last_period": periods[-1] if periods else None,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--api-key", default=os.environ.get("EIA_API_KEY", "DEMO_KEY"))
    parser.add_argument("--first-year", type=int, default=2021)
    parser.add_argument("--last-year", type=int, default=2025)
    parser.add_argument("--output", default="ercot_eia930_2021_2025.csv")
    args = parser.parse_args()

    rows = download(args.api_key, args.first_year, args.last_year)
    rows.sort(key=lambda r: (r.get("period", ""), r.get("type", "")))
    output = Path(args.output)
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
    summary = validate(rows, args.first_year, args.last_year)
    print(json.dumps(summary, indent=2))
    print(f"Saved {output.resolve()}")


if __name__ == "__main__":
    main()
