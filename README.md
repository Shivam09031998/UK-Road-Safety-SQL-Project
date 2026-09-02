<div align="center">

# 🚦 UK Road Safety SQL Analyst Project

### 50 analytical questions • MySQL 8.0+ • STATS19 data, 2021–2025

[![Data source: UK Department for Transport](https://img.shields.io/badge/Data%20Source-UK%20Department%20for%20Transport-006853?style=for-the-badge)](https://www.gov.uk/government/statistical-data-sets/road-safety-open-data)

</div>

A portfolio case study analysing police-reported personal-injury collisions, vehicles and casualties in Great Britain using the UK Department for Transport (DfT) STATS19 Road Safety Open Data.

The accompanying SQL script answers 50 questions covering data validation, trends, severity, time, geography, road conditions, vehicles and vulnerable road users. It also demonstrates careful use of data grain, denominators and caveats so that results are not overstated.

> **Disclaimer:** This is an independent educational portfolio project. It is not affiliated with or endorsed by the DfT. The badge above identifies the data source; it is not an official departmental logo.

## Project objective

The project investigates:

- collision and casualty trends;
- fatal and serious collision severity;
- time-of-day and seasonal patterns;
- geographic and road-environment differences;
- weather, lighting and road-surface conditions;
- vehicle and driver characteristics; and
- pedestrian- and cyclist-casualty collisions.

## Tools and data

- **Database:** MySQL 8.0+
- **Database tool:** MySQL Workbench
- **Language:** SQL
- **Data source:** UK Department for Transport, STATS19 Road Safety Open Data
- **Loaded dataset period:** 1 January 2021 to 31 December 2025
- **Project format:** SQL case study hosted on GitHub

## Dataset overview

The analysis uses three related tables joined by **collision_index**:

| Table | Grain | Verified row count |
|---|---|---:|
| collisions | One row per collision | 513,801 |
| vehicles | One row per vehicle involved | 937,265 |
| casualties | One row per casualty | 652,821 |

One collision can involve multiple vehicles and casualties. A raw join therefore repeats collision rows. The script protects collision-level measures by using **COUNT(DISTINCT collision_index)**, conditional distinct counts, or pre-aggregated CTEs.

## Severity definition

| Code | Severity |
|---:|---|
| 1 | Fatal |
| 2 | Serious |
| 3 | Slight |

A **severe collision** is a fatal or serious collision: **collision_severity IN (1, 2)**. This is a collision-level classification, not a casualty-severity measure.

## Analysis structure

| Section | Questions | Coverage |
|---|---:|---|
| Data quality and validation | 1–11 | Counts, uniqueness, reconciliation, date coverage, duplicates, missing/unknown codes, orphan records and severity codes |
| Five-year performance and severity | 12–18 | Annual counts and percentages, year-over-year change, peak KPIs and casualties per collision |
| Time-based analysis | 19–24 | Month, weekday, hour, year-month and day-hour patterns |
| Geographic and road analysis | 25–36 | Urban/rural area, police force, LSOA, speed limit, road type, junctions and road class |
| Environmental conditions | 37–41 | Weather, road surface, lighting and combined environmental categories |
| Vehicles and vulnerable road users | 42–50 | Vehicle type, vehicle and driver age, driver sex, pedestrian and cyclist collisions, and lower-volume/high-severity categories |

## SQL skills demonstrated

- aggregate functions: COUNT(), SUM(), AVG(), MIN() and MAX();
- conditional aggregation with CASE WHEN;
- INNER JOIN, LEFT JOIN and CROSS JOIN;
- common table expressions with WITH;
- window functions including LAG() and RANK();
- subqueries, NOT EXISTS and UNION ALL;
- GROUP BY, HAVING and distinct counting;
- date and time functions including YEAR(), MONTH(), MONTHNAME() and HOUR();
- percentage and rate calculations with explicit decimal arithmetic;
- division-by-zero protection with NULLIF(); and
- minimum-count thresholds for more stable rankings.

## Analytical approach

**Volume is not risk.** A common category may contain more severe collisions in absolute terms while a less common category has a higher severe-collision percentage. The script reports volume and within-category severity rate separately.

**The denominator must match the question.** Collision severity uses collisions as the denominator. Vehicle analyses count distinct collisions involving each vehicle type. Casualties per collision compares casualty rows with collision rows. Geographic results are not population- or traffic-exposure rates.

**Association is not causation.** Differences across road, environmental and vehicle categories are descriptive. They may also reflect traffic exposure, speed, rurality, road design, time of day and road-user mix.

## Verified outputs

Only results explicitly recorded as verified in the SQL script are listed here:

- **513,801** collision records and unique collision IDs;
- **937,265** vehicle records;
- **652,821** casualty records;
- date coverage from **1 January 2021 to 31 December 2025**;
- at **00:00**, **8,110** collisions, including **2,508** severe collisions, for an observed severe-collision rate of **30.92%**; and
- light-condition code **6** (darkness with no lighting) had an observed severe-collision rate of **34.95%** in the supplied run.

The remaining queries must be executed against the complete database before additional findings are presented as verified.

## Environmental coding

Weather and road-surface conditions are separate STATS19 fields. The SQL script retains raw codes alongside readable labels for auditability.

- **Weather examples:** fine, raining, snowing, high winds, fog or mist, other and unknown.
- **Road-surface examples:** dry, wet or damp, snow, frost or ice, flood, oil or diesel, mud and unknown.
- **Light examples:** daylight and the documented darkness categories.

Use the DfT data guide for the exact release when interpreting coded fields, particularly across specification changes.

## Repository structure

~~~text
UK-Road-Safety-SQL-Project/
├── README.md
└── uk_road_safety_sql_analyst_project_q1_q50.sql
~~~

The SQL file contains Questions 1–50, explanatory notes, query logic, result interpretations, analytical cautions and the verified outputs available for this project.

## How to run the analysis

1. Download the DfT collision, vehicle and casualty files for the required 2021–2025 releases.
2. Import them into MySQL tables named **collisions**, **vehicles** and **casualties**.
3. Confirm that imported column names match the SQL script.
4. Open **uk_road_safety_sql_analyst_project_q1_q50.sql** in MySQL Workbench.
5. Select the required database with **USE your_database_name;**
6. Run Questions 1–11 first and investigate unexpected duplicates, missing/unknown codes, reconciliation differences or orphan records.
7. Execute the remaining questions individually and record only outputs verified from the database.

## Limitations

- STATS19 covers police-reported personal-injury collisions, not every road incident.
- The analysis has no traffic-volume, distance-travelled or population-exposure denominators.
- Results are descriptive associations and do not establish causal effects.
- Coded missing or unknown values may exist even when SQL NULL rates are low.
- Small categories can produce unstable rates. Disclosed minimum-count thresholds reduce, but do not eliminate, this problem.
- A collision may appear in multiple vehicle-type or vehicle-age groups, so those category totals are not mutually exclusive and must not be summed.
- Injury-based reporting can affect comparisons of recorded severity across police forces and years.
- The period spans the transition to the 2024 STATS19 specification, which police forces adopted at different times; definition and reporting changes may create breaks in time series.
- Geographic rankings describe collision locations, not the home areas of the people involved.

## Data source

[UK Department for Transport — Road Safety Open Data](https://www.gov.uk/government/statistical-data-sets/road-safety-open-data)

Consult the DfT data guide supplied with each downloaded release to decode categorical fields and identify specification changes.

## Author

**Shivam Garg**

Created as a SQL portfolio case study demonstrating data validation, exploratory analysis, analytical reasoning and clear communication of road-safety findings.
