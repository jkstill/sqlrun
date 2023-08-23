#!/bin/bash		

./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode flood \
	--tx-behavior rollback \
	--max-sessions 50 \
	--exe-delay 0 \
	--db lestrade/orcl.jks.com \
	--username jkstill \
	--password grok \
	--runtime 60  \
	--sqldir $(pwd)/SQL

	#--tracefile-id CRC-RC-TEST \
	#--trace \

	#--exit-trigger
	#--debug 
	##--trace 
	#--timer-test
	#--parmfile parameters.conf \
	#--sqlfile sqlfile.conf  \
	# --driver Oracle \
	#--client-result-cache-trace \
