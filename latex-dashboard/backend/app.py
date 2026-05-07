import os
import logging
from datetime import datetime, timedelta
from functools import wraps

from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore, auth as firebase_auth
import jwt
import numpy as np

# ── Load environment variables ────────────────────────────────────────────────
load_dotenv()

SECRET_KEY    = os.getenv('SECRET_KEY')
FIREBASE_CRED = os.getenv('FIREBASE_CRED', 'serviceAccountKey.json')
FLASK_ENV     = os.getenv('FLASK_ENV', 'development')
PORT          = int(os.getenv('PORT', 5000))

# ── Model paths — uncomment AFTER training is complete ───────────────────────
# MODEL_PATH  = os.getenv('MODEL_PATH', 'model/random_forest_vfa.pkl')
# SCALER_PATH = os.getenv('SCALER_PATH', 'model/scaler.pkl')

if not SECRET_KEY:
    raise ValueError("SECRET_KEY not set in .env file!")

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

# ── Flask app ─────────────────────────────────────────────────────────────────
app = Flask(__name__)
app.config['SECRET_KEY'] = SECRET_KEY

CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:3000", "http://localhost:5173"],
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})

# ── Firebase Admin init ───────────────────────────────────────────────────────
try:
    cred = credentials.Certificate(FIREBASE_CRED)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    logger.info("Firebase initialized successfully")
except Exception as e:
    logger.error(f"Firebase initialization failed: {e}")
    db = None

# ── ML Model — loaded only when training is complete ─────────────────────────
model  = None
scaler = None

def load_model():
    """Call this after model training is complete."""
    global model, scaler
    try:
        import joblib
        MODEL_PATH  = os.getenv('MODEL_PATH',  'model/random_forest_vfa.pkl')
        SCALER_PATH = os.getenv('SCALER_PATH', 'model/scaler.pkl')
        model  = joblib.load(MODEL_PATH)
        scaler = joblib.load(SCALER_PATH)
        logger.info("Random Forest model loaded successfully")
        return True
    except Exception as e:
        logger.warning(f"Model not loaded yet: {e}")
        return False

# Try loading model — ok to fail if not trained yet
load_model()

# ── VFA Grade helper ──────────────────────────────────────────────────────────
def get_vfa_grade(vfa: float) -> dict:
    """Classify VFA value into Grade A / B / C."""
    if vfa <= 0.05:
        return {"grade": "A", "status": "Excellent", "color": "#4CAF50"}
    elif vfa <= 0.10:
        return {"grade": "B", "status": "Good",      "color": "#FF9800"}
    else:
        return {"grade": "C", "status": "Poor",      "color": "#F44336"}

# ── JWT Auth decorator ────────────────────────────────────────────────────────
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
        if not token:
            return jsonify({'error': 'Token is missing', 'code': 401}), 401
        try:
            data = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
            request.user = data
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token expired', 'code': 401}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token', 'code': 401}), 401
        return f(*args, **kwargs)
    return decorated

# ══════════════════════════════════════════════════════════════════════════════
# ROUTES
# ══════════════════════════════════════════════════════════════════════════════

# ── Health check ──────────────────────────────────────────────────────────────
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status':    'ok',
        'project':   'R26-IT-120',
        'system':    'IoT Rubber Quality Assessment',
        'model':     'loaded' if model else 'not trained yet',
        'firebase':  'connected' if db else 'disconnected',
        'timestamp': datetime.utcnow().isoformat()
    }), 200

# ── Firebase Auth verify + JWT issue ─────────────────────────────────────────
@app.route('/api/auth/verify', methods=['POST'])
def verify_token():
    """Verify Firebase ID token, issue internal JWT with role."""
    data = request.get_json()
    if not data or 'idToken' not in data:
        return jsonify({'error': 'idToken required'}), 400
    try:
        decoded = firebase_auth.verify_id_token(data['idToken'])
        uid     = decoded['uid']
        email   = decoded.get('email', '')

        # Get user role from Firestore
        role = 'farmer'
        if db:
            user_doc = db.collection('users').document(uid).get()
            if user_doc.exists:
                role = user_doc.to_dict().get('role', 'farmer')

        payload = {
            'uid':   uid,
            'email': email,
            'role':  role,
            'exp':   datetime.utcnow() + timedelta(hours=24)
        }
        token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')

        logger.info(f"Auth success: {email} | role: {role}")
        return jsonify({
            'token': token,
            'uid':   uid,
            'email': email,
            'role':  role
        }), 200

    except firebase_auth.InvalidIdTokenError:
        return jsonify({'error': 'Invalid Firebase token'}), 401
    except Exception as e:
        logger.error(f"Auth error: {e}")
        return jsonify({'error': 'Authentication failed'}), 500

