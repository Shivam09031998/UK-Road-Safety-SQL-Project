/*
===============================================================================
UK ROAD SAFETY — SQL ANALYST PROJECT
QUESTIONS 1–50 — FINAL ANNOTATED NOTEBOOK

Author: Shivam Garg
SQL dialect: MySQL 8.0+
Data source: UK Department for Transport (DfT), STATS19 open data
Dataset period: 2021-01-01 to 2025-12-31

Official documentation:
https://www.gov.uk/government/statistical-data-sets/road-safety-open-data

ABOUT THE DATA
--------------
STATS19 contains police-reported personal-injury collisions on public roads in
Great Britain. It is not a record of every road incident and should not be used
as a population/exposure risk measure without traffic, distance or population
denominators.

EXPECTED TABLES AND GRAIN
-------------------------
collisions : one row per collision
vehicles   : one row per vehicle involved in a collision
casualties : one row per casualty

All three tables use collision_index as the link. Vehicles and casualties can
contain several rows for one collision. Joining either raw child table to
collisions multiplies collision rows. Queries therefore count DISTINCT
collision_index or aggregate each table before joining whenever the requested
measure is at collision grain.

SEVERITY CODING
---------------
collision_severity = 1 Fatal, 2 Serious, 3 Slight
Severe collision   = collision_severity IN (1, 2)

REPRODUCIBILITY NOTES
---------------------
1. Run USE your_database_name; before this notebook if required.
2. Column names follow DfT open-data names used in the supplied project.
3. 100.0 is used in percentage arithmetic to make decimal intent explicit.
4. NULLIF(denominator, 0) prevents division-by-zero errors.
5. Coded fields must be interpreted using the DfT guide for the downloaded
   release. Q37–Q41 preserve official codes alongside readable labels.
6. Verified outputs supplied with the project are stated below. No unavailable
   result has been invented; run the relevant query to populate it.
===============================================================================
*/


-- =============================================================================
-- SECTION 1 — DATA QUALITY AND VALIDATION
-- =============================================================================

-- =============================================================================
-- QUESTION 1
-- How many collision, vehicle and casualty records are in the dataset?
-- DELIVERABLE: one record count for each table.
-- =============================================================================

-- INTERPRETATION:
-- COUNT(*) counts rows. Because each table has a different grain, the three
-- counts describe different things and should not be added together.

SELECT 'collisions' AS table_name, COUNT(*) AS record_count FROM collisions
UNION ALL
SELECT 'vehicles', COUNT(*) FROM vehicles
UNION ALL
SELECT 'casualties', COUNT(*) FROM casualties;

-- VERIFIED RESULT:
-- collisions = 513,801; vehicles = 937,265; casualties = 652,821.
-- More vehicle and casualty rows than collision rows is expected because one
-- collision can involve several vehicles and injure several people.


-- =============================================================================
-- QUESTION 2
-- How many unique collisions are represented?
-- =============================================================================

-- COUNT(DISTINCT collision_index) removes repeated IDs before counting. In a
-- valid collision-grain table it should equal COUNT(*).
SELECT
    COUNT(*) AS collision_rows,
    COUNT(DISTINCT collision_index) AS unique_collisions,
    COUNT(*) - COUNT(DISTINCT collision_index) AS extra_rows_from_duplicate_ids
FROM collisions;

-- VERIFIED RESULT: 513,801 unique collisions.


-- =============================================================================
-- QUESTION 3
-- Does collisions.number_of_casualties agree with linked casualty records?
-- DELIVERABLE: only collisions whose recorded and calculated totals differ.
-- =============================================================================

-- LEFT JOIN keeps collisions even if no matching casualty row exists.
-- COUNT(CA.collision_index), rather than COUNT(*), returns zero for an unmatched
-- LEFT JOIN row. GROUP BY restores one row per collision. HAVING filters the
-- grouped result to mismatches only.
SELECT
    C.collision_index,
    C.number_of_casualties AS recorded_casualties,
    COUNT(CA.collision_index) AS calculated_casualty_rows,
    C.number_of_casualties - COUNT(CA.collision_index) AS difference
FROM collisions AS C
LEFT JOIN casualties AS CA
    ON C.collision_index = CA.collision_index
GROUP BY C.collision_index, C.number_of_casualties
HAVING C.number_of_casualties <> COUNT(CA.collision_index)
ORDER BY ABS(C.number_of_casualties - COUNT(CA.collision_index)) DESC,
         C.collision_index;

-- RESULT INTERPRETATION: no rows means the two sources reconcile perfectly.
-- Returned rows should be investigated rather than silently deleted.


-- =============================================================================
-- QUESTION 4
-- What exact date range is covered, and how many calendar years appear?
-- =============================================================================

-- MIN(date) is the earliest date; MAX(date) is the latest. This corrects the
-- earlier version in which MIN and MAX labels were reversed.
SELECT
    MIN(date) AS first_date,
    MAX(date) AS last_date,
    COUNT(DISTINCT YEAR(date)) AS number_of_years
FROM collisions;

-- VERIFIED RESULT: 2021-01-01 to 2025-12-31; five years.


-- =============================================================================
-- QUESTION 5
-- Are all five years represented, and how many collisions occur in each year?
-- =============================================================================

SELECT
    collision_year,
    COUNT(*) AS collision_count
FROM collisions
GROUP BY collision_year
ORDER BY collision_year;

-- RESULT INTERPRETATION: expect one row for every year from 2021 through 2025.
-- A missing or unexpected year signals a load/filter problem.


-- =============================================================================
-- QUESTION 6
-- Are there duplicate collision IDs?
-- =============================================================================

SELECT collision_index, COUNT(*) AS duplicate_count
FROM collisions
GROUP BY collision_index
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, collision_index;

-- No rows means collision_index is unique at collision grain.


-- =============================================================================
-- QUESTION 7
-- Are vehicle records duplicated within a collision?
-- =============================================================================

