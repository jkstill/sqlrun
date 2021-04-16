#!/bin/bash		

sessions=640
runtime=240


./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode trickle \
	--connect-delay 0.1 \
	--context-tag "SQLRUN-${sessions}" \
	--tx-behavior rollback \
	--max-sessions $sessions \
	--exe-delay 0.1 \
	--db o77-swingbench02/soe \
	--username soe \
	--password soe \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime $runtime
	#--trace \
	#--tracefile-id 'SQLRUN' 
	#--exit-trigger
	#--debug 
	#--timer-test
