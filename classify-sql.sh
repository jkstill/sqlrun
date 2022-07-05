#!/bin/bash		

	#--db //ora12c102rac01/p1.jks.com \
	#--connect-delay 2 \
		
./classify-sql.pl \
	--exe-mode semi-random \
	--connect-mode flood \
	--max-sessions 1 \
	--exe-delay 0.1 \
	--db ora192rac01/pdb2.jks.com \
	--username jkstill \
	--password grok \
	--schema system \
	--runtime 2  \
	--sqldir /home/jkstill/oracle/dba/undo_size/temp-undo/sqlrun/SQL
	#--debug 
	#--parmfile parameters.conf \
	#--sqlfile sqlfile.conf  \
	##--trace 
	#--timer-test
