#!/bin/bash		

sessions=1
runtime=120

	#--context-tag "SQLRUN-DRCP-${sessions}" \
	#--db ora192rac02/pdb4.jks.com:pooled \
	#--drcp \
	#--drcp-class 'drcp-benchmark' \

: << 'DBD-drcp'

 As per the docs, adding the 'ora_drcp => 1' attribute to the 
 connection string should automatically connect via DRCP.

 So far, that does not work. 

 It has been necessary to append ':pooled' to the connection,
 otherwise a standard dedicated connection is created

 This is DBD::Oracle 1.80.
 

DBD-drcp


./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode trickle \
	--connect-delay 0.1 \
	--tx-behavior rollback \
	--max-sessions $sessions \
	--exe-delay 0.1 \
	--db ora192rac02/pdb4.jks.com:pooled \
	--drcp \
	--drcp-class 'drcp-benchmark' \
	--username drcp_bench \
	--password drcp_bench \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime $runtime
	#--trace \
	#--tracefile-id 'SQLRUN' 
	#--exit-trigger
	#--debug 
	#--timer-test


