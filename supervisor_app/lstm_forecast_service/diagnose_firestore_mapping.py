"""Read-only diagnostic for the Firebase display ID/model mapping.

It intentionally prints only the project ID, document existence, the mapping
value representation, and whether F003 is a supported model column.
"""

import argparse
import json
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore


DEFAULT_UID = "eOAqWsoazNQwpo4pMispfWY5wIh1"
MODEL_METADATA = Path(__file__).resolve().parent / "model" / "metadata.json"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--service-account", required=True, type=Path)
    parser.add_argument("--uid", default=DEFAULT_UID)
    args = parser.parse_args()

    with args.service_account.open(encoding="utf-8") as source:
        project_id = json.load(source).get("project_id")
    with MODEL_METADATA.open(encoding="utf-8") as source:
        farmer_columns = json.load(source)["farmer_dummy_columns"]
    app = firebase_admin.initialize_app(credentials.Certificate(str(args.service_account)))
    document = firestore.client(app=app).collection("users").document(args.uid).get()
    data = document.to_dict() if document.exists else {}
    mapping = data.get("displayId")
    forecast = firestore.client(app=app).collection("quality_forecasts").document(args.uid).get()
    forecast_data = forecast.to_dict() if forecast.exists else {}
    required_forecast_fields = {
        "title", "message", "reason", "recommendations", "riskLevel",
        "riskProbability", "predictedVfa", "trend", "forecastDate",
    }

    # repr makes leading/trailing whitespace and non-string types visible.
    print(f"Firebase project_id: {project_id}")
    print(f"User document exists: {document.exists}")
    print(f"displayId value: {mapping!r} (type={type(mapping).__name__})")
    print(f"farmer_F003 in FARMER_COLUMNS: {'farmer_F003' in farmer_columns}")
    print(f"Forecast document exists: {forecast.exists}")
    print(f"Forecast has all required fields: {required_forecast_fields.issubset(forecast_data)}")
    print(f"Forecast missing required fields: {sorted(required_forecast_fields - set(forecast_data))}")


if __name__ == "__main__":
    main()
