"""Run a DEMO_MODE forecast using only genuine historical training records.

This utility never fabricates a model feature.  It selects a target event from
the package's test predictions, reconstructs its 30 preceding records from the
original training CSV, and sends the target event's real context to /forecast.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import os
import sys
from datetime import date, datetime
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


SERVICE_DIR = Path(__file__).resolve().parent
METADATA_PATH = SERVICE_DIR / "model" / "metadata.json"
DEFAULT_CSV = Path(r"C:\Users\subod\Downloads\farmer_dataset_12_farmers.csv")
DEFAULT_PREDICTIONS = Path(r"C:\Users\subod\Downloads\Mihisarani_VFA_LSTM_package\test_predictions.csv")
DEMO_FARMER_ID = "F003"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a historical LSTM validation forecast.")
    parser.add_argument("--case", choices=("normal", "high"), required=True)
    parser.add_argument("--uid", default=os.getenv("DEMO_TEST_UID"), help="Firebase UID to receive the demo forecast.")
    parser.add_argument("--endpoint", default="http://127.0.0.1:5000/forecast")
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV, help="Original farmer_dataset_12_farmers.csv path.")
    parser.add_argument("--predictions", type=Path, default=DEFAULT_PREDICTIONS, help="Package test_predictions.csv path.")
    parser.add_argument("--request-out", type=Path, help="Optional path to save the exact POST JSON request.")
    return parser.parse_args()


def finite_number(value: object, field: str) -> float:
    try:
        number = float(str(value).strip())
    except (TypeError, ValueError) as error:
        raise ValueError(f"{field} is missing or non-numeric") from error
    if not math.isfinite(number):
        raise ValueError(f"{field} is not finite")
    return number


def ammonia_flag(value: object) -> float:
    text = str(value).strip().lower()
    if text in {"true", "1", "yes"}:
        return 1.0
    if text in {"false", "0", "no"}:
        return 0.0
    raise ValueError("ammonia_added is not a recognised boolean")


def parse_date(value: str) -> date:
    return datetime.strptime(value.strip()[:10], "%Y-%m-%d").date()


def model_values(row: dict[str, str], record_date: date, days_since_last: int) -> dict[str, float]:
    return {
        "vfa_value": finite_number(row.get("vfa_value"), "vfa_value"),
        "drc_value": finite_number(row.get("drc_value"), "drc_value"),
        "temperature_c": finite_number(row.get("temperature_c"), "temperature_c"),
        "humidity_percent": finite_number(row.get("humidity_percent"), "humidity_percent"),
        "rainfall_mm": finite_number(row.get("rainfall_mm"), "rainfall_mm"),
        "storage_duration_hours": finite_number(row.get("storage_duration_hours"), "storage_duration_hours"),
        "collection_gap_hours": finite_number(row.get("collection_gap_hours"), "collection_gap_hours"),
        "latex_quantity_kg": finite_number(row.get("latex_quantity_kg"), "latex_quantity_kg"),
        "ammonia_amount_ml": finite_number(row.get("ammonia_amount_ml"), "ammonia_amount_ml"),
        "tapping_hour": finite_number(row.get("tapping_hour"), "tapping_hour"),
        "ammonia_added": ammonia_flag(row.get("ammonia_added")),
        "doy_sin": math.sin(2 * math.pi * record_date.timetuple().tm_yday / 365.25),
        "doy_cos": math.cos(2 * math.pi * record_date.timetuple().tm_yday / 365.25),
        "days_since_last": float(max(1, min(14, days_since_last))),
    }


def load_rows(csv_path: Path, farmer_id: str) -> list[dict[str, str]]:
    if not csv_path.is_file():
        raise FileNotFoundError(f"Original training CSV not found: {csv_path}")
    with csv_path.open(newline="", encoding="utf-8-sig") as source:
        rows = [row for row in csv.DictReader(source) if row.get("farmer_id") == farmer_id]
    rows.sort(key=lambda row: parse_date(row["date"]))
    return rows


def select_target(predictions_path: Path, case: str) -> tuple[str, date]:
    if not predictions_path.is_file():
        raise FileNotFoundError(f"Test predictions CSV not found: {predictions_path}")
    with predictions_path.open(newline="", encoding="utf-8-sig") as source:
        predictions = list(csv.DictReader(source))

    # The demo is tied to Kamal Hewage's existing displayId. Selection metadata
    # chooses a genuine F003 validation window; the endpoint still runs the
    # actual .keras model for every command.
    farmer_id = DEMO_FARMER_ID
    candidates = [row for row in predictions if row.get("farmer_id") == farmer_id]
    if case == "normal":
        candidates = [
            row for row in candidates
            if finite_number(row["predicted_vfa"], "predicted_vfa") < 0.06
            and finite_number(row["risk_probability"], "risk_probability") < 0.28
        ]
        candidates.sort(key=lambda row: (finite_number(row["predicted_vfa"], "predicted_vfa"), finite_number(row["risk_probability"], "risk_probability")))
    else:
        candidates = [
            row for row in candidates
            if finite_number(row["predicted_vfa"], "predicted_vfa") >= 0.06
            and finite_number(row["risk_probability"], "risk_probability") >= 0.28
        ]
        candidates.sort(key=lambda row: (finite_number(row["predicted_vfa"], "predicted_vfa"), finite_number(row["risk_probability"], "risk_probability")), reverse=True)
    if not candidates:
        raise ValueError(f"No genuine {case} validation window was found for {farmer_id}")
    return farmer_id, parse_date(candidates[0]["target_date"])


def build_payload(csv_path: Path, predictions_path: Path, case: str, user_id: str) -> tuple[dict[str, object], str, date]:
    with METADATA_PATH.open(encoding="utf-8") as source:
        metadata = json.load(source)
    lookback = int(metadata["lookback_collection_records"])
    farmer_id, target_date = select_target(predictions_path, case)
    rows = load_rows(csv_path, farmer_id)
    target_index = next((index for index, row in enumerate(rows) if parse_date(row["date"]) == target_date), None)
    if target_index is None:
        raise ValueError(f"Target date {target_date} is not present in the original CSV for {farmer_id}")
    if target_index < lookback:
        raise ValueError(f"Target date {target_date} has fewer than {lookback} preceding records")

    history_rows = rows[target_index - lookback:target_index]
    target_row = rows[target_index]
    sequence_records: list[dict[str, object]] = []
    previous_date: date | None = (
        parse_date(rows[target_index - lookback - 1]["date"])
        if target_index > lookback
        else None
    )
    for row in history_rows:
        current_date = parse_date(row["date"])
        gap = 1 if previous_date is None else (current_date - previous_date).days
        record: dict[str, object] = model_values(row, current_date, gap)
        record["capturedAt"] = current_date.isoformat()
        sequence_records.append(record)
        previous_date = current_date

    target_gap = (target_date - parse_date(history_rows[-1]["date"])).days
    target_values = model_values(target_row, target_date, target_gap)
    # The backend supplies approved farmer one-hot columns itself. Confirm the
    # remaining model context fields are all present before making the request.
    farmer_columns = set(metadata["farmer_dummy_columns"])
    missing = [field for field in metadata["context_features"] if field not in farmer_columns and field not in target_values]
    if missing:
        raise ValueError(f"Cannot build complete context; missing {missing}")
    context = {
        field: target_values[field]
        for field in metadata["context_features"]
        if field not in farmer_columns
    }

    return {
        "userId": user_id,
        "sequenceRecords": sequence_records,
        "context": context,
        "forecastDate": target_date.isoformat(),
        "saveToFirestore": True,
        "demoMode": True,
        "demoCase": case,
    }, farmer_id, target_date


def post_forecast(endpoint: str, payload: dict[str, object]) -> dict[str, object]:
    request = Request(
        endpoint,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Backend returned HTTP {error.code}: {detail}") from error
    except URLError as error:
        raise RuntimeError(f"Could not reach backend at {endpoint}: {error.reason}") from error


def main() -> int:
    args = parse_args()
    if not args.uid:
        print("Set DEMO_TEST_UID or pass --uid with the Firebase test UID.", file=sys.stderr)
        return 2
    try:
        payload, required_farmer_id, target_date = build_payload(args.csv, args.predictions, args.case, args.uid)
        if args.request_out:
            args.request_out.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        print(f"DEMO_MODE: {args.case} historical validation window: {required_farmer_id}, target {target_date}")
        print(f"The Firebase user's displayId must be {required_farmer_id}.")
        result = post_forecast(args.endpoint, payload)
    except (FileNotFoundError, ValueError, RuntimeError) as error:
        print(f"Demo forecast not run: {error}", file=sys.stderr)
        return 1

    print(json.dumps({
        "predictedVfa": result.get("predictedVfa"),
        "riskProbability": result.get("riskProbability"),
        "riskLevel": result.get("riskLevel"),
        "forecastDate": result.get("forecastDate"),
        "savedToFirestore": payload["saveToFirestore"],
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
