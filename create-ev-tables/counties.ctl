load data
infile 'counties.csv'
into table counties
fields terminated by ',' optionally enclosed by '"'

(
	county,
   state
)
