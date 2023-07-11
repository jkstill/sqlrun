#/usr/bin/env bash

#set -u 

declare -A leftFiles rightFiles

: << 'COMMENT'

Compare files from two directories

Calculate checksums

display:

- files from the left that do not exist on the right
- files from the right that do not exist on the left
- files that exist in both, but have different checksums

say you have two directories

/home/jkstill/oracle/sqlrun-tests/result-cache
/home/jkstill/oracle/sqlrun

and the current directory is: /home/jkstill/oracle/sqlrun

Where the result-cache directory contains new and modified files from sqlrun, this command will show the differences

  $  ./file-compare.sh ../sqlrun-tests/tufts/result-cache ../sqlrun

  These files are different

  ./SQL/Oracle/parameters.conf
  ./sqlrun.pl
  ./lib/Sqlrun.pm
  ./sqlrun.sh
  ./SQL/Oracle/sqlfile.conf

  These files appear only in ../sqlrun-tests/tufts/result-cache

  ./rco.sql
  ./result-cache-config/client-annotate-tables-manual.sql
  ./sqltext.txt
  ./SQL/Oracle/select-8j53dscbsbqmb-hinted.sql
  ./s.sql
  ./create-8j53dscbsbqmb/holiday-table.sql
  ./result-cache-config/client-annotate-tables-force.sql
  ./create-8j53dscbsbqmb/chair.ctl
  ./result-cache-config/client-settings.sql
  ./rct.sql
  ./result-cache-config/server-result-cache-config.sql
  ./SQL/Oracle/update-op-count.sql
  ./create-8j53dscbsbqmb/chair.txt
  ./crc-1.sql
  ./create-8j53dscbsbqmb/logging-table.sql
  ./crc-stats.sql
  ./sum.py
  ./create-8j53dscbsbqmb/chair.bad
  ./flush.sql
  ./s2.sql
  ./SQL/Oracle/select-8j53dscbsbqmb.sql
  ./SQL/Oracle/bind-vals-8j53dscbsbqmb.txt
  ./login.sql
  ./RESULTS.md
  ./create-8j53dscbsbqmb/holiday.par
  ./SQL/Oracle/bind-vals-8j53dscbsbqmb-ALL.txt
  
  These files appear only in ../sqlrun

  ./file-compare.sh

This would also work, but I like seeing the directory name

  $  ./file-compare.sh ../sqlrun-tests/tufts/result-cache .

COMMENT


declare leftDir rightDir

leftDir="$1"
rightDir="$2"

[[ -z $rightDir ]] && {
	echo
	echo ./$0 left-dir right-dir
	echo
	exit 1
}

[ -d "$leftDir" -a -x "$leftDir" ] || {
	echo
	echo Left: cannot read $leftDir
	echo
	exit 2
}

[ -d "$rightDir" -a -x "$rightDir" ] || {
	echo
	echo Right: cannot read $rightDir
	echo
	exit 3
}

leftHomeDir=$(dirname $leftDir)
leftBaseDir=$(basename $leftDir )

#echo "leftHomeDir: $leftHomeDir"
#echo "leftBaseDir: $leftBaseDir"

#cd $leftHomeDir
currDir=$(pwd)
#echo "currDir: $currDir"
cd $leftHomeDir/$leftBaseDir

for file in $(find . -type f | grep -vE '(\.(trc|trm|buf|log)$)|^./.git' | sort)
do
	sum=$(md5sum  $file)
	leftFiles[$file]=$sum
done

cd $currDir
#pwd

rightHomeDir=$(dirname $rightDir)
rightBaseDir=$(basename $rightDir)

#echo "rightHomeDir: $rightHomeDir"
#echo "rightBaseDir: $rightBaseDir"
cd $rightHomeDir/$rightBaseDir
#pwd

for file in $(find . -type f | grep -vE '(\.(trc|trm|buf|log)$)|^./.git' | sort)
do
	sum=$(md5sum  $file)
	rightFiles[$file]=$sum
done

declare -A diff

# walk the left side files and add each file

for key in ${!leftFiles[@]}
do
	#echo key: $key
	[[ -n ${rightFiles[$key]} ]] && {
		rightSum=${rightFiles[$key]}
		leftSum=${leftFiles[$key]}

		[[ $leftSum != $rightSum ]] && {
			#diff[$key]=$leftFiles[$key]
			diff[$key]=''
		}
	}
done

echo
echo These files are different
echo 

for key in ${!diff[@]}
do
	echo $key
done


echo
echo These files appear only in $leftHomeDir/$leftBaseDir
echo 

for key in ${!leftFiles[@]}
do
	[[ -n ${rightFiles[$key]} ]] || {
		echo $key
	}

done


echo
echo These files appear only in $rightHomeDir/$rightBaseDir
echo 

for key in ${!rightFiles[@]}
do
	[[ -n ${leftFiles[$key]} ]] || {
		echo $key
	}

done





