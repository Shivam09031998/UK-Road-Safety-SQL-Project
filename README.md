<div align="center">

# 🚦 UK Road Safety SQL Analyst Project

### 50 Analytical Questions • MySQL 8.0+ • STATS19 2021–2025

<a href="https://www.gov.uk/government/statistical-data-sets/road-safety-open-data">
  <img src="https://img.shields.io/badge/Data%20Source-UK%20Department%20for%20Transport-006853?style=for-the-badge" alt="Data source: UK Department for Transport">
</a>

</div>

A SQL case study using the **UK Department for Transport STATS19 Road Safety Open Data** to analyse police-reported personal-injury collisions, vehicles and casualties across Great Britain from **2021 to 2025**.

The project contains **50 analytical questions** designed to demonstrate practical SQL skills, including data-quality validation, joins, CTEs, conditional aggregation, window functions, rate calculations and analytical interpretation.

> **Educational project disclaimer:** This is an independent portfolio analysis and is not affiliated with or endorsed by the UK Department for Transport. The badge identifies the official data source; it is not an official departmental logo.

---

## 📊 Project Objective

To explore five years of UK road-safety data and identify meaningful patterns in:

- Collision and casualty trends
- Fatal and serious collision severity
- Time-of-day and seasonal patterns
- Geographic and road-environment differences
- Weather, lighting and road-surface conditions
- Vehicle and driver characteristics
- Pedestrian and cyclist collisions

The project also demonstrates how to choose the correct **data grain and denominator**, avoid double-counting after joins, distinguish collision volume from severity rate, and communicate findings without making unsupported causal claims.

---

## 🧰 Tech Stack

- **Database:** MySQL 8.0+
- **Database tool:** MySQL Workbench
- **Language:** SQL
- **Data source:** UK Department for Transport, STATS19
- **Dataset period:** 2021–2025
- **Project format:** SQL case study hosted on GitHub

---

## 🗂️ Dataset Overview

The project uses three related STATS19 tables:

| Table | Data grain | Verified records |
|---|---|---:|
| `collisions` | One row per collision | 513,801 |
| `vehicles` | One row per vehicle involved | 937,265 |
| `casualties` | One row per casualty | 652,821 |

The tables are connected through `collision_index`.

```text
collisions
    │
    ├── one collision can involve many vehicles
    │       └── vehicles
    │
    └── one collision can result in many casualties
            └── casualties
```

### Important grain rule

The three tables cannot be joined and counted without considering their different grains. A collision involving multiple vehicles or casualties will appear several times after a raw join.

To prevent double-counting, the project uses:

- `COUNT(DISTINCT collision_index)` when measuring collisions after a join
- Separate CTEs to aggregate collision and casualty tables before joining
- Conditional distinct counts for vehicle-type involvement analysis

---

## 🚑 Collision Severity Definition

The official collision-severity coding used in the project is:

| Code | Severity |
|---:|---|
| `1` | Fatal |
| `2` | Serious |
| `3` | Slight |

For this analysis, a **severe collision** is defined as:

```sql
collision_severity IN (1, 2)
```

This includes fatal and serious collisions.

---

## 🔍 Analysis Sections

The 50 questions are organised into six sections.

### 1. Data Quality and Validation — Questions 1–11

- Count collision, vehicle and casualty records
- Confirm the number of unique collisions
- Reconcile recorded and calculated casualty totals
- Validate the 2021–2025 date range
- Detect duplicate collision, vehicle and casualty records
- Audit SQL `NULL` values and coded unknown values
- Identify orphan vehicle or casualty records
- Validate collision-severity codes

### 2. Five-Year Performance and Severity — Questions 12–18

- Count fatal, serious and slight collisions by year
- Calculate yearly severity percentages
- Measure year-over-year KPI changes using `LAG()`
- Identify the peak year for each KPI
- Calculate the overall severe-collision percentage
- Calculate average casualties per collision
- Compare yearly averages using full-precision values

### 3. Time-Based Analysis — Questions 19–24

- Analyse collisions by month
- Compare days of the week
- Rank hours by collision volume
- Rank hours by severe-collision rate
- Identify high-volume year-month combinations
- Find the busiest day-and-hour periods

### 4. Geographic and Road Analysis — Questions 25–36

- Compare urban and rural areas
- Rank police-force areas by volume and severity
- Identify high-volume and high-severity LSOAs
- Analyse speed limits, road types and junctions
- Compare casualties per collision geographically
- Examine combined urban/rural and speed-limit patterns
- Compare collision severity with vehicle and casualty counts

### 5. Environmental Conditions — Questions 37–41

- Analyse verified DfT weather-condition codes
- Compare road-surface conditions
- Compare daylight and darkness conditions
- Analyse combined weather, lighting and surface conditions
- Rank environmental categories by observed severe-collision rate

### 6. Vehicles and Vulnerable Road Users — Questions 42–50

- Rank vehicle types by collision involvement
- Compare severe-collision volume and rate by vehicle type
- Analyse vehicle age and driver age
- Compare driver-sex categories
- Examine pedestrian-casualty collisions
- Examine cyclist-casualty collisions
- Identify lower-volume vehicle types with above-average severity

