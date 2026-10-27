# Calories Calculator - Architecture & Technical Decisions Specification

## 1. Project Overview
A lightweight, privacy-first, on-device mobile application for tracking daily caloric intake against a calculated Total Daily Energy Expenditure (TDEE). All AI inference and data storage run locally on the user's mobile device without relying on external cloud APIs.

---

## 2. Technical Stack & Architecture Decisions

### Phase 1: User Profile & TDEE Calculation
* **Approach:** Pure Code / Mathematical Formula (No AI needed)
* **Algorithm:** Mifflin-St Jeor Equation
  * **BMR (Male):** $10 \times \text{weight (kg)} + 6.25 \times \text{height (cm)} - 5 \times \text{age (years)} + 5$
  * **BMR (Female):** $10 \times \text{weight (kg)} + 6.25 \times \text{height (cm)} - 5 \times \text{age (years)} - 161$
  * **TDEE:** $\text{BMR} \times \text{Activity Factor}$ ($1.2$ to $1.9$)
* **Execution:** Synchronous calculation directly in app state.

---

### Phase 2: Image Text Recognition (OCR)
* **Model:** `PP-OCRv4 Mobile` (PaddleOCR Mobile Edition)
* **Deployment:** On-Device (Android NPU/CPU or iOS Metal via ONNX Runtime / TFLite)
* **Input:** Image from Camera capture or File Gallery pick
* **Output:** Raw string / Bounding box text blocks
* **Resource Profile:** ~10-15 MB memory footprint, execution latency $< 300\text{ ms}$.

---

### Phase 3: Calorie & Macro Extraction
* **Model:** `Qwen2.5-0.5B-Instruct` (Quantized to `INT4`)
* **Deployment:** On-Device via `llama.cpp` / `MLC-LLM` / `ONNX`
* **Function:** Parses raw OCR text output and extracts structured nutritional values.
* **Prompt Strategy:**
  * Input: Raw text from OCR
  * Constraint: JSON-only output format `{ "calories": number, "protein": number, "carbs": number, "fat": number }`
* **Resource Profile:** ~350 MB RAM consumption, low CPU/GPU overhead.

---

### Phase 4: Data Storage & Automation
* **Storage Engine:** Local Storage (`SQLite` / `Hive` / `Room` / `CoreData`)
* **Persistence Policy:** 
  * Save daily total calories, individual entry history, and user settings.
  * 100% offline; no external network requests required.
* **Scheduled Reset:**
  * **Android:** `WorkManager` background worker.
  * **iOS:** `BGTaskScheduler` background task.
  * **Trigger:** Daily at user-defined time (e.g., 00:00 AM).
  * **Action:** Reset `current_daily_calories` to `0` while retaining historical log entries.

---

## 3. Data Flow Pipeline

```
[ User Input (Age/Height/Weight) ] ──> Mifflin-St Jeor Formula ──> [ Daily TDEE Target ]
                                                                             │
[ Camera / Gallery Image ]                                                   │
          │                                                                  │
          ▼                                                                  │
  [ PP-OCRv4 Mobile ] ──(Raw Text)──> [ Qwen2.5-0.5B INT4 ]                  │
                                              │                              │
                                      (Extracted JSON)                       │
                                              ▼                              │
                               [ User Confirmation Prompt ]                  │
                                              │                              │
                                           [ YES ]                           │
                                              │                              │
                                              ▼                              ▼
                                 [ Local Storage (SQLite) ] ──> [ Format: Consumed / TDEE ]
                                              │
                                              ▼
                             [ Background Worker (Reset @ Time) ]
```

---

## 4. Key Metrics & Optimization Constraints
* **App Binary Size:** Target $< 150\text{ MB}$ (including model weights).
* **Network Dependency:** Zero (100% Offline Capable).
* **Target Hardware:** Mid-range Android ($\ge 4\text{GB RAM}$) & iOS devices.

---

### Phase 3: Calorie & Macro Extraction
* **Model:** `Qwen2.5-0.5B-Instruct` (Quantized to `INT4`)
* **Deployment:** On-Device via `llama.cpp` / `MLC-LLM` / `ONNX`
* **Function:** Parses raw OCR text output and extracts structured nutritional values.
* **Prompt Strategy:**
  * Input: Raw text from OCR
  * Constraint: JSON-only output format `{ "calories": number, "protein": number, "carbs": number, "fat": number }`
* **Resource Profile:** ~350 MB RAM consumption, low CPU/GPU overhead.

---

### Phase 4: Data Storage & Automation
* **Storage Engine:** Local Storage (`SQLite` / `Hive` / `Room` / `CoreData`)
* **Persistence Policy:** 
  * Save daily total calories, individual entry history, and user settings.
  * 100% offline; no external network requests required.
* **Scheduled Reset:**
  * **Android:** `WorkManager` background worker.
  * **iOS:** `BGTaskScheduler` background task.
  * **Trigger:** Daily at user-defined time (e.g., 00:00 AM).
  * **Action:** Reset `current_daily_calories` to `0` while retaining historical log entries.

---

## 3. Data Flow Pipeline

```
[ User Input (Age/Height/Weight) ] ──> Mifflin-St Jeor Formula ──> [ Daily TDEE Target ]
                                                                             │
[ Camera / Gallery Image ]                                                   │
          │                                                                  │
          ▼                                                                  │
  [ PP-OCRv4 Mobile ] ──(Raw Text)──> [ Qwen2.5-0.5B INT4 ]                  │
                                              │                              │
                                      (Extracted JSON)                       │
                                              ▼                              │
                               [ User Confirmation Prompt ]                  │
                                              │                              │
                                           [ YES ]                           │
                                              │                              │
                                              ▼                              ▼
                                 [ Local Storage (SQLite) ] ──> [ Format: Consumed / TDEE ]
                                              │
                                              ▼
                             [ Background Worker (Reset @ Time) ]
```

---

## 4. Key Metrics & Optimization Constraints
* **App Binary Size:** Target $< 150\text{ MB}$ (including model weights).
* **Network Dependency:** Zero (100% Offline Capable).
* **Target Hardware:** Mid-range Android ($\ge 4\text{GB RAM}$) & iOS devices.

