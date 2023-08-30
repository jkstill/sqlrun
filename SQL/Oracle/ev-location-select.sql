
select count(*) ev_count
from ev_locations el
join cities ci on ci.city = el.city
        and ci.county = el.county
        and ci.state = el.state
        and el.make = :1
        and el.model = :2
        and el.county = :3
        and el.city = :4
        and el.state = :5
join ev_models m on m.make = el.make
        and m.model = el.model

