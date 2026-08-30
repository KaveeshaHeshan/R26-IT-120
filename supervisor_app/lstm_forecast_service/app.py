"""Isolated inference API for Mihisarani's per-farmer VFA LSTM model."""

import json
import os
from datetime import datetime
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


def _missing_numeric_fields(record, features, prefix):
    """Returns every missing/non-numeric model input without imputing data."""
    missing = []
    if not isinstance(record, dict):
        return [f"{prefix} (must be an object)"]
    for feature in features:
        if feature in FARMER_COLUMNS:
            continue
        value = record.get(feature)
        try:
            float(value)
        except (TypeError, ValueError):
            missing.append(f"{prefix}.{feature}")
    return missing


def _record_time(record):
    value = record.get("capturedAt", record.get("date")) if isinstance(record, dict) else None
    if not isinstance(value, str) or not value.strip():
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def _prepare_history(records):
    """Keeps only valid, dated records and selects the most recent lookback."""
    if not isinstance(records, list):
        return None, ["sequenceRecords (must be a list)"], 0
    valid_records = []
    invalid_fields = []
    for index, record in enumerate(records):
        missing = _missing_numeric_fields(record, SEQUENCE_FEATURES, f"sequenceRecords[{index}]")
        captured_at = _record_time(record)
        if captured_at is None:
            missing.append(f"sequenceRecords[{index}].capturedAt")
        if missing:
            invalid_fields.extend(missing)
        else:
            valid_records.append((captured_at, record))
    valid_records.sort(key=lambda item: item[0])
    return [record for _, record in valid_records[-LOOKBACK:]], invalid_fields, len(valid_records)


def _missing_context_fields(context, forecast_date):
    missing = _missing_numeric_fields(context, CONTEXT_FEATURES, "context")
    if not isinstance(forecast_date, str) or not forecast_date.strip():
        missing.append("forecastDate")
    return missing


def _risk_level(predicted_vfa, risk_probability):
    if predicted_vfa >= VFA_ALERT_THRESHOLD and risk_probability >= RISK_PROBABILITY_THRESHOLD:
        return "critical"
    if predicted_vfa >= VFA_ALERT_THRESHOLD:
        return "high"
    if risk_probability >= RISK_PROBABILITY_THRESHOLD:
        return "medium"
    return "normal"


def _recent_trend(records, field_name):
    """Describes an observed sequence trend; it never claims model attribution."""
    values = [float(record[field_name]) for record in records]
    window = min(5, len(values) // 2)
    earlier = float(np.mean(values[-2 * window:-window]))
    recent = float(np.mean(values[-window:]))
    tolerance = max(abs(earlier) * 0.02, 0.0001)
    if recent > earlier + tolerance:
        direction = "increased"
    elif recent < earlier - tolerance:
        direction = "decreased"
    else:
        direction = "remained stable"
    return direction, earlier, recent


def _numeric_deviations(records, context):
    """Reports observed context deviations, not causal explanations."""
    candidates = (
        "temperature_c",
        "humidity_percent",
        "rainfall_mm",
        "storage_duration_hours",
        "collection_gap_hours",
        "latex_quantity_kg",
        "ammonia_amount_ml",
        "tapping_hour",
        "ammonia_added",
        "days_since_last",
    )
    observations = []
    for feature in candidates:
        history = [float(record[feature]) for record in records]
        baseline = float(np.mean(history[-5:]))
        current = float(context[feature])
        tolerance = max(abs(baseline) * 0.20, 0.0001)
        if abs(current - baseline) > tolerance:
            direction = "above" if current > baseline else "below"
            observations.append(
                f"The submitted {feature} for this forecast ({current:.2f}) is {direction} "
                f"the recent submitted average ({baseline:.2f})."
            )
    return observations[:2]


def _farmer_guidance(predicted_vfa, risk_probability, risk_level, records, context):
    """Creates short, non-technical guidance for the farmer dashboard."""
    vfa_trend, _, _ = _recent_trend(records, "vfa_value")

    if risk_level == "normal":
        return (
            "Rubber Quality Stable",
            (
                "Your current quality trend is stable. Continue your normal collection and storage practices."
                if vfa_trend == "remained stable"
                else "Your forecast remains below the configured quality-risk thresholds."
            ),
            "The forecast is below both configured safety thresholds.",
            ["Continue your normal collection and storage practices.", "Record the next quality measurement on schedule."],
            "stable" if vfa_trend == "remained stable" else vfa_trend,
        )

    if risk_level in {"critical", "high"}:
        return (
            "Critical Rubber Quality Risk",
            "Your latex may lose quality before the next collection.",
            "The predicted freshness level is above the safe limit.",
            ["Arrange collection as soon as possible.", "Keep the latex covered and follow your normal storage procedure."],
            "increasing" if vfa_trend == "increased" else vfa_trend,
        )

    return (
        "Rubber Quality Warning",
        "Your latex quality may decline before the next collection.",
        "The predicted quality risk is higher than normal.",
        ["Review the next collection time.", "Keep the latex covered and follow your normal storage procedure."],
        "increasing" if vfa_trend == "increased" else vfa_trend,
    )


def _firestore_client():
    """Uses a trusted Admin SDK identity; client-provided mappings are ignored."""
    service_account = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    if not service_account:
        raise RuntimeError("FIREBASE_SERVICE_ACCOUNT is not configured")
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(service_account))
    return firestore.client()


