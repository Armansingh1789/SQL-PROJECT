# 🔍 Crime Incident Data Analysis — MySQL

> **End-to-end data cleaning, standardisation, and analytical reporting on 5,000+ messy crime records using MySQL.**

---

## 📌 Project Overview

This project demonstrates a complete SQL-based data analytics workflow — from raw, dirty crime incident data to a fully cleaned, standardised dataset with 10 actionable business insights. The project covers duplicate removal, multi-column normalisation, null handling, and complex analytical queries.

| Detail | Info |
|---|---|
| **Tool** | MySQL (Workbench) |
| **Dataset Size** | ~5,000 rows, 33 columns |
| **Duplicates Removed** | 182 records |
| **Columns Cleaned** | 30+ |
| **Insights Generated** | 10 |
| **Project Type** | Independent / Personal |
| **Timeline** | May – Jun 2026 |

---

## 📁 Project Files

```
├── crime_incidents_messy.csv                         # Raw input dataset (dirty data)
├── Crime_incident_data_clean_and_standardisation.sql # Data cleaning & ETL pipeline
└── Crime_clean_Insights.sql                          # Analytical queries & insights
```

---

## 🗂️ Dataset Description

The raw dataset (`crime_incidents_messy.csv`) contains crime incident records with the following columns:

| Column Group | Columns |
|---|---|
| **Incident Info** | `incident_id`, `crime_type`, `incident_datetime`, `district`, `city`, `state`, `address`, `latitude`, `longitude` |
| **Officer Info** | `officer_id`, `officer_first_name`, `officer_last_name`, `badge_number` |
| **Suspect Info** | `suspect_id`, `suspect_first_name`, `suspect_last_name`, `suspect_age`, `suspect_gender`, `suspect_race` |
| **Victim Info** | `victim_id`, `victim_first_name`, `victim_last_name`, `victim_age`, `victim_gender`, `victim_phone` |
| **Case Details** | `weapon_used`, `severity`, `case_status`, `resolution`, `num_arrests`, `property_loss_usd`, `reported_online`, `notes` |

**Known data quality issues in raw file:**
- Duplicate records (same incident appearing multiple times)
- Inconsistent crime type labels (e.g., `asslt`, `ASSAULT`, `Assault & Battery`)
- Invalid ages (`-28`, `262`, `231`)
- Invalid coordinates (latitude `170.28` — outside valid range)
- Mixed datetime formats (`YYYY-MM-DD` and `DD-MM-YYYY`)
- Mixed gender values (`M`, `Male`, `MALE`, `F`, `Female`)
- Inconsistent severity codes (`1`, `Low`, `LOW`, `LOW `)
- Blank and NULL values across multiple columns
- Typos in case status, resolution, and weapon fields

---

## 🛠️ Data Cleaning Pipeline

The cleaning process follows a **3-stage ETL pipeline**:

```
dirty  ──→  stage_01  ──→  crime_clean  ──→  crime_clean01
(raw)     (deduped)     (normalised)       (nulls handled)
```

### Stage 1 — Duplicate Detection & Removal (`dirty` → `stage_01`)

```sql
-- Identify duplicates using ROW_NUMBER() window function
WITH DUPLICATE1 AS (
  SELECT *, ROW_NUMBER() OVER(
    PARTITION BY incident_id, crime_type, latitude, longitude
  ) AS row_num
  FROM dirty
)
SELECT * FROM DUPLICATE1 WHERE row_num > 1;
```

- Created `stage_01` (same schema as `dirty`) with an extra `row_num` column
- Inserted all rows with window-function row numbers
- **Deleted 182 duplicate rows** (kept `row_num = 1`)
- Original `dirty` table preserved as rollback reference

---

### Stage 2 — Standardisation & Normalisation (`stage_01` → `crime_clean`)

Used `CREATE TABLE crime_clean AS SELECT ...` with extensive `CASE WHEN` logic:

#### Crime Type Normalisation (15+ variants → 16 clean categories)
```sql
CASE
  WHEN UPPER(TRIM(crime_type)) IN ('ASSAULT','ASSLT','BATTERY','ASSAULT & BATTERY') THEN 'Assault'
  WHEN UPPER(TRIM(crime_type)) IN ('ROBBERY','ROBBRY','ARMED ROBBERY')              THEN 'Robbery'
  WHEN UPPER(TRIM(crime_type)) IN ('THEFT','LARCENY','STEALING','THEFT/LARCENY')    THEN 'Theft'
  WHEN UPPER(TRIM(crime_type)) IN ('HOMICIDE','HOMOCIDE','MURDER','MANSLAUGHTER')   THEN 'Homicide'
  -- ...and 12 more categories
END AS crime_type
```

#### Coordinate Validation
```sql
CASE WHEN latitude  BETWEEN -90  AND 90  THEN latitude  ELSE NULL END AS latitude,
CASE WHEN longitude BETWEEN -180 AND 180 THEN longitude ELSE NULL END AS longitude
```

#### Date Format Unification
```sql
CASE
  WHEN incident_datetime LIKE '____-__-__ %' THEN incident_datetime
  WHEN incident_datetime LIKE '__-__-____'   THEN
      SUBSTR(incident_datetime,7,4) || '-' ||
      SUBSTR(incident_datetime,4,2) || '-' ||
      SUBSTR(incident_datetime,1,2)
  ELSE NULL
END AS incident_datetime
```

