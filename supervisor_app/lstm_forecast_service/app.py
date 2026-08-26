"""Isolated inference API for Mihisarani's per-farmer VFA LSTM model."""

import json
import os
from pathlib import Path

import joblib
import numpy as np
import tensorflow as tf
import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, jsonify, request

MODEL_DIR = Path(__file__).parent / "model"
with (MODEL_DIR / "metadata.json").open(encoding="utf-8") as metadata_file:
    METADATA = json.load(metadata_file)

MODEL = tf.keras.models.load_model(MODEL_DIR / "vfa_lstm_multitask.keras")
SEQUENCE_SCALER = joblib.load(MODEL_DIR / "sequence_scaler.joblib")
CONTEXT_SCALER = joblib.load(MODEL_DIR / "context_scaler.joblib")
VFA_SCALER = joblib.load(MODEL_DIR / "vfa_target_scaler.joblib")

SEQUENCE_FEATURES = METADATA["sequence_features"]
CONTEXT_FEATURES = METADATA["context_features"]
FARMER_COLUMNS = METADATA["farmer_dummy_columns"]
LOOKBACK = METADATA["lookback_collection_records"]
VFA_ALERT_THRESHOLD = METADATA["vfa_alert_threshold"]
RISK_PROBABILITY_THRESHOLD = METADATA["risk_probability_threshold"]

app = Flask(__name__)


def _numeric(value, field_name):
    try:
        return float(value)
    except (TypeError, ValueError) as error:
        raise ValueError(f"{field_name} must be numeric") from error


def _feature_row(record, features, farmer_id):
    row = []
    for feature in features:
        if feature in FARMER_COLUMNS:
            row.append(1.0 if feature == f"farmer_{farmer_id}" else 0.0)
        else:
            row.append(_numeric(record.get(feature), feature))
    return row


def _risk_level(predicted_vfa, risk_probability):
    if predicted_vfa >= VFA_ALERT_THRESHOLD and risk_probability >= RISK_PROBABILITY_THRESHOLD:
        return "critical"
    if predicted_vfa >= VFA_ALERT_THRESHOLD:
        return "high"
    if risk_probability >= RISK_PROBABILITY_THRESHOLD:
        return "medium"
    return "low"


def _save_forecast(user_id, result):
    """Writes only the LSTM result document when persistence is configured."""
    service_account = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    if not service_account:
        raise RuntimeError("FIREBASE_SERVICE_ACCOUNT is not configured")
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(service_account))
    firestore.client().collection("quality_forecasts").document(user_id).set(
        {**result, "updatedAt": firestore.SERVER_TIMESTAMP}
    )


@app.get("/health")
def health():
    return jsonify({"status": "ready", "model": "vfa_lstm_multitask"})


@app.post("/forecast")
def forecast():
    """Forecast one farmer's next VFA result.

    Request body: userId, farmerId (F001--F012), sequenceRecords (30
    chronological records), context (the target-date weather/collection data),
    and optional forecastDate.
    """
    payload = request.get_json(silent=True) or {}
    user_id = str(payload.get("userId", "")).strip()
    farmer_id = str(payload.get("farmerId", "")).strip()
    records = payload.get("sequenceRecords")
    context = payload.get("context")

    if not user_id or not farmer_id:
        return jsonify({"error": "userId and farmerId are required"}), 400
    if f"farmer_{farmer_id}" not in FARMER_COLUMNS:
        return jsonify({"error": "farmerId is not supported by this trained model"}), 400
    if not isinstance(records, list) or len(records) != LOOKBACK:
        return jsonify({"error": f"sequenceRecords must contain exactly {LOOKBACK} records"}), 400
    if not isinstance(context, dict):
        return jsonify({"error": "context must be an object"}), 400

    try:
        sequence = np.asarray([_feature_row(record, SEQUENCE_FEATURES, farmer_id) for record in records], dtype=np.float32)
        context_row = np.asarray([_feature_row(context, CONTEXT_FEATURES, farmer_id)], dtype=np.float32)
    except (AttributeError, ValueError) as error:
        return jsonify({"error": str(error)}), 400

    scaled_sequence = SEQUENCE_SCALER.transform(sequence).reshape(1, LOOKBACK, len(SEQUENCE_FEATURES))
    scaled_context = CONTEXT_SCALER.transform(context_row)
    prediction = MODEL.predict({"sequence": scaled_sequence, "context": scaled_context}, verbose=0)
    risk_probability = float(prediction[0][0][0])
    predicted_vfa = float(VFA_SCALER.inverse_transform(prediction[1])[0][0])
    risk_level = _risk_level(predicted_vfa, risk_probability)

    result = {
        "userId": user_id,
        "farmerId": farmer_id,
        "forecastDate": payload.get("forecastDate"),
        "predictedVfa": predicted_vfa,
        "riskProbability": risk_probability,
        "riskLevel": risk_level,
        "alert": risk_level in {"medium", "high", "critical"},
        "thresholds": {
            "vfa": VFA_ALERT_THRESHOLD,
            "riskProbability": RISK_PROBABILITY_THRESHOLD,
        },
    }
    if payload.get("saveToFirestore") is True:
        try:
            _save_forecast(user_id, result)
        except (RuntimeError, ValueError) as error:
            return jsonify({"error": str(error)}), 500
    return jsonify(result)


if __name__ == "__main__":
    app.run(host=os.getenv("HOST", "0.0.0.0"), port=int(os.getenv("PORT", "5000")), debug=True)
