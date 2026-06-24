SELECT *
FROM dirty;

-- FINDING DUPLICATE
-- LET'S FIND DUPLICATE 
WITH DUPLICATE1 AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY incident_id,crime_type,latitude,longitude ) AS ROW_NUM 
FROM dirty )
SELECT * 
FROM DUPLICATE1
WHERE ROW_NUM >1
;  
-- WE RUN THIS QUIRY AND FIND ALL DUPLICATES 

-- LET'S VERIFY THE DUPLICATE THAT THESE ARE ACTUAL DUPLICATE OR NOT
SELECT * FROM dirty
WHERE incident_id='INC000263';

-- WE CHECK THOSE VALUE'INC000008' ,'INC000264','INC000109','INC000263' AND FIND YES THESE ARE TWO TIME IN OUR DATA
-- SO THESE ARE DUPLICATE

-- DELETING DUPLICATE()
-- NOW WE ARE GOING TO REMOVING ALL OF THOSE DUPLICATE

WITH DUPLICATE1 AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY incident_id,crime_type,latitude,longitude ) AS ROW_NUM 
FROM dirty )
DELETE
FROM DUPLICATE1
WHERE ROW_NUM >1
;
-- SEE HERE  WE CAN'T DIRECT DELETE DATA FROM CTE TABLE SO WE HAVE TO MAKE A ANOTHER TABLE LOOK LIKE EXITING ONE 
-- AND I HAVE TO CREATE ANOTHER COLUMN FOR ROW_NUM() 
-- LET'S DO THIS
 
 -- WE HAVE CREATE A TABLESAME AS dirty
 CREATE TABLE stage_01
 LIKE dirty;

SELECT * 
FROM stage_01;
-- IT'S WORK  

-- NOW CREATING A NEW COLUMN ROW_NUM 

ALTER TABLE stage_01
ADD COLUMN row_num INT 
;

-- WE HAVE CHECK COLUMN IT HAVE BEEN ADDED SUCCESSFULLY
SELECT * 
FROM stage_01;

-- NOW INSERTING THE DATA IN TO stage_01
INSERT INTO stage_01 
SELECT *, ROW_NUMBER() OVER(PARTITION BY incident_id,crime_type,latitude,longitude ) AS ROW_NUM 
FROM dirty ;

SELECT * 
FROM stage_01;

-- NOW IN NEW TABLE JUST CHECK DUPLICATE IN DATA 
SELECT *
FROM stage_01 
WHERE row_num >1;
-- WHEN WE RUN THIS 182 ROWS EFECTED
-- NOW HERE SAME DUPLICATE VALUE 
-- BUT WE CAN DELETE HERE DUPLICATE AND OUR UNIQUE DATA SAFE 
-- AND MAIN DATA WILL(dirty TABLE) BE SAME AS WE IMPORTED BECAUSE IF WE DO SOMETHING WRONG WE CAN USE IT AGAIN 

-- LET DELETE DUPLICATE
SET SQL_SAFE_UPDATES=0;

DELETE 
FROM stage_01 
WHERE row_num >1;
-- WE RUN THIS SAME 182 ROWS DELETED 
SELECT *
FROM stage_01 
WHERE row_num >1;


SELECT *
FROM stage_01 
WHERE crime_type = 0
;

--  NOW JUST STANDERIZE THE DATA
SELECT * 
FROM stage_01;

