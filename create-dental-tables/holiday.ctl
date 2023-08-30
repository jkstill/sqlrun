load data
infile 'holiday.txt'
into table holiday
fields terminated by ',' optionally enclosed by '"'
(
	"ID" "to_number(:\"ID\")",
	"CLINIC" "to_number(:\"CLINIC\")",
   "DESCRIPTION",
	"STARTDATE" "to_date(:\"STARTDATE\",'dd-mon-yy')",
	"ENDDATE" "to_date(:\"ENDDATE\",'dd-mon-yy')",
	"PARTIALDAY" "to_number(:\"PARTIALDAY\")",
	"STARTTIME" "to_number(:\"STARTTIME\")",
	"ENDTIME" "to_number(:\"ENDTIME\")",
   "DISPLAYDESC"
)
