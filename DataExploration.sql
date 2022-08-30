--select *
--from portfolio_project..CovidDeaths
--order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from portfolio_project..CovidDeaths
order by 1,2

-- Total cases vs total deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from portfolio_project..CovidDeaths
order by 1,2

-- Total cases vs population
select location, date, total_cases, population, (total_cases/population)*100 as CovidPercentage
from portfolio_project..CovidDeaths
where location like '%Indonesia'
order by 1,2

-- Countries with Highest Covid Cases by population
select location, population, max(total_cases) as HighestCovidCases,max((total_cases/population))*100 as CasesPercentage
from portfolio_project..CovidDeaths
where continent is not null
group by location, population
order by 4 desc

-- Countries with Highest Death Count by population
select location, max(cast(total_deaths as int)) as TotalDeathCount
from portfolio_project..CovidDeaths
where continent is not null
group by location
order by 2 desc

-- By continent
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from portfolio_project..CovidDeaths
where continent is not null
group by continent
order by 2 desc

-- Global Numbers
select date, sum(new_cases) as totalCases, sum(cast(new_deaths as int)) as totalDeaths, 
	(sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
from portfolio_project..CovidDeaths
where continent is not null
group by date
order by 1,2

-- Total population vs vaccinations
-- With method
with popvac (Continent, location, date, population, new_vaccinations, rollingVaccinations)
as
(
select death.continent, death.location, death.date, death.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) over 
(partition by death.location order by death.location, death.date rows unbounded preceding)
as rollingVaccinations
from portfolio_project..CovidDeaths death
join portfolio_project..CovidVaccinations vac
on death.location = vac.location
and death.date = vac.date
where death.continent is not null
)
select *, (rollingVaccinations/population)*100 as vaccinationPercentage
from popvac

-- Temp Table method
drop table if exists #PercentVaccination
create table #PercentVaccination(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingVaccinations numeric
)
insert into #PercentVaccination
select death.continent, death.location, death.date, death.population, cast(vac.new_vaccinations as int)
, sum(convert(bigint,vac.new_vaccinations)) over 
(partition by death.location order by death.location, death.date rows unbounded preceding)
as rollingVaccinations
from portfolio_project..CovidDeaths death
join portfolio_project..CovidVaccinations vac
on death.location = vac.location
and death.date = vac.date
where death.continent is not null

select *, (rollingVaccinations/population)*100 as rollingPercentage
from #PercentVaccination

-- Create view for data vis
drop view if exists populationVaccinated
Create view populationVaccinated as
select death.continent, death.location, death.date, death.population, vac.new_vaccinations
, sum(convert(bigint,vac.new_vaccinations)) over 
(partition by death.location order by death.location, death.date rows unbounded preceding)
as rollingVaccinations
from portfolio_project..CovidDeaths death
join portfolio_project..CovidVaccinations vac
on death.location = vac.location
and death.date = vac.date
where death.continent is not null

select *
from populationVaccinated