load data
infile 'states.csv'
into table states
fields terminated by ',' optionally enclosed by '"'

(
	name,
   abbreviation
)
