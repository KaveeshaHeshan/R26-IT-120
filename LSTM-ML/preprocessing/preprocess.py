print("Script started...")

import os
import pandas as pd
from sklearn.preprocessing import LabelEncoder, MinMaxScaler

# =========================
# CREATE OUTPUT FOLDER
# =========================
os.makedirs("data/processed", exist_ok=True)

# =========================
# LOAD DATASETS
# =========================
latex_data = pd.read_csv("data/raw/Latex_ML_Dataset.csv")
farmer_data = pd.read_csv("data/raw/farmer_dataset.csv")
weather_data = pd.read_csv("data/raw/merged_weather_all.csv")
tapping_data = pd.read_csv("data/raw/tapping_dataset.csv")

print("Original Shapes:")
print("Latex:", latex_data.shape)
print("Farmer:", farmer_data.shape)
print("Weather:", weather_data.shape)
print("Tapping:", tapping_data.shape)

# =========================
# REMOVE DUPLICATES
# =========================
for df in [latex_data, farmer_data, weather_data, tapping_data]:
    df.drop_duplicates(inplace=True)

# =========================
# RENAME WEATHER COLUMNS
# =========================
weather_data.rename(columns={
    'temperature_2m_max (°C)': 'temp_max',
    'temperature_2m_min (°C)': 'temp_min',
    'temperature_2m_mean (°C)': 'temp_mean',
    'relative_humidity_2m_max (%)': 'humidity_max',
    'relative_humidity_2m_min (%)': 'humidity_min',
    'precipitation_sum (mm)': 'precipitation',
    'wind_speed_10m_max (km/h)': 'wind_speed'
}, inplace=True)

# =========================
# CONVERT DATES
# =========================
date_columns = {
    "latex": ("collection_date", latex_data),
    "farmer": ("date", farmer_data),
    "tapping": ("tapping_date", tapping_data),
    "weather": ("time", weather_data)
}

for name, (col, df) in date_columns.items():
    if col in df.columns:
        df[col] = pd.to_datetime(
            df[col],
            format="mixed",
            dayfirst=True,
            errors="coerce"
        )

# =========================
# FORCE NUMERIC COLUMNS
# =========================
farmer_numeric_cols = [
    'land_size', 'tree_count', 'collection_gap_hours',
    'storage_duration_hours', 'latex_quantity_kg',
    'ammonia_amount_ml', 'temperature_c',
    'humidity_percent', 'rainfall_mm', 'drc_value'
]

tapping_numeric_cols = [
    'tapping_hour', 'tapping_minute',
    'collection_gap_hours', 'storage_duration_hours',
    'latex_quantity_kg', 'ammonia_amount_ml'
]

weather_numeric_cols = [
    'temp_max', 'temp_min', 'temp_mean',
    'humidity_max', 'humidity_min',
    'precipitation', 'wind_speed'
]

latex_numeric_cols = [
    'pH', 'pH_duplicate', 'turbidity_ntu',
    'turbidity_log', 'temperature_c',
    'ammonia_content', 'color_score',
    'vfa', 'drc'
]

for col in farmer_numeric_cols:
    if col in farmer_data.columns:
        farmer_data[col] = pd.to_numeric(farmer_data[col], errors='coerce')

for col in tapping_numeric_cols:
    if col in tapping_data.columns:
        tapping_data[col] = pd.to_numeric(tapping_data[col], errors='coerce')

for col in weather_numeric_cols:
    if col in weather_data.columns:
        weather_data[col] = pd.to_numeric(weather_data[col], errors='coerce')

for col in latex_numeric_cols:
    if col in latex_data.columns:
        latex_data[col] = pd.to_numeric(latex_data[col], errors='coerce')

# =========================
# HANDLE MISSING VALUES
# =========================
for df in [latex_data, farmer_data, weather_data, tapping_data]:
    numeric_cols = df.select_dtypes(include=['number']).columns
    text_cols = df.select_dtypes(include=['object']).columns

    df[numeric_cols] = df[numeric_cols].fillna(df[numeric_cols].mean())
    df[text_cols] = df[text_cols].fillna("Unknown")

# =========================
# AGGREGATE FARMER DATA
# =========================
farmer_numeric_available = [
    col for col in farmer_numeric_cols
    if col in farmer_data.columns
]

farmer_numeric = farmer_data.groupby('farmer_id')[farmer_numeric_available].mean().reset_index()

farmer_cat_cols = [
    'experience', 'district', 'season',
    'ammonia_added', 'container_type'
]

farmer_cat_available = [
    col for col in farmer_cat_cols
    if col in farmer_data.columns
]

farmer_categorical = farmer_data.groupby('farmer_id')[farmer_cat_available].first().reset_index()

farmer_summary = pd.merge(
    farmer_numeric,
    farmer_categorical,
    on='farmer_id',
    how='left'
)

print("Farmer Summary:", farmer_summary.shape)

# =========================
# AGGREGATE TAPPING DATA
# =========================
tapping_numeric_available = [
    col for col in tapping_numeric_cols
    if col in tapping_data.columns
]