-- NOW CREATE NEW TABLE FOR FINAL CLEANED DATA
-- THERE WAS TO MANY MISTAKE IN EVERY SINGLE COLUMN SHOW WE FIX IT 
-- NOW JUST INSERTING ALL THING IN TO NEW TABLE
CREATE TABLE crime_clean AS
SELECT
    incident_id,
 
    -- ---- CRIME TYPE: normalize all variants ----
    CASE
        WHEN UPPER(TRIM(crime_type)) IN ('ARSON','ARSEN','FIRE SETTING')               THEN 'Arson'
        WHEN UPPER(TRIM(crime_type)) IN ('ASSAULT','ASSLT','BATTERY','ASSAULT & BATTERY','ASSAULT  &  BATTERY') THEN 'Assault'
        WHEN UPPER(TRIM(crime_type)) IN ('BURGLARY','BURGLRY','B&E','BREAKING & ENTERING') THEN 'Burglary'
        WHEN UPPER(TRIM(crime_type)) IN ('ROBBERY','ROBBRY','ROBERRY','ARMED ROBBERY','ARMED  ROBBERY') THEN 'Robbery'
        WHEN UPPER(TRIM(crime_type)) IN ('THEFT','THEFT ','THEFT  ','LARCENY','STEALING','THEFT/LARCENY') THEN 'Theft'
        WHEN UPPER(TRIM(crime_type)) IN ('HOMICIDE','HOMOCIDE','MURDER','MANSLAUGHTER')  THEN 'Homicide'
        WHEN UPPER(TRIM(crime_type)) IN ('DOMESTIC VIOLENCE','DOMESTIC  VIOLENCE','DOMESTC VIOLENCE','DOM. VIOLENCE','DV') THEN 'Domestic Violence'
        WHEN UPPER(TRIM(crime_type)) IN ('DRUG OFFENSE','DRUG OFFENCE','DRUG  OFFENSE','DRUG  OFFENCE','NARCOTICS','DRUGS') THEN 'Drug Offense'
        WHEN UPPER(TRIM(crime_type)) IN ('DUI','DUII','DWI','D.U.I.','DRUNK DRIVING')   THEN 'DUI'
        WHEN UPPER(TRIM(crime_type)) IN ('FRAUD','FRAUDULENT ACTIVITY','DECEPTION','SCAM','ONLINE FRAUD') THEN 'Fraud'
        WHEN UPPER(TRIM(crime_type)) IN ('SEXUAL ASSAULT','SEXUAL ASSUALT','SEX ASSAULT','SEX  ASSAULT','SA') THEN 'Sexual Assault'
        WHEN UPPER(TRIM(crime_type)) IN ('CYBERCRIME','CYBER CRIME','CYBER  CRIME','HACKING') THEN 'Cybercrime'
        WHEN UPPER(TRIM(crime_type)) IN ('KIDNAPPING','KIDNAPING')                      THEN 'Kidnapping'
        WHEN UPPER(TRIM(crime_type)) IN ('TRESPASSING','TRESPASS','TRESSPASSING')       THEN 'Trespassing'
        WHEN UPPER(TRIM(crime_type)) IN ('VANDALISM','VANDLISM','GRAFFITI')             THEN 'Vandalism'
        WHEN UPPER(TRIM(crime_type)) IN ('ABDUCTION')                                   THEN 'Kidnapping'
        ELSE TRIM(crime_type)
    END AS crime_type,
 
    TRIM(district)  AS district,
    TRIM(city)      AS city,
    UPPER(TRIM(state)) AS state,
    TRIM(address)   AS address,
 
    -- ---- COORDINATES: null out invalid ----
    CASE WHEN latitude  BETWEEN -90  AND 90  THEN latitude  ELSE NULL END AS latitude,
    CASE WHEN longitude BETWEEN -180 AND 180 THEN longitude ELSE NULL END AS longitude,
 
    -- ---- DATETIME: parse both formats ----
    CASE
        WHEN incident_datetime LIKE '____-__-__ %' THEN incident_datetime
        WHEN incident_datetime LIKE '__-__-____'   THEN
            SUBSTR(incident_datetime,7,4) || '-' ||
            SUBSTR(incident_datetime,4,2) || '-' ||
            SUBSTR(incident_datetime,1,2)
        ELSE NULL
    END AS incident_datetime,
 
    officer_id,
 
    -- ---- BADGE NUMBER: null if missing ----
    CASE WHEN badge_number IS NOT NULL THEN badge_number ELSE NULL END AS badge_number,
 
    suspect_id,
    TRIM(suspect_first_name) AS suspect_first_name,
    TRIM(suspect_last_name)  AS suspect_last_name,
 
    -- ---- SUSPECT AGE: fix invalid values ----
    CASE
        WHEN suspect_age > 0 AND suspect_age < 100 THEN suspect_age
        ELSE NULL
    END AS suspect_age,
 
    -- ---- SUSPECT GENDER: normalize ----
    CASE
        WHEN UPPER(TRIM(suspect_gender)) IN ('M','MALE')   THEN 'Male'
        WHEN UPPER(TRIM(suspect_gender)) IN ('F','FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(suspect_gender)) = 'OTHER'         THEN 'Other'
        ELSE NULL
    END AS suspect_gender,
 
    TRIM(suspect_race) AS suspect_race,
 
    victim_id,
    TRIM(victim_first_name) AS victim_first_name,
    TRIM(victim_last_name)  AS victim_last_name,
 
    -- ---- VICTIM AGE: fix invalid values ----
    CASE
        WHEN victim_age > 0 AND victim_age < 120 THEN victim_age
        ELSE NULL
    END AS victim_age,
 
    -- ---- VICTIM GENDER: normalize ----
    CASE
        WHEN UPPER(TRIM(victim_gender)) IN ('M','MALE')   THEN 'Male'
        WHEN UPPER(TRIM(victim_gender)) IN ('F','FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(victim_gender)) = 'OTHER'         THEN 'Other'
        ELSE NULL
    END AS victim_gender,
 
    -- ---- WEAPON: normalize ----
    CASE
        WHEN UPPER(TRIM(weapon_used)) IN ('FIREARM','GUN','PISTOL','RIFLE') THEN 'Firearm'
        WHEN UPPER(TRIM(weapon_used)) IN ('KNIFE','KNFE')                   THEN 'Knife'
        WHEN UPPER(TRIM(weapon_used)) IN ('BLUNT OBJECT','BAT')             THEN 'Blunt Object'
        WHEN UPPER(TRIM(weapon_used)) IN ('HANDS','HANDS/FEET','UNARMED')   THEN 'Unarmed/Hands'
        ELSE NULL
    END AS weapon_used,
 
    -- ---- SEVERITY: normalize (numbers → labels) ----
    CASE
        WHEN UPPER(TRIM(severity)) IN ('1','LOW','LOW ')      THEN 'Low'
        WHEN UPPER(TRIM(severity)) IN ('2','MEDIUM','MED')    THEN 'Medium'
        WHEN UPPER(TRIM(severity)) IN ('3','HIGH')            THEN 'High'
        WHEN UPPER(TRIM(severity)) IN ('4','CRITICAL','CRIT') THEN 'Critical'
        ELSE NULL
    END AS severity,
 
    -- ---- CASE STATUS: normalize ----
    CASE
        WHEN UPPER(TRIM(case_status)) IN ('OPEN')                           THEN 'Open'
        WHEN UPPER(TRIM(case_status)) IN ('CLOSED')                         THEN 'Closed'
        WHEN UPPER(TRIM(case_status)) IN ('RESOLVED')                       THEN 'Resolved'
        WHEN UPPER(TRIM(case_status)) IN ('PENDING','PENDNG')               THEN 'Pending'
        WHEN UPPER(TRIM(case_status)) IN ('UNDER INVESTIGATION','INVESTGATION') THEN 'Under Investigation'
        ELSE NULL
    END AS case_status,
 
    -- ---- RESOLUTION: normalize ----
    CASE
        WHEN UPPER(TRIM(resolution)) IN ('ARREST MADE','ARRES MADE')  THEN 'Arrest Made'
        WHEN UPPER(TRIM(resolution)) IN ('NO ARREST')                  THEN 'No Arrest'
        WHEN UPPER(TRIM(resolution)) IN ('WARNING ISSUED','WARNING')   THEN 'Warning Issued'
        WHEN UPPER(TRIM(resolution)) IN ('CASE DISMISSED','DISMISSED') THEN 'Case Dismissed'
        ELSE NULL
    END AS resolution,
 
    CASE WHEN num_arrests >= 0 THEN num_arrests ELSE NULL END AS num_arrests,
    CASE WHEN property_loss_usd >= 0 THEN property_loss_usd ELSE NULL END AS property_loss_usd,
 
    -- ---- REPORTED ONLINE: normalize to 1/0 ----
    CASE
        WHEN UPPER(TRIM(reported_online)) IN ('YES','TRUE','1') THEN 1
        WHEN UPPER(TRIM(reported_online)) IN ('NO','FALSE','0') THEN 0
        ELSE NULL
    END AS reported_online
FROM stage_01;

# HANDING MISSING AND NULL VALUE AND 

SELECT * FROM clean.crime_clean ;

delete from crime_clean
where suspect_id ='' and suspect_first_name=''
and suspect_last_name='' and suspect_age is null and suspect_gender is null ;
set sql_SAFE_UPDATES=0;


delete from crime_clean 
where victim_id='' and  victim_first_name=''and victim_last_name='' and victim_age is null  and victim_gender is null;


create table crime_clean01
select 
case when badge_number='' then "unknown"
else badge_number
end as badge_num,
case when suspect_id='' then "unknown"
else suspect_id
end as suspect_id,
CASE WHEN suspect_age IS NULL THEN 0
else suspect_age
END AS SUSPECT_AGE,
CASE WHEN suspect_gender IS NULL AND suspect_age%2=0  THEN "Male"
ELSE "Female" 
END AS SUSPECT_GENDER,
case when suspect_race ='' or suspect_race ='N/A' then 'Unknown'
else suspect_race
end as suspect_race ,
case when victim_id ='' then 'Unknown'
else victim_id
end as victim_id,
CASE WHEN victim_age IS NULL THEN 0
else victim_age
END AS victim_age,
CASE WHEN victim_gender IS NULL AND victim_age%2=0  THEN "Male"
ELSE "Female" 
END AS victim_gender,
case  when weapon_used is null then 'Unknown weapon'
else weapon_used
end as weapon_used,
case when severity is null then 'No severity'
else severity
end as severity,
case when case_status is null then 'Pending'
else case_status 
end as case_status,
case when resolution is null then 'No arrest'
else resolution
end as resolution,
case when num_arrests is null or num_arrests='' then 0
else num_arrests
end as num_arrests,
case when property_loss_usd is null or property_loss_usd='' then '22654.45'
else property_loss_usd
end as property_loss_usd,
case when reported_online is null then 0
else reported_online
end as reported_online
from crime_clean;


select suspect_gender , avg(suspect_age) from crime_clean01
group by SUSPECT_GENDER;

update  crime_clean01
set suspect_age=46
where suspect_age =0;
update  crime_clean01
set suspect_age=46
where suspect_age =0; 

SELECT * FROM crime_clean01 ;
 


