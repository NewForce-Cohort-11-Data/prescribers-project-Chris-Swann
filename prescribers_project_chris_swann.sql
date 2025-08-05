--Due 8/5/25
--GROUPING SETS exercise starts at row 354
--BONUS exercise starts at row ~600

--1 a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
--   total_claim_count from prescription table ; npi from prescriber table ; joined on npi
--  ANSWER: 1881634483 ; 99707  

SELECT
	npi,
	SUM(total_claim_count) AS total_claims
FROM
	prescription
GROUP BY
	npi
ORDER BY
	total_claims DESC
LIMIT
	1;


--  b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
--     ANSWER: Bruce Pendley , Family Practice , 99707

SELECT
	npi,
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM
	prescriber p
INNER JOIN
	prescription pr USING (npi)
GROUP BY
	npi,
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	specialty_description
ORDER BY
	total_claims DESC
LIMIT
	1;

--2 a. Which specialty had the most total number of claims (totaled over all drugs)?
--  ANSWER: Family Practice ; 9752347

SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM 
	prescription
INNER JOIN
	prescriber ON prescriber.npi = prescription.npi
GROUP BY
	specialty_description
ORDER BY
	total_claims DESC
LIMIT 
	1;

--  b. Which specialty had the most total number of claims for opioids?
--    ANSWER: NP ; 900845

SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM 
	prescription
INNER JOIN
	prescriber USING (npi)
INNER JOIN
	drug USING (drug_name)
WHERE 
	opioid_drug_flag = 'Y'
GROUP BY
	specialty_description
ORDER BY
	total_claims DESC
LIMIT 
	1;


--  c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
--  Left join keeps all prescribers, even if they have no matching prescriptions ; INNER JOIN would not return any values

SELECT 
    p.specialty_description,
    SUM(pr.total_claim_count) AS total_claims
FROM 
	prescriber p
LEFT JOIN 
	prescription pr USING (npi)
GROUP BY 
	p.specialty_description
HAVING 
	SUM(pr.total_claim_count) = 0
	OR SUM(pr.total_claim_count) IS NULL;

--Use COALESCE to replace NULL with 0

SELECT 
    p.specialty_description,
    COALESCE(SUM(pr.total_claim_count), 0) AS total_claims
FROM 
	prescriber p
LEFT JOIN 
	prescription pr USING (npi)
GROUP BY 
	p.specialty_description
HAVING 
	COALESCE(SUM(pr.total_claim_count), 0) = 0;


--  d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. 
--     Which specialties have a high percentage of opioids?

SELECT
	pb.specialty_description,
	ROUND(SUM(CASE WHEN d.opioid_drug_flag = 'Y' THEN p.total_claim_count ELSE 0 END)::numeric /
	SUM(p.total_claim_count)::numeric * 100, 2) AS percent_opioid_claims
FROM
	prescriber pb
INNER JOIN
	prescription p ON p.npi = pb.npi
INNER JOIN
	drug d ON d.drug_name = p.drug_name
GROUP BY
	pb.specialty_description
ORDER BY
	percent_opioid_claims DESC;
	
--3 a. Which drug (generic_name) had the highest total drug cost?
--  ANSWER: INSULIN GLARGINE,HUM.REC.ANLOG ; 104264066.35

SELECT
	generic_name,
	SUM(total_drug_cost) AS highest_total_cost
FROM
	drug
INNER JOIN
	prescription ON prescription.drug_name = drug.drug_name
GROUP BY
	generic_name
ORDER BY
	highest_total_cost DESC
LIMIT 
	1;

--  b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
--   ANSWER: C1 ESTERASE INHIBITOR ; 3495.22

SELECT
	generic_name,
	ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2) AS cost_per_day
FROM
	drug
INNER JOIN
	prescription ON prescription.drug_name = drug.drug_name
GROUP BY
	generic_name
ORDER BY
	cost_per_day DESC
LIMIT 
	1;
	

--4 a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 
-- says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT
	drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' 
	END AS drug_type
FROM
	drug
ORDER BY
	drug_type;

--  b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' 
	END AS drug_type,
	SUM(total_drug_cost::money) AS total_cost
