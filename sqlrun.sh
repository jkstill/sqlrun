#!/bin/bash		

timestamp=$(date +%Y%m%d%H%M%S)

./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode flood \
	--tx-behavior commit \
	--max-sessions 2 \
	--exe-delay 0 \
	--db p1 \
	--username scott \
	--password tiger \
	--runtime 10 \
	--tracefile-id TEST \
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
