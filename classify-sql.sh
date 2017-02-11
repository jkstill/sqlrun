#!/bin/bash		

	#--db //ora12c102rac01/p1.jks.com \
	#--connect-delay 2 \
		
./classify-sql.pl \
	--exe-mode semi-random \
	--connect-mode flood \
	--max-sessions 1 \
	--exe-delay 0.1 \
	--db p1 \
	--username jkstill \
	--password grok \
	--schema system \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime 2 
	#--debug 
	##--trace 
	#--timer-test
