#!/usr/bin/env bash


# make, model, county, city, state

while read evline
do
	while read cityline 
	do
		echo "$evline,$cityline"
	done < <(cat cities.csv)
done < <(cat ev-models.csv) | tee ev-sightings.csv

