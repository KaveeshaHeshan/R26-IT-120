# backend/remove_temp_users.py
import firebase_admin
from firebase_admin import credentials, auth, db
import os
from dotenv import load_dotenv

load_dotenv()

FIREBASE_CRED   = os.getenv('FIREBASE_CRED', 'serviceAccountKey.json')
FIREBASE_DB_URL = os.getenv('FIREBASE_DB_URL', 'https://rubberquality-33cab-default-rtdb.firebaseio.com/')

if not os.path.exists(FIREBASE_CRED):
    print(f"Error: Credentials file {FIREBASE_CRED} not found!")
    exit(1)

cred = credentials.Certificate(FIREBASE_CRED)
firebase_admin.initialize_app(cred, {'databaseURL': FIREBASE_DB_URL})

temp_accounts = [
    'manager@lalanrubbers.com',
    'qa@lalanrubbers.com',
]

for email in temp_accounts:
    try:
        user = auth.get_user_by_email(email)
        uid  = user.uid
        # Remove role entry from Realtime DB
        db.reference(f'roles/{uid}').delete()
        print(f"Removed roles/{uid} from DB")
        # Delete from Firebase Auth
        auth.delete_user(uid)
        print(f"Deleted Auth user: {email}")
    except auth.UserNotFoundError:
        print(f"User not found (already removed?): {email}")

print("Done — only admin account remains.")
