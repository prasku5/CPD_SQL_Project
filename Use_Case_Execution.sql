SET SQL_SAFE_UPDATES = 0; -- disabling sql workbench safe mode safety feature 
CREATE USER 'test'@'localhost' IDENTIFIED BY '1234'; -- enabling a test user to check access previleges
CREATE USER 'neptune'@'localhost' IDENTIFIED BY '4321'; -- enabling a new user to check revoke previleges

create database IF NOT EXISTS db_design_project;
use db_design_project;
show tables;

-- After import check the counts 
select count(*) from arrests;
select count(*) from chicagopopulation;
select count(*) from crimedate;
select count(*) from crimedesc;
select count(*) from crimelocation;
select count(*) from sexoffenders;
select count(*) from climate;

-- Preview the data 
select * from arrests limit 5;
select * from chicagopopulation limit 5;
select * from crimedate limit 5;
select * from crimedesc limit 20;
select * from crimelocation limit 5;
select * from sexoffenders limit 5;
select * from climate limit 5;

-- ===========================================================================================================================
-- USECASE: Update table schema to proper datetime and date columns from text columns - Challenges overcome
-- ===========================================================================================================================

-- Update the 'ARREST DATE' column in the 'arrests' table
-- Convert the existing date string format to MySQL datetime format

-- Convert source txt to date format example command to check if syntax is fine
UPDATE arrests
SET `ARREST DATE` = DATE_FORMAT(STR_TO_DATE(`ARREST DATE`, '%m/%d/%Y %h:%i:%s %p'), '%Y-%m-%d %H:%i:%s');

-- Alter the 'chicagopopulation' table
-- Modify the data type of the 'YEAR' column to SMALLINT
ALTER TABLE chicagopopulation
MODIFY COLUMN `YEAR` SMALLINT;

-- Update the 'DATE' column in the 'crimedate' table
-- Convert the existing date string format to MySQL date format
UPDATE crimedate
SET `DATE` = STR_TO_DATE(`DATE`, '%m/%d/%y');

-- Retrieve the count of crimes per year from the 'crimedate' table
SELECT YEAR(`DATE`) AS year, COUNT(*) AS count_per_year
FROM crimedate
GROUP BY YEAR(`DATE`)
ORDER BY year;

-- Update the 'DATE' column in the 'crimedesc' table
-- Convert the existing date string format to MySQL date format
UPDATE crimedesc
SET `DATE` = STR_TO_DATE(`DATE`, '%m/%d/%y');

-- Alter the 'crimelocation' table
-- Modify the data type of the 'YEAR' column to SMALLINT
ALTER TABLE crimelocation
MODIFY COLUMN `YEAR` SMALLINT;

-- Update the 'BIRTH DATE' column in the 'sexoffenders' table
-- Convert the existing date string format to MySQL date format
UPDATE sexoffenders
SET `BIRTH DATE` = date_format(STR_TO_DATE(`BIRTH DATE`, '%m/%d/%Y'), '%Y-%m-%d');

-- Update the 'time' column in the 'climate' table
-- Convert the existing datetime string format to MySQL datetime format
UPDATE climate
SET `time` = DATE_FORMAT(STR_TO_DATE(`time`, '%Y-%m-%dT%H:%i'), '%Y-%m-%d %H:%i:%s');

-- ===========================================================================================================================
-- USECASE:	Analyze trends in different types of crimes across specific time periods.
-- ===========================================================================================================================

/* This SQL script creates a view named 'RankedCrimesView' that facilitates year-wise crime ranking analysis 
based on the data from the 'crimedate' table. The inner query within the common table expression (CTE) named
 'RankedCrimes' calculates the total number of crimes for each crime type in each year between 2018 and 2022.
 It employs the ROW_NUMBER() window function to assign a rank to each crime type within its respective year 
 based on the total number of crimes, ordered in descending order. The outer query then selects the relevant 
 information, including the crime year, crime type, and total crimes, from the 'RankedCrimes' CTE, filtering 
 the results to include only the top three crime types in terms of the assigned ranks. The final result is an 
 ordered list showing the top three crime types for each year, providing insights into year-over-year crime trends. */

CREATE VIEW RankedCrimesView AS 
WITH RankedCrimes AS (
  SELECT 
    b.CRIME_YEAR,
    b.primary_type,
    b.total_crimes,
    ROW_NUMBER() OVER (PARTITION BY b.CRIME_YEAR ORDER BY total_crimes DESC) AS crime_rank
  FROM (
		SELECT YEAR(`date`) as CRIME_YEAR, primary_type, SUM(crime_count) AS total_crimes
		FROM crimedate
		WHERE YEAR(`date`) BETWEEN 2018 AND 2022
		GROUP BY YEAR(`date`), primary_type
		ORDER BY YEAR(`date`), total_crimes DESC) b
  WHERE b.CRIME_YEAR BETWEEN 2018 AND 2022
  GROUP BY b.CRIME_YEAR, primary_type
)

SELECT CRIME_YEAR, primary_type, total_crimes
FROM RankedCrimes
WHERE crime_rank <= 3
ORDER BY CRIME_YEAR, total_crimes DESC;

--  To analyze the crime trends between 2001- 2005 and 2018-2022. This will help us understand how the crimes evloved over the years, and what were the popular crimes.

#crime trends between 2001-2005

CREATE VIEW RankedCrimesView_2001_2005 AS 
WITH RankedCrimes AS (
  SELECT 
    b.CRIME_YEAR,
    b.primary_type,
    b.total_crimes,
    ROW_NUMBER() OVER (PARTITION BY b.CRIME_YEAR ORDER BY total_crimes DESC) AS crime_rank
  FROM (
		SELECT YEAR(`date`) as CRIME_YEAR, primary_type, SUM(crime_count) AS total_crimes
		FROM crimedate
		WHERE YEAR(`date`) BETWEEN 2001 AND 2005
		GROUP BY YEAR(`date`), primary_type
		ORDER BY YEAR(`date`), total_crimes DESC) b
  WHERE b.CRIME_YEAR BETWEEN 2001 AND 2005
  GROUP BY b.CRIME_YEAR, primary_type
)

SELECT CRIME_YEAR, primary_type, total_crimes
FROM RankedCrimes
WHERE crime_rank <= 3
ORDER BY CRIME_YEAR, total_crimes DESC;

-- 	Crime trends for year's 2018 - 2022 (Top crimes) - Year over Year Analysis

/* This SQL script creates a view named 'RankedCrimesYoYView' that provides insights into year-over-year changes 
in crime statistics. The first common table expression (CTE) named 'RankedCrimes' identifies the top three crime 
types for each year between 2018 and 2022 based on the total number of crimes. The second CTE named 'Year_over_Year_Change'
 calculates the year-over-year percentage change in total crimes for each crime type. It compares the total crimes 
 in the current year with the total crimes in the previous year, determining whether there is an increase, decrease,
 or no change. The final result includes information such as crime year, crime type, total crimes in the current and
 previous years, percentage change, and the trend of change. This view helps analyze patterns and variations in crime
 rates over consecutive years. */


Create view  RankedCrimesYoYView as 
with RankedCrimes as (
SELECT CRIME_YEAR, primary_type, total_crimes
FROM ( SELECT 
    b.CRIME_YEAR,
    b.primary_type,
    b.total_crimes,
    ROW_NUMBER() OVER (PARTITION BY b.CRIME_YEAR ORDER BY total_crimes DESC) AS crime_rank
  FROM (
		SELECT YEAR(`date`) as CRIME_YEAR, primary_type, SUM(crime_count) AS total_crimes
		FROM crimedate
		WHERE YEAR(`date`) BETWEEN 2018 AND 2022
		GROUP BY YEAR(`date`), primary_type
		ORDER BY YEAR(`date`), total_crimes DESC) b
  WHERE b.CRIME_YEAR BETWEEN 2018 AND 2022
  GROUP BY b.CRIME_YEAR, primary_type) a
  WHERE crime_rank <= 3
ORDER BY CRIME_YEAR, total_crimes DESC
),

