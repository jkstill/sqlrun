#!/usr/bin/env bash

sqlldr parfile=ev-models.par
sqlldr parfile=states.par
sqlldr parfile=counties.par
sqlldr parfile=cities.par
sqlldr parfile=ev-locations.par
