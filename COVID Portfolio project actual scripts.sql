-- Retrieve all data from CovidDeaths, ordered by columns 3 and 4
SELECT * FROM portfolioProject..CovidDeaths
ORDER BY 3, 4;

-- Retrieve specific columns from CovidDeaths, ordered by location and date
SELECT Location, Date, Total_Cases, New_Cases, Population
FROM portfolioProject..CovidDeaths
ORDER BY 1, 2;

-- Calculate death percentage for states
SELECT Location, Date, Total_Cases, (Total_Deaths / Total_Cases) * 100 AS DeathPercentage
FROM portfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1, 2;

-- Calculate victims percentage for states
SELECT Location, Date, Total_Cases, Population, (Total_Cases / Population) * 100 AS VictimsPercentage
FROM portfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1, 2;

-- Calculate victims percentage for all locations
SELECT Location, Date, Total_Cases, Population, (Total_Cases / Population) * 100 AS VictimsPercentage
FROM portfolioProject..CovidDeaths
ORDER BY 1, 2;

-- Get highest case count and victim percentage per location
SELECT Location, Population, 
       MAX(Total_Cases) AS HighestCount, 
       MAX((Total_Cases / Population) * 100) AS VictimsPercentage
FROM portfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY VictimsPercentage DESC;

-- Get total death count for locations with known continent
SELECT Location, MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM portfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Get total death count for locations with unknown continent
SELECT Location, MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM portfolioProject..CovidDeaths
WHERE Continent IS NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Summarize new cases and new deaths with death percentage
SELECT 
    SUM(New_Cases) AS SumOfNewCases, 
    SUM(CAST(New_Deaths AS INT)) AS SumOfDeaths,
    SUM(CAST(New_Deaths AS INT)) / SUM(New_Cases) * 100 AS DeathsPerInfection
FROM portfolioProject..CovidDeaths
WHERE Continent IS NULL AND CAST(New_Deaths AS INT) <> 0
ORDER BY 1, 2;

-- Common Table Expression (CTE) for population vs vaccination data
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
    SELECT 
        dea.Continent, 
        dea.Location, 
        dea.Date, 
        dea.Population, 
        vac.New_Vaccinations,
        SUM(COALESCE(vac.New_Vaccinations, 0)) 
            OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
    FROM portfolioProject..CovidDeaths dea
    JOIN portfolioProject..CovidVacinations vac  
    ON dea.Location = vac.Location 
    AND dea.Date = vac.Date
    WHERE dea.Continent IS NOT NULL
)
SELECT * FROM PopvsVac;

-- Temporary table for PercentPopulationVaccinated
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.Continent, 
    dea.Location, 
    dea.Date, 
    dea.Population, 
    vac.New_Vaccinations,
    SUM(CONVERT(INT, vac.New_Vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM portfolioProject..CovidDeaths dea
JOIN portfolioProject..CovidVacinations vac
ON dea.Location = vac.Location 
AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL;

SELECT 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Create a view for PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS  
SELECT 
    dea.Continent, 
    dea.Location, 
    dea.Date, 
    dea.Population, 
    vac.New_Vaccinations,  
    SUM(COALESCE(vac.New_Vaccinations, 0)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated  
FROM portfolioProject..CovidDeaths dea  
JOIN portfolioProject..CovidVacinations vac 
    ON dea.location = vac.location  
    AND dea.date = vac.date  
WHERE 
    dea.continent IS NOT NULL;  

GO  
 
SELECT * FROM PercentPopulationVaccinated;
