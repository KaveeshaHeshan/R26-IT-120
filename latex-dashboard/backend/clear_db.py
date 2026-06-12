"""Clear all test/dummy data from Firebase Realtime Database."""

import firebase_admin
from firebase_admin import credentials, db
import os
from dotenv import load_dotenv

load_dotenv()

FIREBASE_CRED   = os.getenv('FIREBASE_CRED',   'serviceAccountKey.json')
FIREBASE_DB_URL = os.getenv('FIREBASE_DB_URL',  'https://rubberquality-33cab-default-rtdb.firebaseio.com/')

if not os.path.exists(FIREBASE_CRED):
    print(f"Error: Credentials file '{FIREBASE_CRED}' not found!")
    exit(1)

cred = credentials.Certificate(FIREBASE_CRED)
firebase_admin.initialize_app(cred, {'databaseURL': FIREBASE_DB_URL})

print("Clearing all dummy data from Firebase...")

db.reference('predictions').delete()
print("  ✅ predictions — cleared")

db.reference('alerts').delete()
print("  ✅ alerts — cleared")

db.reference('farmers').delete()
print("  ✅ farmers — cleared")

db.reference('daily_summary').delete()
print("  ✅ daily_summary — cleared")

print("\nDatabase is now empty. Dashboard will show the empty state.")
