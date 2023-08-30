load data
infile 'ev-models.csv'
into table ev_models
fields terminated by ',' optionally enclosed by '"'

(
	make,
   model
)
