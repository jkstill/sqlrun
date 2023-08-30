load data
infile 'chair.txt'
into table chair
fields terminated by ',' optionally enclosed by '"'

(
   "CHAIR",
   "NAME",
   "DESCRIPTION",
   "CLINIC",
   "ROW",
   "COL",
   "UNAVAILABLE",
   "IMPORT",
   "LOCATION",
   "BLOCKSIZE",
   "ISOVERFLOW",
   "OVERFLOWORDER"
)
