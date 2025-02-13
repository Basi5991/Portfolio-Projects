Select * From portfolioProject..CovidDeaths
order by 3,4


--Select * From portfolioProject..CovidVacinations
--order by 3,4

Select Location,date, total_cases, new_cases, population

From portfolioProject..CovidDeaths
order by 1,2

Select Location,date, total_cases, (total_deaths/total_cases)*100 as DeathPercentage

From portfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2

Select Location,date, total_cases, population, (total_cases/population)*100 as	victmsPercentage

From portfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2



Select Location,date, total_cases, population, (total_cases/population)*100 as	victmsPercentage

From portfolioProject..CovidDeaths
--Where location like '%states%'
order by 1,2



Select Location , population, Max(total_cases) as highstCount , Max((total_cases/population))*100 as	victmsPercentage

From portfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location , population
order by victmsPercentage Desc



Select Location , Max(cast(total_deaths as int)) as TotalDeathCount
From portfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by Location 
order by TotalDeathCount Desc



Select Location , Max(cast(total_deaths as int)) as TotalDeathCount
From portfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null
Group by Location 
order by TotalDeathCount Desc


SELECT 
   
    SUM(new_cases) AS sumOfNewCases, 
    SUM(CAST(new_deaths AS INT)) AS sumOfDeaths,
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS deathsPerInfection
FROM 
    portfolioProject..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE 
    continent IS NULL
    AND CAST(new_deaths AS INT) <> 0
--GROUP BY date
ORDER BY 
    1,2;
   

 WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(COALESCE(vac.new_vaccinations, 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        portfolioProject..CovidVacinations vac  -- Fixed table name
    ON 
        dea.location = vac.location 
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)

SELECT * FROM PopvsVac;









	-- Create the temporary table
	-- Drop the temporary table if it already exists
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;


CREATE TABLE #PercentPopulationVaccinated (
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

-- Insert data into the temporary table
INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    portfolioProject..CovidVacinations vac
ON 
    dea.location = vac.location 
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;




SELECT 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM 
    #PercentPopulationVaccinated;



	CREATE VIEW PercentPopulationVaccinated AS  
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,  
    SUM(COALESCE(vac.new_vaccinations, 0)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated  
FROM 
    PortfolioProject..CovidDeaths dea  
JOIN 
     portfolioProject..CovidVacinations vac 
    ON dea.location = vac.location  
    AND dea.date = vac.date  
WHERE 
    dea.continent IS NOT NULL;  

GO  
 
SELECT * FROM PercentPopulationVaccinated;