Year_over_Year_Change as (
  -- Calculate YoY percentage change
  SELECT
    a.Crime_Year,
    a.primary_type,
    a.total_crimes AS Total_Crimes_CurrentYear,
    b.total_crimes AS Total_Crimes_PreviousYear,
    abs((a.total_crimes - b.total_crimes) / b.total_crimes) * 100 AS YoY_PercentageChange,
    CASE
      WHEN ((a.total_crimes - b.total_crimes) / b.total_crimes) * 100 > 0 THEN 'Increase'
      WHEN ((a.total_crimes - b.total_crimes) / b.total_crimes) * 100 < 0 THEN 'Decrease'
      ELSE 'No Change'
    END AS YoY_Trend
  FROM RankedCrimes a
  LEFT JOIN RankedCrimes b ON a.primary_type = b.primary_type AND a.Crime_Year = b.Crime_Year + 1
)

SELECT
  Crime_Year,
  primary_type,
  Total_Crimes_CurrentYear,
  Total_Crimes_PreviousYear,
  YoY_PercentageChange,
  YoY_Trend
FROM Year_over_Year_Change
ORDER BY Crime_Year, primary_type;

-- ===========================================================================================================================
-- USECASE: Identify patterns in crimes occurring at different climatic conditions.
-- ===========================================================================================================================

/* This SQL query addresses the use case of analyzing crime data grouped by primary crime types and their respective temperature 
categories (high, medium, low). It calculates the average temperature for each category and then identifies the highest and 
lowest average temperatures for each primary crime type within those categories. Essentially, it helps identify temperature 
 patterns associated with different types of crimes */

select max(temperature), min(temperature) from climate;

/* This SQL query retrieves the minimum and maximum temperatures for each temperature category, which is derived from the
 'temperature' values in the 'climate' table joined with the 'crimedate' table. The 'JoinedData' common table expression (CTE)
 combines data from both tables, ensuring that there is a match based on the trimmed date. The temperature categories are
 defined using a CASE statement, classifying temperatures into three categories: 'Low,' 'Medium,' and 'High.' 

The outer query groups the results by the 'temperature_category' and calculates the minimum and maximum temperatures 
within each category. The final output provides a summary of temperature statistics for each defined category, ordered
by the temperature category in ascending order. This analysis can offer insights into temperature patterns and extremes 
related to different crime types. */
 

select temperature_category, MIN(temperature) as MIN, max(temperature) as MAX
from (
WITH JoinedData AS (
  -- Join 'crimedate' and 'climate' tables
  SELECT
	cd.primary_type,
    cd.date as crime_date,
    clim.temperature as temperature
  FROM crimedate cd
  left JOIN climate clim ON TRIM(cd.date) = TRIM(DATE(clim.time))
  where clim.temperature is not null
  GROUP BY cd.primary_type, cd.date,clim.temperature
  ORDER BY
    cd.primary_type ASC,
    cd.date ASC,
    clim.temperature DESC
)
SELECT
	primary_type,
	temperature,
	CASE
        WHEN temperature >= -20.6 AND temperature <= -2.333 THEN 1
        WHEN temperature > -2.333 AND temperature <= 15.933 THEN 2
        WHEN temperature > 15.933 AND temperature <= 34.2 THEN 3
        ELSE NULL -- Handle any other cases, if needed
    END AS temperature_category
FROM JoinedData
) l
group by l.temperature_category
order by l.temperature_category asc ;

/* The SQL script creates a view named 'CrimeTypeByTempView' that analyzes crime types based on average temperatures.
It utilizes a common table expression (CTE) named 'ranked_avg_temps' to calculate the average temperature for each 
crime type, categorize them into temperature ranges ('Low,' 'Medium,' and 'High'), and assign rankings for both high 
and low temperatures within each category.

The final output selects crime types along with their average temperatures, high and low rankings, and the corresponding
 temperature categories. The view helps identify crime types associated with extreme temperature conditions, allowing
 for a comprehensive analysis of how different crime rates relate to temperature variations. */


CREATE VIEW CrimeTypeByTempView AS 
with ranked_avg_temps as (
SELECT
	l.primary_type,
	Avg_temperature,
	ROW_NUMBER() OVER (PARTITION BY l.temperature_category ORDER BY Avg_temperature DESC) AS high_rank,
	ROW_NUMBER() OVER (PARTITION BY l.temperature_category ORDER BY Avg_temperature ASC) AS low_rank
   FROM 
(
Select t.primary_type, t.temperature_category, Avg(temperature) as Avg_temperature 
from (
WITH JoinedData AS (
  -- Join 'crimedate' and 'climate' tables
  SELECT
	cd.primary_type,
    cd.date as crime_date,
    clim.temperature as temperature
  FROM crimedate cd
  left JOIN climate clim ON TRIM(cd.date) = TRIM(DATE(clim.time))
  where clim.temperature is not null
  GROUP BY cd.primary_type, cd.date,clim.temperature
  ORDER BY
    cd.primary_type ASC,
    cd.date ASC,
    clim.temperature DESC
)
SELECT
	primary_type,
	temperature,
	CASE
        WHEN temperature >= -20.6 AND temperature <= -2.333 THEN 1
        WHEN temperature > -2.333 AND temperature <= 15.933 THEN 2
        WHEN temperature > 15.933 AND temperature <= 34.2 THEN 3
        ELSE NULL -- Handle any other cases, if needed
    END AS temperature_category
FROM JoinedData
) t
group by t.primary_type, t.temperature_category
order by t.primary_type, t.temperature_category asc
) l
)
SELECT
primary_type, Avg_temperature, high_rank, low_rank,
CASE
        WHEN Avg_temperature >= -20.6 AND Avg_temperature <= -2.333 THEN 'Low'
        WHEN Avg_temperature > -2.333 AND Avg_temperature <= 15.933 THEN 'Medium'
        WHEN Avg_temperature > 15.933 AND Avg_temperature <= 34.2 THEN 'High'
        ELSE 'Undefined' -- Handle any other cases, if needed
    END AS temperature_category

FROM ranked_avg_temps 
WHERE high_rank = 1
UNION
SELECT
primary_type, Avg_temperature, high_rank, low_rank,
CASE
        WHEN Avg_temperature >= -20.6 AND Avg_temperature <= -2.333 THEN 'Low'
        WHEN Avg_temperature > -2.333 AND Avg_temperature <= 15.933 THEN 'Medium'
        WHEN Avg_temperature > 15.933 AND Avg_temperature <= 34.2 THEN 'High'
        ELSE 'Undefined' -- Handle any other cases, if needed
    END AS temperature_category
FROM ranked_avg_temps
WHERE low_rank = 1;


-- ===========================================================================================================================
-- USECASE: Compare crime rates with population density in different areas to identify patterns 
-- ===========================================================================================================================

/* The SQL script creates a view named 'CrimeDataWithPreviousYearView' that analyzes crime data, including false counts,
 arrest counts, and population statistics, with a year-over-year comparison. The common table expression (CTE) named 
 'CrimeDataWithPreviousYear' calculates the total false count, arrest count, and population for each crime type in each year. 
 It also includes corresponding values from the previous year using the LAG window function.

The final output selects relevant information such as the crime year, crime type, current year false count, previous year
 false count, year-over-year change in false count (both absolute and percentage), current year arrest count, previous
 year arrest count, year-over-year change in arrest count (both absolute and percentage), current year population count, 
 previous year population count, and year-over-year change in population (both absolute and percentage).

This view provides a comprehensive overview of crime-related statistics, facilitating a comparative analysis of year-over-year
 trends for different crime types, arrest counts, and population data. */