-- collision_index + vehicle_reference is the natural record key here.
SELECT collision_index, vehicle_reference, COUNT(*) AS duplicate_count
FROM vehicles
GROUP BY collision_index, vehicle_reference
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, collision_index, vehicle_reference;


-- =============================================================================
-- QUESTION 8
-- Are casualty records duplicated within a collision?
-- =============================================================================

SELECT collision_index, casualty_reference, COUNT(*) AS duplicate_count
FROM casualties
GROUP BY collision_index, casualty_reference
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, collision_index, casualty_reference;


-- =============================================================================
-- QUESTION 9
-- What percentage of key analytical fields contains SQL NULL values?
-- DELIVERABLE: a reusable missingness audit plus coded-unknown checks.
-- =============================================================================

-- Each SELECT audits one field. UNION ALL stacks the results without removing
-- rows. SUM(field IS NULL) works in MySQL because TRUE evaluates to 1.
SELECT 'date' AS column_name, SUM(date IS NULL) AS missing_count,
       COUNT(*) AS total_rows,
       ROUND(SUM(date IS NULL) * 100.0 / COUNT(*), 2) AS missing_percentage
FROM collisions
UNION ALL
SELECT 'time', SUM(time IS NULL), COUNT(*),
       ROUND(SUM(time IS NULL) * 100.0 / COUNT(*), 2) FROM collisions
UNION ALL
SELECT 'collision_severity', SUM(collision_severity IS NULL), COUNT(*),
       ROUND(SUM(collision_severity IS NULL) * 100.0 / COUNT(*), 2) FROM collisions
UNION ALL
SELECT 'speed_limit', SUM(speed_limit IS NULL), COUNT(*),
       ROUND(SUM(speed_limit IS NULL) * 100.0 / COUNT(*), 2) FROM collisions
UNION ALL
SELECT 'weather_conditions', SUM(weather_conditions IS NULL), COUNT(*),
       ROUND(SUM(weather_conditions IS NULL) * 100.0 / COUNT(*), 2) FROM collisions
UNION ALL
SELECT 'road_surface_conditions', SUM(road_surface_conditions IS NULL), COUNT(*),
       ROUND(SUM(road_surface_conditions IS NULL) * 100.0 / COUNT(*), 2) FROM collisions
UNION ALL
SELECT 'light_conditions', SUM(light_conditions IS NULL), COUNT(*),
       ROUND(SUM(light_conditions IS NULL) * 100.0 / COUNT(*), 2) FROM collisions
UNION ALL
SELECT 'lsoa_of_accident_location', SUM(lsoa_of_accident_location IS NULL), COUNT(*),
       ROUND(SUM(lsoa_of_accident_location IS NULL) * 100.0 / COUNT(*), 2)
FROM collisions;

-- IMPORTANT DATA-QUALITY CAUTION:
-- NULL is not the only form of missingness. DfT coded fields can contain -1
-- (data missing/out of range), 9/99 (unknown) or another field-specific code.
-- Inspect raw distributions and confirm every unknown code in the exact guide.
SELECT 'weather_conditions' AS field_name, weather_conditions AS raw_code,
       COUNT(*) AS rows_with_code
FROM collisions
WHERE weather_conditions IN (-1, 9) OR weather_conditions IS NULL
GROUP BY weather_conditions
UNION ALL
SELECT 'light_conditions', light_conditions, COUNT(*)
FROM collisions
WHERE light_conditions = -1 OR light_conditions IS NULL
GROUP BY light_conditions
UNION ALL
SELECT 'road_surface_conditions', road_surface_conditions, COUNT(*)
FROM collisions
WHERE road_surface_conditions IN (-1, 9) OR road_surface_conditions IS NULL
GROUP BY road_surface_conditions;


-- =============================================================================
-- QUESTION 10
-- Are there orphan vehicle or casualty rows without a collision parent?
-- =============================================================================

-- NOT EXISTS tests whether the parent key is absent without multiplying rows.
SELECT 'orphan_vehicle_rows' AS check_name, COUNT(*) AS affected_rows
FROM vehicles AS V
WHERE NOT EXISTS (
    SELECT 1 FROM collisions AS C
    WHERE C.collision_index = V.collision_index
)
UNION ALL
SELECT 'orphan_casualty_rows', COUNT(*)
FROM casualties AS CA
WHERE NOT EXISTS (
    SELECT 1 FROM collisions AS C
    WHERE C.collision_index = CA.collision_index
);


-- =============================================================================
-- QUESTION 11
-- Which raw collision-severity values occur in the data?
-- =============================================================================

SELECT collision_severity, COUNT(*) AS collision_count
FROM collisions
GROUP BY collision_severity
ORDER BY collision_severity;

-- Expected documented values: 1 Fatal, 2 Serious, 3 Slight. Unexpected values
-- must be investigated before severity metrics are published.


-- =============================================================================
-- SECTION 2 — FIVE-YEAR PERFORMANCE AND SEVERITY
-- =============================================================================

-- =============================================================================
-- QUESTION 12
-- How many fatal, serious and slight collisions occurred in each year?
-- =============================================================================

-- Each CASE returns 1 when a row belongs to the category, so SUM counts rows.
-- It must not return 2 or 3: those are category codes, not count weights.
SELECT
    collision_year,
    SUM(CASE WHEN collision_severity = 1 THEN 1 ELSE 0 END) AS fatal_collisions,
    SUM(CASE WHEN collision_severity = 2 THEN 1 ELSE 0 END) AS serious_collisions,
    SUM(CASE WHEN collision_severity = 3 THEN 1 ELSE 0 END) AS slight_collisions
FROM collisions
GROUP BY collision_year
ORDER BY collision_year;


-- =============================================================================
-- QUESTION 13
-- What percentage of each year's collisions was fatal, serious or slight?
-- =============================================================================

