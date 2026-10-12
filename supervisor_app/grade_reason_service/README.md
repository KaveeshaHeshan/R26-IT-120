# Grade-C Reason Service

This service uses the existing trained Isolation Forest for pH, temperature and turbidity, then adds transparent contextual quality checks (VFA, preservative ratio, storage duration, weather and tree condition) to explain a supervisor-confirmed Grade C.

The service writes the complete explanation to `grade_alerts/{farmerUid}`. The farmer app listens to that document in real time and displays the Grade C reason, contributing factors, measurements and practical improvement tips.

The existing model is not silently retrained. If a future A/B/C supervised model is trained from labelled `collections` history, it can replace the anomaly model while keeping the same response contract.

Run:

```bash
cd grade_reason_service
pip install -r requirements.txt
set FIREBASE_SERVICE_ACCOUNT=C:\real\path\to\service-account.json
python app.py
```

The project includes the development credential at
`grade_reason_service\model\rubberquality-33cab-firebase-adminsdk-fbsvc-4a31e13ded.json`,
so the service also uses that file automatically when
`FIREBASE_SERVICE_ACCOUNT` is not set. For production, set
`FIREBASE_SERVICE_ACCOUNT` to a protected service-account file and do not
commit credentials. Do not use the literal example path
`C:\full\path\to\your\firebase-service-account.json`.

Endpoint: `POST /grade-reason`

Required identity/input: `userId`, `grade=C`. The model inputs `ph`, `temperature`
and `turbidity` are optional: when present they enable the Isolation Forest
analysis; when absent the service still saves a contextual Grade-C explanation
and improvement tips, while reporting the missing sensor fields. Optional
context: `vfa`, `latex_volume_l`, `trees_count`, `storage_duration_hours`,
`actual_ammonia_ratio`, `weather_condition`, `tree_condition`, `collectionId`.