# ── VFA Prediction ────────────────────────────────────────────────────────────
@app.route('/api/predict', methods=['POST'])
@token_required
def predict():
    """
    Predict VFA from sensor readings.
    NOTE: Returns 503 until model training is complete.

    Expected JSON:
    {
        "pH":          6.8,
        "EC":          1.2,
        "turbidity":   45.0,
        "temperature": 28.5
    }
    """
    # ── Model not ready yet ───────────────────────────────────────────────────
    if not model or not scaler:
        return jsonify({
            'error':   'ML model not trained yet',
            'message': 'Please complete model training first. '
                       'Run: python model/train.py',
            'code':    503
        }), 503

    data = request.get_json()
    if not data:
        return jsonify({'error': 'JSON body required'}), 400

    required = ['pH', 'EC', 'turbidity', 'temperature']
    missing  = [f for f in required if f not in data]
    if missing:
        return jsonify({'error': f'Missing fields: {missing}'}), 400

    try:
        features = np.array([[
            float(data['pH']),
            float(data['EC']),
            float(data['turbidity']),
            float(data['temperature'])
        ]])

        features_scaled = scaler.transform(features)
        vfa_predicted   = round(float(model.predict(features_scaled)[0]), 4)
        grade_info      = get_vfa_grade(vfa_predicted)

        result = {
            'vfa':     vfa_predicted,
            'grade':   grade_info['grade'],
            'status':  grade_info['status'],
            'color':   grade_info['color'],
            'inputs':  {
                'pH':          data['pH'],
                'EC':          data['EC'],
                'turbidity':   data['turbidity'],
                'temperature': data['temperature']
            },
            'timestamp': datetime.utcnow().isoformat(),
            'model':     'RandomForestRegressor'
        }

        # Save to Firestore
        if db:
            try:
                db.collection('predictions').add({
                    **result,
                    'uid':       request.user.get('uid'),
                    'createdAt': firestore.SERVER_TIMESTAMP
                })
            except Exception as e:
                logger.warning(f"Firestore save failed: {e}")

        logger.info(
            f"Prediction: VFA={vfa_predicted} "
            f"Grade={grade_info['grade']} "
            f"pH={data['pH']} EC={data['EC']}"
        )
        return jsonify(result), 200

    except ValueError as e:
        return jsonify({'error': f'Invalid input: {e}'}), 422
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        return jsonify({'error': 'Prediction failed'}), 500

# ── Get predictions history ───────────────────────────────────────────────────
@app.route('/api/predictions', methods=['GET'])
@token_required
def get_predictions():
    """Get recent VFA predictions from Firestore."""
    if not db:
        return jsonify({'error': 'Database not connected'}), 503
    try:
        limit = int(request.args.get('limit', 50))
        role  = request.user.get('role')
        uid   = request.user.get('uid')

        query = db.collection('predictions').order_by(
            'createdAt', direction=firestore.Query.DESCENDING
        ).limit(limit)

        if role == 'farmer':
            query = query.where('uid', '==', uid)

        predictions = []
        for doc in query.stream():
            d = doc.to_dict()
            d['id'] = doc.id
            if 'createdAt' in d and hasattr(d['createdAt'], 'isoformat'):
                d['createdAt'] = d['createdAt'].isoformat()
            predictions.append(d)

        return jsonify({
            'count':       len(predictions),
            'predictions': predictions
        }), 200

    except Exception as e:
        logger.error(f"Fetch predictions error: {e}")
        return jsonify({'error': 'Failed to fetch predictions'}), 500

# ── VFA Statistics ────────────────────────────────────────────────────────────
@app.route('/api/stats', methods=['GET'])
@token_required
def get_stats():
    """Get VFA grade statistics for KPI dashboard."""
    if not db:
        return jsonify({'error': 'Database not connected'}), 503
    try:
        docs       = db.collection('predictions').stream()
        vfa_values = []
        grades     = {'A': 0, 'B': 0, 'C': 0}

        for doc in docs:
            d = doc.to_dict()
            if 'vfa' in d:
                vfa_values.append(d['vfa'])
            if 'grade' in d and d['grade'] in grades:
                grades[d['grade']] += 1

        total = len(vfa_values)
        if total == 0:
            return jsonify({'message': 'No predictions yet'}), 200

        return jsonify({
            'total':   total,
            'average': round(sum(vfa_values) / total, 4),
            'min':     round(min(vfa_values), 4),
            'max':     round(max(vfa_values), 4),
            'grades':  grades,
            'gradePercentage': {
                'A': round(grades['A'] / total * 100, 1),
                'B': round(grades['B'] / total * 100, 1),
                'C': round(grades['C'] / total * 100, 1),
            }
        }), 200

    except Exception as e:
        logger.error(f"Stats error: {e}")
        return jsonify({'error': 'Failed to fetch stats'}), 500

# ── Error handlers ────────────────────────────────────────────────────────────
@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Endpoint not found', 'code': 404}), 404

@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({'error': 'Method not allowed', 'code': 405}), 405

@app.errorhandler(500)
def internal_error(e):
    return jsonify({'error': 'Internal server error', 'code': 500}), 500

# ── Run ───────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    logger.info(f"Starting R26-IT-120 API — port {PORT}")
    logger.info(f"Environment : {FLASK_ENV}")
    logger.info(f"Model status: {'loaded' if model else 'not trained yet'}")
    app.run(
        host='0.0.0.0',
        port=PORT,
        debug=(FLASK_ENV == 'development')
    )