-- Denominator: all collisions in that year. The three percentages should total
-- approximately 100%, allowing for display rounding.
SELECT
    collision_year,
    ROUND(SUM(CASE WHEN collision_severity = 1 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 2) AS fatal_percentage,
    ROUND(SUM(CASE WHEN collision_severity = 2 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 2) AS serious_percentage,
    ROUND(SUM(CASE WHEN collision_severity = 3 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 2) AS slight_percentage
FROM collisions
GROUP BY collision_year
ORDER BY collision_year;


-- =============================================================================
-- QUESTION 14
-- What is the year-over-year percentage change in collisions, casualties,
-- fatal collisions and serious collisions?
-- =============================================================================

-- First aggregate each raw table to one row per year. Joining these summaries
-- cannot duplicate collision counts. LAG() then retrieves the prior-year KPI.
WITH yearly_collisions AS (
    SELECT collision_year,
           COUNT(*) AS collisions,
           SUM(CASE WHEN collision_severity = 1 THEN 1 ELSE 0 END) AS fatal,
           SUM(CASE WHEN collision_severity = 2 THEN 1 ELSE 0 END) AS serious
    FROM collisions GROUP BY collision_year
),
yearly_casualties AS (
    SELECT collision_year, COUNT(*) AS casualties
    FROM casualties GROUP BY collision_year
),
yearly_data AS (
    SELECT C.collision_year, C.collisions, CA.casualties, C.fatal, C.serious
    FROM yearly_collisions AS C
    JOIN yearly_casualties AS CA USING (collision_year)
),
with_previous AS (
    SELECT *,
           LAG(collisions) OVER (ORDER BY collision_year) AS previous_collisions,
           LAG(casualties) OVER (ORDER BY collision_year) AS previous_casualties,
           LAG(fatal) OVER (ORDER BY collision_year) AS previous_fatal,
           LAG(serious) OVER (ORDER BY collision_year) AS previous_serious
    FROM yearly_data
)
SELECT collision_year,
       ROUND((collisions - previous_collisions) * 100.0 /
             NULLIF(previous_collisions, 0), 2) AS collision_yoy_pct,
       ROUND((casualties - previous_casualties) * 100.0 /
             NULLIF(previous_casualties, 0), 2) AS casualty_yoy_pct,
       ROUND((fatal - previous_fatal) * 100.0 /
             NULLIF(previous_fatal, 0), 2) AS fatal_yoy_pct,
       ROUND((serious - previous_serious) * 100.0 /
             NULLIF(previous_serious, 0), 2) AS serious_yoy_pct
FROM with_previous
ORDER BY collision_year;

-- The first year returns NULL because no earlier year exists. Positive means an
-- increase; negative means a decrease. Volume and severity can move differently.


-- =============================================================================
-- QUESTION 15
-- Which year recorded the maximum value for each principal KPI?
-- =============================================================================

WITH yearly_collisions AS (
    SELECT collision_year, COUNT(*) AS collisions,
           SUM(collision_severity = 1) AS fatal,
           SUM(collision_severity = 2) AS serious
    FROM collisions GROUP BY collision_year
),
yearly_casualties AS (
    SELECT collision_year, COUNT(*) AS casualties
    FROM casualties GROUP BY collision_year
),
yearly_data AS (
    SELECT C.*, CA.casualties
    FROM yearly_collisions AS C JOIN yearly_casualties AS CA USING (collision_year)
)
SELECT 'collisions' AS kpi, collision_year, collisions AS kpi_value
FROM yearly_data WHERE collisions = (SELECT MAX(collisions) FROM yearly_data)
UNION ALL
SELECT 'casualties', collision_year, casualties
FROM yearly_data WHERE casualties = (SELECT MAX(casualties) FROM yearly_data)
UNION ALL
SELECT 'fatal collisions', collision_year, fatal
FROM yearly_data WHERE fatal = (SELECT MAX(fatal) FROM yearly_data)
UNION ALL
SELECT 'serious collisions', collision_year, serious
FROM yearly_data WHERE serious = (SELECT MAX(serious) FROM yearly_data);

-- Equality to MAX retains ties instead of arbitrarily choosing one year.


-- =============================================================================
-- QUESTION 16
-- What percentage of all five-year collisions was fatal or serious?
-- =============================================================================

SELECT COUNT(*) AS total_collisions,
       SUM(CASE WHEN collision_severity IN (1, 2) THEN 1 ELSE 0 END)
           AS severe_collisions,
       ROUND(SUM(CASE WHEN collision_severity IN (1, 2) THEN 1 ELSE 0 END)
             * 100.0 / COUNT(*), 2) AS severe_collision_percentage
FROM collisions;

-- Denominator: all collision rows, because this is a collision severity
-- proportion—not a casualty, population or traffic-exposure rate.


-- =============================================================================
-- QUESTION 17
-- What was the average number of casualties per collision in each year?
-- =============================================================================

WITH yearly_collisions AS (
    SELECT collision_year, COUNT(*) AS collisions
    FROM collisions GROUP BY collision_year
),
yearly_casualties AS (
    SELECT collision_year, COUNT(*) AS casualties
    FROM casualties GROUP BY collision_year
)
SELECT C.collision_year, C.collisions, CA.casualties,
       ROUND(CA.casualties * 1.0 / NULLIF(C.collisions, 0), 2)
           AS avg_casualties_per_collision
FROM yearly_collisions AS C
JOIN yearly_casualties AS CA USING (collision_year)
ORDER BY C.collision_year;


-- =============================================================================
-- QUESTION 18
-- Does average casualties per collision increase, decrease or remain stable?
-- =============================================================================

-- The CTE stores the unrounded value. LAG compares full precision; ROUND is
-- applied only in the final display. This prevents two nearby values that both
-- display as 1.27 from being incorrectly labelled Stable.
WITH yearly_collisions AS (
    SELECT collision_year, COUNT(*) AS collisions
    FROM collisions GROUP BY collision_year
),
yearly_casualties AS (
    SELECT collision_year, COUNT(*) AS casualties
    FROM casualties GROUP BY collision_year
),
yearly_average AS (
    SELECT C.collision_year,
           CA.casualties * 1.0 / NULLIF(C.collisions, 0) AS full_precision_average
    FROM yearly_collisions AS C
    JOIN yearly_casualties AS CA USING (collision_year)
),
comparison AS (
    SELECT *, LAG(full_precision_average) OVER (ORDER BY collision_year)
              AS previous_average
    FROM yearly_average
)
SELECT collision_year,
       ROUND(full_precision_average, 2) AS avg_casualties_per_collision,
       ROUND(previous_average, 2) AS previous_year_display_average,
       CASE WHEN previous_average IS NULL THEN 'No previous year'
            WHEN full_precision_average > previous_average THEN 'Increasing'
            WHEN full_precision_average < previous_average THEN 'Decreasing'
            ELSE 'Stable' END AS direction
FROM comparison
ORDER BY collision_year;


-- =============================================================================
-- SECTION 3 — WHEN DO COLLISIONS HAPPEN?
-- =============================================================================

-- =============================================================================
-- QUESTION 19
-- How do collision volume and severe-collision rate vary by month?
-- =============================================================================

SELECT MONTH(date) AS month_number, MONTHNAME(date) AS month_name,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate
FROM collisions
WHERE date IS NOT NULL
GROUP BY MONTH(date), MONTHNAME(date)
ORDER BY month_number;

-- Volume answers where most collisions occur; the severe rate answers what
-- share of that month's collisions is severe. These are different questions.


-- =============================================================================
-- QUESTION 20
-- How do collisions vary by day of week?
-- =============================================================================

SELECT day_of_week AS day_code,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate
FROM collisions
GROUP BY day_of_week
ORDER BY day_of_week;

-- The raw official code is deliberately retained. Decode it using the DfT
-- guide for the release, or join a validated lookup table.


-- =============================================================================
-- QUESTION 21
-- Which hours record the highest collision volumes?
-- =============================================================================

SELECT HOUR(time) AS hour_of_day, COUNT(*) AS collision_count,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS volume_rank
FROM collisions
WHERE time IS NOT NULL
GROUP BY HOUR(time)
ORDER BY volume_rank, hour_of_day;


-- =============================================================================
-- QUESTION 22
-- Which hours have the highest severe-collision rate?
-- =============================================================================

SELECT HOUR(time) AS hour_of_day,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate,
       RANK() OVER (
           ORDER BY SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*) DESC
       ) AS severity_rate_rank
FROM collisions
WHERE time IS NOT NULL
GROUP BY HOUR(time)
ORDER BY severity_rate_rank, hour_of_day;

-- VERIFIED RESULT FROM THE SUPPLIED PROJECT:
-- 00:00 recorded 8,110 collisions, 2,508 severe collisions and a 30.92% severe
-- rate. This is a rate insight; another hour can have more severe collisions in
-- absolute terms. No minimum threshold was necessary because every hourly group
-- contained more than 3,000 collisions.


-- =============================================================================
-- QUESTION 23
-- Which year-month combinations recorded the most collisions?
-- =============================================================================

SELECT collision_year, MONTH(date) AS month_number, MONTHNAME(date) AS month_name,
       COUNT(*) AS collisions,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS overall_rank
FROM collisions
WHERE date IS NOT NULL
GROUP BY collision_year, MONTH(date), MONTHNAME(date)
ORDER BY overall_rank, collision_year, month_number;


-- =============================================================================
-- QUESTION 24
-- Which day-and-hour combinations are the busiest collision periods?
-- =============================================================================

SELECT day_of_week AS day_code, HOUR(time) AS hour_of_day,
       COUNT(*) AS collisions,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS volume_rank
FROM collisions
WHERE time IS NOT NULL
GROUP BY day_of_week, HOUR(time)
ORDER BY volume_rank, day_code, hour_of_day;


-- =============================================================================
-- SECTION 4 — WHERE AND ON WHAT ROADS DO COLLISIONS OCCUR?
-- =============================================================================

-- =============================================================================
-- QUESTION 25
-- Compare collision volume, casualty volume and casualties per collision by
-- urban/rural area.
-- =============================================================================

-- Aggregate each table separately before joining. Joining raw casualties first
-- would repeat collision rows once per casualty.
WITH collision_area AS (
    SELECT urban_or_rural_area, COUNT(*) AS collisions
    FROM collisions GROUP BY urban_or_rural_area
),
casualty_area AS (
    SELECT C.urban_or_rural_area, COUNT(*) AS casualties
    FROM casualties AS CA
    JOIN collisions AS C ON C.collision_index = CA.collision_index
    GROUP BY C.urban_or_rural_area
)
SELECT C.urban_or_rural_area AS area_code, C.collisions, CA.casualties,
       ROUND(CA.casualties * 1.0 / NULLIF(C.collisions, 0), 2)
           AS casualties_per_collision
FROM collision_area AS C
JOIN casualty_area AS CA USING (urban_or_rural_area)
ORDER BY C.urban_or_rural_area;


-- =============================================================================
-- QUESTION 26
-- Which police-force areas record the largest collision volume?
-- =============================================================================

SELECT police_force AS police_force_code, COUNT(*) AS collisions,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS volume_rank
FROM collisions
GROUP BY police_force
ORDER BY volume_rank, police_force_code;


-- =============================================================================
-- QUESTION 27
-- Which police-force areas have the highest observed severe-collision rate?
-- DELIVERABLE: rate ranking with a stable-denominator threshold.
-- =============================================================================

SELECT police_force AS police_force_code,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate,
       RANK() OVER (
           ORDER BY SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*) DESC
       ) AS rate_rank
FROM collisions
GROUP BY police_force
HAVING COUNT(*) >= 100
ORDER BY rate_rank, police_force_code;

-- The threshold is an analytical choice, not an official DfT standard. It
-- reduces unstable rankings caused by very small groups and should be disclosed.


-- =============================================================================
-- QUESTION 28
-- Which LSOAs have the greatest collision volume?
-- =============================================================================

SELECT lsoa_of_accident_location AS lsoa_code,
       COUNT(*) AS collisions,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS volume_rank
FROM collisions
WHERE lsoa_of_accident_location IS NOT NULL
GROUP BY lsoa_of_accident_location
ORDER BY volume_rank, lsoa_code;


-- =============================================================================
-- QUESTION 29
-- Which LSOAs have the highest severe-collision rate among areas with at least
-- 50 collisions?
-- =============================================================================

SELECT lsoa_of_accident_location AS lsoa_code,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate,
       RANK() OVER (
           ORDER BY SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*) DESC
       ) AS rate_rank
