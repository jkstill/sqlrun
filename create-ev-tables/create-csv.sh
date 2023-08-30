#!/usr/bin/env bash

# https://catalog.data.gov/dataset/electric-vehicle-population-data
# http://goodcsv.com/geography/us-states-territories/

evData=/mnt/zips/zips/data-sets/data.gov/ev-population/Electric_Vehicle_Population_Data.csv
stateData=/mnt/zips/zips/data-sets/US-States/us-states-territories.csv

cut -f7-8 -d,  $evData | tail -n+2 | sort | uniq | sed -e 's/^ *//g' -e '/,$/d' > ev-models.csv

grep -E '^(State|Federal District)' $stateData | cut -d, -f2,3 |  sed -r -e 's/^ *//g' -e 's/ ,/,/' -e 's/\[.*\]//g' -e 's/\s+$//' > states.csv

cut -f2-4 -d, $evData | tail -n+2 |  sort -u | sed -e 's/Doña /Dona /g' > cities.csv

tail -n+2 $evData | cut -f2,4 -d, | sort -u | sed -e 's/Doña /Dona /g' > counties.csv


