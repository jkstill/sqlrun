#!/bin/bash		

timestamp=$(date +%Y%m%d%H%M%S)

./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode flood \
	--tx-behavior commit \
	--max-sessions 2 \
	--exe-delay 0 \
	--db lestrade/orcl.jks.com \
	--username jkstill \
	--password grok \
	--runtime 10 \
	--tracefile-id EV-RC \
	--trace \
	--xact-tally \
	--xact-tally-file  rc-test-$timestamp.log \
	--pause-at-exit \
	--sqldir $(pwd)/SQL 


	#--client-result-cache-trace \
	#--exit-trigger
	#--debug 
	##--trace 
	#--timer-test
	#--parmfile parameters.conf \
	#--sqlfile sqlfile.conf  \
	# --driver Oracle \
	#--username evs \
	#--password evs \