FROM collisions
WHERE lsoa_of_accident_location IS NOT NULL
GROUP BY lsoa_of_accident_location
HAVING COUNT(*) >= 50
ORDER BY rate_rank, lsoa_code;

-- This ranks observed collision severity, not resident population risk. Traffic
-- exposure and population denominators are not present in these three tables.


-- =============================================================================
-- QUESTION 30
-- How do collision volume and severity vary by speed limit?
-- =============================================================================

SELECT speed_limit,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate
FROM collisions
WHERE speed_limit IS NOT NULL AND speed_limit > 0
GROUP BY speed_limit
ORDER BY speed_limit;

-- Association does not prove speed limits cause severity; road design, actual
-- travel speed, road-user mix and rurality may confound the result.


-- =============================================================================
-- QUESTION 31
-- How do collision volume and severity vary by road type?
-- =============================================================================

SELECT road_type AS road_type_code,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate
FROM collisions
GROUP BY road_type
ORDER BY collisions DESC;


-- =============================================================================
-- QUESTION 32
-- How do collision volume and severity vary by junction detail?
-- =============================================================================

SELECT junction_detail AS junction_detail_code,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate
FROM collisions
GROUP BY junction_detail
ORDER BY collisions DESC;


-- =============================================================================
-- QUESTION 33
-- Which police-force areas have the highest average casualties per collision?
-- =============================================================================