#### Other Normalised Fields
| Field | Raw Examples | Clean Output |
|---|---|---|
| `suspect_gender` | `M`, `MALE`, `male`, `F`, `FEMALE` | `Male`, `Female`, `Other` |
| `victim_gender` | `M`, `MALE`, `N/A`, `Unknown` | `Male`, `Female`, `Other` |
| `weapon_used` | `GUN`, `PISTOL`, `RIFLE`, `Firearm` | `Firearm` |
| `severity` | `1`, `LOW`, `LOW `, `2`, `MED` | `Low`, `Medium`, `High`, `Critical` |
| `case_status` | `OPEN`, `PENDNG`, `INVESTGATION` | `Open`, `Pending`, `Under Investigation` |
| `resolution` | `ARRES MADE`, `ARREST MADE` | `Arrest Made` |
| `reported_online` | `YES`, `True`, `1`, `NO`, `False` | `1` or `0` |
| `suspect_age` | `-28`, `262` | `NULL` (out of valid range) |
| `victim_age` | `231`, `243` | `NULL` (out of valid range) |

---

### Stage 3 — Null & Missing Value Handling (`crime_clean` → `crime_clean01`)

```sql
-- Remove records with completely empty suspect/victim data
DELETE FROM crime_clean
WHERE suspect_id='' AND suspect_first_name='' AND suspect_last_name=''
  AND suspect_age IS NULL AND suspect_gender IS NULL;
```

Final table built with fallback values:
```sql
CASE WHEN badge_number = ''  THEN 'Unknown' ELSE badge_number END AS badge_num,
CASE WHEN suspect_age IS NULL THEN 0 ELSE suspect_age END AS suspect_age,
CASE WHEN weapon_used IS NULL THEN 'Unknown weapon' ELSE weapon_used END AS weapon_used,
CASE WHEN severity IS NULL   THEN 'No severity' ELSE severity END AS severity,
CASE WHEN resolution IS NULL THEN 'No Arrest' ELSE resolution END AS resolution
```

---

## 📊 Analytical Insights (10 Queries)

All insights run on the final cleaned table `crime_clean01`:

| # | Insight | Key SQL Technique |
|---|---|---|
| 1 | **Crime Type Frequency** — which crimes occur most | `GROUP BY`, `COUNT`, percentage calculation |
| 2 | **Top 10 Most Dangerous Cities** — by incident count + avg property loss | `GROUP BY city, state`, `AVG`, `ORDER BY`, `LIMIT` |
| 3 | **Case Status Breakdown** — Open vs Closed vs Pending etc. | `GROUP BY case_status`, percentage via subquery |
| 4 | **Severity vs Property Loss** — avg/max/min loss per severity level | `GROUP BY severity`, custom `ORDER BY CASE` |
| 5 | **Weapon Usage Frequency** — firearm vs knife vs unarmed etc. | `GROUP BY weapon_used`, filtered `COUNT` |
| 6 | **Crime Trends by Year** — incidents + avg loss per year | `SUBSTR(incident_datetime,1,4)`, `GROUP BY year` |
| 7 | **Arrest Rate by Crime Type** — which crimes lead to most arrests | `SUM(CASE WHEN resolution='Arrest Made')`, rate calculation |
| 8 | **Gender of Suspects by Crime Type** | `GROUP BY crime_type, suspect_gender` |
| 9 | **District-wise Crime Distribution** — crimes + avg arrests + avg loss | `GROUP BY district`, `AVG(num_arrests)` |
| 10 | **Online vs Offline Reporting Trend** — % reported online + avg loss | `GROUP BY reported_online`, percentage via subquery |

---

## 💡 Key Findings (Sample)

- **Theft** and **Assault** were the most frequently occurring crime types
- Cities with higher crime volumes also showed significantly elevated average property losses
- **~40%** of all cases ended with no arrest (resolution = `No Arrest`)
- **Firearms** were the most commonly recorded weapon in the dataset
- Online-reported incidents had a distinct pattern in average property loss vs offline reports
- Crime incidents showed year-on-year variation, with certain years spiking in both volume and financial impact

---

## ⚙️ How to Run

### Prerequisites
- MySQL 8.0+ (or compatible)
- MySQL Workbench (recommended) or any SQL client

### Steps

1. **Import the raw data**
   ```sql
   -- Create your database and import crime_incidents_messy.csv as table: dirty
   CREATE DATABASE crime_analysis;
   USE crime_analysis;
   -- Use Table Data Import Wizard in MySQL Workbench to load the CSV as `dirty`
   ```

2. **Run the cleaning script**
   ```
   Execute: Crime_incident_data_clean_and_standardisation.sql
   ```
   This creates: `stage_01` → `crime_clean` → `crime_clean01`

3. **Run the insights queries**
   ```
   Execute: Crime_clean_Insights.sql
   ```
   All 10 insight queries are ready to run on `crime_clean01`

---

## 🧠 SQL Concepts Used

- `ROW_NUMBER()` window function for duplicate detection
- CTEs (`WITH` clause) for readable multi-step logic
- `CASE WHEN` for multi-branch normalisation
- `UPPER()`, `TRIM()`, `SUBSTR()` for string cleaning
- `ALTER TABLE` / `CREATE TABLE AS SELECT` for schema management
- Aggregate functions: `COUNT`, `AVG`, `MAX`, `MIN`, `SUM`
- Subqueries for percentage calculations
- `GROUP BY` with custom `ORDER BY CASE` for sorted severity output
- `DELETE` with safe update mode (`SET SQL_SAFE_UPDATES = 0`)

---

## 👤 Author

**Arman Singh**  
📧 armansingharmansingh484@gmail.com  
🔗 [LinkedIn](https://linkedin.com/in/armansingh) | [GitHub](https://github.com/Armansingh1789)  
📍 Kanpur, Uttar Pradesh, India

---

> *This project is part of my data analytics portfolio demonstrating real-world SQL data cleaning and business insight generation capabilities.*
