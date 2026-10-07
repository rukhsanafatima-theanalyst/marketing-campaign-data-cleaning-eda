# Marketing Campaign Data Cleaning, EDA & ROI Optimization (MySQL Workbench)

## Executive Summary
This project analyzes **1,980 marketing campaigns** representing **$6.18 Million** in total ad spend, **98.7 Million impressions**, **2.97 Million clicks**, and **331,450 conversions**. Using **MySQL Workbench**, raw campaign data was cleaned, standardized, and queried to evaluate channel efficiency, active vs. inactive campaign performance, and campaign duration dynamics.

---

## Technical Architecture & Tools
* **Database Engine:** MySQL Workbench 8.0
* **Language:** SQL (Window Functions, CTEs, Date/Time Arithmetic, Conditional Logic, Aggregations)
* **Dataset:** [Messy Marketing Campaign Data (Kaggle)](https://www.kaggle.com/datasets/govindsingh9447/marketing-campaign-data-messy)
* **Artifacts:** Cleaning SQL scripts, query result CSVs, and an executive PDF strategy report.

---

## Key Data Cleaning & Modeling Protocols
1. **Deduplication:** Applied MySQL window functions (`ROW_NUMBER()`) to remove duplicate lead entries.
2. **Text & Tag Standardization:** Normalized casing, trimmed white spaces, and categorized campaign channels.
3. **Date & Duration Formatting:** Converted unformatted date strings to `DATETIME` formats and calculated exact campaign run-time durations (`DATEDIFF()`).
4. **Data Validation:** Imputed missing values and handled zero/negative spend metrics to preserve calculation integrity.

---

## Key Analytical Insights

### 1. Portfolio Baseline
* **Total Spend:** $6,179,454.28
* **Total Conversions:** 331,450
* **Overall Click-Through Rate (CTR):** 3.01%
* **Average Cost Per Click (CPC):** $2.08
* **Overall Cost Per Conversion (CAC):** $18.64

---

### 2. Channel Performance & Efficiency Tiers

| Efficiency Tier | Channel | Total Spend ($) | Total Conversions | CTR (%) | Avg CPC ($) | Cost / Conversion ($) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **High Efficiency** | **Instagram** | $633,951.12 | 56,874 | 2.98% | $1.23 | **$11.15** |
| **High Efficiency** | **Google Ads** | $666,030.70 | 59,436 | 3.03% | $1.27 | **$11.21** |
| **High Efficiency** | **TikTok** | $762,598.23 | 67,104 | 3.00% | $1.25 | **$11.36** |
| **Medium Efficiency**| **Facebook** | $1,760,416.71 | 68,441 | 3.06% | $2.85 | **$25.72** |
| **High Cost** | **Email** | $2,186,708.27 | 61,886 | 2.93% | $3.96 | **$35.33** |

---

### 3. Active vs. Inactive Campaign Dynamics
* **The Email Recovery Discovery:** While Email appears inefficient overall ($35.33 CAC), **currently active email campaigns operate at $11.19 CAC**. The overall average was heavily skewed by historical inactive campaigns ($74.75 CAC, $1.75M spend).
* **Systemic Facebook Inflation:** Active Facebook campaigns ($25.64 CAC) show no improvement over inactive ones ($25.80 CAC), indicating a platform-level efficiency limit.

---

### 4. Campaign Duration Analysis

| Duration Bracket | Campaigns | Total Spend ($) | Conversions | Avg CPC ($) | Cost / Conversion ($) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Short-term (< 7 Days)** | 442 | $1,806,316.82 | 74,107 | $2.74 | **$24.37** |
| **Medium-term (7–14 Days)** | 521 | $1,970,418.25 | 83,795 | $2.57 | **$23.51** |
| **Standard (15–30 Days)** | 999 | $2,360,813.94 | 170,057 | $1.56 | **$13.88** |
| **Long-term (> 30 Days)** | 18 | $41,905.27 | 3,491 | $1.21 | **$12.00** |

* **Algorithmic Learning Curve:** Campaigns running under 14 days suffer from ~$24.00 CAC because bidding engines do not complete the learning phase.
* **Extended Run-Time:** Campaigns running 15+ days reduce CAC by ~50% ($12.00–$13.88) without showing ad fatigue.

---

## Strategic Recommendations
1. **Reallocate Capital to High-Efficiency Channels:** Shift budget toward Instagram, Google Ads, and TikTok ($11.15–$11.36 CAC).
2. **Enforce 14+ Day Campaign Flights:** Avoid short-term campaigns (<14 days) to ensure algorithms exit the learning phase.
3. **Cap Facebook Bidding:** Implement strict bidding caps on Facebook to manage the $25.70 CAC ceiling.
4. **Maintain Active Email Campaigns:** Continue current active email workflows ($11.19 CAC) while archiving legacy structures.

---

## Repository Structure
```text
├── marketing_data_cleaning_eda.sql             # Master SQL Script
├── marketing_campaign_performance_report.pdf   # Executive PDF Analytics Report
├── results/                                     # Exported query CSV outputs
└── README.md                                    # Documentation
