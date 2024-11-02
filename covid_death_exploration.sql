SELECT *
FROM CovidDeath
-- to remove the aggregated continent columns from the data bcz
-- Eg, Asia should be present in Continent and not location column
WHERE continent IS NOT NULL -- run command without this to know the diff.
ORDER BY 3, 4;

SELECT *
FROM CovidVaccination
ORDER BY 3, 4;

SELECT
	Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeath
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths
-- Percentage of people who dies after getting infected
SELECT
	Location, date, total_cases, total_deaths,
	CAST(total_deaths AS Float)/total_cases*100 AS "Death%"
FROM CovidDeath
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths in United States
-- Percentage of people who dies after getting infected in United States
-- Shows the likelihood of dying if you contract covid in your country
-- Name you country in the WHERE clause
SELECT
	Location, date, total_cases, total_deaths,
	CAST(total_deaths AS Float)/total_cases*100 AS "Death%"
FROM CovidDeath
WHERE location LIKE '%state%'
ORDER BY 1,2;

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT
	location, date, population, total_cases,
	CAST(total_cases AS FLOAT)/population*100 AS InfectedPercentage
FROM CovidDeath
WHERE location LIKE '%India%';

-- Looking at countries with Highest Infection compared to Population
SELECT
	location,
	population,
	MAX(total_cases) AS HighestInf_cnt,
	MAX((CAST(total_cases AS FLOAT)/population))*100 AS "Infected%"
FROM CovidDeath
GROUP BY location, Population
ORDER BY "Infected%" DESC;

-- Showing countries with Highest Death Count per Population
SELECT
	location,
	MAX(total_deaths) AS highest_death_cnt
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_cnt DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- maximum total deaths in one day per continent
SELECT
	continent,
	MAX(CAST(total_deaths AS INT)) AS total_deaths
FROM CovidDeath
WHERE continent IS NULL
GROUP BY continent
ORDER BY total_deaths desc;

-- total deaths per continent
SELECT
	continent,
	SUM(CAST(total_deaths AS INT)) AS total_deaths
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_deaths desc;

-- GLOBAL NUMBERS
SELECT
	date,
	SUM(total_cases) AS total_cases,
	SUM(total_deaths) AS total_deaths,
	SUM(CAST(total_cases AS FLOAT))/SUM(total_deaths) AS perc_death 
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

SELECT
	date,
	SUM(new_cases) AS new_cases,
	SUM(new_deaths) AS new_deaths,
	SUM(CAST(new_deaths AS FLOAT))/SUM(new_cases)*100 AS perc_death 
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;


-- Joining CovidDeath and CovidVaccination Tables.
SELECT *
FROM CovidDeath d
INNER JOIN CovidVaccination v
	ON d.location=v.location
	AND d.date=v.date;

-- Looking at Total Population vs Vaccinations
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CONVERT(int,v.new_vaccinations))
	OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_sum_new_vac
	-- ,(rolling_sum_new_vac/population)*100
-- [this will give error bcz aggregated functions cannot be used in SELECT clause]
FROM CovidDeath d
INNER JOIN CovidVaccination v
	ON d.location=v.location
	AND d.date=v.date
WHERE d.continent IS NOT NULL 
ORDER BY 2,3;

-- 1. USING CTE TO GET "Rolling_%_Vaccinated"
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	----SUM(CONVERT(int,v.new_vaccinations))
	OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_sum_new_vac
	-- ,(rolling_sum_new_vac/population)*100
-- [this will give error bcz aggregated functions cannot be used in SELECT clause]
FROM CovidDeath d
INNER JOIN CovidVaccination v
	ON d.location=v.location
	AND d.date=v.date
WHERE d.continent IS NOT NULL 
-- ORDER BY 2,3; it cannot be used inside WITH clause
)

SELECT *,
	(CONVERT(FLOAT, RollingPeopleVaccinated)/population)*100 AS "Rolling_%_Vaccinated"
FROM PopvsVac;

-- 2. USING TEMP TABLE TO GET "Rolling_%_Vaccinated"
-- DROP TABLE IF EXISTS #PercentPopulationVaccinated -- to drop temp table bcz it runs only once
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CONVERT(int,v.new_vaccinations))
	OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_sum_new_vac
	-- ,(rolling_sum_new_vac/population)*100
-- [this will give error bcz aggregated functions cannot be used in SELECT clause]
FROM CovidDeath d
INNER JOIN CovidVaccination v
	ON d.location=v.location
	AND d.date=v.date
WHERE d.continent IS NOT NULL 
ORDER BY 2,3;

SELECT *,
	(CONVERT(FLOAT, RollingPeopleVaccinated)/population)*100 AS "Rolling_%_Vaccinated"
FROM #PercentPopulationVaccinated;

-- 3. CREATE VIEW TO STORE DATA FOR LATER VISUALIZATIONS
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CONVERT(int,v.new_vaccinations))
	OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_sum_new_vac
	-- ,(rolling_sum_new_vac/population)*100
-- [this will give error bcz aggregated functions cannot be used in SELECT clause]
FROM CovidDeath d
INNER JOIN CovidVaccination v
	ON d.location=v.location
	AND d.date=v.date
WHERE d.continent IS NOT NULL 
-- ORDER BY 2,3; -- ORDER BY cannot be used inside the VIEW

SELECT *
FROM PercentPopulationVaccinated;



