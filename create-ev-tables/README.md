

see create-csv.sh


https://catalog.data.gov/dataset/electric-vehicle-population-data

cut -f7-8 -d,  /mnt/zips/zips/data-sets/data.gov/ev-population/Electric_Vehicle_Population_Data.csv | tail -n+2 | sort | uniq | sed -e 's/^ *//g' -e '/,$/d' > ev-models.csv


http://goodcsv.com/geography/us-states-territories/


grep -E '^(State|Federal District)' /mnt/zips/zips/data-sets/US-States/us-states-territories.csv | cut -d, -f2,3 |  sed -r -e 's/^ *//g' -e 's/ ,/,/' -e 's/\[.*\]//g' -e 's/\s+$//' > states.csv



cut -f2-4 -d,  /mnt/zips/zips/data-sets/data.gov/ev-population/Electric_Vehicle_Population_Data.csv | tail -n+2 |  sort -u | sed -e 's/Doña /Dona /g' > cities.csv

tail -n+2   /mnt/zips/zips/data-sets/data.gov/ev-population/Electric_Vehicle_Population_Data.csv | cut -f2,4 -d, | sort -u | sed -e 's/Doña /Dona /g' > counties.csv


====

A subset of cities.csv and ev-models.csv will be used as bind variables for sqlrun

