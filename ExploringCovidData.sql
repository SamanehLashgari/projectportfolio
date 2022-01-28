/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

select * from PortfolioProject..CovidDeath$
where continent is not null
order by 3,4


select * from PortfolioProject..CovidDeath$
where continent is null
order by 3,4


-- Select Data that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeath$
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
From PortfolioProject..CovidDeath$
Where continent is not null 
and location like '%Canada%'
--and (total_deaths/total_cases)*100 is not null
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
From PortfolioProject..CovidDeath$
Where continent is not null 
and location like '%Canada%'
--and (total_deaths/total_cases)*100 is not null
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, population, Max (total_cases) HighestInfectionCount, Max(total_cases/population)*100 as InfectionRate
From PortfolioProject..CovidDeath$
Where continent is not null
--and location like '%Iran%'
Group by location, population
--and (total_deaths/total_cases)*100 is not null
order by InfectionRate desc


-- Countries with Highest Death Count per Population

Select location, Max (cast(Total_deaths as int)) HighestDeathCount
From PortfolioProject..CovidDeath$
Where continent is not null
--and location like '%United%'
Group by location
--and (total_deaths/total_cases)*100 is not null
order by HighestDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, Max (cast(Total_deaths as int)) HighestDeathCount
From PortfolioProject..CovidDeath$
Where continent is not null
--and location like '%United%'
Group by continent
--and (total_deaths/total_cases)*100 is not null
order by HighestDeathCount desc

-- GLOBAL NUMBERS for Covid Death and Infections
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeath$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


--Delete population column from CovidVaccination Table
ALTER TABLE CovidVaccine
DROP COLUMN population;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select * from PortfolioProject..CovidVaccine
where continent is not null 
and location like '%Canada%'
order by 3,4

----peaple vaccinated in Canada

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,people_vaccinated
--, SUM(CONVERT(int,vac.people_vaccinated)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as allVaccinepeapleSum
,MAX(CONVERT(int,vac.people_vaccinated)) over (partition by dea.location)
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeath$ dea
Join PortfolioProject..CovidVaccine vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
and dea.location like '%Canada%'
order by 2,3

---Use CTE to show vaccination rate in each Location

with popvac (continent, location, date, population, new_vaccinations, peaple_vaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,people_vaccinated
--, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as VaccineSum
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeath$ dea
Join PortfolioProject..CovidVaccine vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--and dea.location= 'iran'
--order by 2,3
)
select *,(peaple_vaccinated/[population])*100 as vaccineRate  from popvac 
order by 2,3


----Max VaccineRate in each location

Select  dea.location,dea.population,MAX(cast( vacc.people_vaccinated as int)) over (partition by dea.location) as hey
--,vac.people_vaccinated
--, SUM(CONVERT(int,vac.people_vaccinated)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as allVaccinepeapleSum

--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeath$ dea
Join PortfolioProject..CovidVaccine vacc
	On dea.location = vacc.location
	and dea.date = vacc.date
where dea.continent is not null 
and dea.location like '%Canada%'
--group by dea.location,dea.population
order by hey desc


----Vaccine Rate in the Globe

with popva (location, population,peapleVaccine)
as
(
Select  dea.location,dea.population,MAX(cast( vacc.people_vaccinated as int)) over (partition by dea.location) as peapleVaccine
--,vac.people_vaccinated
--, SUM(CONVERT(int,vac.people_vaccinated)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as allVaccinepeapleSum

--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeath$ dea
Join PortfolioProject..CovidVaccine vacc
	On dea.location = vacc.location
	and dea.date = vacc.date
where dea.continent is not null 
--and dea.location like '%Canada%'
--group by dea.location,dea.population
--order by hey desc

)
select *,peapleVaccine/population*100 as VaccineRate from popva
group by location, population,peapleVaccine
order by VaccineRate desc

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeath$ dea
Join PortfolioProject..CovidVaccine vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

create view  PercentPopulationVaccinated as

Select  dea.continent,dea.location,dea.population,dea.date,MAX(cast( vacc.people_vaccinated as int)) over (partition by dea.location) as peapleVaccine
--,vac.people_vaccinated,dae
--, SUM(CONVERT(int,vac.people_vaccinated)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as allVaccinepeapleSum

--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeath$ dea
Join PortfolioProject..CovidVaccine vacc
	On dea.location = vacc.location
	and dea.date = vacc.date
where dea.continent is not null 
select * from PercentPopulationVaccinated