WITH collision_force AS (
    SELECT police_force, COUNT(*) AS collisions
    FROM collisions GROUP BY police_force
),
casualty_force AS (
    SELECT C.police_force, COUNT(*) AS casualties
    FROM casualties AS CA
    JOIN collisions AS C ON C.collision_index = CA.collision_index
    GROUP BY C.police_force
)
SELECT C.police_force AS police_force_code, C.collisions, CA.casualties,
       ROUND(CA.casualties * 1.0 / NULLIF(C.collisions, 0), 3)
           AS casualties_per_collision,
       RANK() OVER (
           ORDER BY CA.casualties * 1.0 / NULLIF(C.collisions, 0) DESC
       ) AS rank_by_average
FROM collision_force AS C
JOIN casualty_force AS CA USING (police_force)
WHERE C.collisions >= 100
ORDER BY rank_by_average, police_force_code;


-- =============================================================================
-- QUESTION 34
-- Which combinations of urban/rural area and speed limit have the highest
-- observed severe-collision rates?
-- =============================================================================

SELECT urban_or_rural_area AS area_code, speed_limit,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate,
       RANK() OVER (
           ORDER BY SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*) DESC
       ) AS rate_rank
FROM collisions
WHERE speed_limit IS NOT NULL AND speed_limit > 0
GROUP BY urban_or_rural_area, speed_limit
HAVING COUNT(*) >= 100
ORDER BY rate_rank, area_code, speed_limit;


-- =============================================================================
-- QUESTION 35
-- How many vehicles and casualties are involved in the average collision by
-- collision severity?
-- =============================================================================

-- number_of_vehicles and number_of_casualties already live at collision grain,
-- so no child-table join is needed.
SELECT collision_severity,
       COUNT(*) AS collisions,
       ROUND(AVG(number_of_vehicles), 2) AS avg_vehicles_per_collision,
       ROUND(AVG(number_of_casualties), 2) AS avg_casualties_per_collision
FROM collisions
GROUP BY collision_severity
ORDER BY collision_severity;


-- =============================================================================
-- QUESTION 36
-- Which road-class and speed-limit combinations account for the largest number
-- of severe collisions?
-- =============================================================================

SELECT first_road_class AS road_class_code, speed_limit,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate,
       RANK() OVER (
           ORDER BY SUM(collision_severity IN (1, 2)) DESC
       ) AS severe_volume_rank
FROM collisions
WHERE speed_limit IS NOT NULL
GROUP BY first_road_class, speed_limit
ORDER BY severe_volume_rank, road_class_code, speed_limit;


-- =============================================================================
-- SECTION 5 — ENVIRONMENTAL CONDITIONS
-- =============================================================================

-- =============================================================================
-- QUESTION 37
-- How do weather conditions relate to collision volume and severity?
-- =============================================================================

-- VERIFIED DfT WEATHER CODES:
-- 1 Fine/no high winds; 2 Raining/no high winds; 3 Snowing/no high winds;
-- 4 Fine + high winds; 5 Raining + high winds; 6 Snowing + high winds;
-- 7 Fog or mist; 8 Other; 9 Unknown; -1 Missing/out of range.
-- The raw code remains in the output so the result is auditable.
SELECT weather_conditions AS weather_code,
       CASE weather_conditions
           WHEN 1 THEN 'Fine, no high winds'
           WHEN 2 THEN 'Raining, no high winds'
           WHEN 3 THEN 'Snowing, no high winds'
           WHEN 4 THEN 'Fine + high winds'
           WHEN 5 THEN 'Raining + high winds'
           WHEN 6 THEN 'Snowing + high winds'
           WHEN 7 THEN 'Fog or mist'
           WHEN 8 THEN 'Other'
           WHEN 9 THEN 'Unknown'
           WHEN -1 THEN 'Data missing or out of range'
           ELSE 'Unmapped code — check DfT guide'
       END AS weather_label,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate
FROM collisions
GROUP BY weather_conditions
ORDER BY collisions DESC;

-- Earlier project labels such as Dry/Wet/Frost were incorrect here: those are
-- road-surface categories and are handled in Q38.


-- =============================================================================
-- QUESTION 38
-- How do road-surface conditions relate to volume and severity?
-- =============================================================================

