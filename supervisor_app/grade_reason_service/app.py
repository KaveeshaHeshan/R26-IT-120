"""
Grade-C Reason Service  (Flask REST API)
-----------------------------------------
Answers "why is this latex Grade C?" using the Isolation Forest anomaly
model trained in Colab on three sensor readings: pH, temperature_c,
turbidity_ntu (see model/scaler.pkl -> feature_names_in_).

The model itself only says normal / anomaly (+ a continuous anomaly
score). The *reason* shown to the farmer/supervisor is built on top of
that, from each feature's z-score against the scaler's training mean/std
-- the same "compare against a known-good baseline" approach already
used in lstm_forecast_service/app.py's _farmer_guidance().

Endpoints
    GET  /health          -> quick check that the model loaded
    POST /grade-reason     -> one sensor reading -> is_anomaly, reason text

NOTE: this model does not take VFA as an input feature (only pH,
temperature, turbidity were used to train it). VFA and grade are
accepted in the request and echoed back for context/logging, but they
do not affect the anomaly prediction. If VFA should factor into the
reason, it needs to be added as a fourth training feature and the
model retrained -- flagging this rather than silently pretending VFA
was used.
"""

import os
import numpy as np
import joblib
import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify

app = Flask(__name__)


@app.after_request
def add_cors_headers(resp):
    """Same rationale as backend/app.py -- Flutter web needs these to call
    a Flask API cross-origin without the preflight being blocked."""
    resp.headers["Access-Control-Allow-Origin"] = "*"
    resp.headers["Access-Control-Allow-Headers"] = "Content-Type"
    resp.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return resp


# ----------------------------------------------------------------------
# 1. Load model + scaler ONCE at startup
# ----------------------------------------------------------------------
MODEL = joblib.load("model/isolation_forest_model.pkl")
SCALER = joblib.load("model/scaler.pkl")

# Feature order the model was actually trained on. Read off the scaler
# rather than hard-coded, so a retrain with different features doesn't
# silently go stale here.
FEATURES = list(SCALER.feature_names_in_)   # ['pH', 'temperature_c', 'turbidity_ntu']
MEAN = dict(zip(FEATURES, SCALER.mean_))
SCALE = dict(zip(FEATURES, SCALER.scale_))

# Maps the request's field names (matching SensorReading in the Flutter
# app: ph, temperature, turbidity) to the model's training column names.
REQUEST_TO_FEATURE = {
    "ph": "pH",
    "temperature": "temperature_c",
    "turbidity": "turbidity_ntu",
}

# A z-score beyond this is called out by name in the reason text.
Z_FLAG = 1.0

# Friendly labels + directionality for each feature.
FEATURE_INFO = {
    "pH": {
        "label": "pH",
        "unit": "",
        "high_meaning": "more acidic than usual, a sign of bacterial "
                         "activity breaking the latex down",
        "low_meaning": "more acidic than usual, a sign of bacterial "
                        "activity breaking the latex down",
        # pH drop (not rise) is the spoilage direction for latex.
        "bad_direction": "low",
    },
    "temperature_c": {
        "label": "Temperature",
        "unit": "\u00b0C",
        "high_meaning": "warmer than usual, which speeds up bacterial "
                         "growth and coagulation",
        "low_meaning": "cooler than usual",
        "bad_direction": "high",
    },
    "turbidity_ntu": {
        "label": "Turbidity",
        "unit": "NTU",
        "high_meaning": "cloudier than usual, consistent with early "
                         "coagulation or contamination",
        "low_meaning": "clearer than usual",
        "bad_direction": "high",
    },
}


def _missing_fields(data):
    return [k for k in REQUEST_TO_FEATURE if data.get(k) is None]


def _feature_vector(data):
    """Request fields (ph/temperature/turbidity), in the model's training
    column order."""
    row = {}
    for req_key, feat_name in REQUEST_TO_FEATURE.items():
        row[feat_name] = float(data[req_key])
    return np.array([[row[f] for f in FEATURES]])


def _deviations(data):
    """Per-feature z-score against the training mean/std, most extreme
    first. This is what turns a bare anomaly flag into a specific,
    checkable reason."""
    out = []
    for req_key, feat_name in REQUEST_TO_FEATURE.items():
        value = float(data[req_key])
        mean, scale = MEAN[feat_name], SCALE[feat_name]
        z = (value - mean) / scale if scale else 0.0
        out.append({
            "feature": feat_name,
            "request_key": req_key,
            "value": value,
            "training_mean": round(float(mean), 3),
            "z_score": round(float(z), 2),
        })
    out.sort(key=lambda d: abs(d["z_score"]), reverse=True)
    return out


