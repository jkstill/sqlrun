#!/bin/bash		

# options for Oracle Client Result Cache

./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode flood \
	--tx-behavior commit \
	--max-sessions 10 \
	--exe-delay 0 \
	--db lestrade/orcl.jks.com \
	--username evs \
	--password evs \
	--runtime 10 \
	--tracefile-id EV-RC_TEST \
	--trace \
	--xact-tally \
	--xact-tally-file  rc-test.log \
	--client-result-cache-trace \
	--pause-at-exit \
	--sqldir $(pwd)/SQL 


	#--exit-trigger
	#--debug 
	##--trace 
	#--timer-test
	#--parmfile parameters.conf \
	#--sqlfile sqlfile.conf  \
	# --driver Oracle \
