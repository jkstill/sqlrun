
Fix and Obfuscate
=================

## upper case column names in SQL and CTL files

```text
$  ./uc-columns.sh
col: BLOCKSIZE
col: CHAIR
col: CLINIC
col: COL
col: DESCRIPTION
col: DISPLAYDESC
col: ENDDATE
col: ENDTIME
col: ID
col: IMPORT
col: ISOVERFLOW
col: LOCATION
col: NAME
col: OVERFLOWORDER
col: PARTIALDAY
col: ROW
col: STARTDATE
col: STARTTIME
col: UNAVAILABLE
```

## Obfuscate Data

Change ID numbers, locations, names, etc.


Must be changed in sqlldr data files and in SQL for testing.

```text
$  ls -l *.txt
-rw-r--r-- 1 jkstill dba 17560 Jun  1 14:49 chair.txt
-rw-r--r-- 1 jkstill dba 59980 Jun  1 14:49 holiday.txt

$  ls -l ../SQL/Oracle/*8*
-rwxr-xr-x 1 jkstill dba 78496 Jun  1 16:42 ../SQL/Oracle/bind-vals-8j53dscbsbqmb-ALL.txt
-rw-rw-r-- 1 jkstill dba   434 Jun  2 08:18 ../SQL/Oracle/bind-vals-8j53dscbsbqmb.txt
-rw-rw-r-- 1 jkstill dba   232 Jun  2 11:14 ../SQL/Oracle/select-8j53dscbsbqmb-hinted.sql
-rw-rw-r-- 1 jkstill dba   212 Jun  2 11:14 ../SQL/Oracle/select-8j53dscbsbqmb.sql
```



