load data
infile 'ev-sightings.csv'
into table ev_locations
fields terminated by ',' optionally enclosed by '"'

(
	make,
	model,
	county,
   city,
	state
)