def _model_farmer_id_for_user(user_id):
    """Uses the existing farmer display ID after validating model support."""
    user = _firestore_client().collection("users").document(user_id).get()
    display_id = user.to_dict().get("displayId") if user.exists else None
    if display_id is None:
        return None
    farmer_id = str(display_id).strip()
    if f"farmer_{farmer_id}" not in FARMER_COLUMNS:
        return None
    return farmer_id


def _save_forecast(user_id, result):
    """Writes only the LSTM result document when persistence is configured."""
    _firestore_client().collection("quality_forecasts").document(user_id).set(
        {**result, "updatedAt": firestore.SERVER_TIMESTAMP}
    )


@app.get("/health")
def health():
    return jsonify({"status": "ready", "model": "vfa_lstm_multitask"})


@app.post("/forecast")
def forecast():
    """Forecast one farmer's next VFA result.

    Request body: userId, sequenceRecords (chronological records), context
    (the target-date weather/collection data), and optional forecastDate.
    The approved model farmer identity is read from users/{userId}, never from
    the request body.
    """
    payload = request.get_json(silent=True) or {}
    user_id = str(payload.get("userId", "")).strip()
    records = payload.get("sequenceRecords")
    context = payload.get("context")
    forecast_date = payload.get("forecastDate")

    if not user_id:
        return jsonify({"error": "userId is required"}), 400
    try:
        farmer_id = _model_farmer_id_for_user(user_id)
    except RuntimeError as error:
        return jsonify({"error": "model_deployment_limitation", "message": str(error)}), 422
    if farmer_id is None:
        return jsonify({
            "error": "model_deployment_limitation",
            "message": "The user's displayId is missing or unsupported. This trained model supports only farmer IDs F001 through F012.",
            "supportedFarmerIds": [column.removeprefix("farmer_") for column in FARMER_COLUMNS],
        }), 422

    # Historical-validation calls are deliberately marked in server logs only.
    # Nothing in this branch changes the farmer-facing forecast document/text.
    if payload.get("demoMode") is True:
        app.logger.warning(
            "DEMO_MODE historical validation request: userId=%s displayId=%s case=%s",
            user_id,
            farmer_id,
            payload.get("demoCase", "unspecified"),
        )

    history, invalid_history_fields, valid_history_count = _prepare_history(records)
    if valid_history_count < LOOKBACK:
        return jsonify({
            "error": "insufficient_history",
            "message": f"Prediction was not run. At least {LOOKBACK} valid chronological records are required; {valid_history_count} are available.",
            "validRecordCount": valid_history_count,
            "invalidFields": invalid_history_fields,
        }), 422

    missing_fields = _missing_context_fields(context, forecast_date)
    if missing_fields:
        return jsonify({
            "error": "prediction_data_incomplete",
            "message": "Prediction was not run. Supply every listed field with a genuine numeric value; no values were imputed.",
            "missingFields": missing_fields,
        }), 422

    sequence = np.asarray([_feature_row(record, SEQUENCE_FEATURES, farmer_id) for record in history], dtype=np.float32)
    context_row = np.asarray([_feature_row(context, CONTEXT_FEATURES, farmer_id)], dtype=np.float32)

    scaled_sequence = SEQUENCE_SCALER.transform(sequence).reshape(1, LOOKBACK, len(SEQUENCE_FEATURES))
    scaled_context = CONTEXT_SCALER.transform(context_row)
    prediction = MODEL.predict({"sequence": scaled_sequence, "context": scaled_context}, verbose=0)
    # This saved multi-output Keras model returns named outputs. Use their
    # names rather than positional indexes so the risk and VFA heads cannot be
    # swapped or fail with KeyError when TensorFlow returns a dictionary.
    if isinstance(prediction, dict):
        risk_output = prediction["risk"]
        vfa_output = prediction["vfa"]
    else:
        risk_output, vfa_output = prediction
    risk_probability = float(np.asarray(risk_output).reshape(-1)[0])
    predicted_vfa = float(VFA_SCALER.inverse_transform(np.asarray(vfa_output).reshape(-1, 1))[0][0])
    risk_level = _risk_level(predicted_vfa, risk_probability)
    title, message, reason, recommendations, trend = _farmer_guidance(
        predicted_vfa,
        risk_probability,
        risk_level,
        history,
        context,
    )

    if payload.get("demoMode") is True:
        app.logger.warning(
            "DEMO_MODE historical validation result: userId=%s displayId=%s predictedVfa=%.6f riskProbability=%.6f riskLevel=%s",
            user_id,
            farmer_id,
            predicted_vfa,
            risk_probability,
            risk_level,
        )

    result = {
        "predictedVfa": predicted_vfa,
        "riskProbability": risk_probability,
        "riskLevel": risk_level,
        "trend": trend,
        "reason": reason,
        "recommendations": recommendations,
        "forecastDate": forecast_date,
        # These two fields are farmer-facing text generated from the validated
        # values above, rather than generated by Flutter.
        "title": title,
        "message": message,
        "userId": user_id,
        "farmerId": farmer_id,
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
