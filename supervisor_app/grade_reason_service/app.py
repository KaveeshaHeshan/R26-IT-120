import os
from datetime import datetime, timezone
from pathlib import Path
import numpy as np
import joblib
import firebase_admin
from firebase_admin import credentials, firestore
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.after_request
def add_cors_headers(resp):
    resp.headers["Access-Control-Allow-Origin"] = "*"
    resp.headers["Access-Control-Allow-Headers"] = "Content-Type"
    resp.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return resp

MODEL = joblib.load("model/isolation_forest_model.pkl")
SCALER = joblib.load("model/scaler.pkl")
FEATURES = list(SCALER.feature_names_in_)
MEAN = dict(zip(FEATURES, SCALER.mean_))
SCALE = dict(zip(FEATURES, SCALER.scale_))

#features 
REQUEST_TO_FEATURE = {
    "ph": "pH",
    "temperature": "temperature_c",
    "turbidity": "turbidity_ntu",
}
Z_FLAG = 1.0
MODEL_VERSION = "grade-c-explainer-v2"


CONTEXT_THRESHOLDS = {
    "vfa": {"high": 0.85, "label": "VFA"},
    "actual_ammonia_ratio": {"low": 0.025, "high": 0.035, "label": "Ammonia ratio"},
    "storage_duration_hours": {"high": 4.0, "label": "Collection-to-processing time"},
    "temperature": {"high": 32.0, "label": "Temperature"},
    "turbidity": {"high": 3000.0, "label": "Turbidity"},
}

FEATURE_INFO = {
    "pH": {
        "label": "pH",
        "unit": "",
        "high_meaning": "higher than the normal training baseline",
        "low_meaning": "lower than the normal training baseline, which can be associated with latex deterioration",
    },
    "temperature_c": {
        "label": "Temperature",
        "unit": " °C",
        "high_meaning": "warmer than the normal training baseline, which can accelerate deterioration",
        "low_meaning": "cooler than the normal training baseline",
    },
    "turbidity_ntu": {
        "label": "Turbidity",
        "unit": " NTU",
        "high_meaning": "cloudier than the normal training baseline, which can be consistent with contamination or early coagulation",
        "low_meaning": "clearer than the normal training baseline",
    },
}


def _num(data, key):
    value = data.get(key)
    if value is None or value == "":
        return None
    try:
        value = float(value)
        return value if np.isfinite(value) else None
    except (TypeError, ValueError):
        return None


def _feature_vector(data):
    row = {}
    for req_key, feat_name in REQUEST_TO_FEATURE.items():
        row[feat_name] = float(data[req_key])
    return np.array([[row[f] for f in FEATURES]], dtype=float)


def _deviations(data):
    out = []
    for req_key, feat_name in REQUEST_TO_FEATURE.items():
        value = float(data[req_key])
        mean, scale = float(MEAN[feat_name]), float(SCALE[feat_name])
        z = (value - mean) / scale if scale else 0.0
        out.append({
            "feature": feat_name,
            "request_key": req_key,
            "value": round(value, 4),
            "training_mean": round(mean, 4),
            "z_score": round(z, 3),
            "direction": "high" if z > 0 else "low" if z < 0 else "normal",
        })
    out.sort(key=lambda d: abs(d["z_score"]), reverse=True)
    return out


def _model_factors(deviations):
    factors = []
    for d in deviations:
        if abs(d["z_score"]) < Z_FLAG:
            continue
        info = FEATURE_INFO[d["feature"]]
        direction = d["direction"]
        meaning = info["high_meaning"] if direction == "high" else info["low_meaning"]
        factors.append({
            "feature": d["feature"],
            "label": info["label"],
            "value": d["value"],
            "expected": d["training_mean"],
            "unit": info["unit"],
            "impact": round(min(1.0, abs(d["z_score"]) / 3.0), 3),
            "severity": "high" if abs(d["z_score"]) >= 2 else "medium",
            "reason": meaning,
            "source": "trained_model_baseline",
        })
    return factors


