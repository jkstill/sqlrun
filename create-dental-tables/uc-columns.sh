#!/usr/bin/env bash

# upper case column names

for lcColumn in $(grep -ohE '"[[:alnum:]_]+"' *.sql *.ctl| sort -u| tr -d '"')
do
	ucColumn=${lcColumn@U}
	echo "col: $ucColumn " 
	sed -i -e "s/$lcColumn/$ucColumn/g" *.sql *.ctl
done