SELECT road_surface_conditions AS surface_code,
       CASE road_surface_conditions
           WHEN 1 THEN 'Dry'
           WHEN 2 THEN 'Wet or damp'
           WHEN 3 THEN 'Snow'
           WHEN 4 THEN 'Frost or ice'
           WHEN 5 THEN 'Flood over 3cm deep'
           WHEN 6 THEN 'Oil or diesel'
           WHEN 7 THEN 'Mud'
           WHEN 9 THEN 'Unknown (self-reported)'
           WHEN -1 THEN 'Data missing or out of range'
           ELSE 'Unmapped code — check DfT guide'
       END AS surface_label,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate
FROM collisions
GROUP BY road_surface_conditions
ORDER BY collisions DESC;


-- =============================================================================
-- QUESTION 39
-- How do light conditions relate to collision volume and severity?
-- =============================================================================

SELECT light_conditions AS light_code,
       CASE light_conditions
           WHEN 1 THEN 'Daylight'
           WHEN 4 THEN 'Darkness - lights lit'
           WHEN 5 THEN 'Darkness - lights unlit'
           WHEN 6 THEN 'Darkness - no lighting'
           WHEN 7 THEN 'Darkness - lighting unknown'
           WHEN -1 THEN 'Data missing or out of range'
           ELSE 'Unmapped code — check DfT guide'
       END AS light_label,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate
FROM collisions
GROUP BY light_conditions
ORDER BY collisions DESC;

-- VERIFIED FIGURE SUPPLIED: light condition code 6 (darkness, no lighting)
-- showed an observed severe-collision rate of 34.95% in the user's run.


-- =============================================================================
-- QUESTION 40
-- Which weather, light and surface combinations show the highest observed
-- severe-collision rates?
-- =============================================================================

-- Codes are safest for a reproducible multi-field output; their labels are
-- fully listed in Q37–Q39. The minimum of 100 collisions limits tiny groups.
SELECT weather_conditions AS weather_code,
       light_conditions AS light_code,
       road_surface_conditions AS surface_code,
       COUNT(*) AS collisions,
       SUM(collision_severity IN (1, 2)) AS severe_collisions,
       ROUND(SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*), 2)
           AS severe_collision_rate,
       RANK() OVER (
           ORDER BY SUM(collision_severity IN (1, 2)) * 100.0 / COUNT(*) DESC
       ) AS rate_rank
FROM collisions
GROUP BY weather_conditions, light_conditions, road_surface_conditions
HAVING COUNT(*) >= 100
ORDER BY rate_rank, weather_code, light_code, surface_code;


-- =============================================================================
-- QUESTION 41
-- Among the environmental categories examined, which has the highest observed
-- severe-collision rate?
-- =============================================================================

WITH environmental_groups AS (
    SELECT 'Light' AS condition_type,
           CAST(light_conditions AS CHAR) AS condition_code,
           COUNT(*) AS collisions,
           SUM(collision_severity IN (1, 2)) AS severe_collisions
    FROM collisions GROUP BY light_conditions
    UNION ALL
    SELECT 'Weather', CAST(weather_conditions AS CHAR), COUNT(*),
           SUM(collision_severity IN (1, 2))
    FROM collisions GROUP BY weather_conditions
    UNION ALL
    SELECT 'Road surface', CAST(road_surface_conditions AS CHAR), COUNT(*),
           SUM(collision_severity IN (1, 2))
    FROM collisions GROUP BY road_surface_conditions
),
eligible_groups AS (
    SELECT *, severe_collisions * 100.0 / NULLIF(collisions, 0) AS full_rate
    FROM environmental_groups
    WHERE collisions >= 100
)
SELECT condition_type, condition_code, collisions, severe_collisions,
       ROUND(full_rate, 2) AS severe_collision_rate,
       RANK() OVER (ORDER BY full_rate DESC) AS rate_rank
FROM eligible_groups
ORDER BY rate_rank, condition_type, condition_code;

-- DEFENSIBLE INTERPRETATION:
-- This identifies the individual category with the highest observed severe
-- rate. It does not establish which variable has the strongest statistical
-- association, and it does not demonstrate causation. Darkness, weather and
-- surface may overlap with rurality, speed limit, road design and time of day.


-- =============================================================================
-- SECTION 6 — VEHICLES AND VULNERABLE ROAD USERS
-- =============================================================================

-- =============================================================================
-- QUESTION 42
-- Which vehicle types are involved in the greatest number of collisions?
-- =============================================================================

-- Vehicle rows are not collision rows. COUNT(DISTINCT collision_index) makes a
-- collision involving two vehicles of the same type count once for that type.
SELECT vehicle_type,
       COUNT(*) AS vehicle_records,
       COUNT(DISTINCT collision_index) AS distinct_collisions,
       RANK() OVER (ORDER BY COUNT(DISTINCT collision_index) DESC) AS rank_by_volume
FROM vehicles
GROUP BY vehicle_type
ORDER BY rank_by_volume, vehicle_type;


-- =============================================================================
-- QUESTION 43
-- Which vehicle types are involved in the greatest number of fatal/serious
-- collisions?
-- =============================================================================

SELECT V.vehicle_type,
       COUNT(DISTINCT V.collision_index) AS collision_count,
       COUNT(DISTINCT CASE WHEN C.collision_severity IN (1, 2)
                           THEN V.collision_index END) AS severe_collision_count,
       RANK() OVER (
           ORDER BY COUNT(DISTINCT CASE WHEN C.collision_severity IN (1, 2)
                                        THEN V.collision_index END) DESC
       ) AS severe_volume_rank
FROM vehicles AS V
JOIN collisions AS C ON C.collision_index = V.collision_index
GROUP BY V.vehicle_type
ORDER BY severe_volume_rank, V.vehicle_type;

-- This ranks absolute severe-collision involvement, not the probability that a
-- collision involving the vehicle type is severe. Q44 calculates that rate.


-- =============================================================================
-- QUESTION 44
-- Which vehicle types have the highest severe-collision involvement rate?
-- =============================================================================