def _context_factors(data):
    factors = []

    vfa = _num(data, "vfa")
    if vfa is not None and vfa >= CONTEXT_THRESHOLDS["vfa"]["high"]:
        factors.append({
            "feature": "vfa", "label": "VFA", "value": round(vfa, 4),
            "expected": CONTEXT_THRESHOLDS["vfa"]["high"], "unit": "",
            "impact": 0.95, "severity": "high", "source": "quality_threshold",
            "reason": "VFA is above the configured freshness threshold, indicating reduced latex freshness.",
        })

    ammonia = _num(data, "actual_ammonia_ratio")
    if ammonia is not None:
        t = CONTEXT_THRESHOLDS["actual_ammonia_ratio"]
        if ammonia < t["low"] or ammonia > t["high"]:
            factors.append({
                "feature": "actual_ammonia_ratio", "label": "Ammonia ratio",
                "value": round(ammonia * 100, 2), "expected": [t["low"] * 100, t["high"] * 100],
                "unit": "%", "impact": 0.75, "severity": "medium", "source": "quality_threshold",
                "reason": "The preservative ratio is outside the configured target range; verify dosing and mixing.",
            })

    storage = _num(data, "storage_duration_hours")
    if storage is not None and storage > CONTEXT_THRESHOLDS["storage_duration_hours"]["high"]:
        factors.append({
            "feature": "storage_duration_hours", "label": "Collection-to-processing time",
            "value": round(storage, 2), "expected": CONTEXT_THRESHOLDS["storage_duration_hours"]["high"],
            "unit": " h", "impact": min(0.95, 0.55 + (storage - 4) / 10), "severity": "high" if storage >= 8 else "medium",
            "source": "quality_threshold", "reason": "Longer holding time can reduce freshness; move latex to processing sooner.",
        })

    
    weather = str(data.get("weather_condition") or "").strip().lower()
    if weather in {"rain", "rainy", "heavy rain", "storm"}:
        factors.append({
            "feature": "weather_condition", "label": "Weather condition", "value": data.get("weather_condition"),
            "expected": "dry/normal collection conditions", "unit": "", "impact": 0.35, "severity": "low",
            "source": "field_context", "reason": "Wet conditions can increase contamination risk during collection.",
        })

    tree = str(data.get("tree_condition") or "").strip().lower()
    if tree in {"poor", "unhealthy", "damaged", "weak"}:
        factors.append({
            "feature": "tree_condition", "label": "Tree condition", "value": data.get("tree_condition"),
            "expected": "healthy", "unit": "", "impact": 0.30, "severity": "low",
            "source": "field_context", "reason": "Poor tree condition can reduce latex yield and consistency.",
        })

    return factors


def _tips_for(factors):
    tips = []
    feature_names = {f.get("feature") for f in factors}
    if "vfa" in feature_names:
        tips.append("Reduce the time between tapping, collection and processing to keep latex fresher.")
    if "storage_duration_hours" in feature_names:
        tips.append("Deliver the collected latex to processing sooner and avoid unnecessary holding time.")
    if "temperature_c" in feature_names:
        tips.append("Keep collected latex away from excessive heat while waiting for transport or processing.")
    if "pH" in feature_names:
        tips.append("Check container cleanliness and collection timing because unusual pH can indicate latex deterioration.")
    if "turbidity_ntu" in feature_names:
        tips.append("Use clean collection containers and avoid soil, water or other contamination entering the latex.")
    if "actual_ammonia_ratio" in feature_names:
        tips.append("Measure the latex volume and keep preservative dosing within the supervisor-approved target ratio.")
    if "weather_condition" in feature_names:
        tips.append("During wet weather, protect collection containers from rainwater and external contamination.")
    if "tree_condition" in feature_names:
        tips.append("Inspect affected trees and discuss poor tree condition with the field supervisor before the next tapping cycle.")
    if not tips:
        tips.append("Keep collection containers clean, minimise collection-to-processing time, and follow the supervisor's recommended preservation procedure.")
    return tips[:6]


def _firestore_client():
    configured_path = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    default_path = Path(__file__).resolve().parent / "model" / "rubberquality-33cab-firebase-adminsdk-fbsvc-4a31e13ded.json"
    placeholder = "C:\\full\\path\\to\\your\\firebase-service-account.json"
    if configured_path and configured_path.strip() != placeholder:
        service_account = Path(configured_path).expanduser()
    else:
        service_account = default_path
    if not service_account.is_file():
        raise RuntimeError(
            "Firebase service-account JSON was not found. Set FIREBASE_SERVICE_ACCOUNT "
            f"to a valid file path (checked: {service_account})"
        )
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(str(service_account)))
    return firestore.client()


