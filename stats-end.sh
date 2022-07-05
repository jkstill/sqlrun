#!/usr/bin/env bash

USERNAME=jkstill
PASSWORD=grok
DB=ora192rac01/pdb2.jks.com


while :
do
 
	sqlplus -S -L $USERNAME/$PASSWORD@$DB  <<-EOF
		set pause off verify off feed on term on
		@@stats-end
		@@stats-report
		exit
	EOF

	sleep 5

done

