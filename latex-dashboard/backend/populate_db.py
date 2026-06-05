# latex-dashboard/backend/populate_db.py
import firebase_admin
from firebase_admin import credentials, db
import random
import datetime
import os
from dotenv import load_dotenv

# Load env variables from .env
load_dotenv()

FIREBASE_CRED = os.getenv('FIREBASE_CRED', 'serviceAccountKey.json')
FIREBASE_DB_URL = os.getenv('FIREBASE_DB_URL', 'https://rubberquality-33cab-default-rtdb.firebaseio.com/')

if not os.path.exists(FIREBASE_CRED):
    print(f"Error: Credentials file {FIREBASE_CRED} not found!")
    exit(1)

print(f"Connecting to database: {FIREBASE_DB_URL}")
cred = credentials.Certificate(FIREBASE_CRED)
firebase_admin.initialize_app(cred, {
    'databaseURL': FIREBASE_DB_URL
})

# Clear existing references to build clean test data
print("Cleaning database...")
db.reference('predictions').delete()
db.reference('alerts').delete()
db.reference('farmers').delete()

# Test Farmers list
farmers = ['FARM_001', 'FARM_002', 'FARM_003', 'FARM_004']
devices = ['DEV_01', 'DEV_02']

def assign_grade(vfa):
    if vfa < 0.05: return 'A'
    if vfa < 0.08: return 'B'
    return 'C'

# Generate 7 days of collection data
now = datetime.datetime.now(datetime.timezone.utc)
print("Generating 7 days of data...")

# A list to store all predictions for push
all_predictions = []

for day_offset in range(6, -1, -1):
    day_date = now - datetime.timedelta(days=day_offset)
    # Number of entries per day (more today, moderate on previous days)
    entries_count = 15 if day_offset == 0 else random.randint(8, 12)
    
    for i in range(entries_count):
        # Generate spread times during working hours (8:00 AM to 5:00 PM)
        hour = random.randint(8, 16)
        minute = random.randint(0, 59)
        second = random.randint(0, 59)
        
        timestamp = day_date.replace(hour=hour, minute=minute, second=second)
        timestamp_str = timestamp.isoformat().replace('+00:00', 'Z')
        
        # pH: normally 6.0 to 7.5. Grade C might correlate with outlier pH values
        # Turbidity: normally 10 to 120 NTU.
        # Temp: normally 26 to 34 C.
        # VFA: Grade A (<0.05), Grade B (0.05 - 0.08), Grade C (>0.08)
        
        farmer_id = random.choice(farmers)
        device_id = random.choice(devices)
        
        # Quality distribution: 65% Grade A, 25% Grade B, 10% Grade C
        rand_quality = random.random()
        if rand_quality < 0.65:
            # Grade A
            vfa = round(random.uniform(0.015, 0.048), 5)
            pH = round(random.uniform(6.5, 7.3), 2)
            turbidity = round(random.uniform(30.0, 75.0), 1)
            temperature = round(random.uniform(27.0, 31.0), 1)
        elif rand_quality < 0.90:
            # Grade B
            vfa = round(random.uniform(0.050, 0.078), 5)
            pH = round(random.uniform(6.0, 6.4), 2)
            turbidity = round(random.uniform(75.0, 110.0), 1)
            temperature = round(random.uniform(31.1, 33.5), 1)
        else:
            # Grade C (Outliers / Bad quality)
            vfa = round(random.uniform(0.081, 0.115), 5)
            pH = round(random.uniform(5.2, 5.9), 2)
            turbidity = round(random.uniform(115.0, 170.0), 1)
            temperature = round(random.uniform(33.6, 35.5), 1)
            
        grade = assign_grade(vfa)
        sample_id = f"LAT_{timestamp.strftime('%Y%m%d%H%M%S')}"
        
        prediction_data = {
            'vfa': vfa,
            'grade': grade,
            'pH': pH,
            'turbidity': turbidity,
            'temperature': temperature,
            'farmer_id': farmer_id,
            'device_id': device_id,
            'sample_id': sample_id,
            'timestamp': timestamp_str
        }
        all_predictions.append((timestamp, prediction_data))

# Sort predictions chronologically to ensure they push in correct sequence
all_predictions.sort(key=lambda x: x[0])

# Push predictions to Firebase
predictions_ref = db.reference('predictions')
alerts_ref = db.reference('alerts')

print(f"Pushing {len(all_predictions)} records to Firebase...")

for timestamp, pred in all_predictions:
    # Push to predictions
    new_pred_ref = predictions_ref.push(pred)
    pred_key = new_pred_ref.key
    
    # Push to farmer history
    db.reference(f"farmers/{pred['farmer_id']}/history/{pred_key}").set(pred)
    
    # If grade is C, push to alerts
    if pred['grade'] == 'C':
        # Older alerts (before today) are marked as read. Today's alerts are unread.
        is_today = (timestamp.date() == now.date())
        alert_data = {
            **pred,
            'read': not is_today  # unread if today, read if in the past
        }
        alerts_ref.child(pred_key).set(alert_data)

print("Data generation successfully completed!")
