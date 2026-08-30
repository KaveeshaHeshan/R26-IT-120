# Grade-C Reason Service

Explains *why* a latex sample was graded C, using the Isolation Forest
anomaly-detection model trained in Colab
(`isolation_forest_model_.pkl` + `scaler_.pkl`).

## What the model actually uses

The scaler's `feature_names_in_` confirms the model was trained on
**three** features only:

```
pH, temperature_c, turbidity_ntu
```

**VFA is not a model input.** If you want VFA to factor into the
anomaly detection itself, it needs to be added as a fourth column in
the Colab training data and the model retrained/re-exported — this
service will pick that up automatically (it reads the feature list off
the scaler, not a hard-coded list), but until then VFA is only ever
carried through as *context* in the response, not used for the
prediction.

## Run locally

```bash
cd grade_reason_service
pip install -r requirements.txt
python app.py     # listens on 0.0.0.0:5002
```

This is the third Flask process in the project, alongside:
- `backend/app.py` — spoilage score + collection routing (port 5000)
- `lstm_forecast_service/app.py` — future VFA forecast (port 5001)
- `grade_reason_service/app.py` — this service, explains a *current*
  Grade C reading (port 5002)

They're kept separate so a slow/broken one never blocks the others,
same reasoning as the existing two.

## Endpoint

`POST /grade-reason`

```json
{
  "userId": "abc123",
  "ph": 5.9,
  "temperature": 34.0,
  "turbidity": 3150,
  "vfa": 0.091,
  "grade": "C",
  "saveToFirestore": true
}
```

`ph`, `temperature`, `turbidity` are required. `userId` is required
only when `saveToFirestore` is true. `vfa` / `grade` are optional and
echoed back as context.

Response:

```json
{
  "is_anomaly": true,
  "anomaly_score": -0.1116,
  "reason": "The model flags this reading as an anomaly consistent with spoiled/degraded latex: Turbidity is 3150.00NTU (typical is 2838.67NTU) -- cloudier than usual, consistent with early coagulation or contamination. Temperature is 34.00\u00b0C (typical is 29.21\u00b0C) -- warmer than usual, which speeds up bacterial growth and coagulation.",
  "deviations": [ /* all 3 features, most extreme z-score first */ ],
  "vfa": 0.091,
  "grade": "C"
}
```

When none of the three readings are unusual (all `|z| < 1.0`), the
`reason` says so explicitly rather than guessing — a Grade C call in
that case likely rests on VFA or another factor this model doesn't
see.

## Firestore persistence

When `saveToFirestore: true`, the result is written to
`grade_alerts/{userId}` using a Firebase Admin SDK identity (same
convention as `lstm_forecast_service`) — client writes to that
collection are blocked in `firestore.rules`; only this service's Admin
SDK identity may write it, and a farmer may only read their own
document.

Set `FIREBASE_SERVICE_ACCOUNT` to the path of a service-account JSON
key before running with persistence enabled, exactly as
`lstm_forecast_service` requires.

## Model versioning note

The pickles were trained with scikit-learn 1.6.1. Loading them under a
different installed version prints an `InconsistentVersionWarning` —
harmless for now, but if predictions ever look wrong after a dependency
upgrade, re-export the model from Colab under the pinned version above
before assuming the reasoning logic is at fault.
