# latex-dashboard/backend/create_user.py
import firebase_admin
from firebase_admin import credentials, auth, db
import os
from dotenv import load_dotenv

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

users_to_create = [
    {
        'email': 'admin@lalanrubbers.com',
        'password': 'AdminPass123!',
        'role': 'admin',
        'user_id': 'ADM_001',
        'name': 'System Admin'
    },
    {
        'email': 'manager@lalanrubbers.com',
        'password': 'ManagerPass123!',
        'role': 'manager',
        'user_id': 'MGR_001',
        'name': 'Factory Manager'
    },
    {
        'email': 'qa@lalanrubbers.com',
        'password': 'QAPass123!',
        'role': 'qa_officer',
        'user_id': 'QA_001',
        'name': 'QA Officer'
    }
]

for user_data in users_to_create:
    try:
        # Check if user already exists in Firebase Auth
        user = auth.get_user_by_email(user_data['email'])
        print(f"User {user_data['email']} already exists in Auth. UID: {user.uid}")
        uid = user.uid
    except auth.UserNotFoundError:
        # Create user in Firebase Auth
        user = auth.create_user(
            email=user_data['email'],
            password=user_data['password'],
            display_name=user_data['name']
        )
        print(f"Created user {user_data['email']} in Auth. UID: {user.uid}")
        uid = user.uid
    
    # Store/update role database records
    role_ref = db.reference(f"roles/{uid}")
    role_ref.set({
        'role': user_data['role'],
        'user_id': user_data['user_id'],
        'name': user_data['name']
    })
    print(f"Role data written to Database for {user_data['email']}")

print("All default users checked and verified successfully!")
