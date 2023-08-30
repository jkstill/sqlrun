load data
infile 'cities.csv'
into table cities
fields terminated by ',' optionally enclosed by '"'

(
	county,
   city,
	state
)
