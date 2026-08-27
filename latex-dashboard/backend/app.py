# backend/app.py

import threading
import datetime
import time
from functools import wraps

from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, db as firebase_db
import joblib
import numpy as np
import jwt

from config import Config

app = Flask(__name__)
CORS(app)

# ── Firebase ──────────────────────────────────────────────────────────────────
cred = credentials.Certificate(Config.FIREBASE_CRED)
firebase_admin.initialize_app(cred, {
    'databaseURL': Config.FIREBASE_DB_URL
})

# ── Load Model ──────────────────────────────────────────────────────────────
model = joblib.load(Config.MODEL_PATH)
scaler = joblib.load(Config.SCALER_PATH)
print("✅ RF Model loaded!")

# ── JWT Decorator ─────────────────────────────────────────────────────────────
def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get(
            'Authorization', ''
        ).replace('Bearer ', '')
        if not token:
            return jsonify({'error': 'Token missing'}), 401
        try:
            jwt.decode(
                token,
                Config.SECRET_KEY,
                algorithms=['HS256']
            )
        except Exception:
            return jsonify({'error': 'Invalid token'}), 401
        return f(*args, **kwargs)
    return decorated

# ── Grade ─────────────────────────────────────────────────────────────────────
def assign_grade(vfa):
    if vfa < 0.05:
        return 'A'
    if vfa < 0.08:
        return 'B'
    return 'C'

# ── Sensor range validation (matches SENSOR_RANGES spec) ──────────────────────
# ⚠️ PH_RANGE temporarily widened (2.0-30.0) to allow ammonia-preserved latex
# readings through for pipeline testing. Model was trained on pH 5.0-8.0 data,
# so predictions outside that range are extrapolation — not reliable for
# real decisions. Narrow this back once dataset/model reflects true field pH.
PH_RANGE = (2.0, 30.0)
TURBIDITY_RANGE = (0, 3000)
TEMP_RANGE = (26, 34)

def validate_ranges(pH, turbidity, temperature):
    errors = []
    if not (PH_RANGE[0] <= pH <= PH_RANGE[1]):
        errors.append(f"pH {pH} out of range {PH_RANGE}")
    if not (TURBIDITY_RANGE[0] <= turbidity <= TURBIDITY_RANGE[1]):
        errors.append(f"turbidity {turbidity} out of range {TURBIDITY_RANGE}")
    if not (TEMP_RANGE[0] <= temperature <= TEMP_RANGE[1]):
        errors.append(f"temperature {temperature} out of range {TEMP_RANGE}")
    return errors

# ── Core prediction pipeline (shared by /predict AND the auto listener) ───────
def process_and_predict(pH, turbidity, temperature, farmer_id, device_id, timestamp=None):
    errors = validate_ranges(pH, turbidity, temperature)
    if errors:
        print(f"⚠️  Skipped prediction — invalid sensor reading: {'; '.join(errors)}")
        return None

    features = np.array([[pH, turbidity, temperature]])
    features_scaled = scaler.transform(features)
    vfa_pred = float(model.predict(features_scaled)[0])
    grade = assign_grade(vfa_pred)

    timestamp = timestamp or datetime.datetime.now().isoformat()
    sample_id = f"LAT_{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}"

    prediction_data = {
        'vfa': round(vfa_pred, 5),
        'grade': grade,
        'pH': pH,
        'turbidity': turbidity,
        'temperature': temperature,
        'farmer_id': farmer_id,
        'device_id': device_id,
        'sample_id': sample_id,
        'timestamp': timestamp,
    }

    firebase_db.reference('predictions').push(prediction_data)
    firebase_db.reference(f"farmers/{farmer_id}/history").push(prediction_data)

    if grade == 'C':
        firebase_db.reference('alerts').push({**prediction_data, 'read': False})

    date = timestamp[:10]
    summary_ref = firebase_db.reference(f'daily_summary/{date}')

    def update_summary(summary):
        summary = summary or {
            'total': 0, 'gradeA': 0, 'gradeB': 0,
            'gradeC': 0, 'totalVFA': 0.0
        }
        summary['total'] += 1
        summary[f'grade{grade}'] += 1
        summary['totalVFA'] += vfa_pred
        summary['avgVFA'] = round(summary['totalVFA'] / summary['total'], 5)
        return summary

    summary_ref.transaction(update_summary)

    print(f"✅ Predicted VFA={vfa_pred:.5f} -> Grade {grade} (farmer={farmer_id})")
    return prediction_data

