print("Sensor-assisted preprocessing started...")

import os
import pandas as pd
from sklearn.preprocessing import LabelEncoder, MinMaxScaler

os.makedirs("data/processed", exist_ok=True)

# Load datasets
latex_data = pd.read_csv("data/raw/Latex_ML_Dataset.csv")
farmer_data = pd.read_csv("data/raw/farmer_dataset.csv")
weather_data = pd.read_csv("data/raw/merged_weather_all.csv")
tapping_data = pd.read_csv("data/raw/tapping_dataset.csv")

print("Original Shapes:")
print("Latex:", latex_data.shape)
print("Farmer:", farmer_data.shape)
print("Weather:", weather_data.shape)
print("Tapping:", tapping_data.shape)

# Remove duplicates
for df in [latex_data, farmer_data, weather_data, tapping_data]:
    df.drop_duplicates(inplace=True)

# Rename weather columns
weather_data.rename(columns={
    'temperature_2m_max (°C)': 'temp_max',
    'temperature_2m_min (°C)': 'temp_min',
    'temperature_2m_mean (°C)': 'temp_mean',
    'relative_humidity_2m_max (%)': 'humidity_max',
    'relative_humidity_2m_min (%)': 'humidity_min',
    'precipitation_sum (mm)': 'precipitation',
    'wind_speed_10m_max (km/h)': 'wind_speed'
}, inplace=True)

# Convert dates
date_map = {
    'collection_date': latex_data,
    'date': farmer_data,
    'tapping_date': tapping_data,
    'time': weather_data
}

for col, df in date_map.items():
    if col in df.columns:
        df[col] = pd.to_datetime(
            df[col],
            format="mixed",
            dayfirst=True,
            errors="coerce"
        )

# Force numeric columns
numeric_cols = {
    "latex": [
        'pH', 'pH_duplicate', 'turbidity_ntu', 'turbidity_log',
        'temperature_c', 'ammonia_content', 'color_score',
        'vfa', 'drc'
    ],
    "farmer": [
        'land_size', 'tree_count', 'tapping_hour', 'tapping_minute',
        'collection_gap_hours', 'storage_duration_hours',
        'latex_quantity_kg', 'ammonia_amount_ml',
        'temperature_c', 'humidity_percent', 'rainfall_mm', 'drc_value'
    ],
    "tapping": [
        'tapping_hour', 'tapping_minute',
        'collection_gap_hours', 'storage_duration_hours',
        'latex_quantity_kg', 'ammonia_amount_ml'
    ],
    "weather": [
        'temp_max', 'temp_min', 'temp_mean',
        'humidity_max', 'humidity_min',
        'precipitation', 'wind_speed'
    ]
}

for col in numeric_cols["latex"]:
    if col in latex_data.columns:
        latex_data[col] = pd.to_numeric(latex_data[col], errors="coerce")

for col in numeric_cols["farmer"]:
    if col in farmer_data.columns:
        farmer_data[col] = pd.to_numeric(farmer_data[col], errors="coerce")

for col in numeric_cols["tapping"]:
    if col in tapping_data.columns:
        tapping_data[col] = pd.to_numeric(tapping_data[col], errors="coerce")

for col in numeric_cols["weather"]:
    if col in weather_data.columns:
        weather_data[col] = pd.to_numeric(weather_data[col], errors="coerce")

# Fill missing values
for df in [latex_data, farmer_data, weather_data, tapping_data]:
    num = df.select_dtypes(include=['number']).columns
    txt = df.select_dtypes(include=['object']).columns

    df[num] = df[num].fillna(df[num].mean())
    df[txt] = df[txt].fillna("Unknown")

# Aggregate farmer data
farmer_num_available = [
    col for col in numeric_cols["farmer"]
    if col in farmer_data.columns
]

farmer_numeric = farmer_data.groupby("farmer_id")[farmer_num_available].mean().reset_index()

farmer_cat_cols = [
    'experience', 'district', 'season',
    'ammonia_added', 'container_type'
]

farmer_cat_available = [
    col for col in farmer_cat_cols
    if col in farmer_data.columns
]

farmer_categorical = farmer_data.groupby("farmer_id")[farmer_cat_available].first().reset_index()

farmer_summary = pd.merge(
    farmer_numeric,
    farmer_categorical,
    on="farmer_id",
    how="left"
)

print("Farmer Summary:", farmer_summary.shape)

# Aggregate tapping data
tapping_num_available = [
    col for col in numeric_cols["tapping"]
    if col in tapping_data.columns
]

tapping_numeric = tapping_data.groupby("farmer_id")[tapping_num_available].mean().reset_index()

tapping_cat_cols = [
    'ammonia_added', 'container_type', 'experience'
]

tapping_cat_available = [
    col for col in tapping_cat_cols
    if col in tapping_data.columns
]