SELECT V.vehicle_type,
       COUNT(DISTINCT V.collision_index) AS collision_count,
       COUNT(DISTINCT CASE WHEN C.collision_severity IN (1, 2)
                           THEN V.collision_index END) AS severe_collision_count,
       ROUND(
           COUNT(DISTINCT CASE WHEN C.collision_severity IN (1, 2)
                               THEN V.collision_index END) * 100.0 /
           NULLIF(COUNT(DISTINCT V.collision_index), 0), 2
       ) AS severe_collision_rate,
       RANK() OVER (
           ORDER BY COUNT(DISTINCT CASE WHEN C.collision_severity IN (1, 2)
                                        THEN V.collision_index END) * 100.0 /
                    NULLIF(COUNT(DISTINCT V.collision_index), 0) DESC
       ) AS rate_rank
FROM vehicles AS V
JOIN collisions AS C ON C.collision_index = V.collision_index
GROUP BY V.vehicle_type
HAVING COUNT(DISTINCT V.collision_index) >= 100
ORDER BY rate_rank, V.vehicle_type;


-- =============================================================================
-- QUESTION 45
-- How does vehicle age relate to severe-collision involvement?
-- =============================================================================

-- NULL must be tested explicitly. Otherwise SQL comparisons with NULL are not
-- TRUE and a missing age would incorrectly fall into the ELSE '13+ years'.
WITH vehicle_age_groups AS (
    SELECT V.collision_index, C.collision_severity,
           CASE
               WHEN V.age_of_vehicle IS NULL OR V.age_of_vehicle < 0 THEN 'Unknown'
               WHEN V.age_of_vehicle <= 3 THEN '0-3 years'
               WHEN V.age_of_vehicle <= 6 THEN '4-6 years'
               WHEN V.age_of_vehicle <= 9 THEN '7-9 years'
               WHEN V.age_of_vehicle <= 12 THEN '10-12 years'
               ELSE '13+ years'
           END AS vehicle_age_group
    FROM vehicles AS V
    JOIN collisions AS C ON C.collision_index = V.collision_index
)
SELECT vehicle_age_group,
       COUNT(DISTINCT collision_index) AS collisions,
       COUNT(DISTINCT CASE WHEN collision_severity IN (1, 2)
                           THEN collision_index END) AS severe_collisions,
       ROUND(COUNT(DISTINCT CASE WHEN collision_severity IN (1, 2)
                                 THEN collision_index END) * 100.0 /
             NULLIF(COUNT(DISTINCT collision_index), 0), 2)
           AS severe_collision_rate
FROM vehicle_age_groups
GROUP BY vehicle_age_group
ORDER BY FIELD(vehicle_age_group, '0-3 years', '4-6 years', '7-9 years',
               '10-12 years', '13+ years', 'Unknown');

-- A collision with vehicles in different age groups can appear once in each
-- relevant group. That is correct for involvement analysis; groups are not
-- mutually exclusive at collision level.


-- =============================================================================
-- QUESTION 46
-- How does driver age relate to severe-collision involvement?
-- =============================================================================

WITH driver_groups AS (
    SELECT V.collision_index, C.collision_severity,
           CASE
               WHEN V.age_of_driver IS NULL OR V.age_of_driver < 0 THEN 'Unknown'
               WHEN V.age_of_driver < 17 THEN 'Under 17'
               WHEN V.age_of_driver <= 24 THEN '17-24'
               WHEN V.age_of_driver <= 34 THEN '25-34'
               WHEN V.age_of_driver <= 44 THEN '35-44'
               WHEN V.age_of_driver <= 54 THEN '45-54'
               WHEN V.age_of_driver <= 64 THEN '55-64'
               WHEN V.age_of_driver <= 74 THEN '65-74'
               ELSE '75+'
           END AS driver_age_group
    FROM vehicles AS V
    JOIN collisions AS C ON C.collision_index = V.collision_index
)
SELECT driver_age_group,
       COUNT(DISTINCT collision_index) AS collisions,
       COUNT(DISTINCT CASE WHEN collision_severity IN (1, 2)
                           THEN collision_index END) AS severe_collisions,
       ROUND(COUNT(DISTINCT CASE WHEN collision_severity IN (1, 2)
                                 THEN collision_index END) * 100.0 /
             NULLIF(COUNT(DISTINCT collision_index), 0), 2)
           AS severe_collision_rate
FROM driver_groups
GROUP BY driver_age_group
ORDER BY FIELD(driver_age_group, 'Under 17', '17-24', '25-34', '35-44',
               '45-54', '55-64', '65-74', '75+', 'Unknown');


-- =============================================================================
-- QUESTION 47
-- Which driver-sex categories are involved in the most collisions and what is
-- their observed severe-collision rate?
-- =============================================================================

SELECT V.sex_of_driver AS sex_of_driver_code,
       COUNT(DISTINCT V.collision_index) AS collisions,
       COUNT(DISTINCT CASE WHEN C.collision_severity IN (1, 2)
                           THEN V.collision_index END) AS severe_collisions,
       ROUND(COUNT(DISTINCT CASE WHEN C.collision_severity IN (1, 2)
                                 THEN V.collision_index END) * 100.0 /
             NULLIF(COUNT(DISTINCT V.collision_index), 0), 2)
           AS severe_collision_rate
FROM vehicles AS V
JOIN collisions AS C ON C.collision_index = V.collision_index
GROUP BY V.sex_of_driver
ORDER BY collisions DESC;

-- This is collision involvement, not a per-driver risk rate. The dataset has no
-- denominator for licensed drivers, miles driven or journey frequency.


-- =============================================================================
-- QUESTION 48
-- Which vehicle types are most often involved in collisions with a pedestrian
-- casualty?
-- =============================================================================