# ── Single deployed device — hardcoded since there's only one ESP32 ───────────
DEVICE_ID = "DEV_01"

# ── Prediction debounce ─────────────────────────────────────────────────────
# The ESP32 does 3 SEPARATE writes per reading cycle (temperature, ph,
# turbidity) — each one fires the listener, so a single physical dip can
# trigger 2-3 predictions in quick succession. This enforces a minimum gap
# between predictions, matching the ESP32's own send interval, so only one
# prediction goes through per real reading cycle.
MIN_PREDICT_INTERVAL_SECONDS = 10
_last_predict_time = 0
_predict_lock = threading.Lock()

# ── Auto listener — triggers on every sensorData/ write from the ESP32 ────────
def on_sensor_data(event):
    global _last_predict_time
    try:
        if event.data is None:
            return

        snapshot = event.data if event.path == '/' else firebase_db.reference('sensorData').get()
        if not snapshot:
            return

        pH = snapshot.get('ph')
        turbidity = snapshot.get('turbidity')
        temperature = snapshot.get('temperature')

        if pH is None or turbidity is None or temperature is None:
            return

        # Debounce — skip if a prediction just ran within the cooldown window.
        with _predict_lock:
            now = time.time()
            if now - _last_predict_time < MIN_PREDICT_INTERVAL_SECONDS:
                return
            _last_predict_time = now

        # Look up which farmer this device is currently assigned to.
        # The supervisor's mobile app writes this when they tap "Start Collection".
        session = firebase_db.reference(f'activeSessions/{DEVICE_ID}').get()
        if not session or not session.get('farmer_id'):
            print(f"⚠️  Skipped prediction — no active session for device {DEVICE_ID} "
                  f"(supervisor hasn't started a collection on the mobile app)")
            return

        farmer_id = session['farmer_id']  # Firestore farmer doc ID

        process_and_predict(pH, turbidity, temperature, farmer_id, DEVICE_ID)

    except Exception as e:
        print(f"❌ Error in sensor listener: {e}")

def start_listener():
    firebase_db.reference('sensorData').listen(on_sensor_data)

# ── Health Check ──────────────────────────────────────────────────────────────
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'running',
        'model': 'Random Forest Regression',
        'model_loaded': model is not None,
        'timestamp': datetime.datetime.now().isoformat()
    })

# ── Predict (manual/testing — auto listener covers real device readings) ──────
@app.route('/predict', methods=['POST'])
@require_auth
def predict():
    try:
        data = request.json
        for field in ['pH', 'turbidity', 'temperature', 'farmer_id', 'device_id']:
            if field not in data:
                return jsonify({'error': f'Missing: {field}'}), 400

        result = process_and_predict(
            float(data['pH']),
            float(data['turbidity']),
            float(data['temperature']),
            data['farmer_id'],
            data['device_id'],
            data.get('timestamp'),
        )
        if result is None:
            return jsonify({'error': 'sensor values out of valid range'}), 422

        return jsonify({**result, 'status': 'success'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ── Get Predictions ───────────────────────────────────────────────────────────
@app.route('/predictions', methods=['GET'])
@require_auth
def get_predictions():
    try:
        limit = int(request.args.get('limit', 20))
        data = firebase_db.reference('predictions').get()
        if not data:
            return jsonify([])
        items = list(data.values())[-limit:]
        return jsonify(items)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ── Start Session ────────────────────────────────────────────────────────────
# NOTE: this is called by the SUPERVISOR'S MOBILE APP when they tap
# "Start Collection" and pick a farmer — NOT by the factory web dashboard.
# The web dashboard stays read-only (predictions/alerts/summary views only);
# it should never trigger an active test session.
@app.route('/start-session', methods=['POST'])
@require_auth
def start_session():
    try:
        data = request.json or {}
        farmer_id = data.get('farmer_id')
        if not farmer_id:
            return jsonify({'error': 'farmer_id required'}), 400

        firebase_db.reference(f'activeSessions/{DEVICE_ID}').set({
            'farmer_id': farmer_id,
            'started_at': datetime.datetime.now().isoformat(),
        })
        return jsonify({
            'status': 'session started',
            'farmer_id': farmer_id,
            'device_id': DEVICE_ID,
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ── Run ───────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    listener_thread = threading.Thread(target=start_listener, daemon=True)
    listener_thread.start()
    print("👂 Listening sensorData/...")

    app.run(
        host='0.0.0.0',
        port=Config.PORT,
        debug=Config.DEBUG,
        use_reloader=False,  # required alongside debug — prevents double listener registration
    )