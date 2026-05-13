# 🌿 IoT-Enabled Rubber Quality Assessment and Streamlined Latex Collection System

<p align="center">
  <img src="https://img.shields.io/badge/Project-R26--IT--120-7F77DD?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Institution-SLIIT-003087?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Year-2026-1D9E75?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Status-In%20Progress-C98A14?style=for-the-badge" />
</p>

<p align="center">
  <b>A final-year research project by the Department of Information Technology, SLIIT, Sri Lanka.</b><br/>
  Supervised by <b>Prof. Pradeep Abeygunawardhana</b> | Co-supervised by <b>Mr. Ashvinda Iddemagoda</b> | External Supervisor: <b>Prof. Asha Galhenage</b>
</p>

---

## 📌 Table of Contents

- [Project Overview](#-project-overview)
- [The Problem](#-the-problem)
- [Proposed Solution](#-proposed-solution)
- [System Architecture](#-system-architecture)
- [Team & Individual Components](#-team--individual-components)
  - [Member 1 — IoT Hardware & VFA Prediction](#member-1--iot-hardware--vfa-prediction-model)
  - [Member 2 — Security Architecture & Anomaly Detection](#member-2--security-architecture--anomaly-detection)
  - [Member 3 — DQN Route Optimiser & Field-to-Cloud Communication](#member-3--dqn-route-optimiser--field-to-cloud-communication)
  - [Member 4 — LSTM Quality Forecasting & Farmer Dashboard](#member-4--lstm-quality-forecasting--farmer-dashboard)
- [Dataset](#-dataset)
- [Tech Stack](#-tech-stack)
- [SDG Alignment](#-sdg-alignment)
- [Industry Validation](#-industry-validation)
- [Expected Outcomes & KPIs](#-expected-outcomes--kpis)
- [Project Timeline](#-project-timeline)
- [Budget](#-budget)
- [References](#-references)

---

## 🌍 Project Overview

The natural rubber industry is a cornerstone of Sri Lanka's agricultural export economy. Yet, the rubber latex collection and quality assessment process remains heavily reliant on **manual measurements, subjective judgment, and delayed laboratory testing** — practices that have not meaningfully changed in decades.

This research project introduces a **fully integrated, IoT-enabled digital system** that transforms rubber latex collection from a fragmented, paper-based workflow into a **smart, data-driven, and transparent supply chain**. The system addresses every stage of the collection process — from the moment latex leaves the tree to the moment it arrives at the factory gate.

The core challenge this project solves: **Volatile Fatty Acid (VFA)** levels — the primary indicator of latex freshness and quality — can currently only be determined through laboratory testing, a process that takes **6 to 8 hours**. By the time a result is returned, the latex has already been collected, transported, and often mixed with other batches, making contamination irreversible.

This research eliminates that delay entirely.

---

## ❗ The Problem

| Problem | Impact |
|---|---|
| No real-time VFA detection at collection point | Lab testing takes 6–8 hrs; contaminated batches are only identified after the damage is done |
| Quality-blind collection routing | Routes planned by distance or habit, ignoring latex spoilage risk |
| Remote plantation connectivity gaps | 4G/5G is unavailable in most rubber plantation areas |
| Subjective quality assessment | Supervisors rely on smell and visual inspection — highly error-prone |
| No traceability or digital audit trail | Paper-based records lead to pricing disputes, data loss, and lack of accountability |
| Farmer-side adulteration | Addition of water, soap, or starch is undetected until factory lab testing |

**Stakeholders directly affected:**
- 🌱 **Smallholder Farmers** — pricing uncertainty, delayed payments, lack of quality visibility
- 🚛 **Collection Supervisors** — manual coordination, no real-time data support
- 🏭 **Rubber Factories** — batch rejections, high lab dependency, financial loss from contamination
- 🇱🇰 **Sri Lankan Rubber Industry** — reduced global competitiveness due to operational inefficiency

---

## 💡 Proposed Solution

The system is composed of **four tightly integrated components**, each developed by one research team member, designed to work together as a single pipeline:

```
[IoT Sensor Device] ──WiFi──► [Cloud / MQTT Broker] ──► [ML Models] ──► [DQN Route Agent]
        │                                                                        │
        └──► [Supervisor Mobile App] ◄──── [Optimised Stop List + VFA Alerts] ◄─┘
                        │
                        └──► [Factory Dashboard] ◄──── [LSTM Forecasts + Farmer Portal]
```

1. **Real-time VFA soft-sensing** at the collection point using IoT sensors and a machine learning regression model — eliminating lab dependency
2. **Intelligent route optimisation** using a Deep Q-Network (DQN) that prioritises collection stops by chemical urgency, not distance
3. **Secure, anomaly-detecting architecture** that flags adulterated latex and protects farmer data end-to-end
4. **Time-series quality forecasting** using LSTM to predict future quality trends per farmer and enable transparent, data-backed pricing

---

## 🏗 System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        USER INTERACTION TIER                         │
│         Farmer App  |  Supervisor Mobile App  |  Factory Dashboard   │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────────┐
│                     APPLICATION PROCESSING TIER                      │
│   Communication | Security | Plugin Management | System Monitoring   │
│                     IoT & Sensor Module                              │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────────┐
│                  INTELLIGENCE & CONNECT MODULE TIER                  │
│  Vehicle Tracking | DQN Route Optimiser | Farmer Records | Offline  │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────────┐
│                       PERSISTENCE TIER                               │
│        Database (Collections, GPS, Routes)  |  Blockchain Audit Log  │
└─────────────────────────────────────────────────────────────────────┘
```

All microservices are containerised via **Docker**, decoupled via **Apache Kafka**, and secured with **mTLS on all IoT-to-cloud connections**.

---

## 👥 Team & Individual Components

---

### Member 1 — IoT Hardware & VFA Prediction Model

**Senarathna V K P K H | IT22167132**

#### Overview
This component is the **physical sensing layer** of the system. It develops a portable, field-deployable IoT device capable of capturing real-time chemical and physical properties of rubber latex, and uses a machine learning model to instantly predict the **Volatile Fatty Acid (VFA)** value — eliminating the need for laboratory testing during field collection.

#### The Sub-Problem
The traditional Metrolac tool measures only **Dry Rubber Content (DRC)** — a physical measurement that tells nothing about the chemical freshness of the latex. Determining VFA requires sending samples to a laboratory, a process that takes 6–8 hours. In this window, degrading latex is routinely mixed with fresh batches, contaminating entire factory processing tanks.

#### Solution Approach
A portable **ESP32-based IoT device** is assembled with the following sensors:
- **pH Sensor (MD0415)** — measures acidity, a key VFA proxy
- **DS18B20 Temperature Sensor (MD0094)** — captures ambient and sample temperature
- **Turbidity Sensor (MD0591)** — detects dilution or foreign matter in latex

Sensor readings are stabilised using a **moving average filter** in firmware to reduce noise from field conditions. The processed readings are then sent as a JSON payload to the cloud over WiFi.

A **Random Forest Regression model** trained on paired sensor + lab-validated VFA ground-truth data (collected at Lalan Rubbers Pvt Ltd, ISO 506:2020 standard) maps the electronic signals to actual VFA concentrations.

#### Key Novelty
> No existing portable field device predicts VFA in rubber latex using multi-sensor fusion. This reduces quality assessment from **6–8 hours to under 5 seconds**.

#### Tech Stack
`ESP32` `Arduino / ESP-IDF` `pH / Turbidity / Temperature Sensors` `Python` `Scikit-learn` `Random Forest Regression` `Flask REST API` `React.js KPI Dashboard` `Firebase`

#### KPIs
- VFA prediction accuracy benchmarked against ISO 506:2020 lab results
- Real-time KPI dashboard for factory-level quality trend monitoring

---

### Member 2 — Security Architecture & Anomaly Detection

**Perera C A | IT22218162**

#### Overview
This component is the **trust and integrity layer** of the system. It ensures that every data record produced across the platform is authentic, tamper-evident, and accessible only to authorised parties — while simultaneously detecting fraudulent practices such as latex adulteration at the point of collection.

#### The Sub-Problem
The rubber collection process is vulnerable to **adulteration** — farmers adding water, soap, starch, or acidic substances to inflate the apparent volume or weight of their latex. Current supervisors have no scientific tool to detect this in the field. Additionally, the absence of any digital audit trail means quality disputes between farmers and factories cannot be resolved objectively.

#### Solution Approach

**Security Architecture:**
- **RBAC (Role-Based Access Control)** with OTP/JWT authentication controls access across farmer, supervisor, factory, and admin roles
- **mTLS (Mutual TLS)** encrypts all IoT-to-cloud MQTT connections requiring device-specific certificates
- **AES-256 field-level encryption** protects sensitive farmer payment records and quality histories
- **Secure Boot v2** on ESP32 hardware ensures only digitally signed firmware executes on field devices
- **Offline data buffering** using SQLCipher (encrypted SQLite) stores sensor readings during network outages and syncs on reconnection
- **Blockchain-backed audit log** provides a tamper-evident, immutable record of every collection event

**Anomaly Detection (ML):**
- An **Isolation Forest** unsupervised machine learning model continuously monitors sensor data patterns (pH, turbidity, conductivity) for statistical anomalies
- Abnormal sensor signatures that match known adulteration patterns trigger an automatic alert to the supervisor and factory dashboard

#### Key Novelty
> First application of unsupervised anomaly detection for rubber latex adulteration identification at field level, combined with a multi-layer security framework from device firmware to cloud.

#### Tech Stack
`Firebase Auth` `JWT` `OTP` `RBAC` `mTLS` `AES-256` `SQLCipher` `Isolation Forest` `Scikit-learn` `Blockchain (Audit Log)` `Node.js` `Firestore`

#### KPIs
- SUS (System Usability Scale) score ≥ 70
- Zero data loss on offline/reconnect cycle
- Adulteration detection precision/recall benchmarked on labelled anomaly dataset

---

### Member 3 — DQN Route Optimiser & Field-to-Cloud Communication

**Wickramasinghe R M | IT22182432**

#### Overview
This component is the **logistics intelligence and communication layer** of the system. It replaces subjective, distance-based collection routing with an AI-driven agent that dynamically re-orders collection stops based on the **chemical urgency** of each batch, and provides the communication bridge that transmits sensor data from the field to the cloud in real time.

#### The Sub-Problem
Current collection routes are **quality-blind** — planned by habit or shortest distance, with no awareness of which farms have latex at the highest risk of spoilage. High-VFA (degrading) latex batches sit in the sun while supervisors collect fresher, nearer batches first. By the time the degraded batch is collected, it has fermented enough to contaminate the entire factory processing tank. Additionally, rural rubber plantations lack cellular connectivity, meaning quality data collected in the field had no reliable path to the cloud.

#### Solution Approach

**Field-to-Cloud Communication:**
- The **ESP32 sensor device** connects to the supervisor's smartphone via **WiFi (mobile hotspot)**, replacing the earlier BLE dependency with a simpler, more reliable connection
- Sensor readings are formatted as standardised **JSON payloads** and transmitted securely to an **Eclipse Mosquitto MQTT broker** using **mTLS encryption**
- An offline-first queue buffers records locally if the hotspot disconnects, syncing automatically on reconnection

**Deep Q-Network (DQN) Route Optimiser:**
- The collection problem is formally modelled as a **Markov Decision Process (MDP)**
- The **state vector** encodes: current GPS coordinates, remaining tank capacity (litres), time elapsed, ambient temperature, season index, and per-farm VFA quality estimates
- The **DQN agent** (built in PyTorch) learns through 10,000 simulated route iterations to maximise a specialised reward function:

```
R = SM(season, temp) × freshness_score(VFA) − distance_cost − time_penalty
```

- The **Seasonal Multiplier (SM)** dynamically adjusts VFA urgency based on Sri Lanka's bimodal monsoon calendar — recognising that the same VFA reading represents a very different level of risk in April (pre-monsoon, 30°C, SM=1.25) versus January (dry season, 26°C, SM=1.0)
- When a farm's VFA exceeds the seasonal threshold, the DQN agent triggers a **Critical VFA Alert** pushed to the supervisor's app in < 500ms via Firebase FCM

**Supervisor Mobile App (Flutter):**
- Field supervisors interact with an AI-ordered digital stop list, live GPS route map (Google Maps SDK), and real-time VFA alert notifications
- A **GPS tracking microservice** (Node.js) uses Haversine formula calculations cached in **Redis (TTL 65s)** to provide live ETAs to the factory
- A **200m geofence event** auto-triggers a batch arrival notification when the collection truck enters factory proximity

#### Key Novelty
> First application of a quality-aware DQN reward function in rubber latex logistics — the AI optimises for chemical freshness, not distance. The seasonal multiplier is the first formal encoding of Sri Lanka's monsoon calendar into a logistics reward function.

#### Tech Stack
`ESP32` `WiFi Hotspot` `MQTT` `mTLS` `Eclipse Mosquitto` `PyTorch` `Deep Q-Network (DQN)` `OpenAI Gym (simulation)` `Flutter (Dart)` `Google Maps SDK` `Node.js` `Redis` `Firebase FCM` `Kafka` `Docker`

#### KPIs
| Metric | Target |
|---|---|
| Route efficiency improvement | ≥ 25% reduction in total km vs. manual |
| Critical VFA alert latency | < 500ms |
| BLE/WiFi data sync reliability | ≥ 99.5% |
| ETA prediction accuracy | ± 5 minutes |
| IoT battery longevity | ≥ 12 hours per shift |

---

### Member 4 — LSTM Quality Forecasting & Farmer Dashboard

**Mihisarani A K S | IT22175366**

#### Overview
This component is the **predictive analytics and transparency layer** of the system. It analyses historical collection data to forecast future quality trends for individual farmers using a time-series model, and presents these insights to farmers through a digital portal — replacing opaque, dispute-prone manual grading with transparent, data-backed quality histories.

#### The Sub-Problem
The current system provides no mechanism for farmers to understand how their rubber is graded, why their payment is a certain amount, or how their practices affect quality over time. This opacity creates persistent **disputes between farmers and factories** with no digital evidence for resolution. Additionally, factories have no predictive capability — they cannot anticipate which farms will likely produce high-risk latex on a given collection day.

#### Solution Approach

**Data Modelling & Traceability:**
- A **relational database schema** links farmers, daily collections, sensor-derived quality values, factory batches, and payment records end-to-end
- Every collection event is traceable from sensor reading → quality grade → payment calculation → blockchain audit entry

**LSTM Quality Prediction:**
- A **Long Short-Term Memory (LSTM)** neural network analyses each farmer's sequential delivery history (DRC, VFA, volume, weather conditions)
- The model captures long-term quality patterns — recognising, for example, that a specific farmer consistently produces high-VFA latex during hot, humid weeks
- Outputs: **per-farmer quality trend forecasts** and **anomaly deviation alerts** for the factory

**Farmer Digital Portal:**
- A **React.js farmer-facing dashboard** visualises personal quality history, predicted trends, and grading explanations in a simple, accessible format
- Farmers can view their blockchain-verified collection history to independently verify payment calculations
- The portal reduces pricing disputes by replacing subjective verbal grading with an **auditable, evidence-based pricing mechanism**

#### Key Novelty
> First time-series quality forecasting system applied at individual farmer level in rubber latex collection — enabling proactive quality management and transparent, data-backed farmer-factory communication.

#### Tech Stack
`Python` `TensorFlow / Keras` `LSTM` `React.js` `Firebase Realtime Database` `Firestore` `Flask` `PostgreSQL` `Blockchain (audit trail)` `Node.js`

#### KPIs
- LSTM forecast accuracy (MAE/RMSE) on held-out VFA time-series test data
- Reduction in farmer-factory pricing disputes (pilot comparison)
- Farmer portal usability score (SUS ≥ 70)

---

## 📊 Dataset

The project uses a **hybrid dataset** composed of:

| Data Source | Description |
|---|---|
| **Lalan Rubbers Lab Records** | ISO 506:2020 validated VFA measurements, DRC values, TSC readings — ground-truth for ML model training |
| **IoT Sensor Telemetry** | Real-time pH, turbidity, temperature, conductivity readings paired with lab results |
| **GPS & Operational Logs** | Vehicle positions, timestamps, farm visit sequences, collection quantities |
| **Weather API (OpenWeatherMap)** | Ambient temperature and humidity for seasonal multiplier calibration |
| **RRISL Climate Data** | Historical fermentation rate data correlated with monsoon periods |
| **Synthetic Simulation Data** | 10,000 route scenarios generated in OpenAI Gym for DQN training |

The dataset (`Latex_ML_Dataset_Updated.csv`) contains **11,010 records** across **23 features** including pH, turbidity, temperature, ammonia content, DRC, VFA, grade, GPS coordinates, and weather conditions.

> ⚠️ All farmer data is anonymised for model training. Raw records containing personal identifiers are stored with AES-256 field-level encryption and accessible only through RBAC-controlled interfaces.

---

## 🛠 Tech Stack

| Layer | Technologies |
|---|---|
| **IoT Hardware** | ESP32, pH Sensor (MD0415), DS18B20 Temp (MD0094), Turbidity Sensor (MD0591), IP54 Enclosure |
| **Firmware** | Arduino / ESP-IDF, Secure Boot v2, JSON payload schema |
| **Communication** | WiFi (Mobile Hotspot), MQTT, mTLS, Eclipse Mosquitto, Apache Kafka |
| **ML / AI** | Python, Scikit-learn, PyTorch, TensorFlow/Keras, Random Forest, LSTM, Isolation Forest, DQN |
| **Backend** | Node.js, Flask (REST API), Redis, PostgreSQL, Docker |
| **Mobile** | Flutter (Dart), Google Maps SDK, Firebase FCM |
| **Frontend** | React.js, Firebase Realtime Database |
| **Security** | JWT, OTP, RBAC, AES-256, mTLS, SQLCipher, Blockchain Audit Log |
| **DevOps** | Docker, GitHub, Apache Kafka, Redis |

---

## 🌱 SDG Alignment

| SDG | Goal | How This Project Contributes |
|---|---|---|
| **SDG 9** | Industry, Innovation & Infrastructure | Introducing IoT and AI to a traditional agricultural sector |
| **SDG 12** | Responsible Consumption & Production | Reducing batch contamination and production waste through real-time grading |
| **SDG 13** | Climate Action | AI route optimisation reduces fuel consumption and carbon emissions from collection vehicles |

---

## 🏭 Industry Validation

This research has been validated through a direct on-site collaboration with:

> **Lalan Rubbers (Pvt) Ltd.**
> No. 95B, Zone A, Biyagama Export Processing Zone (BEPZ), Walgama, Malwana, Sri Lanka
> *Site visit conducted: 10 March 2026*

Factory representatives and quality assurance officers confirmed:
- Current VFA assessment is exclusively post-collection laboratory testing with no field-level detection
- Latex adulteration is a recognised, recurring operational challenge causing measurable financial losses
- Collection supervisors rely on unreliable subjective checks (visual, smell-based)
- Factory management expressed direct interest in a real-time, field-deployable quality grading and fraud detection system

---

## 🎯 Expected Outcomes & KPIs

| KPI | Target |
|---|---|
| Route efficiency improvement | ≥ 25% reduction in total km per collection cycle |
| VFA assessment speed | < 5 seconds (vs. 6–8 hours lab testing) |
| Critical VFA alert latency | < 500ms from sensor reading to supervisor phone |
| Data sync reliability (WiFi/field) | ≥ 99.5% successful transmissions |
| ETA prediction accuracy | ± 5 minutes margin |
| IoT device battery life | ≥ 12 hours continuous field operation |
| Transportation-induced VFA rise reduction | ≥ 20% (Mean Freshness Index) |
| System usability score | SUS ≥ 70 |

---

## 📅 Project Timeline

| Phase | Period | Milestone |
|---|---|---|
| Proposal & Planning | Jan – Mar 2026 | ✅ Proposal submission & supervisor approval |
| Hardware & Firmware | Feb – Apr 2026 | ESP32 assembly, sensor calibration, field data collection |
| ML Model Development | May – Jul 2026 | VFA prediction, anomaly detection, LSTM training |
| DQN & App Development | May – Aug 2026 | Route optimiser, Flutter app, GPS microservice |
| Integration & Testing | Aug – Sep 2026 | Full system integration, end-to-end testing |
| Progress Presentation 2 | Sep 2026 | ⬜ PP2 milestone |
| Final Report & Viva | Nov 2026 | ⬜ Final submission |
| Publication Evidence | Dec 2026 | ⬜ Research paper submission |

---

## 💰 Budget

| Category | Estimated Cost (LKR) |
|---|---|
| Hardware (ESP32, sensors, enclosures × 10 sets) | 6,600 |
| Software licenses (GitHub Pro, Flutter tools) | 13,000 |
| Cloud services (hosting, DB, SSL — 12 months) | 38,000 |
| Field data collection & lab VFA testing fees | 25,000 |
| Miscellaneous (printing, documentation) | 2,000 |
| **Total** | **84,600** |

---

## 📚 References

1. Rubber Research Institute of Sri Lanka (RRISL), *Collection and Preservation of Latex and Advisory Circulars*, rrisl.gov.lk, 2026.
2. A. Al-Fuqaha et al., "Internet of Things: A Survey on Enabling Technologies, Protocols, and Applications," *IEEE Communications Surveys & Tutorials*, vol. 17, no. 4, 2015.
3. M. Nazari et al., "Reinforcement Learning for Solving the Vehicle Routing Problem," in *NeurIPS*, 2018.
4. ANRPC, *Natural Rubber Statistics and Sustainable Agriculture Standards*, anrpc.org, 2026.
5. H. M. Jawad et al., "Energy-efficient wireless sensor networks for precision agriculture," *Sensors*, vol. 17, no. 8, 2017.
6. S. Kadyrov et al., "Deep reinforcement learning for dynamic vehicle routing," *Operations Research Perspectives*, 2025.
7. Spectroscopy Online, "Smart Farming: How IoT and Sensors are Changing Agriculture," Feb. 2025.
8. A. Rong et al., "An optimization model for managing freshness in a food supply chain," *Int. Journal of Production Economics*, vol. 131, no. 1, 2011.
9. J. Ma et al., "JPDS-NN: Reinforcement Learning-Based Dynamic Task Allocation," ResearchGate, Nov. 2025.
10. "A Survey on Real-Time Data Transfer and Energy Consumption Strategies for Rural IoT Technologies," *IEEE Xplore*, Nov. 2025.
11. Parliament of Sri Lanka, *Personal Data Protection Act, No. 9 of 2022*, Colombo: Government Publications Bureau, 2022.

---

<p align="center">
  <b>R26-IT-120 · Department of Information Technology · SLIIT · 2026</b><br/>
  <i>Senarathna V K P K H · Perera C A · Wickramasinghe R M · Mihisarani A K S</i>
</p>
