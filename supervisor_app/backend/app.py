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


@app.after_request
def add_cors_headers(resp):
    """Allow the Flutter web build to call this API from the browser.

    Flutter web issues real cross-origin requests, and a JSON content-type
    triggers a preflight. Without these headers the browser blocks the call
    before Flask sees it, which surfaces in the app as the opaque
    "ClientException: Failed to fetch". Flask already answers the OPTIONS
    preflight itself; only the headers were missing.

    "*" is fine for a dev server on a local hotspot. Restrict the origin if
    this is ever exposed beyond that.
    """
    resp.headers["Access-Control-Allow-Origin"] = "*"
    resp.headers["Access-Control-Allow-Headers"] = "Content-Type"
    resp.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return resp


# ----------------------------------------------------------------------
# 1. Load everything ONCE at startup (not per request)
# ----------------------------------------------------------------------
SPOILAGE = joblib.load("spoilage_model.joblib")   # {'model','columns'} (+ optional 'num','cat')
CONFIG = json.load(open("farmers.json"))

# The saved model only carries {'model','columns'}, so the numeric/categorical
# split is derived from the training column names instead of being read off the
# file. If a future export does include 'num'/'cat', those are used as-is.
#
# Derivation cannot simply split on "_": 'hours_since_tapping' contains
# underscores but is a single numeric feature. A request key is therefore
# numeric when it appears verbatim in the training columns, and categorical
# when the columns contain one-hot expansions named "<key>_<value>".
COLUMNS = list(SPOILAGE["columns"])
_COLSET = set(COLUMNS)


def split_features(keys):
    """Split request keys into (categorical, numeric) using the training columns.

    Keys matching neither are unknown to the model; reindex drops them later.
    """
    saved_cat = SPOILAGE.get("cat")
    saved_num = SPOILAGE.get("num")
    if saved_cat is not None and saved_num is not None:
        return list(saved_cat), list(saved_num)

    cat, num = [], []
    for k in keys:
        if k in _COLSET:
            num.append(k)
        elif any(c.startswith(f"{k}_") for c in COLUMNS):
            cat.append(k)
    return cat, num


def known_values(base):
    """Category values the model was trained on for a categorical feature."""
    prefix = f"{base}_"
    return {c[len(prefix):] for c in COLUMNS if c.startswith(prefix)}

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
    cat, _num = split_features(record.keys())

    # An unrecognised category one-hot encodes to a column the model never saw,
    # which reindex then drops — leaving that feature all-zeros and quietly
    # skewing the score instead of raising. Log it so it is at least visible.
    for base in cat:
        value = record.get(base)
        if value is not None and value not in known_values(base):
            app.logger.warning(
                "unknown %s=%r; model knows %s. Feature encoded as all-zeros.",
                base, value, sorted(known_values(base)),
            )

    row = pd.DataFrame([record])
    if cat:
        row = pd.get_dummies(row, columns=cat)
    row = row.reindex(columns=COLUMNS, fill_value=0)  # align to training columns
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