CREATE VIEW CrimeDataWithPreviousYearView AS 
WITH CrimeDataWithPreviousYear AS (
 SELECT
    YEAR(cd.date) AS YEAR,
    cd.primary_type,
    SUM(cd.false_count) AS total_false_count,
    SUM(cd.arrest_count) AS total_arrest_count,
    SUM(cp.`Population - Total`) / 1000000.0 AS total_population_millions,
    LAG(SUM(cd.false_count)) OVER (PARTITION BY cd.primary_type ORDER BY YEAR(cd.date) ASC) AS prev_year_false_count,
    LAG(SUM(cd.arrest_count)) OVER (PARTITION BY cd.primary_type ORDER BY YEAR(cd.date) ASC) AS prev_year_arrest_count,
    LAG(SUM(cp.`Population - Total`) / 1000000.0) OVER (PARTITION BY cd.primary_type ORDER BY YEAR(cd.date) ASC) AS prev_year_population_millions
FROM
    crimedate cd
JOIN
    chicagopopulation cp ON YEAR(cd.date) = cp.Year
WHERE
    YEAR(cd.date) IS NOT NULL AND cp.Year IS NOT NULL 
GROUP BY
    cd.primary_type, YEAR(cd.date)
ORDER BY
    YEAR ASC, PRIMARY_TYPE ASC, SUM(cd.false_count) DESC, SUM(cd.crime_count) ASC
)
SELECT
    YEAR,
    primary_type,
    total_false_count as current_year_false_count,
    prev_year_false_count,
    CASE
        WHEN prev_year_false_count IS NULL THEN 'No Previous Year Data'
        WHEN total_false_count > prev_year_false_count THEN 'Increase'
        WHEN total_false_count < prev_year_false_count THEN 'Decrease'
        ELSE 'No Change'
    END AS false_count_comparison_previous_year,
      
    CASE
        WHEN prev_year_false_count IS NOT NULL AND total_false_count != 0
            THEN ((total_false_count - prev_year_false_count) / prev_year_false_count) * 100
        ELSE NULL
    END AS percent_false_count_yoy_change,
    
    total_arrest_count as current_year_arrest_count,
    prev_year_arrest_count,
    
    CASE
        WHEN prev_year_arrest_count IS NULL THEN 'No Previous Year Data'
        WHEN total_arrest_count > prev_year_arrest_count THEN 'Increase'
        WHEN total_arrest_count < prev_year_arrest_count THEN 'Decrease'
        ELSE 'No Change'
    END AS arrest_count_comparison_previous_year,
    
     CASE
        WHEN prev_year_arrest_count IS NOT NULL AND total_arrest_count != 0
            THEN ((total_arrest_count - prev_year_arrest_count) / prev_year_arrest_count) * 100
        ELSE NULL
    END AS percent_arrest_count_yoy_change,
    
    total_population_millions as current_year_population_count,
    prev_year_population_millions,
    
     CASE
        WHEN prev_year_population_millions IS NULL THEN 'No Previous Year Data'
        WHEN total_population_millions > prev_year_population_millions THEN 'Increase'
        WHEN total_population_millions < prev_year_population_millions THEN 'Decrease'
        ELSE 'No Change'
    END AS population_count_comparison_previous_year,
    
    CASE
        WHEN prev_year_population_millions IS NOT NULL AND total_population_millions != 0
            THEN ((total_population_millions - prev_year_population_millions) / prev_year_population_millions) * 100
        ELSE NULL
    END AS percent_population_yoy_change

FROM
    CrimeDataWithPreviousYear
ORDER BY
    YEAR ASC, PRIMARY_TYPE ASC, total_false_count DESC, total_arrest_count ASC;


/* 
The SQL script creates a view named 'YoY_Crime_FalseArrest_Population_View' that incorporates a comprehensive
 year-over-year analysis of crime-related statistics, specifically focusing on false counts, arrest counts, and
 population data for different crime types. The script uses a common table expression (CTE) named 'CrimeDataWithPreviousYear'
 to calculate the total false count, arrest count, and population for each crime type in each year, including corresponding 
 values from the previous year using the LAG window function.

The final output of the view includes information such as the crime year, crime type, current year false count, previous
 year false count, year-over-year change in false count (both absolute and percentage), current year arrest count, previous
 year arrest count, year-over-year change in arrest count (both absolute and percentage), current year population count,
 previous year population count, and year-over-year change in population (both absolute and percentage).

Additionally, the view provides a summary of correlation strength based on the direction of changes in arrest count,
 population count, and false count. It categorizes the correlation as 'Strong Positive Correlation' if all three metrics 
 increase or 'Strong Negative Correlation' if all three metrics decrease, otherwise, it indicates 'No strong correlation.'

This view offers valuable insights into the year-over-year trends and relationships among crime-related variables, providing 
a comprehensive analysis for decision-making and understanding correlations in crime statistics.
*/

CREATE VIEW YoY_Crime_FalseArrest_Population_View AS
with yoy_crime_false_arrest_population as 
(

WITH CrimeDataWithPreviousYear AS (
 SELECT
    YEAR(cd.date) AS YEAR,
    cd.primary_type,
    SUM(cd.false_count) AS total_false_count,
    SUM(cd.arrest_count) AS total_arrest_count,
    SUM(cp.`Population - Total`) / 1000000.0 AS total_population_millions,
    LAG(SUM(cd.false_count)) OVER (PARTITION BY cd.primary_type ORDER BY YEAR(cd.date) ASC) AS prev_year_false_count,
    LAG(SUM(cd.arrest_count)) OVER (PARTITION BY cd.primary_type ORDER BY YEAR(cd.date) ASC) AS prev_year_arrest_count,
    LAG(SUM(cp.`Population - Total`) / 1000000.0) OVER (PARTITION BY cd.primary_type ORDER BY YEAR(cd.date) ASC) AS prev_year_population_millions
FROM
    crimedate cd
JOIN
    chicagopopulation cp ON YEAR(cd.date) = cp.Year
WHERE
    YEAR(cd.date) IS NOT NULL AND cp.Year IS NOT NULL 
GROUP BY
    cd.primary_type, YEAR(cd.date)
ORDER BY
    YEAR ASC, PRIMARY_TYPE ASC, SUM(cd.false_count) DESC, SUM(cd.crime_count) ASC
)
SELECT
    YEAR,
    primary_type,
    total_false_count as current_year_false_count,
    prev_year_false_count,
    CASE
        WHEN prev_year_false_count IS NULL THEN 'No Previous Year Data'
        WHEN total_false_count > prev_year_false_count THEN 'Increase'
        WHEN total_false_count < prev_year_false_count THEN 'Decrease'
        ELSE 'No Change'
    END AS false_count_comparison_previous_year,
      
    CASE
        WHEN prev_year_false_count IS NOT NULL AND total_false_count != 0
            THEN ((total_false_count - prev_year_false_count) / prev_year_false_count) * 100
        ELSE NULL
    END AS percent_false_count_yoy_change,
    
    total_arrest_count as current_year_arrest_count,
    prev_year_arrest_count,
    
    CASE
        WHEN prev_year_arrest_count IS NULL THEN 'No Previous Year Data'
        WHEN total_arrest_count > prev_year_arrest_count THEN 'Increase'
        WHEN total_arrest_count < prev_year_arrest_count THEN 'Decrease'
        ELSE 'No Change'
    END AS arrest_count_comparison_previous_year,
    
     CASE
        WHEN prev_year_arrest_count IS NOT NULL AND total_arrest_count != 0
            THEN ((total_arrest_count - prev_year_arrest_count) / prev_year_arrest_count) * 100
        ELSE NULL
    END AS percent_arrest_count_yoy_change,
    
    total_population_millions as current_year_population_count,
    prev_year_population_millions,
    
     CASE
        WHEN prev_year_population_millions IS NULL THEN 'No Previous Year Data'
        WHEN total_population_millions > prev_year_population_millions THEN 'Increase'
        WHEN total_population_millions < prev_year_population_millions THEN 'Decrease'
        ELSE 'No Change'
    END AS population_count_comparison_previous_year,
    
    CASE
        WHEN prev_year_population_millions IS NOT NULL AND total_population_millions != 0
            THEN ((total_population_millions - prev_year_population_millions) / prev_year_population_millions) * 100
        ELSE NULL
    END AS percent_population_yoy_change

FROM
    CrimeDataWithPreviousYear
ORDER BY
    YEAR ASC, PRIMARY_TYPE ASC, total_false_count DESC, total_arrest_count ASC
)
select YEAR, Primary_type,
  current_year_population_count,
 current_year_arrest_count,
 current_year_false_count,
 arrest_count_comparison_previous_year,
 false_count_comparison_previous_year,
 population_count_comparison_previous_year,
  CASE
        WHEN arrest_count_comparison_previous_year = 'Increase' AND population_count_comparison_previous_year = 'Increase' AND false_count_comparison_previous_year = 'Increase' THEN 'Strong Positive Correlation'
        WHEN arrest_count_comparison_previous_year = 'Decrease' AND population_count_comparison_previous_year = 'Decrease' AND false_count_comparison_previous_year = 'Decrease' THEN 'Strong Negative Correlation'
        ELSE 'No strong correlation'
    END AS correlation_strength
 from yoy_crime_false_arrest_population
 order by YEAR asc, PRIMARY_TYPE ASC, current_year_arrest_count ASC, current_year_false_count ASC;

 
