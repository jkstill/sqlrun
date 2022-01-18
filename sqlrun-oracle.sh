#!/bin/bash		

sessions=10
runtime=20

	#--context-tag "SQLRUN-${sessions}" \

./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode trickle \
	--connect-delay 0.1 \
	--tx-behavior rollback \
	--max-sessions $sessions \
	--runtime $runtime \
	--exe-delay 0.1 \
	--db js01 \
	--username scott \
	--password tiger  
	#--trace
