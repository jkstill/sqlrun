#!/bin/bash		

sessions=256
pool_connections=64
runtime=240

: << 'DBD-drcp'

 As per the docs, adding the 'ora_drcp => 1' attribute to the 
 connection string should automatically connect via DRCP.

 So far, that does not work. 

 It has been necessary to append ':pooled' to the connection,
 otherwise a standard dedicated connection is created

 This is DBD::Oracle 1.80.
 

DBD-drcp

## 64-64 for 64 sessions and 64 connection pool connections
## see how it performs 1:1

./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode trickle \
	--connect-delay 0.01 \
	--context-tag "DRCP-${sessions}-${pool_connections}" \
	--tx-behavior rollback \
	--max-sessions $sessions \
	--exe-delay 0.1 \
	--db 'o77-swingbench02/soe:pooled' \
	--username soe \
	--password soe \
	--drcp \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime $runtime
	#--trace \
	#--tracefile-id 'SQLRELAY' 
	#--exit-trigger
	#--debug 
	#--timer-test
