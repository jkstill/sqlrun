#!/bin/bash		

./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode flood \
	--tx-behavior commit \
	--max-sessions 10 \
	--exe-delay 0.25 \
	--db p2 \
	--username undotest \
	--password grok \
	--runtime  300 \
	--sqldir $(pwd)/SQL

