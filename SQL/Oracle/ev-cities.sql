select /*+ RESULT_CACHE */ county,city,state
from cities 
where 
	county = :1 
	and city = :2
	and state = :3
