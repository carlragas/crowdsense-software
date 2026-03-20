# Product Requirements Document (PRD): CrowdSense

**Project Name:** CrowdSense: Intelligent Crowd Monitoring and Emergency Alert System
**Project Type:** Computer Engineering Thesis
**Target Academic Standard:** Polytechnic University of the Philippines – College of Engineering and Architecture (PUP CEA)
**Tech Stack:** Flutter (Frontend), Firebase (Backend/Database), ESP32 WROOM32D (Hardware), Arduino IDE (Firmware)
**Communication Protocol:** REST APIs (HTTP/HTTPS) and JSON

---

## 1. Project Overview & Objective
CrowdSense is an integrated IoT and mobile application system designed to enhance building safety and spatial management. The system utilizes an ESP32 microcontroller equipped with a Time-of-Flight (ToF) sensor to accurately monitor foot traffic in hourly intervals, alongside a suite of environmental sensors (Flame, Gas/Smoke, Temperature) to detect potential fire hazards. The mobile app serves as the centralized command center, utilizing REST APIs to provide building administrators with historical analytics, device management, and critical emergency alerts when environmental thresholds are breached.

## 2. Target Audience
* **Building Administrators & Facility Managers:** Primary users who monitor building usage trends and safety status.
* **Safety & Security Personnel:** Users who require immediate, localized alerts and actionable data during emergency protocols.

---

## 3. System Architecture & Data Flow
* **Hardware Data Acquisition (ESP32):** The microcontroller continuously reads environmental data (Flame, Gas, Temperature) and processes local logic for the Time-of-Flight (ToF) entry/exit counts.
* **Hardware-to-Cloud Routine Logs (REST API):** Every 1 hour, the ESP32 compiles the net ToF count into a JSON payload and transmits it to the Firebase backend via an HTTP `POST` or `PUT` request. The local counter then resets.
* **Hardware-to-Cloud Emergency Interrupts (REST API):** If a hazard sensor crosses a critical threshold, the ESP32 immediately fires a high-priority HTTP request to update the emergency status flag in the database, bypassing the hourly cycle.
* **Cloud-to-App Historical Data (REST API):** The Flutter application utilizes Dart HTTP packages to make RESTful `GET` requests, retrieving the hourly traffic logs and historical hazard events to populate charts and tables.
* **Cloud-to-App Real-Time Alerts:** The app maintains a lightweight stream or high-frequency polling mechanism to monitor the specific Firebase endpoint dedicated to the emergency status flag, ensuring latency requirements for critical alerts are met.

---

## 4. Core App Features (Requirements)

### 4.1. Real-Time Monitoring Dashboard
* **Active Hourly Counter:** Displays the net number of people (Entries minus Exits) currently inside the building for the active 1-hour window.
* **Sync & Reset Timer:** A visual indicator showing the time remaining until the current hour's count is finalized, logged, and reset to zero.
* **Sensor Status Grid:** Displays real-time readings from the Temperature, Gas, and Flame sensors.

### 4.2. Emergency Alert Protocol
* **Threshold Triggers:** The app must react when Firebase registers data exceeding defined safety parameters.
* **Visual & Audio Alarms:** When an alert is triggered, the app screen must display a prominent red warning overlay and trigger a localized phone notification/sound.

### 4.3. Analytics & Device Activity Logs
* **Hourly Foot Traffic Logs:** A database view showing the total number of entries and exits recorded in each 1-hour block, allowing administrators to identify peak building usage times.
* **Hazard & Activity Logs:** A chronological log of any times the sensors triggered a warning or alert state, integrated alongside the hourly ToF data points for comprehensive safety audits.

### 4.4. Device & System Management
* **Hardware Connectivity Status:** An indicator showing if the ESP32 is currently online and communicating with Firebase.
* **Threshold Configuration:** A settings page where the admin can adjust the trigger points (e.g., setting the critical temperature from 45°C to 50°C).

---

## 5. Sensor Threshold Guidelines (Configurable)

| Sensor Type | Standard Operation | Warning State | Critical/Alert State |
| :--- | :--- | :--- | :--- |
| **Temperature** | Below 35°C | 35°C - 45°C (Rapid rise) | Above 45°C |
| **Gas / Smoke** | Normal baseline | Minor elevation | High PPM (Combustible levels) |
| **Flame** | No IR detected | N/A | Flame detected (Immediate) |
| **ToF (Count)** | Continuous Counting | N/A | N/A (Resets & logs every 1 hour) |

---

## 6. Non-Functional Requirements
* **Latency:** The delay between a sensor detecting a hazard and the Flutter app displaying the alert should be under 2 seconds.
* **Reliability:** The ESP32 must have a reconnection protocol if the Wi-Fi drops, caching the current hour's ToF count locally to ensure data isn't permanently lost before the next REST payload is sent.
* **UI/UX:** The interface must be high-contrast and easy to read at a glance, especially during high-stress emergency situations.