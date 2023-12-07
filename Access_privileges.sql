-- Grant access to test user

GRANT SELECT ON db_design_project.RankedCrimesView TO 'test'@'localhost';
GRANT SELECT ON db_design_project.RankedCrimesView_2001_2005 TO 'test'@'localhost';
GRANT SELECT ON db_design_project.RankedCrimesYoYView TO 'test'@'localhost';
GRANT SELECT ON db_design_project.CrimeTypeByTempView TO 'test'@'localhost';
GRANT SELECT ON db_design_project.CrimeDataWithPreviousYearView TO 'test'@'localhost';
GRANT SELECT ON db_design_project.YoY_Crime_FalseArrest_Population_View TO 'test'@'localhost';
GRANT SELECT ON db_design_project.CrimeFalseArrestCountCorrelationView TO 'test'@'localhost';
GRANT SELECT ON db_design_project.CrimeTypeByDistrictView TO 'test'@'localhost';
GRANT SELECT ON db_design_project.CrimeTypeByDistrictYoYView TO 'test'@'localhost';
GRANT SELECT ON db_design_project.PredictedDistrictsByCrimeTypeView TO 'test'@'localhost';
GRANT SELECT ON db_design_project.RankedCrimesView_2001_2005 TO 'test'@'localhost';
GRANT SELECT ON db_design_project.SexOffenderCounts TO 'test'@'localhost';
GRANT SELECT ON db_design_project.SexOffenderVictimCounts TO 'test'@'localhost';
GRANT SELECT ON db_design_project.sexoffender_age_victim_counts TO 'test'@'localhost';
GRANT SELECT ON db_design_project.crime_patterns_day_of_week TO 'test'@'localhost';
GRANT SELECT ON db_design_project.sexoffender_age_victim_counts TO 'test'@'localhost';

-- revoke access ( we include grant queries since revoke only works followed by GRANT)

GRANT SELECT ON db_design_project.RankedCrimesView TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.RankedCrimesView_2001_2005 TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.RankedCrimesYoYView TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.CrimeTypeByTempView TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.CrimeDataWithPreviousYearView TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.YoY_Crime_FalseArrest_Population_View TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.CrimeFalseArrestCountCorrelationView TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.CrimeTypeByDistrictView TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.CrimeTypeByDistrictYoYView TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.PredictedDistrictsByCrimeTypeView TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.RankedCrimesView_2001_2005 TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.SexOffenderCounts TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.SexOffenderVictimCounts TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.crime_patterns_day_of_week TO 'neptune'@'localhost';
GRANT SELECT ON db_design_project.sexoffender_age_victim_counts TO 'neptune'@'localhost';

REVOKE SELECT ON db_design_project.RankedCrimesView FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.RankedCrimesView_2001_2005 FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.RankedCrimesYoYView FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.CrimeTypeByTempView FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.CrimeDataWithPreviousYearView FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.YoY_Crime_FalseArrest_Population_View FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.CrimeFalseArrestCountCorrelationView FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.CrimeTypeByDistrictView FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.CrimeTypeByDistrictYoYView FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.PredictedDistrictsByCrimeTypeView FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.RankedCrimesView_2001_2005 FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.SexOffenderCounts FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.SexOffenderVictimCounts FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.sexoffender_age_victim_counts FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.crime_patterns_day_of_week FROM 'neptune'@'localhost';
REVOKE SELECT ON db_design_project.sexoffender_age_victim_counts FROM 'neptune'@'localhost';

-- Now 'neptune'@'localhost' will not have any SELECT access previleges to all tables
-- This way we made sure of privacy concerns and ensured access to selected users like test'@'localhost'