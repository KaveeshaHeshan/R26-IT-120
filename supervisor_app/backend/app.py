"""
Latex Collection Backend  (Flask REST API)
------------------------------------------
Loads two trained models and turns a supervisor's request into a collection plan:

    farmer tapping data  ->  spoilage score (Random Forest)
    spoilage scores + GPS ->  collection order (DQN)

Endpoints
    GET  /health           -> quick check that models loaded
    POST /predict-spoilage -> one tapping record  -> 0-100 score
    POST /plan-collection  -> all farmers' tapping -> ordered route + scores

NOTE: the DQN was trained for a FIXED set of farmers (N = 12). This backend
serves that same fixed set. A different number of farmers needs retraining.
"""

import json
import numpy as np
import pandas as pd
import joblib
import torch
import torch.nn as nn
from flask import Flask, request, jsonify

app = Flask(__name__)

# ----------------------------------------------------------------------
# 1. Load everything ONCE at startup (not per request)
# ----------------------------------------------------------------------
SPOILAGE = joblib.load("spoilage_model.joblib")   # {'model','columns','num','cat'}
CONFIG = json.load(open("farmers.json"))

FARMERS = sorted(CONFIG["farmers"], key=lambda f: f["farmer_id"])   # keep training order
DEPOT = CONFIG["depot"]
N = len(FARMERS)
SDIM = N + (N + 1) + N + N

# distance matrix (real km) over farmers + depot (index N = depot)
def _haversine(a, b):
    R = 6371.0
    la1, lo1, la2, lo2 = map(np.radians, [a[0], a[1], b[0], b[1]])
    dla, dlo = la2 - la1, lo2 - lo1
    h = np.sin(dla / 2) ** 2 + np.cos(la1) * np.cos(la2) * np.sin(dlo / 2) ** 2
    return 2 * R * np.arcsin(np.sqrt(h))

_pts = [(f["latitude"], f["longitude"]) for f in FARMERS] + [(DEPOT["latitude"], DEPOT["longitude"])]
D = np.array([[_haversine(_pts[i], _pts[j]) for j in range(N + 1)] for i in range(N + 1)])
DMAX = D.max()

class QNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(SDIM, 128), nn.ReLU(),
            nn.Linear(128, 128), nn.ReLU(),
            nn.Linear(128, N),
        )
    def forward(self, x):
        return self.net(x)

DQN = QNet()
DQN.load_state_dict(torch.load("dqn_router.pt", map_location="cpu"))
DQN.eval()

# ----------------------------------------------------------------------
# 2. Helper functions
# ----------------------------------------------------------------------
def score_one(record: dict) -> float:
    """record = farmer-entered tapping fields -> 0-100 spoilage score."""
    row = pd.DataFrame([record])
    row = pd.get_dummies(row, columns=SPOILAGE["cat"])
    row = row.reindex(columns=SPOILAGE["columns"], fill_value=0)  # align to training columns
    return float(np.clip(SPOILAGE["model"].predict(row)[0], 0, 100))

def _state_vec(visited, cur, s):
    curoh = np.zeros(N + 1, np.float32); curoh[cur] = 1
    dist = (D[cur, :N] / DMAX).astype(np.float32)
    return np.concatenate([visited.astype(np.float32), curoh, s.astype(np.float32), dist])

def plan_route(scores_by_id: dict):
    """scores_by_id = {farmer_id: 0-100}. Returns ordered list of farmer_ids."""
    s = np.array([scores_by_id[f["farmer_id"]] for f in FARMERS], dtype=np.float32) / 100.0
    visited = np.zeros(N); cur = N; order = []
    for _ in range(N):
        with torch.no_grad():
            q = DQN(torch.tensor(_state_vec(visited, cur, s))).numpy()
        q[visited == 1] = -1e9
        a = int(q.argmax())
        order.append(FARMERS[a]["farmer_id"]); visited[a] = 1; cur = a
    return order

# ----------------------------------------------------------------------
# 3. Endpoints
# ----------------------------------------------------------------------
@app.get("/health")
def health():
    return jsonify(status="ok", farmers=N, models_loaded=True)

@app.post("/predict-spoilage")
def predict_spoilage():
    data = request.get_json(force=True)
    return jsonify(spoilage_risk_score=round(score_one(data), 1))

@app.post("/plan-collection")
def plan_collection():
    """
    Body: {"farmers": [{"farmer_id": "F001", "hours_since_tapping": 6.0,
                         "weatherCondition": "Rainy", "district": "Galle",
                         "experience": "3 - 5 years", "treeCondition": "Healthy"}, ...]}
    """
    data = request.get_json(force=True)
    scores = {}
    for rec in data["farmers"]:
        fid = rec["farmer_id"]
        scores[fid] = score_one({k: v for k, v in rec.items() if k != "farmer_id"})
    order = plan_route(scores)

    # coordinate lookup so the app can draw the route without holding GPS itself
    coord = {f["farmer_id"]: (f["latitude"], f["longitude"]) for f in FARMERS}
    stops = [
        {
            "order": i + 1,
            "farmer_id": fid,
            "latitude": coord[fid][0],
            "longitude": coord[fid][1],
            "spoilage_risk_score": round(scores[fid], 1),
        }
        for i, fid in enumerate(order)
    ]

    return jsonify(
        collection_order=order,
        scores={k: round(v, 1) for k, v in scores.items()},
        depot={"latitude": DEPOT["latitude"], "longitude": DEPOT["longitude"]},
        stops=stops,
        note="Route from DQN; scores 0-100. Depot/GPS from farmers.json.",
    )

if __name__ == "__main__":
    # 0.0.0.0 so the phone on the same hotspot can reach it
    app.run(host="0.0.0.0", port=5000, debug=True)
