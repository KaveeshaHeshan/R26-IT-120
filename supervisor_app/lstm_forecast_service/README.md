# LSTM forecast service

This standalone service is only for the per-farmer VFA LSTM model. It does not
read, write, or alter the VFA regression, anomaly, or route-optimisation models.

Install dependencies and run it:

```powershell
cd lstm_forecast_service
python -m pip install -r requirements.txt
python app.py
```

Runs on port `5001` by default (override with `PORT`) so it can run alongside
`backend/app.py`, which uses `5000`. Set `FIREBASE_SERVICE_ACCOUNT` to a
Firebase Admin SDK service-account JSON path before starting it if you want
`saveToFirestore: true` writes to work.

## Automatic call on a Grade C collection

`FirestoreService.saveCollection()` in the Flutter app calls this service's
`/forecast` automatically whenever a collection is saved with `grade: 'C'`
(see `lib/services/firestore_service.dart`, `triggerQualityForecast()`). It
builds `sequenceRecords` from that farmer's real `collections` history —
never from a guess — so with the app's current schema it will correctly come
back `insufficient_history` or `prediction_data_incomplete` until the fields
below actually get captured somewhere:

`drc_value`, `temperature_c`, `humidity_percent`, `rainfall_mm`,
`storage_duration_hours`, `collection_gap_hours`, `latex_quantity_kg`.

That is expected, not a bug — see the data-integrity rules just below. Once
those fields are logged (a lab DRC reading, a weather source, storage
timing), no further Flutter changes are needed for real predictions to start
flowing through the same call path.

Send `POST /forecast` with a Firebase `userId`, chronological
`sequenceRecords` (each with `capturedAt`), a target-day `context` object, and
`forecastDate`. The service reads and validates `displayId` from
`users/{userId}`; callers must not supply or infer it. The exact input fields
are listed in `model/metadata.json`.

## Data-integrity rules

- This trained model supports only `F001` through `F012`. It does not safely
  support a new farmer, and the service never maps a Firebase UID to a model
  farmer ID automatically.
- Every required numeric value must be provided as an actual value. Missing
  values are never replaced by zero, an average, or an estimate.
- The service sorts valid records by `capturedAt` and uses the latest 30. More
  than 30 records are allowed. Fewer than 30 valid records returns HTTP 422
  with `insufficient_history`.
- Missing target-day context fields return HTTP 422 with `missingFields`; no
  prediction is run.
- Reasons are built only from threshold comparisons and submitted sequence /
  context values. They identify observations, not causes.

The response and `quality_forecasts/{userId}` document contain `predictedVfa`,
`riskProbability`, `riskLevel`, `trend`, `reason`, `recommendations`,
`forecastDate`, and server-generated `updatedAt`. It also contains the
farmer-facing `title` and `message` so Flutter does not invent explanations.
Add `"saveToFirestore": true` to the request and set
`FIREBASE_SERVICE_ACCOUNT` to a Firebase Admin SDK service-account JSON file
path to write that document automatically.

## Current model inputs versus future collection data

The deployed model still requires its legacy `latex_quantity_kg` and
`ammonia_amount_ml` inputs exactly as recorded in `model/metadata.json`.
The app's new canonical field-data schema stores `latex_volume_l`,
`recommended_ammonia_l`, `recommended_ammonia_ratio`, `actual_ammonia_l`,
`actual_ammonia_ratio`, and `followed_standard_ammonia_ratio` for future
retraining only. `latex_volume_l` is never converted to kilograms or supplied
to this model.

When a new model is trained, its metadata and preprocessing must explicitly
define the new features. A future model may use `latex_volume_l` directly and
derive its ammonia features from the stored actual amounts and ratios; it must
not silently reuse the legacy kilogram feature. Feature selection must be
evaluated then: recommended ammonia is deterministic from volume, the actual
amount and ratio are mathematically related, and the followed-standard flag is
derived from the ammonia decision. These fields remain stored for traceability,
not as a commitment that every one will become a model feature.

## Historical validation demo

`demo_forecast.py` is a viva/demo utility for the existing F003 farmer, not a production data path. It
reads the original `farmer_dataset_12_farmers.csv`, selects a complete 30-row
historical window, and posts the real rows plus real target-event context to
the running API with `saveToFirestore: true`. It logs `DEMO_MODE` on the
backend only and does not change farmer-facing alert text.

- Both `--case normal` and `--case high` select matching genuine F003 test
  windows from the supplied prediction package.

The Firebase test user's existing `displayId` must be `F003`. The utility does
not create or modify the farmer document.