FROM
	drug
INNER JOIN
	prescription
	ON drug.drug_name = prescription.drug_name
WHERE 
	opioid_drug_flag = 'Y' OR antibiotic_drug_flag = 'Y'
GROUP BY
	drug_type
ORDER BY
	total_cost DESC;

--5  a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT 
	COUNT(DISTINCT cbsa)
FROM 
	cbsa
WHERE
	cbsaname LIKE '%TN%';


--  b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
--     ANSWER: "Nashville-Davidson--Murfreesboro--Franklin, TN"  ;  1830410
--			   "Morristown, TN"  ;  116352
--  **Note that there are many nulls

SELECT
	cbsaname,
	SUM(population) AS total_population
FROM
	cbsa c
INNER JOIN
	population p ON p.fipscounty = c.fipscounty
GROUP BY
	cbsaname
ORDER BY 
	total_population DESC
LIMIT 
	1;
--
SELECT
	cbsaname,
	SUM(population) AS total_population
FROM
	cbsa c
INNER JOIN
	population p ON p.fipscounty = c.fipscounty
GROUP BY
	cbsaname
ORDER BY 
	total_population ASC
LIMIT 
	1;
	
--  c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
--     ANSWER: SEVIER  ;  95523

SELECT
    fc.county,
    p.population
FROM
    population p
LEFT JOIN
    cbsa c ON p.fipscounty = c.fipscounty
JOIN
    fips_county fc ON p.fipscounty = fc.fipscounty
WHERE
    c.cbsaname IS NULL
ORDER BY
    p.population DESC
LIMIT 
	1;

--6 a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT
	drug_name,
	total_claim_count
FROM
	prescription
WHERE 
	total_claim_count >= 3000;



--  b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT
	drug.drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'True'
		ELSE 'False' 
	END AS opioid_drug_flag,
	total_claim_count
FROM
	prescription
INNER JOIN
	drug ON drug.drug_name = prescription.drug_name
WHERE 
	total_claim_count >= 3000;
	

--  c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT
	drug.drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'True'
		ELSE 'False' 
	END AS opioid_drug_flag,
	total_claim_count, 
	nppes_provider_first_name,
	nppes_provider_last_org_name
FROM
	prescription
INNER JOIN
	drug ON drug.drug_name = prescription.drug_name
INNER JOIN
	prescriber ON prescriber.npi = prescription.npi
WHERE 
	total_claim_count >= 3000;

--7 The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. 
--  Hint: The results from all 3 parts will have 637 rows.

--  a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the 
--     city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. 
--     You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.


SELECT 
	npi,
	drug_name
FROM
	prescriber
CROSS JOIN
	drug
WHERE 
	specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';


--  b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
--     You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT 
	pb.npi,
	d.drug_name,
	p.total_claim_count
FROM
	prescriber pb
INNER JOIN
	drug d ON d.opioid_drug_flag = 'Y'
LEFT JOIN
	prescription p ON pb.npi = p.npi 
	AND p.drug_name = d.drug_name
WHERE 
	pb.specialty_description = 'Pain Management'
	AND pb.nppes_provider_city = 'NASHVILLE'
ORDER BY
	pb.npi, d.drug_name;
	
--  c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT 
	pb.npi,
	d.drug_name,
	COALESCE(p.total_claim_count, 0) AS total_claim_count
FROM
	prescriber pb
INNER JOIN
	drug d ON d.opioid_drug_flag = 'Y'
LEFT JOIN
	prescription p ON pb.npi = p.npi 
	AND p.drug_name = d.drug_name
WHERE 
	pb.specialty_description = 'Pain Management'
	AND pb.nppes_provider_city = 'NASHVILLE'
ORDER BY
	total_claim_count DESC;




-- In this set of exercises you are going to explore additional ways to group and organize the output of a query when using postgres. 

-- For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management Specialists compared to those from Pain Managment specialists.

-- 1. Write a query which returns the total number of claims for these two groups. Your output should look like this: 

-- specialty_description         |total_claims|
-- ------------------------------|------------|
-- Interventional Pain Management|       55906|
-- Pain Management               |       70853|

