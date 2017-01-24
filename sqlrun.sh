#!/bin/bash		
		
./sqlrun.pl \
	--exe-mode semi-random \
	--connect-mode tsunami \
	--connect-delay 2 \
	--max-sessions 5 \
	--db p1 \
	--username sys \
	--password sys \
	--schema system \
	--sysdba \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime 10 
