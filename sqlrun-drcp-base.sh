#!/bin/bash		

sessions=256
pool_connections=32
runtime=240

## 64-64 for 64 sessions and 64 connection pool connections
## see how it performs 1:1

./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode trickle \
	--connect-delay 0.01 \
	--context-tag "DRCP-${sessions}-BASE" \
	--tx-behavior rollback \
	--max-sessions $sessions \
	--exe-delay 0.1 \
	--db 'o77-swingbench02/soe' \
	--username soe \
	--password soe \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime $runtime
	#--trace \
	#--tracefile-id 'SQLRELAY' 
	#--exit-trigger
	#--debug 
	#--timer-test