/* The SQL code creates a view named 'CrimeFalseArrestCountCorrelationView,' which builds upon the previous analysis of 
year-over-year crime-related statistics, specifically focusing on false counts, arrest counts, and population data. The script
 uses two common table expressions (CTEs): 'yoy_crime_false_arrest_population' and 'crime_false_arrest_count_correlation.'

The 'yoy_crime_false_arrest_population' CTE calculates year-over-year changes and comparisons for false counts, arrest counts,
 and population, similar to the previous view. The 'crime_false_arrest_count_correlation' CTE, in turn, utilizes the results 
 from 'yoy_crime_false_arrest_population' to analyze correlations between crime-related variables. It categorizes the 
 correlation strength as 'Strong Positive Correlation,' 'Strong Negative Correlation,' or 'No strong correlation' based on
 the direction of changes in arrest count, population count, and false count.

The final output of the 'CrimeFalseArrestCountCorrelationView' provides a summary of the correlation strength for each crime
 type, counting occurrences of strong positive, strong negative, and no strong correlation. It further categorizes the overall
 correlation with climate conditions, offering insights into the relationships between crime-related variables and environmental 
 factors.*/

CREATE VIEW CrimeFalseArrestCountCorrelationView AS
with crime_false_arrest_count_correlation as 
(

with yoy_crime_false_arrest_population as 
(

WITH CrimeDataWithPreviousYear AS (
 SELECT
    YEAR(cd.date) AS YEAR,
    cd.primary_type,
    SUM(cd.false_count) AS total_false_count,
    SUM(cd.arrest_count) AS total_arrest_count,
    SUM(cp.`Population - Total`) / 1000000.0 AS total_population_millions,
    LAG(SUM(cd.false_count)) OVER (PARTITION BY cd.primary_type ORDER BY YEAR(cd.date) ASC) AS prev_year_false_count,
    LAG(SUM(cd.arrest_count)) OVER (PARTITION BY cd.primary_type ORDER BY YEAR(cd.date) ASC) AS prev_year_arrest_count,
    LAG(SUM(cp.`Population - Total`) / 1000000.0) OVER (PARTITION BY cd.primary_type ORDER BY YEAR(cd.date) ASC) AS prev_year_population_millions
FROM
    crimedate cd
JOIN
    chicagopopulation cp ON YEAR(cd.date) = cp.Year
WHERE
    YEAR(cd.date) IS NOT NULL AND cp.Year IS NOT NULL 
GROUP BY
    cd.primary_type, YEAR(cd.date)
ORDER BY
    YEAR ASC, PRIMARY_TYPE ASC, SUM(cd.false_count) DESC, SUM(cd.crime_count) ASC
)
SELECT
    YEAR,
    primary_type,
    total_false_count as current_year_false_count,
    prev_year_false_count,
    CASE
        WHEN prev_year_false_count IS NULL THEN 'No Previous Year Data'
        WHEN total_false_count > prev_year_false_count THEN 'Increase'
        WHEN total_false_count < prev_year_false_count THEN 'Decrease'
        ELSE 'No Change'
    END AS false_count_comparison_previous_year,
      
    CASE
        WHEN prev_year_false_count IS NOT NULL AND total_false_count != 0
            THEN ((total_false_count - prev_year_false_count) / prev_year_false_count) * 100
        ELSE NULL
    END AS percent_false_count_yoy_change,
    
    total_arrest_count as current_year_arrest_count,
    prev_year_arrest_count,
    
    CASE
        WHEN prev_year_arrest_count IS NULL THEN 'No Previous Year Data'
        WHEN total_arrest_count > prev_year_arrest_count THEN 'Increase'
        WHEN total_arrest_count < prev_year_arrest_count THEN 'Decrease'
        ELSE 'No Change'
    END AS arrest_count_comparison_previous_year,
    
     CASE
        WHEN prev_year_arrest_count IS NOT NULL AND total_arrest_count != 0
            THEN ((total_arrest_count - prev_year_arrest_count) / prev_year_arrest_count) * 100
        ELSE NULL
    END AS percent_arrest_count_yoy_change,
    
    total_population_millions as current_year_population_count,
    prev_year_population_millions,
    
     CASE
        WHEN prev_year_population_millions IS NULL THEN 'No Previous Year Data'
        WHEN total_population_millions > prev_year_population_millions THEN 'Increase'
        WHEN total_population_millions < prev_year_population_millions THEN 'Decrease'
        ELSE 'No Change'
    END AS population_count_comparison_previous_year,
    
    CASE
        WHEN prev_year_population_millions IS NOT NULL AND total_population_millions != 0
            THEN ((total_population_millions - prev_year_population_millions) / prev_year_population_millions) * 100
        ELSE NULL
    END AS percent_population_yoy_change

FROM
    CrimeDataWithPreviousYear
ORDER BY
    YEAR ASC, PRIMARY_TYPE ASC, total_false_count DESC, total_arrest_count ASC
)
select YEAR, Primary_type,
  current_year_population_count,
 current_year_arrest_count,
 current_year_false_count,
 arrest_count_comparison_previous_year,
 false_count_comparison_previous_year,
 population_count_comparison_previous_year,
  CASE
        WHEN arrest_count_comparison_previous_year = 'Increase' AND population_count_comparison_previous_year = 'Increase' AND false_count_comparison_previous_year = 'Increase' THEN 'Strong Positive Correlation'
        WHEN arrest_count_comparison_previous_year = 'Decrease' AND population_count_comparison_previous_year = 'Decrease' AND false_count_comparison_previous_year = 'Decrease' THEN 'Strong Negative Correlation'
        ELSE 'No strong correlation'
    END AS correlation_strength
 from yoy_crime_false_arrest_population
 order by YEAR asc, PRIMARY_TYPE ASC, current_year_arrest_count ASC, current_year_false_count ASC
 )
 SELECT
    primary_type,
    COUNT(CASE WHEN correlation_strength = 'No Strong correlation' THEN 1 END) AS 'No Strong correlation',
    COUNT(CASE WHEN correlation_strength = 'Strong Positive Correlation' THEN 1 END) AS 'Strong positive correlation',
    COUNT(CASE WHEN correlation_strength = 'Strong Negative Correlation' THEN 1 END) AS 'Strong negative correlation',
    CASE
        WHEN COUNT(CASE WHEN correlation_strength = 'No Strong correlation' THEN 1 END) > COUNT(CASE WHEN correlation_strength = 'Strong Positive Correlation' THEN 1 END)
            AND COUNT(CASE WHEN correlation_strength = 'No Strong correlation' THEN 1 END) > COUNT(CASE WHEN correlation_strength = 'Strong Negative Correlation' THEN 1 END) THEN 'Not strongly correlated with population'
        WHEN COUNT(CASE WHEN correlation_strength = 'Strong Positive Correlation' THEN 1 END) > COUNT(CASE WHEN correlation_strength = 'No Strong correlation' THEN 1 END)
            AND COUNT(CASE WHEN correlation_strength = 'Strong Positive Correlation' THEN 1 END) > COUNT(CASE WHEN correlation_strength = 'Strong Negative Correlation' THEN 1 END) THEN 'Strongly positively correlated with population'
        WHEN COUNT(CASE WHEN correlation_strength = 'Strong Negative Correlation' THEN 1 END) > COUNT(CASE WHEN correlation_strength = 'No Strong correlation' THEN 1 END)
            AND COUNT(CASE WHEN correlation_strength = 'Strong Negative Correlation' THEN 1 END) > COUNT(CASE WHEN correlation_strength = 'Strong Positive Correlation' THEN 1 END) THEN 'Strongly Negatively correlated with population'
        WHEN COUNT(CASE WHEN correlation_strength = 'No Strong correlation' THEN 1 END) = COUNT(CASE WHEN correlation_strength = 'Strong Positive Correlation' THEN 1 END) THEN 'May or May not be strongly correlated with population'
        WHEN COUNT(CASE WHEN correlation_strength = 'No Strong correlation' THEN 1 END) = COUNT(CASE WHEN correlation_strength = 'Strong Negative Correlation' THEN 1 END) THEN 'May or May not be negatively correlated with population'
        WHEN COUNT(CASE WHEN correlation_strength = 'No Strong correlation' THEN 1 END) = COUNT(CASE WHEN correlation_strength = 'Strong Negative Correlation' THEN 1 END)
            AND COUNT(CASE WHEN correlation_strength = 'No Strong correlation' THEN 1 END) = COUNT(CASE WHEN correlation_strength = 'Strong Positive Correlation' THEN 1 END) THEN 'No correlation with population'
        ELSE 'Unknown'
    END AS 'Correlation with climate conditions'
