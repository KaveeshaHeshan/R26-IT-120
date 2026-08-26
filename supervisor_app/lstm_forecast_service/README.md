# LSTM forecast service

This standalone service is only for the per-farmer VFA LSTM model. It does not
read, write, or alter the VFA regression, anomaly, or route-optimisation models.

Install dependencies and run it:

```powershell
cd lstm_forecast_service
python -m pip install -r requirements.txt
python app.py
```

Send `POST /forecast` with a Firebase `userId`, a model-supported `farmerId`
(`F001` through `F012`), exactly 30 chronological `sequenceRecords`, and a
target-day `context` object. The exact input fields are listed in
`model/metadata.json`.

The response contains `predictedVfa`, `riskProbability`, `riskLevel`, and
`alert`. The farmer dashboard reads the same fields from
`quality_forecasts/{userId}`. Add `"saveToFirestore": true` to the request and
set `FIREBASE_SERVICE_ACCOUNT` to a Firebase Admin SDK service-account JSON
file path to write that document automatically.
