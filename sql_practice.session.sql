--Changing data type to DATE
SELECT 
    job_title_short AS title,
    job_location AS location,
    job_posted_date :: DATE AS date
FROM 
    job_postings_fact;


--Change time zones
SELECT 
    job_title_short AS title,
    job_location AS location,
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST' AS date 
FROM 
    job_postings_fact
LIMIT 10;

--Extract month & year from date
SELECT 
    job_title_short AS title,
    job_location AS location,
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST' AS date, 
    EXTRACT(MONTH FROM job_posted_date) AS  date_month,
    EXTRACT(YEAR FROM job_posted_date) AS  date_year
FROM 
    job_postings_fact
LIMIT 10;

--Analysis based on date
SELECT 
    COUNT(job_id),
    EXTRACT(MONTH FROM job_posted_date) AS  date_month
FROM 
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    date_month
ORDER BY 1 DESC;

--Creating seperate tables for each months
--January
CREATE TABLE january_jobs AS
    SELECT *
    FROM   
        job_postings_fact
    WHERE 
        EXTRACT(MONTH FROM job_posted_date) = 1;
-- February
CREATE TABLE february_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 2;

-- March
CREATE TABLE march_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 3;

--Finding Data Analayst jobs number onsite, remote & localy(New York)
SELECT 
    COUNT(job_id) AS number_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM 
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    location_category;    


--Pulling companies names that don't require degree
--Used subquiery to pull information from 2 tables
SELECT  company_id,
        name AS company_name
FROM    
     company_dim
WHERE company_id IN (
SELECT 
    company_id
FROM    
    job_postings_fact
WHERE
     job_no_degree_mention = TRUE
ORDER BY
    company_id
    )

--Find the companies with the most job openings

WITH company_job_count AS (
SELECT
    company_id,
    COUNT(*) AS total_jobs
FROM
    job_postings_fact    
GROUP BY
    company_id             
)
SELECT company_dim.name,
       company_job_count.total_jobs
FROM company_dim
LEFT JOIN company_job_count ON company_job_count.company_id = company_dim.company_id
ORDER BY total_jobs DESC
          
/*
Find the count of the number of remote job postings per skill
 - Display the top 5 skills by their demand in remote jobs
 - Include skill ID, name, and count of postings requiring the skill
*/

WITH remote_job_skills AS (
SELECT 
    skill_id,
    COUNT(*) AS skill_count
FROM 
    skills_job_dim AS skills_to_job
INNER JOIN job_postings_fact AS job_postings   
ON  job_postings.job_id = skills_to_job.job_id
WHERE 
    job_work_from_home = TRUE AND
    job_postings.job_title_short = 'Data Analyst'
GROUP BY 
    skill_id    
)

SELECT 
    skills.skill_id,
    skills as skill_name,
    skill_count
FROM  remote_job_skills
INNER JOIN skills_dim AS skills 
ON skills.skill_id = remote_job_skills.skill_id
ORDER BY 
    skill_count DESC
LIMIT 5

/*
Find job postings from the first quarter that have a salary greater than $70K
    - Combine jon posting tables from the first quarter of 2023 (Jan-Mar)
    - Gets job postings with an average yearly salary > $70K
*/

SELECT 
    quarter_one.job_title_short,
    quarter_one.job_location,
    quarter_one.job_via,
    quarter_one.job_posted_date::DATE
FROM (
    SELECT *
    FROM january_jobs
    UNION ALL
    SELECT *
    FROM february_jobs
    UNION ALL
    SELECT *
    FROM march_jobs
) AS quarter_one
WHERE 
    quarter_one.salary_year_avg > 70000 AND
    quarter_one.job_title_short = 'Data Analyst'
ORDER BY   
    salary_year_avg DESC
