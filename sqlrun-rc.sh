#!/usr/bin/env bash


# convert to lower case
typeset -l rcMode=$1

set -u

[[ -z $rcMode ]] && {

	echo
	echo include 'force' or 'manual' on the command line
	echo
	echo eg: $0 force
	echo

	exit 1

}


# another method to convert to lower case
#rcMode=${rcMode@L}

echo rcMode: $rcMode

case $rcMode in
	force|manual) ;;
	*) echo 
		echo "arguments are [force|manual] - case is unimportant"
		echo 
		exit 1;;
esac


db='lestrade/orcl.jks.com'
username='jkstill'
password='grok'

# annotate the tables appropriately
unset SQLPATH ORACLE_PATH
sqlplus -L /nolog <<-EOF

	connect $username/$password@$db
	@@result-cache-dental-config/${rcMode}.sql

	exit

EOF

timestamp=$(date +%Y%m%d%H%M%S)
traceDir=trace/${rcMode}-${timestamp}
rcLogDir=rclog
rcLogFile=$rcLogDir/rc-${rcMode}-${timestamp}.log 
traceFileID="RC-${timestamp}"

mkdir -p $traceDir
mkdir -p $rcLogDir

./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode flood \
	--tx-behavior commit \
	--max-sessions 20 \
	--exe-delay 0 \
	--db "$db" \
	--username $username \
	--password "$password" \
	--runtime 1200 \
	--tracefile-id $traceFileID \
	--trace \
	--xact-tally \
	--xact-tally-file  $rcLogFile \
	--pause-at-exit \
	--sqldir $(pwd)/SQL 


# cheating a bit as I know where the trace file are on the server
# lestrade.jks.com:/opt/oracle/diag/rdbms/orcl/orcl/trace/orcl_ora_24103_RC-20230703142522.trc
scp -p oracle@lestrade.jks.com:/opt/oracle/diag/rdbms/orcl/orcl/trace/orcl_ora_*_${traceFileID}*.trc $traceDir

echo 
echo Trace files are in $traceDir/
echo RC Log is $rcLogFile
echo 

	#--client-result-cache-trace \
	#--exit-trigger
	#--debug 
	##--trace 
	#--timer-test
	#--parmfile parameters.conf \
	#--sqlfile sqlfile.conf  \
	# --driver Oracle \
	#--username evs \
	#--password evs \


