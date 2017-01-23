#!/bin/bash		
		
./sqlrun.pl \		
	--exe-mode semi-random \		
	--connect-mode flood \		
	-db p1 \		
	-username USERNAME \		
	-password PASSWORD \		
	--parmfile parameters.conf \		
	--sqlfile sqlfile.conf \		
	--debug 		
	#--timer-test
