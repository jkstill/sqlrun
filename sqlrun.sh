#!/bin/bash		
		
./sqlrun.pl \
	--exe-mode semi-random \
	--connect-mode flood \
	-db p1 \
	-username jkstill \
	-password grok \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf \
	 --debug
	#--timer-test
