#!/bin/bash		

	#--db //ora12c102rac01/p1.jks.com \
	#--connect-delay 2 \
		
./sqlrun.pl \
	--exe-mode semi-random \
	--connect-mode flood \
	--max-sessions 1 \
	--exe-delay 0.1 \
	--db p1 \
	--username jkstill \
	--password grok \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime 5 
	#--debug \
	#--exit-trigger
	##--trace 
	#--timer-test