def _save_grade_alert(user_id, result):
    payload = dict(result)
    payload["updatedAt"] = firestore.SERVER_TIMESTAMP
    _firestore_client().collection("grade_alerts").document(user_id).set(
        payload,
        timeout=10,
    )


def _build_reason(model_anomaly, model_score, factors):
    if not factors:
        if model_anomaly:
            return "The trained sensor model detected an unusual quality pattern, but no individual configured factor was strong enough to explain it confidently. Recheck the sample and measurements."
        return "The available measurements are close to their normal baselines. Grade C may depend on a quality factor that is not currently represented in the trained model; review the supervisor measurements and collection conditions."
    names = [f["label"] for f in factors[:3]]
    if len(names) == 1:
        return f"The main factor associated with this Grade C result is {names[0]}. The analysis below shows the measured value and why it was flagged."
    return "The main factors associated with this Grade C result are " + ", ".join(names[:-1]) + " and " + names[-1] + "."


@app.get("/health")
def health():
    return jsonify(status="ok", features=FEATURES, models_loaded=True, model_version=MODEL_VERSION)


@app.post("/grade-reason")
def grade_reason():
    data = request.get_json(force=True) or {}
    grade = str(data.get("grade") or "").strip().upper()
    if grade and grade != "C":
        return jsonify(error="not_grade_c", message="Grade explanation is only generated for Grade C."), 422

    missing = [k for k in REQUEST_TO_FEATURE if _num(data, k) is None]

    try:
        model_anomaly = False
        model_score = None
        deviations = []
        model_factors = []
        if not missing:
            x = _feature_vector(data)
            x_scaled = SCALER.transform(x)
            prediction = int(MODEL.predict(x_scaled)[0])
            model_anomaly = prediction == -1
            model_score = float(MODEL.decision_function(x_scaled)[0])
            deviations = _deviations(data)
            model_factors = _model_factors(deviations)

        factors = model_factors + _context_factors(data)
        factors.sort(key=lambda f: float(f.get("impact", 0)), reverse=True)
        tips = _tips_for(factors)
        reason = _build_reason(model_anomaly, model_score, factors)

        result = {
            "source": "grade_c_reason",
            "model_version": MODEL_VERSION,
            "grade": grade or "C",
            "is_anomaly": model_anomaly,
            "anomaly_score": round(model_score, 4) if model_score is not None else None,
            "reason": reason,
            "deviations": deviations,
            "top_factors": factors[:6],
            "tips": tips,
            "analysis_status": "complete" if not missing else "insufficient_sensor_data",
            "missing_sensor_fields": missing,
            "analysis_message": (
                "The sensor model uses pH, temperature and turbidity. Other displayed factors are contextual quality checks, not hidden model inputs."
                if not missing else
                "The Grade C was saved, but the trained sensor model could not run because one or more sensor measurements were missing. Collect the missing readings for a complete ML explanation."
            ),
            "collection_id": data.get("collectionId"),
            "measured": {
                "ph": _num(data, "ph"),
                "temperature": _num(data, "temperature"),
                "turbidity": _num(data, "turbidity"),
                "vfa": _num(data, "vfa"),
                "latex_volume_l": _num(data, "latex_volume_l"),
                "trees_count": _num(data, "trees_count"),
                "storage_duration_hours": _num(data, "storage_duration_hours"),
                "actual_ammonia_ratio": _num(data, "actual_ammonia_ratio"),
            },
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

        if data.get("saveToFirestore"):
            user_id = str(data.get("userId") or "").strip()
            if not user_id:
                return jsonify(error="missing_user_id", message="userId is required when saveToFirestore is true."), 422
            try:
                _save_grade_alert(user_id, result)
            except Exception as e:
                app.logger.exception("Could not save Grade C alert for user %s", user_id)
                return jsonify(
                    error="firestore_save_failed",
                    message="The Grade C explanation was generated but could not be saved for the farmer.",
                ), 503

        return jsonify(**result)
    except (TypeError, ValueError) as e:
        return jsonify(error="invalid_input", message=str(e)), 422


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002, debug=False, threaded=True)
