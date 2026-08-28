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

def _state_vec(visited, cur, s, dist_matrix, dmax):
    curoh = np.zeros(N + 1, np.float32); curoh[cur] = 1
    dist = (dist_matrix[cur, :N] / dmax).astype(np.float32)
    return np.concatenate([visited.astype(np.float32), curoh, s.astype(np.float32), dist])


FALLBACK_COORD = {f["farmer_id"]: (f["latitude"], f["longitude"]) for f in FARMERS}
DEPOT_POINT = (DEPOT["latitude"], DEPOT["longitude"])


def resolve_points(records):
    """Coordinate per record: the one sent, else this farmer's farmers.json slot.

    Raises ValueError naming the farmers that have neither, rather than
    silently routing them from (0, 0).
    """
    pts, missing = [], []
    for rec in records:
        la, lo = rec.get("latitude"), rec.get("longitude")
        if isinstance(la, (int, float)) and isinstance(lo, (int, float)):
            pts.append((float(la), float(lo)))
            continue
        fallback = FALLBACK_COORD.get(rec["farmer_id"])
        if fallback is None:
            missing.append(rec["farmer_id"])
        else:
            pts.append(fallback)
    if missing:
        raise ValueError(
            "No coordinates for: " + ", ".join(missing) +
            ". Send latitude/longitude with the record, or add the farmer to farmers.json."
        )
    return pts


def build_distance_matrix(pts):
    """(N+1)x(N+1) matrix with the k routed farms at 0..k-1 and the depot at N.

    The network's input width is fixed at N, so unused slots stay zero; they
    are masked as already-visited and can never be chosen.
    """
    k = len(pts)
    all_pts = list(pts) + [DEPOT_POINT]
    slots = list(range(k)) + [N]           # where each point sits in the matrix
    M = np.zeros((N + 1, N + 1), dtype=np.float64)
    for i, a in enumerate(all_pts):
        for j, b in enumerate(all_pts):
            M[slots[i], slots[j]] = _haversine(a, b)
    return M


def plan_route(records, scores_by_id):
    """Order the given farmers (1..N of them) into a collection route.

    Farmers not included are masked as already-visited before the first step,
    which is the same mechanism the agent uses to avoid revisiting a stop. The
    policy was trained on full N-farm tours, so a partial tour is a heuristic
    restriction of that policy rather than a separately-optimised one.
    """
    k = len(records)
    if k == 0:
        return []
    if k > N:
        raise ValueError(f"At most {N} farmers can be routed at once; got {k}.")

    pts = resolve_points(records)
    dist_matrix = build_distance_matrix(pts)
    dmax = dist_matrix.max() or 1.0        # avoid divide-by-zero for a single stop

    s = np.zeros(N, dtype=np.float32)
    for i, rec in enumerate(records):
        s[i] = scores_by_id[rec["farmer_id"]] / 100.0

    visited = np.ones(N)                   # everything masked...
    visited[:k] = 0                        # ...except the farmers being routed

    cur = N                                # start at the depot
    order = []
    for _ in range(k):
        with torch.no_grad():
            q = DQN(torch.tensor(
                _state_vec(visited, cur, s, dist_matrix, dmax))).numpy()
        q[visited == 1] = -1e9
        a = int(q.argmax())
        order.append(a)                    # index into `records`
        visited[a] = 1
        cur = a
    return [(records[i]["farmer_id"], pts[i]) for i in order]

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
                         "experience": "3 - 5 years", "treeCondition": "Healthy",
                         "latitude": 6.713, "longitude": 79.9074}, ...]}

    Send between 1 and N farmers — any subset may be routed, and the ones left
    out are masked so the agent never selects them. `latitude`/`longitude` are
    optional per record; when absent, that farmer's farmers.json entry is used.
    """
    data = request.get_json(force=True)
    records = data.get("farmers") or []
    if not records:
        return jsonify(error="No farmers supplied."), 400

    # Coordinates are routing inputs, not model features — keep them out of
    # the record handed to the spoilage model.
    non_feature = {"farmer_id", "latitude", "longitude"}
    scores = {}
    for rec in records:
        fid = rec["farmer_id"]
        scores[fid] = score_one(
            {k: v for k, v in rec.items() if k not in non_feature})

    try:
        routed = plan_route(records, scores)
    except ValueError as e:
        return jsonify(error=str(e)), 400

    stops = [
        {
            "order": i + 1,
            "farmer_id": fid,
            "latitude": pt[0],
            "longitude": pt[1],
            "spoilage_risk_score": round(scores[fid], 1),
        }
        for i, (fid, pt) in enumerate(routed)
    ]

    return jsonify(
        collection_order=[fid for fid, _ in routed],
        scores={k: round(v, 1) for k, v in scores.items()},
        depot={"latitude": DEPOT["latitude"], "longitude": DEPOT["longitude"]},
        stops=stops,
        routed_count=len(stops),
        note=(
            f"Route from DQN over {len(stops)} of {N} slots; scores 0-100. "
            "Unselected farmers are masked. The policy was trained on full "
            f"{N}-farm tours, so a partial route is a heuristic restriction "
            "of it — do not quote route-efficiency figures without retraining."
        ),
    )

if __name__ == "__main__":
    # 0.0.0.0 so the phone on the same hotspot can reach it
    app.run(host="0.0.0.0", port=5000, debug=True)
