"""
test_predict.py
Manual test — feed sample sensor readings straight into the ML pipeline,
without going through Firebase or the /predict HTTP route (no JWT needed).

Run this WHILE app.py is NOT running (both would fight over the same
Firebase connection / port).

Usage:
    python test_predict.py
"""

from app import process_and_predict

# ── Edit these values to whatever you want to test ──
samples = [
    {"pH": 10.9,  "turbidity": 35,  "temperature": 29,   "farmer_id": "TEST010"},
    # your real reading
]

for i, s in enumerate(samples, start=1):
    print(f"\n--- Sample {i}: {s} ---")
    result = process_and_predict(
        pH=s["pH"],
        turbidity=s["turbidity"],
        temperature=s["temperature"],
        farmer_id=s["farmer_id"],
        device_id="TEST_DEVICE",
    )
    if result is None:
        print("❌ Skipped — out of valid sensor range")
    else:
        print(f"✅ VFA={result['vfa']}  Grade={result['grade']}")