-- casualty_class = 3 identifies pedestrians. DISTINCT defines the relevant set
-- of collisions before it is joined to vehicles, preventing one collision with
-- multiple pedestrian casualties from multiplying vehicle counts.
WITH pedestrian_collisions AS (
    SELECT DISTINCT collision_index
    FROM casualties
    WHERE casualty_class = 3
)
SELECT V.vehicle_type,
       COUNT(DISTINCT V.collision_index) AS pedestrian_collisions,
       RANK() OVER (ORDER BY COUNT(DISTINCT V.collision_index) DESC) AS rank_by_volume
FROM vehicles AS V
JOIN pedestrian_collisions AS P ON P.collision_index = V.collision_index
GROUP BY V.vehicle_type
ORDER BY rank_by_volume, V.vehicle_type;


-- =============================================================================
-- QUESTION 49
-- Which vehicle types are most often involved in collisions containing a
-- cyclist casualty?
-- =============================================================================

-- casualty_type = 1 identifies a cyclist. DISTINCT first defines the set of
-- cyclist-casualty collisions, so multiple cyclist casualties in one collision
-- do not multiply the vehicle involvement counts.
WITH cyclist_collisions AS (
    SELECT DISTINCT collision_index
    FROM casualties
    WHERE casualty_type = 1
)
SELECT V.vehicle_type,
       COUNT(DISTINCT V.collision_index) AS cyclist_collisions,
       RANK() OVER (ORDER BY COUNT(DISTINCT V.collision_index) DESC) AS rank_by_volume
FROM vehicles AS V
JOIN cyclist_collisions AS CY ON CY.collision_index = V.collision_index
GROUP BY V.vehicle_type
ORDER BY rank_by_volume, V.vehicle_type;


-- =============================================================================
-- QUESTION 50
-- Which vehicle types combine below-average collision volume with an
-- above-average severe-collision rate, suggesting potentially overlooked risk?
-- =============================================================================

-- STEP 1 computes distinct collision involvement for every vehicle type.
-- STEP 2 computes benchmarks across vehicle types.
-- STEP 3 keeps categories below the average volume but above the average rate.
-- A 100-collision eligibility rule is applied before benchmarking so tiny
-- categories do not dominate the comparison.
WITH vehicle_metrics AS (
    SELECT V.vehicle_type,
           COUNT(DISTINCT V.collision_index) AS collisions,
           COUNT(DISTINCT CASE WHEN C.collision_severity IN (1, 2)
                               THEN V.collision_index END) AS severe_collisions,
           COUNT(DISTINCT CASE WHEN C.collision_severity IN (1, 2)
                               THEN V.collision_index END) * 100.0 /
           NULLIF(COUNT(DISTINCT V.collision_index), 0) AS full_severe_rate
    FROM vehicles AS V
    JOIN collisions AS C ON C.collision_index = V.collision_index
    GROUP BY V.vehicle_type
    HAVING COUNT(DISTINCT V.collision_index) >= 100
),
benchmarks AS (
    SELECT AVG(collisions) AS avg_collision_volume,
           AVG(full_severe_rate) AS avg_vehicle_type_severe_rate
    FROM vehicle_metrics
)
SELECT M.vehicle_type, M.collisions, M.severe_collisions,
       ROUND(M.full_severe_rate, 2) AS severe_collision_rate,
       ROUND(B.avg_collision_volume, 2) AS benchmark_avg_volume,
       ROUND(B.avg_vehicle_type_severe_rate, 2) AS benchmark_avg_rate,
       RANK() OVER (ORDER BY M.full_severe_rate DESC) AS priority_rank
FROM vehicle_metrics AS M
CROSS JOIN benchmarks AS B
WHERE M.collisions < B.avg_collision_volume
  AND M.full_severe_rate > B.avg_vehicle_type_severe_rate
ORDER BY priority_rank, M.vehicle_type;

-- MANAGEMENT INTERPRETATION:
-- These categories may receive less attention in a volume-only ranking but show
-- above-average severity among eligible vehicle types. This is a screening tool,
-- not proof that vehicle type causes severe outcomes. Operational prioritisation
-- should also consider exposure, confidence intervals, vehicle occupancy, road
-- environment and intervention feasibility.


/*
===============================================================================
EXECUTIVE REPORTING TEMPLATE — COMPLETE AFTER RUNNING THE NOTEBOOK
===============================================================================

Use verified query outputs rather than invented figures. A useful final summary
should report:
- total collisions, vehicles and casualties;
- change in collision and casualty volume from 2021 to 2025;
- overall and yearly severe-collision proportions;
- highest-volume and highest-rate hours (kept distinct);
- highest-volume geography and highest-rate geography above its threshold;
- notable speed-limit/road-type patterns;
- leading environmental category by observed severe rate;
- leading vehicle types by severe volume and by severe rate;
- pedestrian and cyclist collision-involvement findings;
- Q50's overlooked-risk candidates.

VERIFIED FIGURES AVAILABLE FROM THE SUPPLIED PROJECT
----------------------------------------------------
- 513,801 collision records / unique collisions
- 937,265 vehicle records
- 652,821 casualty records
- data range 2021-01-01 to 2025-12-31
- at 00:00: 8,110 collisions; 2,508 severe; 30.92% severe rate
- light condition code 6: 34.95% observed severe-collision rate

LIMITATIONS
-----------
1. STATS19 covers police-reported personal-injury collisions, not all incidents.
2. Counts/rates are not adjusted for traffic volume, miles travelled or population.
3. Observed associations do not establish causation.
4. Coded unknown/missing values can remain even when SQL NULL rates are low.
5. Small categories can produce unstable rates; disclosed thresholds reduce but
   do not eliminate this issue.
6. A collision may belong to multiple vehicle-type or vehicle-age involvement
   groups; those category counts must not be summed as mutually exclusive totals.
7. Injury-based reporting can affect recorded severity comparability.
8. The dataset spans migration from the earlier STATS19 specification to the
   2024 specification. Police forces adopted the revision at different times, so
   variable definitions and reporting practice can introduce time-series breaks.
9. Geographic rankings identify collision locations, not the home areas of people
   involved, and are not population risk estimates.

END OF NOTEBOOK
===============================================================================
*/
