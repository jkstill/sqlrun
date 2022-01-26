#!/bin/bash		

#  psql postgres://benchmark:grok@ubuntu-20-pg02:5432/postgres

sessions=1
runtime=5

./sqlrun.pl \
	--exe-mode sequential \
	--driver mysql \
	--port 3306 \
	--host  your-mysql-host \
	--connect-mode flood \
	--tx-behavior rollback \
	--exe-delay 0.1 \
	--db db02 \
	--username admin \
	--password password \
	--max-sessions $sessions \
	--runtime $runtime 
	#--exit-trigger
	#--debug 
	##--trace 
	#--timer-test
