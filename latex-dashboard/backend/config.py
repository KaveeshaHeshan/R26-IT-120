# backend/config.py
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY      = os.getenv('SECRET_KEY', 'latex-secret-2026')
    FIREBASE_CRED   = os.getenv('FIREBASE_CRED', 'serviceAccountKey.json')
    FIREBASE_DB_URL = os.getenv('FIREBASE_DB_URL')
    MODEL_PATH      = os.getenv('MODEL_PATH',  'model/rf_vfa_model.pkl')
    SCALER_PATH     = os.getenv('SCALER_PATH', 'model/scaler.pkl')
    PORT            = int(os.getenv('PORT', 5000))
    DEBUG           = os.getenv('DEBUG', 'True') == 'True'