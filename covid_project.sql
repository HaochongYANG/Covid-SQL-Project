/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

USE sql_covid;

SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
ORDER BY 1, 2;

-- Looking at total_cases V.S. total_deaths
-- Shows the likelihood of dying if you contract Covid in Canada

SELECT 
	location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM coviddeaths
WHERE location = "Canada" AND LENGTH(iso_code) = 3
ORDER BY 1, 2;
    
-- total_cases V.S. population
-- Shows what percentage of Canadian population got Covid

SELECT location, date, total_cases, population, (total_cases / population) * 100 AS PercentPopulationInfected
FROM coviddeaths
WHERE location = "Canada" AND LENGTH(iso_code) = 3
ORDER BY 1, 2;

-- Looking at countries with highest Infection Rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases) / population) * 100 AS PercentPopulationInfected
FROM coviddeaths
WHERE LENGTH(iso_code) = 3
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Showing countries with highest death count per population

SELECT location, 
MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM coviddeaths
WHERE LENGTH(iso_code) = 3
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENTS --

-- Showing continents with the highest death count per population

SELECT location, 
MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM coviddeaths
WHERE 
	LENGTH(iso_code) <> 3 AND 
    location NOT Like "%income%" AND 
    location NOT IN ("Kosovo", "Northern Cyprus")
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS

SELECT 
	date, 
    SUM(new_cases) AS "Global Daily Cases", 
    SUM(CAST(new_deaths AS UNSIGNED)) AS "Global Daily Deaths", 
    SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases) * 100 AS "Daily Death Percentage"
FROM coviddeaths
WHERE 
	LENGTH(iso_code) <> 3 AND 
    location NOT Like "%income%" AND 
    location NOT IN ("Kosovo", "Northern Cyprus")
GROUP BY date
ORDER BY 1, 2;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine.

SELECT dea.continent, 
	   dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations, 
	   SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE (dea.continent IS NOT NULL) AND (LENGTH(dea.iso_code) = 3)
ORDER BY dea.location, dea.date;

-- USE CTE to perform calculations on Partition by in previous query.
WITH PopvsVac(continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
AS(
SELECT dea.continent, 
	   dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations, 
	   SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE (dea.continent IS NOT NULL) AND (LENGTH(dea.iso_code) = 3)
ORDER BY dea.location, dea.date
)
SELECT *, (RollingPeopleVaccinated / population) * 100
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
Continent text,
Location text,
Date datetime, 
Population text,
New_Vaccinations text,
RollingPeopleVaccinated text
);
INSERT INTO PercentPopulationVaccinated(
SELECT dea.continent, 
	   dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations, 
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE (dea.continent IS NOT NULL) AND (LENGTH(dea.iso_code) = 3)
ORDER BY dea.location, dea.date);

-- Creating View to store data for later visualizations

DROP VIEW IF EXISTS PercentVaccinated;
CREATE VIEW PercentVaccinated AS (
SELECT dea.continent, 
	   dea.location, 
       dea.date, 
       dea.population, 
       CAST(vac.new_vaccinations AS UNSIGNED), 
	   SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE (dea.continent IS NOT NULL) AND (LENGTH(dea.iso_code) = 3));