SELECT
	specialty_description,
	SUM(total_claim_count)
FROM
	prescriber
INNER JOIN
	prescription USING (npi)
WHERE
	specialty_description = 'Interventional Pain Management'
	OR specialty_description = 'Pain Management'
GROUP BY
	specialty_description;


-- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:

-- specialty_description         |total_claims|
-- ------------------------------|------------|
--                               |      126759|
-- Interventional Pain Management|       55906|
-- Pain Management               |       70853|


(SELECT
--'' creates a blank row
	'' AS specialty_description,
	SUM(total_claim_count) AS total_claims
FROM
	prescriber
INNER JOIN 
	prescription USING (npi)
WHERE
	specialty_description IN ('Interventional Pain Management', 'Pain Management'))
UNION
(SELECT
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM
	prescriber
INNER JOIN 
	prescription USING (npi)
WHERE
	specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY
	specialty_description);
	

-- 3. Now, instead of using UNION, make use of GROUPING SETS (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output.

SELECT
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM
	prescriber
INNER JOIN 
	prescription USING (npi)
WHERE
	specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY
--aggregate function can't be in group by/grouping sets. only need the one column in this case, () means all rows are aggregated down to a single group
	GROUPING SETS ((specialty_description),());

-- 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. 
--    Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:

SELECT
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM
	prescriber
INNER JOIN
	prescription USING (npi)
INNER JOIN
	drug USING (drug_name)
WHERE
	specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY
	GROUPING SETS ((opioid_drug_flag), (specialty_description),());
	
	
-- specialty_description         |opioid_drug_flag|total_claims|
-- ------------------------------|----------------|------------|
--                               |                |      129726|
--                               |Y               |       76143|
--                               |N               |       53583|
-- Pain Management               |                |       72487|
-- Interventional Pain Management|                |       57239|

-- 5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the output from the previous query?

SELECT
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM
	prescriber
INNER JOIN 
	prescription USING (npi)
INNER JOIN
	drug USING (drug_name)
WHERE
	specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY
	ROLLUP (opioid_drug_flag, specialty_description);
	

-- 6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result?

SELECT
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM
	prescriber
INNER JOIN 
	prescription USING (npi)
INNER JOIN
	drug USING (drug_name)
WHERE
	specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY
	ROLLUP (specialty_description, opioid_drug_flag);
	

-- 7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?

SELECT
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM
	prescriber
INNER JOIN 
	prescription USING (npi)
INNER JOIN
	drug USING (drug_name)
WHERE
	specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY
	CUBE (specialty_description, opioid_drug_flag);

-- 8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), 
--the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. 
--For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. 
--For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

-- The end result of this question should be a table formatted like this:

-- city       |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-- -----------|-------|--------|-----------|--------|---------|-----------|
-- CHATTANOOGA|   1323|    3689|      68315|   12126|    49519|       1317|
-- KNOXVILLE  |   2744|    4811|      78529|   20946|    84730|       9186|
-- MEMPHIS    |   4697|    3666|      68036|    4898|    38295|        189|
-- NASHVILLE  |   2043|    6119|      88669|   13572|    62859|       1261|


