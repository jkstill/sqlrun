select 'CITIES' tablename, count(*) from evs.CITIES union all
select 'COUNTIES' tablename, count(*) from evs.COUNTIES union all
select 'EV_MODELS' tablename, count(*) from evs.EV_MODELS union all
select 'EV_SIGHTINGS' tablename, count(*) from evs.EV_SIGHTINGS union all
select 'STATES' tablename, count(*) from evs.STATES
/
