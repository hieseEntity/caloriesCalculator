# Project Execution & Implementation Steps

This document outlines the chronological steps taken from the initial blank Flutter template to a fully functioning, on-device AI-powered Calories Calculator with automated Android build pipelines.

---

## Step 1: Specification Review & Architecture Documentation
* Extracted the technical requirements and architecture decisions covering four key phases:
  * Phase 1: Mifflin-St Jeor TDEE calculation (pure math).
  * Phase 2: On-device OCR text recognition (PP-OCRv4 Mobile).
  * Phase 3: Calorie & macro extraction using on-device quantized LLM (Qwen2.5-0.5B-Instruct INT4).
  * Phase 4: Offline local storage (SQLite) with automated midnight day rollover.
* Replaced the default Flutter boilerplate `README.md` with the comprehensive Technical Decisions Specification and pipeline diagram.

---

## Step 2: Workspace Discovery & Toolchain Setup
* Located the Flutter 3.47.8 SDK installation on the machine.
* Configured core dependencies in `pubspec.yaml`:
  * Internationalization and date formatting.
  * Local key-value preferences for settings and profile persistence.
  * Image picker for camera and gallery input.
  * Offline SQLite database engine and file path utilities.
  * SQLite FFI bindings for cross-platform desktop and unit testing support.
* Resolved package dependencies and verified the base testing environment.

---

## Step 3: Phase 1 — User Profile & TDEE Mathematical Engine
* Created domain models for the user profile, gender definitions, activity levels, and deficit/surplus calorie goals.
* Built the Mifflin-St Jeor formula engine to calculate:
  * Basal Metabolic Rate (BMR) for males and females.
  * Total Daily Energy Expenditure (TDEE) based on activity multipliers.
  * Calorie targets adjusted for weight loss or muscle gain goals.
  * Synchronous athletic macro distributions (Protein, Carbs, Fat).
* Created and passed unit tests validating calculation accuracy against standard clinical examples.

---

## Step 4: Phase 2 — Image Text Recognition (PP-OCRv4 Mobile)
* Established the OCR engine interface and text block models.
* Implemented the PP-OCRv4 Mobile engine abstraction:
  * Image file acquisition and validation.
  * Text block detection and bounding box grouping.
  * Sub-300ms latency execution profiling and telemetry recording.
  * Offline sample fallback for testing environments without native NPU/GPU drivers.

---

## Step 5: Phase 3 — Calorie & Macro Extraction (On-Device AI)
* Designed ChatML prompt templates for the Qwen2.5-0.5B-Instruct model.
* Configured GBNF grammar definitions for strict JSON token decoding.
* Implemented a zero-latency heuristic/regex fallback parser to extract nutritional values from standard FDA, EU, and Asian packaging formats.
* Implemented the Qwen extraction service combining prompt building, JSON parsing, confidence scoring, and telemetry tracking.
* Designed an editable user confirmation dialog allowing users to review, edit, or inspect raw OCR text before saving to the database.
* Created and passed unit tests validating prompt structure, heuristic label parsing, and end-to-end extraction.

---

## Step 6: Phase 4 — Data Storage & Automated Rollover
* Designed local SQLite schema for logged meals and daily historical summaries.
* Implemented the SQLite database helper with in-memory database creation for isolated testing.
* Built the user preferences service for saving user profiles and tracking active dates.
* Implemented the midnight rollover service:
  * Compares current date with last active session date.
  * Resets daily consumed calories to zero when crossing midnight or user-defined hours.
  * Preserves all historical meal entries organized by date.
* Created and passed SQLite database unit tests for insertion, daily grouping, deletion, and query operations.

---

## Step 7: State Management & Reactive Controllers
* Built the Profile Controller to reactively compute BMR, TDEE, and macro targets whenever profile inputs change, persisting state locally.
* Built the Tracker Controller to manage today's meal logs, calculate real-time calorie and macro totals, trigger day rollovers, and manage historical archives.

---

## Step 8: User Interface & Presentation Layer
* Defined a dark-mode health & fitness theme with custom color palettes for calories, protein, carbohydrates, and fats.
* Created visual custom widgets:
  * Circular animated calorie progress gauge showing consumed vs. target calories and remaining/over badges.
  * Macro progress cards for Protein, Carbs, and Fats.
  * Meal entry list items with delete actions and macro chips.
  * Modal bottom sheet for manual meal entry.
* Built main application screens:
  * Today's Dashboard Screen (gauge, macro cards, scan CTA, meals list).
  * AI Nutrition Scanner Screen (camera capture, photo picker, test presets, pipeline telemetry).
  * TDEE Profile Screen (live recalculation of BMR/TDEE with sliders and goal selectors).
  * Intake History Screen (past days list, progress bars, macro summaries).
* Connected all components in the main application entry point.

---

## Step 9: Verification, Quality Assurance & Linting
* Created full app widget smoke tests validating widget tree rendering, navigation tabs, and dashboard elements.
* Resolved Flutter test execution synchronization for SQLite FFI threads.
* Ran Flutter static analysis (`flutter analyze`), cleaned up deprecated member calls, unused variables, string interpolations, and asynchronous context guards to reach 0 warnings and 0 errors.
* Re-ran the complete test suite across all 4 test files to confirm 100% pass rate.

---

## Step 10: Android Platform Configuration
* Updated Android permissions in `AndroidManifest.xml` for camera access and image reading across Android 12, 13, and 14+.
* Marked camera hardware requirements as non-mandatory to support devices without cameras or emulators.
* Updated application label to user-facing name "Calories Calculator".
* Configured Gradle build scripts with Java 17 and Kotlin compatibility.

---

## Step 11: Git Version Control Setup
* Initialized local Git repository on branch `main`.
* Verified `.gitignore` excludes temporary build directories, pub caches, and IDE metadata.
* Configured repository author identity.
* Created initial commits tracking all project source files, tests, and configuration assets.

---

## Step 12: GitHub Actions CI/CD Pipeline for Android Export
* Created automated GitHub Actions workflow file:
  * Triggers on branch pushes, pull requests, version tags, or manual workflow dispatch.
  * Spins up Ubuntu cloud runners with pre-installed Java 17 and Android SDK.
  * Executes static analysis and test validation.
  * Compiles standalone release APK (`app-release.apk`).
  * Compiles Google Play App Bundle (`app-release.aab`).
  * Uploads build artifacts for direct download from the GitHub Actions tab.
  * Automatically creates GitHub Releases with attached APK files whenever version tags (`v*`) are pushed.