FROM
    crime_false_arrest_count_correlation 
GROUP BY
    primary_type
ORDER BY
    primary_type;

-- ===========================================================================================================================
-- Usecase: dentify areas with a high concentration of crimes, enabling law enforcement to allocate resources and increase surveillance in these hotspots. 
-- ===========================================================================================================================

-- Crime count by crimetype based on location district

/* 
	The SQL script creates a view named 'CrimeTypeByDistrictView' that summarizes crime data by district and crime type.
    It uses a common table expression (CTE) named 'crime_by_district' to calculate the total crime count for each combination
    of year, district, and crime type. The script then pivots the data to present crime counts for specific crime
    types ('ARSON,' 'ASSAULT,' 'BATTERY,' etc.) as columns.

	The resulting view provides a clear breakdown of crime counts for various crime types within each district and year.
	This structured format allows for easy analysis and comparison of crime trends across different districts over the 
	specified years. The order of the output is based on the year and district.
*/


CREATE VIEW CrimeTypeByDistrictView AS   
With crime_by_district as 
(
SELECT
    cl.year,
    cl.district,
    cl.primary_type,
    SUM(cl.crime_count) AS Total_crime_count,
    ct.row_num
FROM
    crimelocation cl
JOIN (SELECT
    primary_type,
    ROW_NUMBER() OVER (ORDER BY primary_type) AS row_num
FROM
    (SELECT DISTINCT primary_type FROM crimelocation) AS distinct_primary_types) ct
on cl.primary_type = ct.primary_type
group by cl.year,
    cl.district,
    cl.primary_type
ORDER BY
    cl.year, cl.district, cl.primary_type
) 
SELECT year,district,
SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END) AS 'ARSON',
SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END) AS 'ASSAULT',
SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END) AS 'BATTERY',
SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END) AS 'BURGLARY',
SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END) AS 'CONCEALED CARRY LICENSE VIOLATION',
SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END) AS 'CRIMINAL DAMAGE',
SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END) AS 'CRIMINAL SEXUAL ASSAULT',
SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END) AS 'CRIMINAL TRESPASS',
SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END) AS 'DECEPTIVE PRACTICE',
SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END) AS 'DOMESTIC VIOLENCE',
SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END) AS 'GAMBLING',
SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END) AS 'HOMICIDE',
SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END) AS 'HUMAN TRAFFICKING',
SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END) AS 'INTERFERENCE WITH PUBLIC OFFICER',
SUM(CASE WHEN primary_type = 'INTIMIDATION' THEN Total_crime_count ELSE 0 END) AS 'INTIMIDATION',
SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END) AS 'KIDNAPPING',
SUM(CASE WHEN primary_type = 'LIQUOR LAW VIOLATION' THEN Total_crime_count ELSE 0 END) AS 'LIQUOR LAW VIOLATION',
SUM(CASE WHEN primary_type = 'MOTOR VEHICLE THEFT' THEN Total_crime_count ELSE 0 END) AS 'MOTOR VEHICLE THEFT',
SUM(CASE WHEN primary_type = 'NARCOTICS' THEN Total_crime_count ELSE 0 END) AS 'NARCOTICS',
SUM(CASE WHEN primary_type = 'NON-CRIMINAL' THEN Total_crime_count ELSE 0 END) AS 'NON-CRIMINAL',
SUM(CASE WHEN primary_type = 'NON-CRIMINAL (SUBJECT SPECIFIED)' THEN Total_crime_count ELSE 0 END) AS 'NON-CRIMINAL (SUBJECT SPECIFIED)',
SUM(CASE WHEN primary_type = 'OBSCENITY' THEN Total_crime_count ELSE 0 END) AS 'OBSCENITY',
SUM(CASE WHEN primary_type = 'OFFENSE INVOLVING CHILDREN' THEN Total_crime_count ELSE 0 END) AS 'OFFENSE INVOLVING CHILDREN',
SUM(CASE WHEN primary_type = 'OTHER NARCOTIC VIOLATION' THEN Total_crime_count ELSE 0 END) AS 'OTHER NARCOTIC VIOLATION',
SUM(CASE WHEN primary_type = 'OTHER OFFENSE' THEN Total_crime_count ELSE 0 END) AS 'OTHER OFFENSE',
SUM(CASE WHEN primary_type = 'PROSTITUTION' THEN Total_crime_count ELSE 0 END) AS 'PROSTITUTION',
SUM(CASE WHEN primary_type = 'PUBLIC INDECENCY' THEN Total_crime_count ELSE 0 END) AS 'PUBLIC INDECENCY',
SUM(CASE WHEN primary_type = 'PUBLIC PEACE VIOLATION' THEN Total_crime_count ELSE 0 END) AS 'PUBLIC PEACE VIOLATION',
SUM(CASE WHEN primary_type = 'RITUALISM' THEN Total_crime_count ELSE 0 END) AS 'RITUALISM',
SUM(CASE WHEN primary_type = 'ROBBERY' THEN Total_crime_count ELSE 0 END) AS 'ROBBERY',
SUM(CASE WHEN primary_type = 'SEX OFFENSE' THEN Total_crime_count ELSE 0 END) AS 'SEX OFFENSE',
SUM(CASE WHEN primary_type = 'STALKING' THEN Total_crime_count ELSE 0 END) AS 'STALKING',
SUM(CASE WHEN primary_type = 'THEFT' THEN Total_crime_count ELSE 0 END) AS 'THEFT',
SUM(CASE WHEN primary_type = 'WEAPONS VIOLATION' THEN Total_crime_count ELSE 0 END) AS 'WEAPONS VIOLATION'
from crime_by_district
group by year,district
order by year, district;

-- yoy crime counts by crime type with percentage change from previous year and current year and change status( Increase/decease )


/* This SQL script creates a view called CrimeTypeByDistrictYoYView using a common table expression (CTE). The CTE, named
 crime_by_district, calculates various crime statistics for each district and year, focusing on specific crime types like 
 arson, assault, battery, burglary, etc. It computes metrics such as total crime count, lag values, percentage changes, and 
 change status. The script employs the LAG function to compare the current year's crime count with the previous year's. 
 The resulting view provides a comprehensive overview of year-over-year changes in crime types for each district, aiding 
 in the analysis of crime trends over time. The script utilizes conditional statements to handle edge cases, ensuring accurate
 percentage calculations and change status evaluations. */

CREATE VIEW CrimeTypeByDistrictYoYView AS
With crime_by_district as 
(
SELECT
    cl.year,
    cl.district,
    cl.primary_type,
    SUM(cl.crime_count) AS Total_crime_count,
    ct.row_num
FROM
    crimelocation cl
JOIN (SELECT
    primary_type,
    ROW_NUMBER() OVER (ORDER BY primary_type) AS row_num
FROM
    (SELECT DISTINCT primary_type FROM crimelocation) AS distinct_primary_types) ct
on cl.primary_type = ct.primary_type
group by cl.year,
    cl.district,
    cl.primary_type
ORDER BY
    cl.year, cl.district, cl.primary_type
) 
SELECT year,district,
SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END) AS 'ARSON',
LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_ARSON',
CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'ARSON_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'ARSON_CHANGE_STATUS',
    
SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END) AS 'ASSAULT',
LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_ASSAULT',
CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'ASSAULT_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'ASSAULT_CHANGE_STATUS',
    
SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END) AS 'BATTERY',
LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_BATTERY',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'BATTERY_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'BATTERY_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END) AS 'BURGLARY',
LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_BURGLARY',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'BURGLARY_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'BURGLARY_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END) AS 'CONCEALED CARRY LICENSE VIOLATION',
LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_CONCEALED CARRY LICENSE VIOLATION',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'CONCEALED CARRY LICENSE VIOLATION_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'CONCEALED CARRY LICENSE VIOLATION_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END) AS 'CRIMINAL DAMAGE',
LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_CRIMINAL DAMAGE',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'CRIMINAL DAMAGE_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'CRIMINAL DAMAGE_CHANGE_STATUS',


SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END) AS 'CRIMINAL SEXUAL ASSAULT',
LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_CRIMINAL SEXUAL ASSAULT',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'CRIMINAL SEXUAL ASSAULT_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'CRIMINAL SEXUAL ASSAULT_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END) AS 'CRIMINAL TRESPASS',
LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_CRIMINAL TRESPASS',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'CRIMINAL TRESPASS_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'CRIMINAL TRESPASS_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END) AS 'DECEPTIVE PRACTICE',
LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_DECEPTIVE PRACTICE',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'DECEPTIVE PRACTICE_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'DECEPTIVE PRACTICE_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END) AS 'DOMESTIC VIOLENCE',
LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_DOMESTIC VIOLENCE',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'DOMESTIC VIOLENCE_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'DOMESTIC VIOLENCE_CHANGE_STATUS',


SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END) AS 'GAMBLING',
LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_GAMBLING',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'GAMBLING_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'GAMBLING_CHANGE_STATUS',


SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END) AS 'HOMICIDE',
LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_HOMICIDE',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'HOMICIDE_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'HOMICIDE_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END) AS 'HUMAN TRAFFICKING',
LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_HUMAN TRAFFICKING',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'HUMAN TRAFFICKING_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'HUMAN TRAFFICKING_CHANGE_STATUS',


SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END) AS 'INTERFERENCE WITH PUBLIC OFFICER',
LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_INTERFERENCE WITH PUBLIC OFFICER',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'INTERFERENCE WITH PUBLIC OFFICER_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'INTERFERENCE WITH PUBLIC OFFICER_CHANGE_STATUS',
    
    
SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END) AS 'KIDNAPPING',
LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_KIDNAPPING',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'KIDNAPPING_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'KIDNAPPING_CHANGE_STATUS'

from crime_by_district
group by year,district
order by year, district;

-- Yoy crime trends by crime type 

CREATE TABLE IF NOT EXISTS Crime_transposed as
(
WITH AverageTrends AS (
    SELECT
        district,
        AVG(`ARSON_PERCENTAGE_CHANGE`) AS `ARSON_AVG`,
		AVG(`ASSAULT_PERCENTAGE_CHANGE`) AS `ASSAULT_AVG`,
		AVG(`BATTERY_PERCENTAGE_CHANGE`) AS `BATTERY_AVG`,
		AVG(`BURGLARY_PERCENTAGE_CHANGE`) AS `BURGLARY_AVG`,
		AVG(`CONCEALED CARRY LICENSE VIOLATION_PERCENTAGE_CHANGE`) AS `CONCEALED CARRY LICENSE VIOLATION_AVG`,
		AVG(`CRIMINAL DAMAGE_PERCENTAGE_CHANGE`) AS `CRIMINAL DAMAGE_AVG`,
		AVG(`CRIMINAL SEXUAL ASSAULT_PERCENTAGE_CHANGE`) AS `CRIMINAL SEXUAL ASSAULT_AVG`,
		AVG(`CRIMINAL TRESPASS_PERCENTAGE_CHANGE`) AS `CRIMINAL TRESPASS_AVG`,
		AVG(`DECEPTIVE PRACTICE_PERCENTAGE_CHANGE`) AS `DECEPTIVE PRACTICE_AVG`,
		AVG(`DOMESTIC VIOLENCE_PERCENTAGE_CHANGE`) AS `DOMESTIC VIOLENCE_AVG`,
		AVG(`GAMBLING_PERCENTAGE_CHANGE`) AS `GAMBLING_AVG`,
		AVG(`HOMICIDE_PERCENTAGE_CHANGE`) AS  `HOMICIDE_AVG`,
		AVG(`HUMAN TRAFFICKING_PERCENTAGE_CHANGE`) AS `HUMAN TRAFFICKING_AVG`,
		AVG(`INTERFERENCE WITH PUBLIC OFFICER_PERCENTAGE_CHANGE`) AS `INTERFERENCE WITH PUBLIC OFFICER_AVG`,
		AVG(`KIDNAPPING_PERCENTAGE_CHANGE`) AS `KIDNAPPING_AVG`
from 
(
select year, district,
`ARSON_PERCENTAGE_CHANGE`,
`ASSAULT_PERCENTAGE_CHANGE`,
`BATTERY_PERCENTAGE_CHANGE`,
`BURGLARY_PERCENTAGE_CHANGE`,
`CONCEALED CARRY LICENSE VIOLATION_PERCENTAGE_CHANGE`,
`CRIMINAL DAMAGE_PERCENTAGE_CHANGE`,
`CRIMINAL SEXUAL ASSAULT_PERCENTAGE_CHANGE`,
`CRIMINAL TRESPASS_PERCENTAGE_CHANGE`,
`DECEPTIVE PRACTICE_PERCENTAGE_CHANGE`,
`DOMESTIC VIOLENCE_PERCENTAGE_CHANGE`,
`GAMBLING_PERCENTAGE_CHANGE`,
`HOMICIDE_PERCENTAGE_CHANGE`,
`HUMAN TRAFFICKING_PERCENTAGE_CHANGE`,
`INTERFERENCE WITH PUBLIC OFFICER_PERCENTAGE_CHANGE`,
`KIDNAPPING_PERCENTAGE_CHANGE`
from (
With crime_by_district as 
(
SELECT
    cl.year,
    cl.district,
    cl.primary_type,
    SUM(cl.crime_count) AS Total_crime_count,
    ct.row_num
FROM
    crimelocation cl
JOIN (SELECT
    primary_type,
    ROW_NUMBER() OVER (ORDER BY primary_type) AS row_num
FROM
    (SELECT DISTINCT primary_type FROM crimelocation) AS distinct_primary_types) ct
on cl.primary_type = ct.primary_type
group by cl.year,
    cl.district,
    cl.primary_type
ORDER BY
    cl.year, cl.district, cl.primary_type
) 
SELECT year,district,
SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END) AS 'ARSON',
LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_ARSON',
CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'ARSON_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'ARSON' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'ARSON_CHANGE_STATUS',
    
SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END) AS 'ASSAULT',
LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_ASSAULT',
CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'ASSAULT_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'ASSAULT_CHANGE_STATUS',
    
SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END) AS 'BATTERY',
LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_BATTERY',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'BATTERY_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'BATTERY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'BATTERY_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END) AS 'BURGLARY',
LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_BURGLARY',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'BURGLARY_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'BURGLARY' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'BURGLARY_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END) AS 'CONCEALED CARRY LICENSE VIOLATION',
LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_CONCEALED CARRY LICENSE VIOLATION',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'CONCEALED CARRY LICENSE VIOLATION_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'CONCEALED CARRY LICENSE VIOLATION' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'CONCEALED CARRY LICENSE VIOLATION_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END) AS 'CRIMINAL DAMAGE',
LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_CRIMINAL DAMAGE',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'CRIMINAL DAMAGE_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'CRIMINAL DAMAGE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'CRIMINAL DAMAGE_CHANGE_STATUS',


SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END) AS 'CRIMINAL SEXUAL ASSAULT',
LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_CRIMINAL SEXUAL ASSAULT',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'CRIMINAL SEXUAL ASSAULT_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'CRIMINAL SEXUAL ASSAULT' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'CRIMINAL SEXUAL ASSAULT_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END) AS 'CRIMINAL TRESPASS',
LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_CRIMINAL TRESPASS',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'CRIMINAL TRESPASS_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'CRIMINAL TRESPASS' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'CRIMINAL TRESPASS_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END) AS 'DECEPTIVE PRACTICE',
LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_DECEPTIVE PRACTICE',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'DECEPTIVE PRACTICE_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'DECEPTIVE PRACTICE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'DECEPTIVE PRACTICE_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END) AS 'DOMESTIC VIOLENCE',
LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_DOMESTIC VIOLENCE',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'DOMESTIC VIOLENCE_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'DOMESTIC VIOLENCE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'DOMESTIC VIOLENCE_CHANGE_STATUS',


SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END) AS 'GAMBLING',
LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_GAMBLING',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'GAMBLING_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'GAMBLING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'GAMBLING_CHANGE_STATUS',


SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END) AS 'HOMICIDE',
LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_HOMICIDE',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'HOMICIDE_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'HOMICIDE' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'HOMICIDE_CHANGE_STATUS',

SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END) AS 'HUMAN TRAFFICKING',
LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_HUMAN TRAFFICKING',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'HUMAN TRAFFICKING_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'HUMAN TRAFFICKING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'HUMAN TRAFFICKING_CHANGE_STATUS',


SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END) AS 'INTERFERENCE WITH PUBLIC OFFICER',
LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_INTERFERENCE WITH PUBLIC OFFICER',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'INTERFERENCE WITH PUBLIC OFFICER_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'INTERFERENCE WITH PUBLIC OFFICER' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'INTERFERENCE WITH PUBLIC OFFICER_CHANGE_STATUS',
    
    
SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END) AS 'KIDNAPPING',
LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) AS 'LAG_KIDNAPPING',

CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) = 0 THEN NULL
        ELSE ((SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END) - LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year)) / NULLIF(LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year), 0)) * 100 
    END AS 'KIDNAPPING_PERCENTAGE_CHANGE',
    CASE 
        WHEN LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) IS NULL THEN NULL
        WHEN SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END) > LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Increased'
        WHEN SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END) < LAG(SUM(CASE WHEN primary_type = 'KIDNAPPING' THEN Total_crime_count ELSE 0 END)) OVER (PARTITION BY district ORDER BY year) THEN 'Decreased'
        ELSE 'No Change'
    END AS 'KIDNAPPING_CHANGE_STATUS'
from crime_by_district
group by year,district
order by year, district
) sub
) main 
group by 
        district
)
select * from AverageTrends
);

-- select * from Crime_transposed;
	
