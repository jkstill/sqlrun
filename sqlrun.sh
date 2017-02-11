#!/bin/bash		

./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode flood \
	--tx-behavior rollback \
	--max-sessions 3 \
	--exe-delay 0.1 \
	--db p1 \
	--username scott \
	--password tiger \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime 10 \
	#--exit-trigger
	#--debug 
	##--trace 
	#--timer-test
