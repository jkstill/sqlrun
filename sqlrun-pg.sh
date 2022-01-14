#!/bin/bash		

#  psql postgres://benchmark:grok@ubuntu-20-pg02:5432/postgres

./sqlrun.pl \
	--exe-mode sequential \
	--driver Pg \
	--port 5432 \
	--host 'ubuntu-20-pg02' \
	--connect-mode flood \
	--tx-behavior rollback \
	--max-sessions 50 \
	--exe-delay 0.1 \
	--db postgres \
	--username benchmark \
	--password grok \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime 30 \
	#--exit-trigger
	#--debug 
	##--trace 
	#--timer-test