tapping_categorical = tapping_data.groupby("farmer_id")[tapping_cat_available].first().reset_index()

tapping_summary = pd.merge(
    tapping_numeric,
    tapping_categorical,
    on="farmer_id",
    how="left"
)

print("Tapping Summary:", tapping_summary.shape)

# Aggregate weather data
weather_num_available = [
    col for col in numeric_cols["weather"]
    if col in weather_data.columns
]

weather_summary = weather_data.groupby("district")[weather_num_available].mean().reset_index()

print("Weather Summary:", weather_summary.shape)

# Clean latex unnecessary ID columns only
latex_data.drop(columns=[
    'sample_id',
    'batch_number',
    'lab_technician',
    'truck_number'
], inplace=True, errors='ignore')

# Merge datasets
merged_data = pd.merge(
    latex_data,
    farmer_summary,
    on="farmer_id",
    how="left"
)

merged_data = pd.merge(
    merged_data,
    tapping_summary,
    on="farmer_id",
    how="left",
    suffixes=("_farmer", "_tapping")
)

if "district" in merged_data.columns:
    merged_data = pd.merge(
        merged_data,
        weather_summary,
        on="district",
        how="left"
    )

print("Merged Shape:", merged_data.shape)

# Fill missing after merge
num = merged_data.select_dtypes(include=['number']).columns
txt = merged_data.select_dtypes(include=['object']).columns

merged_data[num] = merged_data[num].fillna(merged_data[num].mean())
merged_data[txt] = merged_data[txt].fillna("Unknown")

# Feature engineering
if 'storage_duration_hours_farmer' in merged_data.columns:
    storage_col = 'storage_duration_hours_farmer'
elif 'storage_duration_hours' in merged_data.columns:
    storage_col = 'storage_duration_hours'
else:
    storage_col = None

if storage_col:
    merged_data['storage_risk'] = (merged_data[storage_col] > 6).astype(int)
else:
    merged_data['storage_risk'] = 0

if 'tapping_hour_farmer' in merged_data.columns and 'tapping_minute_farmer' in merged_data.columns:
    merged_data['tapping_total_hour'] = (
        merged_data['tapping_hour_farmer'] +
        merged_data['tapping_minute_farmer'] / 60
    )
elif 'tapping_hour' in merged_data.columns and 'tapping_minute' in merged_data.columns:
    merged_data['tapping_total_hour'] = (
        merged_data['tapping_hour'] +
        merged_data['tapping_minute'] / 60
    )
else:
    merged_data['tapping_total_hour'] = 0

# temperature + humidity interaction
temp_col = None
for col in ['temperature_c_x', 'temperature_c', 'temperature_c_farmer', 'temp_mean']:
    if col in merged_data.columns:
        temp_col = col
        break

humidity_col = None
for col in ['humidity_percent', 'humidity_percent_farmer', 'humidity_max']:
    if col in merged_data.columns:
        humidity_col = col
        break

if temp_col and humidity_col:
    merged_data['weather_stress'] = merged_data[temp_col] * merged_data[humidity_col]
else:
    merged_data['weather_stress'] = 0

# Remove only non-input leakage/output labels
merged_data.drop(columns=[
    'vfa_value',
    'quality_grade',
    'grade'
], inplace=True, errors='ignore')

# Remove date columns before ML
merged_data.drop(columns=[
    'collection_date',
    'date',
    'tapping_date',
    'time'
], inplace=True, errors='ignore')

# Check target
if 'vfa' not in merged_data.columns:
    raise ValueError("Target column 'vfa' not found!")

merged_data['vfa'] = pd.to_numeric(merged_data['vfa'], errors='coerce')
merged_data.dropna(subset=['vfa'], inplace=True)

# Encode categorical columns
encoder = LabelEncoder()

categorical_columns = merged_data.select_dtypes(include=['object']).columns

for col in categorical_columns:
    merged_data[col] = encoder.fit_transform(
        merged_data[col].astype(str)
    )

# Final missing cleanup
num = merged_data.select_dtypes(include=['number']).columns
merged_data[num] = merged_data[num].fillna(merged_data[num].mean())

# Drop columns still fully NaN
merged_data.dropna(axis=1, how='all', inplace=True)

# Scale features except target
target = merged_data['vfa']
features = merged_data.drop(columns=['vfa'])

scaler = MinMaxScaler()

features_scaled = pd.DataFrame(
    scaler.fit_transform(features),
    columns=features.columns
)

final_data = features_scaled.copy()
final_data['vfa'] = target.values

# Save
final_data.to_csv(
    "data/processed/final_sensor_assisted_dataset.csv",
    index=False
)

print("Sensor-assisted preprocessing completed successfully.")
print("Final Dataset Shape:", final_data.shape)
print("Saved to: data/processed/final_sensor_assisted_dataset.csv")