-- For this question, you should look into use the crosstab function, which is part of the tablefunc extension (https://www.postgresql.org/docs/9.5/tablefunc.html). In order to use this function, you must (one time per database) run the command
-- 	CREATE EXTENSION tablefunc;

-- Hint #1: First write a query which will label each drug in the drug table using the six categories listed above.
-- Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column, one category column, and one value column. So in this case, you need to have a city column, a drug label column, and a total claim count column.
-- Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes. If the query that you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.

CREATE EXTENSION tablefunc;

--Initial query 
SELECT
  pb.nppes_provider_city AS city,
  CASE
    WHEN d.generic_name ILIKE '%codeine%' THEN 'codeine'
    WHEN d.generic_name ILIKE '%fentanyl%' THEN 'fentanyl'
    WHEN d.generic_name ILIKE '%hydrocodone%' THEN 'hydrocodone'
    WHEN d.generic_name ILIKE '%morphine%' THEN 'morphine'
    WHEN d.generic_name ILIKE '%oxycodone%' THEN 'oxycodone'
    WHEN d.generic_name ILIKE '%oxymorphone%' THEN 'oxymorphone'
    ELSE NULL
  END AS category,
  SUM(p.total_claim_count) AS total_claims
FROM
  prescription p
  JOIN prescriber pb ON p.npi = pb.npi
  JOIN drug d ON p.drug_name = d.drug_name
WHERE
  pb.nppes_provider_city IN ('CHATTANOOGA', 'KNOXVILLE', 'MEMPHIS', 'NASHVILLE')
  AND d.opioid_drug_flag = 'Y'
GROUP BY
  pb.nppes_provider_city, category
ORDER BY
  pb.nppes_provider_city, category;


--Initial query placed in crosstab
SELECT *
FROM crosstab(
  'SELECT
     pb.nppes_provider_city AS city,
     CASE
       WHEN d.generic_name ILIKE ''%codeine%'' THEN ''codeine''
       WHEN d.generic_name ILIKE ''%fentanyl%'' THEN ''fentanyl''
       WHEN d.generic_name ILIKE ''%hydrocodone%'' THEN ''hydrocodone''
       WHEN d.generic_name ILIKE ''%morphine%'' THEN ''morphine''
       WHEN d.generic_name ILIKE ''%oxycodone%'' THEN ''oxycodone''
       WHEN d.generic_name ILIKE ''%oxymorphone%'' THEN ''oxymorphone''
       ELSE NULL
     END AS category,
     SUM(p.total_claim_count) AS total_claims
   FROM
     prescription p
     JOIN prescriber pb ON p.npi = pb.npi
     JOIN drug d ON p.drug_name = d.drug_name
   WHERE
     pb.nppes_provider_city IN (''CHATTANOOGA'', ''KNOXVILLE'', ''MEMPHIS'', ''NASHVILLE'')
     AND d.opioid_drug_flag = ''Y''
   GROUP BY
     pb.nppes_provider_city, category
   ORDER BY
     pb.nppes_provider_city, category',
  'SELECT unnest(ARRAY[''codeine'', ''fentanyl'', ''hydrocodone'', ''morphine'', ''oxycodone'', ''oxymorphone''])'
) AS ct (
  city TEXT,
  codeine INT,
  fentanyl INT,
  hydrocodone INT,
  morphine INT,
  oxycodone INT,
  oxymorphone INT
);



-- BONUS


-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

--COUNT = 0 meaning that every npi from the prescriber table has at least one matching row in the prescription table
SELECT
	COUNT(*)
FROM 
	prescriber pr 
LEFT JOIN
	prescription ps ON ps.npi = pr.npi
WHERE
	pr.npi IS NULL;

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT
	generic_name,
	SUM(total_claim_count) AS total_claim
FROM
	prescriber pb
INNER JOIN
	prescription p ON pb.npi = p.npi
INNER JOIN
	drug d ON d.drug_name = p.drug_name
WHERE 
	specialty_description = 'Family Practice'
GROUP BY	
	generic_name
ORDER BY
	total_claim DESC
LIMIT
	5;
	

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.


SELECT
	generic_name,
	SUM(total_claim_count) AS total_claim
FROM
	prescriber pb
INNER JOIN
	prescription p ON pb.npi = p.npi
INNER JOIN
	drug d ON d.drug_name = p.drug_name
WHERE 
	specialty_description = 'Cardiology'
GROUP BY	
	generic_name
ORDER BY
	total_claim DESC
LIMIT
	5;

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

--take sum(total_claim_count) out of select and put in order by to return drug name only
(SELECT
	generic_name
FROM
	prescriber pb
INNER JOIN
	prescription p ON pb.npi = p.npi
INNER JOIN
	drug d ON d.drug_name = p.drug_name
WHERE 
	specialty_description = 'Family Practice'
GROUP BY	
	generic_name
ORDER BY
	SUM(total_claim_count) DESC
LIMIT 
	5)
INTERSECT
(SELECT
	generic_name
FROM
	prescriber pb
INNER JOIN
	prescription p ON pb.npi = p.npi
INNER JOIN
	drug d ON d.drug_name = p.drug_name
WHERE 
	specialty_description = 'Cardiology'
GROUP BY	
	generic_name
ORDER BY
	SUM(total_claim_count) DESC
LIMIT
	5);

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. 
--     Report the npi, the total number of claims, and include a column showing the city.

SELECT
	ps.npi,
	SUM(total_claim_count) AS total_claims,
	nppes_provider_city
FROM
	prescriber ps
INNER JOIN
	prescription p on p.npi = ps.npi
WHERE
	nppes_provider_city = 'NASHVILLE'
GROUP BY
	ps.npi,
	nppes_provider_city
ORDER BY
	total_claims DESC
LIMIT
	5;


--     b. Now, report the same for Memphis.

SELECT
	ps.npi,
	SUM(total_claim_count) AS total_claims,
	nppes_provider_city
FROM
	prescriber ps
INNER JOIN
	prescription p on p.npi = ps.npi
WHERE 
	nppes_provider_city = 'MEMPHIS'
GROUP BY
	ps.npi,
	nppes_provider_city
ORDER BY
	total_claims DESC
LIMIT
	5;
    
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

(SELECT
	ps.npi,
	SUM(total_claim_count) AS total_claims,
	nppes_provider_city
FROM
	prescriber ps
INNER JOIN
	prescription p on p.npi = ps.npi
WHERE 
	nppes_provider_city = 'MEMPHIS'
GROUP BY
	ps.npi,
	nppes_provider_city
ORDER BY
	total_claims DESC
LIMIT
	5)
UNION ALL
(SELECT
	ps.npi,
	SUM(total_claim_count) AS total_claims,
	nppes_provider_city
FROM
	prescriber ps
INNER JOIN
	prescription p on p.npi = ps.npi
WHERE
	nppes_provider_city = 'NASHVILLE'
GROUP BY
	ps.npi,
	nppes_provider_city
ORDER BY
	total_claims DESC
LIMIT
	5)
UNION ALL
(SELECT
	ps.npi,
	SUM(total_claim_count) AS total_claims,
	nppes_provider_city
FROM
	prescriber ps
INNER JOIN
	prescription p on p.npi = ps.npi
WHERE
	nppes_provider_city = 'KNOXVILLE'
GROUP BY
	ps.npi,
	nppes_provider_city
ORDER BY
	total_claims DESC
LIMIT
	5)
UNION ALL
(SELECT
	ps.npi,
	SUM(total_claim_count) AS total_claims,
	nppes_provider_city
FROM
	prescriber ps
INNER JOIN
	prescription p on p.npi = ps.npi
WHERE
	nppes_provider_city = 'CHATTANOOGA'
GROUP BY
	ps.npi,
	nppes_provider_city
ORDER BY
	total_claims DESC
LIMIT
	5)
	
-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT
	county,
	total_od
FROM
	(SELECT
		fc.county,
		SUM(od.overdose_deaths) AS total_od,
		AVG(SUM(od.overdose_deaths)) OVER () AS avg_od
	FROM
		fips_county fc
	INNER JOIN
		overdose_deaths od ON od.fipscounty::integer = fc.fipscounty::integer
	GROUP BY
		fc.county
	)AS county_totals
WHERE 
	total_od > avg_od
ORDER BY
	total_od DESC;


-- 5.
--     a. Write a query that finds the total population of Tennessee.

SELECT
	fc.state,
	SUM(population) AS total_pop_TN
FROM
	fips_county fc
INNER JOIN
	population p USING (fipscounty)
WHERE
	fc.state = 'TN'
GROUP BY
	fc.state;

    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, 
--     its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT
    fc.county,
    SUM(p.population) AS county_pop,
    ROUND(SUM(p.population) * 100.0 / 
            (SELECT 
				SUM(p2.population)
            FROM 
				fips_county fc2
            INNER JOIN 
				population p2 USING (fipscounty)
            WHERE 
				fc2.state = 'TN'),2) AS pct_of_state
FROM
    fips_county fc
INNER JOIN
    population p USING (fipscounty)
WHERE
    fc.state = 'TN'
GROUP BY
    fc.county
ORDER BY
    pct_of_state DESC;