---

## 💻 SQL Skills Demonstrated

- Aggregate functions: `COUNT()`, `SUM()`, `AVG()`, `MIN()` and `MAX()`
- Conditional aggregation with `CASE WHEN`
- `INNER JOIN` and `LEFT JOIN`
- Common table expressions using `WITH`
- Window functions including `LAG()` and `RANK()`
- Subqueries and `NOT EXISTS`
- `COUNT(DISTINCT ...)` for grain-safe analysis
- `GROUP BY`, `HAVING` and `UNION ALL`
- Date and time functions such as `YEAR()`, `MONTH()` and `HOUR()`
- Percentage and rate calculations using `100.0`
- Division-by-zero protection using `NULLIF()`
- Missing-value and coded-unknown auditing
- Minimum sample-size thresholds for more stable rankings

---

## 🧠 Analytical Principles

### Volume is not the same as risk

A category can contain many severe collisions because it is common, while another category can contain fewer severe collisions but have a higher severe-collision percentage.

The project therefore reports both:

- **Severe-collision volume:** number of fatal or serious collisions
- **Severe-collision rate:** severe collisions divided by all collisions in the category

### Denominators must match the question

Examples:

- Collision severity percentage uses total collisions as the denominator
- Vehicle involvement rate uses distinct collisions involving that vehicle type
- Casualties per collision uses casualty rows divided by collision rows
- Geographic collision rates are not population or traffic-exposure rates

### Association does not prove causation

Environmental, vehicle and road categories are compared using observed rates. These results do not prove that an individual condition caused a severe collision.

Other factors—including speed, rurality, road design, traffic exposure and road-user mix—may influence the observed relationship.

---

## 📌 Selected Verified Findings

- The dataset contains **513,801 collisions**, **937,265 vehicle records** and **652,821 casualty records**.
- It covers **1 January 2021 to 31 December 2025**.
- At **00:00**, the supplied analysis recorded **8,110 collisions**, including **2,508 severe collisions**, producing a **30.92% severe-collision rate**.
- **Light-condition code 6 — Darkness with no lighting** recorded a **34.95% observed severe-collision rate** in the supplied results.

Only outputs already verified in the project are listed here. Remaining findings should be added after the final SQL case study has been executed against the complete database.

---

## 🌦️ Environmental Coding Correction

The project uses the official DfT distinctions between weather and road-surface conditions.

**Weather conditions** include:

- Fine
- Raining
- Snowing
- High winds
- Fog or mist

**Road-surface conditions** include:

- Dry
- Wet or damp
- Snow
- Frost or ice
- Flood
- Oil or diesel
- Mud

The raw official code is retained in query outputs so every category remains auditable against the DfT data guide.

---

## 📁 Project Structure

```text
UK-Road-Safety-SQL-Project/
│
├── README.md
└── uk_road_safety_sql_analyst_project_q1_q50.sql
```

The SQL case-study file contains the complete Questions 1–50 analysis with:

```text
QUESTION
INTERPRETATION
SQL ANSWER
RESULT INTERPRETATION
ANALYTICAL CAUTION — where required
```

---

## ▶️ How to Use This Project

1. Download the DfT collision, vehicle and casualty data for 2021–2025.
2. Import the data into MySQL tables named `collisions`, `vehicles` and `casualties`.
3. Confirm that the imported column names match those used in the SQL case-study file.
4. Open `uk_road_safety_sql_analyst_project_q1_q50.sql` in MySQL Workbench.
5. Select the required database:

```sql
USE your_database_name;
```

6. Run the data-quality section first.
7. Investigate unexpected duplicates, missing codes or orphan records before running the analytical sections.
8. Execute each question individually and record verified outputs in the final project summary.

---

## ⚠️ Project Limitations

- STATS19 includes police-reported personal-injury collisions, not every road incident.
- The analysis does not contain traffic volume, distance travelled or population exposure denominators.
- Results show observed associations and should not be interpreted as causal effects.
- Coded missing or unknown values can exist even when SQL `NULL` rates are low.
- Rates from small categories can be unstable; minimum-count thresholds reduce but do not remove this issue.
- A collision may appear in several vehicle involvement categories, so those category totals should not be added together.
- Injury-based severity reporting can affect comparability between police forces and years.
- The data spans the transition to the 2024 STATS19 specification, which different police forces adopted at different times.
- Geographic rankings describe collision locations, not the home areas of the people involved.

---

## 📚 Data Source

**UK Department for Transport — Road Safety Open Data**  
https://www.gov.uk/government/statistical-data-sets/road-safety-open-data

The DfT open-dataset data guide should be used to decode all categorical fields and identify specification changes.

---

## 👤 Author

**Shivam Garg**

This project was created as a SQL portfolio case study to demonstrate data validation, exploratory analysis, analytical reasoning and clear communication of road-safety findings.

---

⭐ If you find this project useful, consider starring the repository.