CREATE VIEW PredictedDistrictsByCrimeTypeView AS
WITH crime_types_by_district as 
(
SELECT `ARSON_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`ARSON_AVG` FROM (SELECT "ARSON_AVG" as `ARSON_AVG`, district, ROW_NUMBER() OVER (ORDER BY `ARSON_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`ARSON_AVG`
UNION
SELECT `ASSAULT_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`ASSAULT_AVG` FROM (SELECT "ASSAULT_AVG" as `ASSAULT_AVG`, district, ROW_NUMBER() OVER (ORDER BY `ASSAULT_AVG` DESC) AS row_num  FROM Crime_transposed) sub2a where row_num<=3 ) sub1b GROUP BY sub1b.`ASSAULT_AVG`
UNION
SELECT `BATTERY_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`BATTERY_AVG` FROM (SELECT "BATTERY_AVG" as `BATTERY_AVG`, district, ROW_NUMBER() OVER (ORDER BY `BATTERY_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`BATTERY_AVG`
UNION
SELECT `BURGLARY_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`BURGLARY_AVG` FROM (SELECT "BURGLARY_AVG" as `BURGLARY_AVG`, district, ROW_NUMBER() OVER (ORDER BY `BURGLARY_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`BURGLARY_AVG`
UNION
SELECT `CONCEALED CARRY LICENSE VIOLATION_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`CONCEALED CARRY LICENSE VIOLATION_AVG` FROM (SELECT "CONCEALED CARRY LICENSE VIOLATION_AVG" as `CONCEALED CARRY LICENSE VIOLATION_AVG`, district, ROW_NUMBER() OVER (ORDER BY `CONCEALED CARRY LICENSE VIOLATION_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`CONCEALED CARRY LICENSE VIOLATION_AVG`
UNION
SELECT `CRIMINAL DAMAGE_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`CRIMINAL DAMAGE_AVG` FROM (SELECT "CRIMINAL DAMAGE_AVG" as `CRIMINAL DAMAGE_AVG`, district, ROW_NUMBER() OVER (ORDER BY `CRIMINAL DAMAGE_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`CRIMINAL DAMAGE_AVG`
UNION
SELECT `CRIMINAL SEXUAL ASSAULT_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`CRIMINAL SEXUAL ASSAULT_AVG` FROM (SELECT "CRIMINAL SEXUAL ASSAULT_AVG" as `CRIMINAL SEXUAL ASSAULT_AVG`, district, ROW_NUMBER() OVER (ORDER BY `CRIMINAL SEXUAL ASSAULT_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`CRIMINAL SEXUAL ASSAULT_AVG`
UNION
SELECT `CRIMINAL TRESPASS_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`CRIMINAL TRESPASS_AVG` FROM (SELECT "CRIMINAL TRESPASS_AVG" as `CRIMINAL TRESPASS_AVG`, district, ROW_NUMBER() OVER (ORDER BY `CRIMINAL TRESPASS_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`CRIMINAL TRESPASS_AVG`
UNION
SELECT `DECEPTIVE PRACTICE_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`DECEPTIVE PRACTICE_AVG` FROM (SELECT "DECEPTIVE PRACTICE_AVG" as `DECEPTIVE PRACTICE_AVG`, district, ROW_NUMBER() OVER (ORDER BY `DECEPTIVE PRACTICE_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`DECEPTIVE PRACTICE_AVG`
UNION
SELECT `DOMESTIC VIOLENCE_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`DOMESTIC VIOLENCE_AVG` FROM (SELECT "DOMESTIC VIOLENCE_AVG" as `DOMESTIC VIOLENCE_AVG`, district, ROW_NUMBER() OVER (ORDER BY `DOMESTIC VIOLENCE_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`DOMESTIC VIOLENCE_AVG`
UNION
SELECT `GAMBLING_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`GAMBLING_AVG` FROM (SELECT "GAMBLING_AVG" as `GAMBLING_AVG`, district, ROW_NUMBER() OVER (ORDER BY `GAMBLING_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`GAMBLING_AVG`
UNION
SELECT `HOMICIDE_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`HOMICIDE_AVG` FROM (SELECT "HOMICIDE_AVG" as `HOMICIDE_AVG`, district, ROW_NUMBER() OVER (ORDER BY `HOMICIDE_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`HOMICIDE_AVG`
UNION
SELECT `HUMAN TRAFFICKING_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`HUMAN TRAFFICKING_AVG` FROM (SELECT "HUMAN TRAFFICKING_AVG" as `HUMAN TRAFFICKING_AVG`, district, ROW_NUMBER() OVER (ORDER BY `HUMAN TRAFFICKING_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`HUMAN TRAFFICKING_AVG`
UNION
SELECT `INTERFERENCE WITH PUBLIC OFFICER_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`INTERFERENCE WITH PUBLIC OFFICER_AVG` FROM (SELECT "INTERFERENCE WITH PUBLIC OFFICER_AVG" as `INTERFERENCE WITH PUBLIC OFFICER_AVG`, district, ROW_NUMBER() OVER (ORDER BY `INTERFERENCE WITH PUBLIC OFFICER_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`INTERFERENCE WITH PUBLIC OFFICER_AVG`
UNION
SELECT `KIDNAPPING_AVG` as Crime_type, group_concat(district) as Highly_predictive_crime_districts FROM ( SELECT district,`KIDNAPPING_AVG` FROM (SELECT "KIDNAPPING_AVG" as `KIDNAPPING_AVG`, district, ROW_NUMBER() OVER (ORDER BY `KIDNAPPING_AVG` DESC) AS row_num  FROM Crime_transposed) sub1a where row_num<=3 ) sub1b GROUP BY sub1b.`KIDNAPPING_AVG`
)
select * from crime_types_by_district;


-- ===========================================================================================================================
-- Usecase: How can we assess sex offender patterns to unveil the demographics of both male and female offenders, while simultaneously determining the number of minor victims involved in these crimes?  
-- ===========================================================================================================================
/*To analyze the Sex Offenders Patterns */


/*This query creates a view named SexOffenderCounts to aggregate and count the number of crimes committed by individuals based 
on their race and gender. The COUNT column represents the total count of crimes for each unique combination of race and gender. 
The results are ordered by race, with the count displayed in descending order, providing insights into the distribution of criminal 
activities across different demographic categories.*/

#To Find out which race committed more crimes (Both MALE AND Female Count) 
CREATE VIEW SexOffenderCounts AS
SELECT
    RACE,
    GENDER,
    COUNT(*) AS COUNT
FROM
    sexoffenders
GROUP BY
    RACE, GENDER
ORDER BY
    RACE, COUNT DESC, GENDER;


/* 
This query constructs a view named SexOffenderVictimCounts to analyze the number of minor and major victims involved 
in crimes based on the offenders' race and gender. The query utilizes conditional aggregation to calculate the counts 
separately for minor and major victims. The resulting view offers a comprehensive breakdown of victim counts, facilitating 
a detailed examination of the impact of crimes across different demographic groups. The results are ordered by race 
and gender for clarity in understanding the distribution of victimization within each category.
*/

#To Find out number of Minor VICTIMS involved

CREATE VIEW SexOffenderVictimCounts AS
SELECT
    RACE,
    GENDER,
    SUM(CASE WHEN `VICTIM MINOR` = 'Y' THEN 1 ELSE 0 END) AS MINOR_COUNT,
    SUM(CASE WHEN `VICTIM MINOR` = 'N' THEN 1 ELSE 0 END) AS MAJOR_COUNT
FROM
    sexoffenders
GROUP BY
    RACE, GENDER
ORDER BY
    RACE, GENDER;

-- ===========================================================================================================================
-- Usecase: * How can we leverage offenders data to gain insights such as age demographics to criminal activities
-- ===========================================================================================================================

/*
This SQL query is designed to derive insights into the age demographics of sex offenders and the corresponding counts of victims,
 distinguishing between minor and non-minor victims. The query achieves the following:

Age Group Calculation:
Utilizes the BIRTH DATE field to determine the age of each sex offender.
Divides the calculated age by 10, rounds down to the nearest multiple of 10, creating distinct age groups.

Victim Count Aggregation:
Considers the VICTIM MINOR field to categorize whether the victim is a minor or not.
Counts the number of occurrences for each combination of age group and victim minor status.

Result Presentation:
Presents the data in a structured manner, with columns for age group, victim minor status, and the count of victims.

Ordering:
Orders the result set by age group, providing a clear view of how victim counts are distributed across different age brackets.
In essence, this query enables the exploration of sex offender data by grouping individuals into age categories and discerning 
the impact of their actions on minor and non-minor victims. The resulting information is valuable for law enforcement and policymakers,
allowing them to understand the demographic patterns of offenses and tailor prevention strategies accordingly.
*/

CREATE VIEW sexoffender_age_victim_counts as 
SELECT 
    FLOOR(DATEDIFF(CURDATE(), STR_TO_DATE(`BIRTH DATE`, '%Y-%m-%d'))/365 / 10) * 10 AS AgeGroup, `VICTIM MINOR`, 
    COUNT(*) AS VictimCount 
FROM 
    sexoffenders 
GROUP BY 
    AgeGroup,`VICTIM MINOR` 
ORDER BY 
    AgeGroup; 
    
-- ===========================================================================================================================
-- Usecase: Identify and analyze the top three primary types of crimes for each week of the year, considering various districts?
-- ===========================================================================================================================

/*
This complex SQL query is designed to analyze crime data and uncover patterns in criminal activities occurring on different days 
of the week across various districts. The query starts by grouping crime incidents based on the day of the week and the primary
 crime type, calculating the count of occurrences. The innermost subquery utilizes advanced window functions, specifically the 
 ROW_NUMBER() function, to rank the primary crime types within each day, considering the count of occurrences. The middle subquery
 then filters out only the top three ranked crime types for each day, creating a subset of the most prevalent crimes.

Moving outward, the next subquery, named TopCrimes, joins this subset with information about crime locations using the primary 
crime type. The final result set, obtained by grouping the data by day of the week, primary crime type, and district, provides 
a detailed breakdown of the top three crimes for each day in each district. The results are ordered to highlight the districts 
and days where these crimes are most prominent. In essence, this query offers a comprehensive view of crime trends, aiding law
 enforcement in strategic planning, resource allocation, and targeted interventions based on the day of the week and specific 
 geographic locations.
 
*/

CREATE VIEW  crime_patterns_day_of_week AS
SELECT
    DayOfWeek, 
    TopCrimes.primary_type, 
    cl.district,
    COUNT(*) AS Crime_Count 
FROM (
    SELECT  
        primary_type, 
        DayOfWeek 
    FROM ( 
        SELECT 
            DAYNAME(cd.date) AS DayOfWeek, 
            cd.primary_type, 
            COUNT(*) AS Crime_Count, 
            ROW_NUMBER() OVER (PARTITION BY DAYNAME(cd.date) ORDER BY COUNT(*) DESC) as rnk 
        FROM crimedate cd 
        INNER JOIN arrests a ON cd.date = STR_TO_DATE(a.`ARREST DATE`, '%Y-%m-%d %H:%i:%s') 
        GROUP BY DAYNAME(cd.date), cd.primary_type 
    ) AS RankedCrimes 
    WHERE rnk <= 3 
) AS TopCrimes 
INNER JOIN crimelocation cl ON TopCrimes.primary_type = cl.primary_type 
GROUP BY DayOfWeek, TopCrimes.primary_type, cl.district 
ORDER BY DayOfWeek, Crime_Count DESC, TopCrimes.primary_type; 
 
 
/* 
This intricate SQL query is constructed to delve into crime data and reveal significant patterns in criminal activities
 over weeks of the year, considering various districts. The query first groups crime incidents based on the primary crime
 type and the week of the year, calculating the count of occurrences. Employing advanced window functions such as ROW_NUMBER(),
 the innermost subquery ranks the primary crime types within each week, factoring in the count of occurrences. The subsequent
 subquery filters out only the top three ranked crime types for each week, creating a refined subset of the most prevalent crimes.

Moving outward, the next subquery, named TopCrimes, joins this subset with information about crime locations using the primary 
crime type. The final result set, obtained by grouping the data by week of the year, primary crime type, and district, provides
 a detailed breakdown of the top three crimes for each week in each district. The results are ordered to highlight the districts
 and weeks where these crimes are most prominent. In essence, this query offers a comprehensive view of crime trends over the 
 course of the year, aiding law enforcement in strategic planning, resource allocation, and targeted interventions based on
 specific weeks and geographic locations. 
*/


CREATE VIEW  crime_patterns_week_of_year AS
SELECT  
    WeekOfYear, 
    TopCrimes.primary_type, 
    cl.district, 
    COUNT(*) AS Crime_Count 
FROM ( 
    SELECT  
        primary_type, 
        WeekOfYear 
    FROM ( 
        SELECT 
            WEEK(cd.date) AS WeekOfYear, 
            cd.primary_type, 
            COUNT(*) AS Crime_Count, 
            ROW_NUMBER() OVER (PARTITION BY WEEK(cd.date) ORDER BY COUNT(*) DESC) as rnk 
        FROM crimedate cd 
        INNER JOIN arrests a ON cd.date = STR_TO_DATE(a.`ARREST DATE`, '%Y-%m-%d %H:%i:%s') 
        GROUP BY WEEK(cd.date), cd.primary_type 
    ) AS RankedCrimes 
    WHERE rnk <= 3 
) AS TopCrimes 
INNER JOIN crimelocation cl ON TopCrimes.primary_type = cl.primary_type 
GROUP BY WeekOfYear, TopCrimes.primary_type, cl.district 
ORDER BY WeekOfYear, TopCrimes.primary_type, Crime_Count DESC;