def _reason_text(deviations, is_anomaly):
    """Builds the human-readable explanation from the ranked deviations.
    Only calls out features whose |z| clears Z_FLAG, so a borderline
    normal reading doesn't get an over-confident explanation."""
    flagged = [d for d in deviations if abs(d["z_score"]) >= Z_FLAG]

    if not flagged:
        return (
            "pH, temperature and turbidity are all close to typical "
            "healthy-latex readings, so no single sensor value explains "
            "the Grade C result. Check the reading was captured for the "
            "right sample -- the grading may rest on VFA or another "
            "factor this model does not evaluate."
        )

    parts = []
    for d in flagged:
        info = FEATURE_INFO[d["feature"]]
        direction = "high" if d["z_score"] > 0 else "low"
        meaning = info["high_meaning"] if direction == "high" else info["low_meaning"]
        parts.append(
            f"{info['label']} is {d['value']:.2f}{info['unit']} "
            f"(typical is {d['training_mean']:.2f}{info['unit']}) -- {meaning}."
        )

    verdict = (
        "The model flags this reading as an anomaly consistent with "
        "spoiled/degraded latex: "
        if is_anomaly else
        "The model does not flag this reading as anomalous overall, but "
        "the following value(s) are outside the typical range: "
    )
    return verdict + " ".join(parts)


def _firestore_client():
    """Uses a trusted Admin SDK identity, same convention as
    lstm_forecast_service/app.py::_firestore_client(). Client-supplied
    userId is only ever used as the document key, never trusted for
    anything else."""
    service_account = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    if not service_account:
        raise RuntimeError("FIREBASE_SERVICE_ACCOUNT is not configured")
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(service_account))
    return firestore.client()


def _save_grade_alert(user_id, result):
    """Writes to grade_alerts/{userId}. Matches quality_forecasts' rule
    shape in firestore.rules: only this Admin SDK identity may write it,
    the farmer may only read their own document."""
    _firestore_client().collection("grade_alerts").document(user_id).set(
        {**result, "updatedAt": firestore.SERVER_TIMESTAMP}
    )


@app.get("/health")
def health():
    return jsonify(status="ok", features=FEATURES, models_loaded=True)


@app.post("/grade-reason")
def grade_reason():
    """
    Body: {"userId": "abc123", "ph": 6.1, "temperature": 33.5,
           "turbidity": 3050, "vfa": 0.091, "grade": "C",
           "saveToFirestore": true}

    ph/temperature/turbidity are required -- they are the model's actual
    inputs. vfa/grade are optional context, echoed back but not used by
    the model (see module docstring). userId is required only when
    saveToFirestore is true.
    """
    data = request.get_json(force=True) or {}

    missing = _missing_fields(data)
    if missing:
        return jsonify(
            error="missing_required_fields",
            message=(
                "This model needs pH, temperature and turbidity to explain "
                f"a grade. Missing: {', '.join(missing)}."
            ),
            missing_fields=missing,
        ), 422

    try:
        x = _feature_vector(data)
    except (TypeError, ValueError) as e:
        return jsonify(error="invalid_input", message=str(e)), 422

    x_scaled = SCALER.transform(x)
    prediction = int(MODEL.predict(x_scaled)[0])       # 1 = normal, -1 = anomaly
    is_anomaly = prediction == -1
    anomaly_score = float(MODEL.decision_function(x_scaled)[0])  # lower = more anomalous

    deviations = _deviations(data)
    reason = _reason_text(deviations, is_anomaly)

    result = {
        "is_anomaly": is_anomaly,
        "anomaly_score": round(anomaly_score, 4),
        "reason": reason,
        "deviations": deviations,
        # Context only -- not model inputs.
        "vfa": data.get("vfa"),
        "grade": data.get("grade"),
    }

    if data.get("saveToFirestore"):
        user_id = data.get("userId")
        if not user_id:
            return jsonify(
                error="missing_user_id",
                message="userId is required when saveToFirestore is true.",
            ), 422
        try:
            _save_grade_alert(user_id, result)
        except Exception as e:
            # The prediction itself succeeded; only persistence failed.
            # Return 200 with the result plus a note, rather than losing
            # a correct prediction because Firestore was unreachable.
            result["firestore_error"] = str(e)

    return jsonify(**result)


if __name__ == "__main__":
    # 0.0.0.0 so a phone on the same hotspot can reach it. Different port
    # from backend/app.py (5000) and lstm_forecast_service/app.py (5001)
    # so all three Flask processes can run side by side.
    app.run(host="0.0.0.0", port=5002, debug=True)
