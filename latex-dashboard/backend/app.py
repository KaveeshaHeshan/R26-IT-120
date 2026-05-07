# backend/app.py

from flask      import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, db as firebase_db
import joblib
import numpy    as np
import jwt
import datetime
from config import Config

app = Flask(__name__)
CORS(app)

# ── Firebase ──────────────────────────────────────────────────────────────────
cred = credentials.Certificate(Config.FIREBASE_CRED)
firebase_admin.initialize_app(cred, {
    'databaseURL': Config.FIREBASE_DB_URL
})

# ── Load Model (uncomment after ML training complete) ─────────────────────────
# model  = joblib.load(Config.MODEL_PATH)
# scaler = joblib.load(Config.SCALER_PATH)
# print("✅ RF Model loaded!")

# ── JWT Decorator ─────────────────────────────────────────────────────────────
def require_auth(f):
    from functools import wraps
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
        except:
            return jsonify({'error': 'Invalid token'}), 401
        return f(*args, **kwargs)
    return decorated

# ── Grade ─────────────────────────────────────────────────────────────────────
def assign_grade(vfa):
    if vfa < 0.05:  return 'A'
    if vfa < 0.08:  return 'B'
    return 'C'

# ── Health Check ──────────────────────────────────────────────────────────────
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status':    'running',
        'model':     'Random Forest Regression',
        'timestamp': datetime.datetime.now().isoformat()
    })

# ── Predict (uncomment after ML training complete) ────────────────────────────
# @app.route('/predict', methods=['POST'])
# @require_auth
# def predict():
#     try:
#         data = request.json
#         for field in ['pH','turbidity','temperature',
#                       'farmer_id','device_id','timestamp']:
#             if field not in data:
#                 return jsonify({'error': f'Missing: {field}'}), 400
#         features = np.array([[
#             float(data['pH']),
#             float(data['turbidity']),
#             float(data['temperature'])
#         ]])
#         features_scaled = scaler.transform(features)
#         vfa_pred        = float(model.predict(features_scaled)[0])
#         grade           = assign_grade(vfa_pred)
#         sample_id       = f"LAT_{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}"
#         prediction_data = {
#             'vfa':         round(vfa_pred, 5),
#             'grade':       grade,
#             'pH':          float(data['pH']),
#             'turbidity':   float(data['turbidity']),
#             'temperature': float(data['temperature']),
#             'farmer_id':   data['farmer_id'],
#             'device_id':   data['device_id'],
#             'sample_id':   sample_id,
#             'timestamp':   data['timestamp'],
#         }
#         firebase_db.reference('predictions').push(prediction_data)
#         firebase_db.reference(
#             f"farmers/{data['farmer_id']}/history"
#         ).push(prediction_data)
#         if grade == 'C':
#             firebase_db.reference('alerts').push({
#                 **prediction_data, 'read': False
#             })
#         date        = data['timestamp'][:10]
#         summary_ref = firebase_db.reference(f'daily_summary/{date}')
#         summary = summary_ref.get() or {
#             'total':0,'gradeA':0,'gradeB':0,
#             'gradeC':0,'totalVFA':0.0
#         }
#         summary['total']         += 1
#         summary[f'grade{grade}'] += 1
#         summary['totalVFA']      += vfa_pred
#         summary['avgVFA']         = round(
#             summary['totalVFA'] / summary['total'], 5
#         )
#         summary_ref.set(summary)
#         return jsonify({
#             'vfa': round(vfa_pred, 5), 'grade': grade,
#             'sample_id': sample_id, 'status': 'success'
#         })
#     except Exception as e:
#         return jsonify({'error': str(e)}), 500

# ── Get Predictions ───────────────────────────────────────────────────────────
@app.route('/predictions', methods=['GET'])
@require_auth
def get_predictions():
    try:
        limit = int(request.args.get('limit', 20))
        data  = firebase_db.reference('predictions').get()
        if not data:
            return jsonify([])
        items = list(data.values())[-limit:]
        return jsonify(items)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ── Get Alerts ────────────────────────────────────────────────────────────────
@app.route('/alerts', methods=['GET'])
@require_auth
def get_alerts():
    try:
        data = firebase_db.reference('alerts').get()
        if not data:
            return jsonify([])
        return jsonify(list(data.values()))
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ── Run ───────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=Config.PORT,
        debug=Config.DEBUG
    )