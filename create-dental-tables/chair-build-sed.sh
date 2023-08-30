#!/usr/bin/env bash

# build data for obfuscation


# obfuscating these fields
# 2. name
# 3. description
# 9. location

declare -A fields

fields=( [2]='name' [3]='description' [9]='location' [8]='import' )

for fieldno in ${!fields[@]} 
do
	echo $fieldno

	sedFile=chair-${fields[$fieldno]}.sed

	[[ -r $sedFile ]] && {
		echo
		echo Cowardly refusing to overwrite $sedFile
		echo as you may have already edited the file
		echo 
		continue
		exit 1
	}

	while IFS='' read val
	do
		#echo "'$val'" >&2
		echo "s/$val/$val/g"
	done  < <(cut -d, -f${fieldno} chair.txt | sort -u) > $sedFile

done


echo
echo Now, edit the following files, changing the second column to the new value.
echo
echo Once that is done, run sed for each file 
echo
echo sed -f chair-name.sed -i chair.txt
echo 



