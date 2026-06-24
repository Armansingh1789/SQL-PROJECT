SELECT * FROM clean.crime_clean01;

SELECT 'Total rows' AS check_name, COUNT(*) AS value FROM crime_clean01;
 
-- ---- INSIGHT 1: Crime type frequency ----
SELECT
    crime_type,
    COUNT(*) AS total_incidents,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM crime_clean), 1) AS percentage
FROM crime_clean01
GROUP BY crime_type
ORDER BY total_incidents DESC;
 
 
-- ---- INSIGHT 2: Top 5 most dangerous cities ----
SELECT city,state,
    COUNT(*) AS total_crimes,
    ROUND(AVG(property_loss_usd), 2) AS avg_property_loss
FROM crime_clean01
GROUP BY city, state
ORDER BY total_crimes DESC
LIMIT 10;
 
 
-- ---- INSIGHT 3: Case status breakdown ----
SELECT case_status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM crime_clean WHERE case_status IS NOT NULL), 1) AS pct
FROM crime_clean01
WHERE case_status IS NOT NULL
GROUP BY case_status
ORDER BY count DESC;
 
 
-- ---- INSIGHT 4: Severity vs average property loss ----
SELECT severity,
    COUNT(*) AS incidents,
    ROUND(AVG(property_loss_usd), 2) AS avg_loss,
    ROUND(MAX(property_loss_usd), 2) AS max_loss,
    ROUND(MIN(property_loss_usd), 2) AS min_loss
FROM crime_clean01
WHERE severity IS NOT NULL
GROUP BY severity
ORDER BY CASE severity
    WHEN 'Low' THEN 1 WHEN 'Medium' THEN 2
    WHEN 'High' THEN 3 WHEN 'Critical' THEN 4
END;
 
 
-- ---- INSIGHT 5: Weapon usage frequency ----
SELECT
    weapon_used,
    COUNT(*) AS times_used,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM crime_clean WHERE weapon_used IS NOT NULL), 1) AS pct
FROM crime_clean01
WHERE weapon_used IS NOT NULL
GROUP BY weapon_used
ORDER BY times_used DESC;
 
 
-- ---- INSIGHT 6: Crime trends by year ----
SELECT
    SUBSTR(incident_datetime, 1, 4) AS year,
    COUNT(*) AS total_incidents,
    ROUND(AVG(property_loss_usd), 2) AS avg_property_loss
FROM crime_clean01
WHERE incident_datetime IS NOT NULL and incident_datetime!=1
GROUP BY year
ORDER BY year;
 
 
-- ---- INSIGHT 7: Resolution rate by crime type ----
SELECT
    crime_type,
    COUNT(*) AS total,
    SUM(CASE WHEN resolution = 'Arrest Made' THEN 1 ELSE 0 END) AS arrests,
    ROUND(SUM(CASE WHEN resolution = 'Arrest Made' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS arrest_rate_pct
FROM crime_clean01
GROUP BY crime_type
ORDER BY arrest_rate_pct DESC;
 
 
-- ---- INSIGHT 8: Gender of suspects vs crime type (top 5 crimes) ----
SELECT
    crime_type,
    suspect_gender,
    COUNT(*) AS count
FROM crime_clean01
WHERE suspect_gender IS NOT NULL
  AND crime_type IN (
      SELECT crime_type FROM crime_clean
      GROUP BY crime_type 
  )
GROUP BY crime_type, suspect_gender
ORDER BY crime_type, count DESC;
 
 
-- ---- INSIGHT 9: District-wise crime distribution ----
SELECT
    district,
    COUNT(*) AS total_crimes,
    ROUND(AVG(num_arrests), 2) AS avg_arrests_per_case,
    ROUND(AVG(property_loss_usd), 2) AS avg_loss
FROM crime_clean01
WHERE district IS NOT NULL
GROUP BY district
ORDER BY total_crimes DESC;
 
 
-- ---- INSIGHT 10: Online vs offline reporting trend ----
SELECT
    reported_online,
    COUNT(*) AS count,
    ROUND(AVG(property_loss_usd), 2) AS avg_loss,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM crime_clean WHERE reported_online IS NOT NULL), 1) AS pct
FROM crime_clean01
WHERE reported_online IS NOT NULL
GROUP BY reported_online;
 
 