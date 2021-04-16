#!/bin/bash		

sessions=512
pool_connections=128
runtime=240

## 64-64 for 64 sessions and 64 connection pool connections
## see how it performs 1:1

./sqlrun.pl \
	--driver SQLRelay \
	--exe-mode sequential \
	--connect-mode trickle \
	--connect-delay 0.01 \
	--context-tag "SQLR-${sessions}-${pool_connections}" \
	--tx-behavior rollback \
	--max-sessions $sessions \
	--exe-delay 0.1 \
	--db "host=sqlrelay;port=9000;tries=0;retrytime=1;debug=0" \
	--username sqlruser \
	--password sqlruser \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime $runtime
	#--trace \
	#--tracefile-id 'SQLRELAY' 
	#--exit-trigger
	#--debug 
	#--timer-test
