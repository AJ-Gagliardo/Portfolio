//* SQL project - Covid 19 data exploration

Tools used: SQL, google sheets
Skills used: Select, Where, Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*//

--In this section I query to look at total cases vs Total deaths in Canada, and orderer the information

Select location, date, total_cases,total_deaths, (total_deaths/total_cases)*100) AS DeathPercentageFromCovid
From PortfolioProject.dbo.CovidDeaths
Where location like '%Canada%'
order by location,date


-- This query will show countries with highest infection rate (at any point in time) compared to population

Select location, population, max(total_cases) AS HighestInfectionCount,  
	MAX((total_cases/population))*100 as MaxPercentagePopulationInfected
from PortfolioProject.dbo.CovidDeaths
Group by Location, population
order by MaxPercentagePopulationInfected desc

//*
--In the case above, I noticed that there where many null values and also some countries had a percentage of infection higher than 100%
--This meant that I had to make some data cleaning, so I filtered in Excel the few countries that had this problem (Venezuela, Poland, Moroco, Saudi Arabia, etc.)
--I noticed some dirty data, in which population was extremely short (i.e. Venezuela had 480 population in a few cells) making the Max (total_cases/population) 
--extremely high, so I just filtered and replaced the dirty data from these countries 
*//



-- highest death count

select location, max(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is not null --this get rid of continents and null data
Group by Location
order by TotalDeathCount desc

--Result above was compared searching in google and the numbers up to the date are really close (i.e. USA 960 k vs 962k, probably becuas eof the few days on difference)

-- Doing by continent

select location, max(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is null -- above I used not null to avoid continents, now I want null to get continents
AND location is not Null and location not like '%income%' 
and location not like 'international' -- not like to avoid locations that are not continents (with the exception of world)
Group by location
order by TotalDeathCount desc

-- Global numbers

select SUM(new_cases) as Total_Cases_Worldwide, 
	SUM(cast(new_deaths as int)) as Total_deaths_worldwide,
	Concat(Round(Sum(cast(new_deaths as int))/sum(new_cases)*100,2),'%') as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
Where continent is not null
order by 1,2


-- New vaccinations per day ordered by country

select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
From PortfolioProject.dbo.CovidDeaths as deaths
Join PortfolioProject.dbo.CovidVaccinations as vac
	On deaths.location = vac.location
	and deaths.date = vac.date
	where deaths.continent is not null
	order by 2,3


-- New vaccinations per day ordered by country

with PopulationvsVac (continent, location, date, population, new_vaccinations, PeopleVaccinated)
as
(
select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
	Sum(convert(float, vac.new_vaccinations)) over(partition by deaths.location 
	order by deaths.location, deaths.date) as PeopleVaccinated
	

From PortfolioProject.dbo.CovidDeaths deaths
Join PortfolioProject.dbo.CovidVaccinations vac
	On deaths.location = vac.location
	and deaths.date = vac.date
	where deaths.continent is not null
	and deaths.location is not null
	and deaths.date is not null 
	and vac.new_vaccinations is not null


	)
select *, (PeopleVaccinated/population)*100 as 'PeopleVaccinated / population'
From PopulationvsVac



-- Create a Temporary table

DROP Table if exists #PercentPopulationVaccinated  -- deletes the table, needed to rerun the code 
Create table #PercentPopulationVaccinated

(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_vaccinations numeric,
PeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated

select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
	Sum(convert(float, vac.new_vaccinations)) over(partition by deaths.location 
	order by deaths.location, deaths.date) as PeopleVaccinated
	

From PortfolioProject.dbo.CovidDeaths deaths
Join PortfolioProject.dbo.CovidVaccinations vac
	On deaths.location = vac.location
	and deaths.date = vac.date
	where deaths.continent is not null


	select *, (PeopleVaccinated/population)*100 as 'PeopleVaccinated / population'
From #PercentPopulationVaccinated

--Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as 

select deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations,
	Sum(convert(float, vac.new_vaccinations)) over(partition by deaths.location 
	order by deaths.location, deaths.date) as PeopleVaccinated
	

From PortfolioProject.dbo.CovidDeaths deaths
Join PortfolioProject.dbo.CovidVaccinations vac
	On deaths.location = vac.location
	and deaths.date = vac.date
	where deaths.continent is not null