tapping_numeric = tapping_data.groupby('farmer_id')[tapping_numeric_available].mean().reset_index()

tapping_cat_cols = [
    'ammonia_added', 'container_type', 'experience'
]

tapping_cat_available = [
    col for col in tapping_cat_cols
    if col in tapping_data.columns
]

tapping_categorical = tapping_data.groupby('farmer_id')[tapping_cat_available].first().reset_index()

tapping_summary = pd.merge(
    tapping_numeric,
    tapping_categorical,
    on='farmer_id',
    how='left'
)

print("Tapping Summary:", tapping_summary.shape)

# =========================
# AGGREGATE WEATHER DATA
# =========================
weather_numeric_available = [
    col for col in weather_numeric_cols
    if col in weather_data.columns
]

weather_summary = weather_data.groupby('district')[weather_numeric_available].mean().reset_index()

print("Weather Summary:", weather_summary.shape)

# =========================
# CLEAN LATEX DATA
# =========================
latex_data.drop(columns=[
    'sample_id',
    'batch_number',
    'lab_technician',
    'truck_number'
], inplace=True, errors='ignore')

# =========================
# MERGE DATASETS SAFELY
# =========================
merged_data = pd.merge(
    latex_data,
    farmer_summary,
    on='farmer_id',
    how='left'
)

merged_data = pd.merge(
    merged_data,
    tapping_summary,
    on='farmer_id',
    how='left',
    suffixes=('_farmer', '_tapping')
)

if 'district' in merged_data.columns:
    merged_data = pd.merge(
        merged_data,
        weather_summary,
        on='district',
        how='left'
    )

print("Merged Shape:", merged_data.shape)

# =========================
# HANDLE MISSING VALUES AFTER MERGE
# =========================
numeric_cols = merged_data.select_dtypes(include=['number']).columns
text_cols = merged_data.select_dtypes(include=['object']).columns

merged_data[numeric_cols] = merged_data[numeric_cols].fillna(
    merged_data[numeric_cols].mean()
)

merged_data[text_cols] = merged_data[text_cols].fillna("Unknown")

# =========================
# FEATURE ENGINEERING
# =========================
storage_col = None

for col in [
    'storage_duration_hours_farmer',
    'storage_duration_hours',
    'storage_duration_hours_tapping'
]:
    if col in merged_data.columns:
        storage_col = col
        break

if storage_col:
    merged_data['storage_risk'] = (
        merged_data[storage_col] > 6
    ).astype(int)
else:
    merged_data['storage_risk'] = 0

temp_col = None

for col in [
    'temperature_c',
    'temperature_c_farmer',
    'temp_mean'
]:
    if col in merged_data.columns:
        temp_col = col
        break

humidity_col = None

for col in [
    'humidity_percent',
    'humidity_percent_farmer',
    'humidity_max'
]:
    if col in merged_data.columns:
        humidity_col = col
        break

if temp_col and humidity_col:
    merged_data['temp_humidity_index'] = (
        merged_data[temp_col] * merged_data[humidity_col]
    )
else:
    merged_data['temp_humidity_index'] = 0

# =========================
# REMOVE TARGET LEAKAGE
# =========================
merged_data.drop(columns=[
    'vfa_value',
    'quality_grade',
    'grade'
], inplace=True, errors='ignore')

# =========================
# REMOVE DATE COLUMNS BEFORE ML
# =========================
merged_data.drop(columns=[
    'collection_date',
    'date',
    'tapping_date',
    'time'
], inplace=True, errors='ignore')

# =========================
# CHECK TARGET
# =========================
if 'vfa' not in merged_data.columns:
    raise ValueError("Target column 'vfa' not found!")

merged_data['vfa'] = pd.to_numeric(
    merged_data['vfa'],
    errors='coerce'
)

merged_data.dropna(subset=['vfa'], inplace=True)

# =========================
# ENCODE TEXT COLUMNS
# =========================
encoder = LabelEncoder()

categorical_columns = merged_data.select_dtypes(include=['object']).columns

for col in categorical_columns:
    merged_data[col] = encoder.fit_transform(
        merged_data[col].astype(str)
    )

# =========================
# FINAL MISSING VALUE CHECK
# =========================
numeric_cols = merged_data.select_dtypes(include=['number']).columns

merged_data[numeric_cols] = merged_data[numeric_cols].fillna(
    merged_data[numeric_cols].mean()
)

# =========================
# SCALE FEATURES EXCEPT TARGET
# =========================
target = merged_data['vfa']
features = merged_data.drop(columns=['vfa'])

scaler = MinMaxScaler()

features_scaled = pd.DataFrame(
    scaler.fit_transform(features),
    columns=features.columns
)

final_data = features_scaled.copy()
final_data['vfa'] = target.values

# =========================
# SAVE FINAL DATASET
# =========================
final_data.to_csv(
    "data/processed/final_processed_dataset.csv",
    index=False
)

print("Preprocessing completed successfully.")
print("Final Dataset Shape:", final_data.shape)
print("Saved to: data/processed/final_processed_dataset.csv")