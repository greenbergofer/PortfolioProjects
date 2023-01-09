-- DataSet import from https://ourworldindata.org/covid-deaths 


-- select data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1,2


-- Looking at Total Cases vs Total Deaths

select location, date, total_cases, total_deaths, (total_deaths/ total_cases)*100 as DeathPercentage
from CovidDeaths
where location = 'Israel'
order by 1,2

-- Looking an Total Cases vs Population
-- Shoes what percentage of population got covid

select location, date, total_cases, population, (total_cases/ population)*100 as CasesPercentage
from CovidDeaths
where location = 'Israel'
order by 1,2

-- Looking at countries with highest infection rate compared to population

select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/ population))*100 as CasesPercentage
from CovidDeaths
group by location, population
order by CasesPercentage desc 

-- Showing countries with highest death count per population

select location, max(cast(total_deaths as int)) as TotalDeathCount 
from CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc 

-- Showing continents with the highest death count per population

select continent, max(cast(total_deaths as int)) as TotalDeathCount 
from CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

-- Global Numbers

select date, sum(new_cases) as SumOfNewCases, sum(cast(new_deaths as int)) as SumOfNewDeaths, 
(sum(cast(new_deaths as int))/sum(new_cases))*100 as PercentageOfDeaths
from CovidDeaths
where continent is not null
group by date
order by 1,2

-- Total sum of the General Numbers

select sum(new_cases) as SumOfNewCases, sum(cast(new_deaths as int)) as SumOfNewDeaths, 
(sum(cast(new_deaths as int))/sum(new_cases))*100 as PercentageOfDeaths
from CovidDeaths
where continent is not null
order by 1,2


-- Looking at total population vs vaccinations (Join Tables)

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from CovidVaccinations vac
join CovidDeaths dea
	on vac.location = dea.location
	and vac.date = dea.date
where dea.continent is not null
order by 2,3

-- Use CTE

with PopVsVac (continent, Location, date, population, new_vaccinations ,RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from CovidVaccinations vac
join CovidDeaths dea
	on vac.location = dea.location
	and vac.date = dea.date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100 as PercentageVacPop from PopVsVac


-- Temp Table

create table #PercentPopulationVaccinated
(
Continent nvarchar(225),
Location nvarchar (225),
Date datetime,
Population numeric,
New_Vaccination numeric, 
RollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from CovidVaccinations vac
join CovidDeaths dea
	on vac.location = dea.location
	and vac.date = dea.date

select *, (RollingPeopleVaccinated/population)*100 as PercentageVacPop from #PercentPopulationVaccinated


-- Create View to store Data

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from CovidVaccinations vac
join CovidDeaths dea
	on vac.location = dea.location
	and vac.date = dea.date
where dea.continent is not null

select *
from PercentPopulationVaccinated


-- Summary of New cases by Month & Year (Using Pivot)

select MM as Month, [2020],[2021],[2022]
from (select YEAR(date) as YY, MONTH(date) as MM, new_cases_smoothed
		from CovidDeaths) cd
PIVOT (sum(new_cases_smoothed) for YY in ([2020],[2021],[2022])) pvt
order by MM


-- Summary of deaths by year (using cte)

WITH CTE_SumTotal 
AS 
(select year(date) as year, Location, sum(cast(new_deaths as float)) as Total,
ROW_NUMBER() over (partition by year(date) order by SUM(cast(new_deaths as float)) desc) as rank
from CovidDeaths
			group by year(date), location)
select Year, location, Total
from CTE_SumTotal
where rank =1













