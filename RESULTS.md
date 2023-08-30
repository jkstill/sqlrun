
# Test query with and without result cache

It is necessary to populate a table (or some method) to count the number of executions of the test query when client result cache is used.

This is because a sqltrace file has a big blank in it while RC is being used, followed by SNMFC that is approximately the same number of seconds as CLIENT_RESULT_CACHE_LAG, when the cache gets synced.

Both cached and un-cached tests are performed the same way.

As the code to update the counting table is run after every select, the resulting trace file needs to be filtered on the sqlid.

example:

```text
$ mrskew --where='$dur<1 and $sqlid eq q{9whtn601zbbm7}' cdb2_ora_31855_SQL-RC-OPCOUNT-20230505133445.trc
CALL-NAME                    DURATION       %  CALLS      MEAN       MIN       MAX
---------------------------  --------  ------  -----  --------  --------  --------
SQL*Net message from client  2.019366   99.7%     20  0.100968  0.100673  0.101548
reliable message             0.004668    0.2%      7  0.000667  0.000263  0.001441
EXEC                         0.001794    0.1%     19  0.000094  0.000000  0.000125
FETCH                        0.000177    0.0%     20  0.000009  0.000000  0.000037
SQL*Net message to client    0.000025    0.0%     20  0.000001  0.000001  0.000002
PARSE                        0.000014    0.0%      1  0.000014  0.000014  0.000014
PGA memory operation         0.000009    0.0%      3  0.000003  0.000001  0.000006
CLOSE                        0.000004    0.0%      1  0.000004  0.000004  0.000004
---------------------------  --------  ------  -----  --------  --------  --------
TOTAL (8)                    2.026057  100.0%     91  0.022264  0.000000  0.101548
```

## Testing

sqlrun is used to perform the tests

sqlrun has been modified to count the number of executions of the test sql, as they will not appear in the sqltrace file when client result cache is used

* sessions: 50
* runtime: 60 seconds
* delay time: 0

```text
./sqlrun.pl \
   --exe-mode sequential \
   --connect-mode flood \
   --tx-behavior rollback \
   --max-sessions 50 \
   --exe-delay 0 \
   --db ora192rac02/pdb1.jks.com \
   --username jkstill \
   --password grok \
   --runtime 60  \
   --tracefile-id SQL-NO-RC-OPCOUNT \
   --trace \
   --sqldir $(pwd)/SQL
```

There is a set of 20 combinations of bind values, which mimics what has been observed in the app.

example from sqltrace file:

```text
$  mrskew  trace-fixed/TDFPRD1_ora_42088.trc  --group='join(",",@bind)' --where='$sqlid eq "8j53dscbsbqmb" and ($call =~ /EXEC|FETCH/)'
join(",",@bind)                           DURATION       %  CALLS      MEAN       MIN       MAX
----------------------------------------  --------  ------  -----  --------  --------  --------
1686,"5/11/2023 0:0:0","5/11/2023 0:0:0"  0.099617   18.9%    280  0.000356  0.000000  0.005248
1762,"5/11/2023 0:0:0","5/11/2023 0:0:0"  0.087122   16.5%    278  0.000313  0.000000  0.000712
1687,"5/11/2023 0:0:0","5/11/2023 0:0:0"  0.085817   16.3%    280  0.000306  0.000000  0.000713
2090,"5/11/2023 0:0:0","5/11/2023 0:0:0"  0.085758   16.3%    280  0.000306  0.000000  0.000725
2089,"5/11/2023 0:0:0","5/11/2023 0:0:0"  0.085235   16.2%    278  0.000307  0.000000  0.000753
1688,"5/11/2023 0:0:0","5/11/2023 0:0:0"  0.083376   15.8%    278  0.000300  0.000000  0.000664
----------------------------------------  --------  ------  -----  --------  --------  --------
TOTAL (6)                                 0.526925  100.0%  1,674  0.000315  0.000000  0.005248
```

### Get the SQLID

```text
$ grep --color=never -B1 'SELECT H.*'  trace-result-cache-limit-bind-set-no-hint/cdb2_ora_31757_SQL-RC-OPCOUNT-20230505133445.trc
PARSING IN CURSOR #140570112439880 len=212 dep=0 uid=108 oct=3 lid=108 tim=1995080701281 hv=66432615 ad='615c9cf8' sqlid='9whtn601zbbm7'
SELECT H.* FROM HOLIDAY H WHERE ( H."Clinic" = 0 OR H."Clinic" = (SELECT C."Clinic" FROM CHAIR C WHERE C."Chair" = :p1)) AND H."StartDate" <= :p2 AND H."EndDate" >= :p2 AND H."PartialDay" = 0 ORDER BY H."Id" DESC
```

SQLID == 9whtn601zbbm7


### Results Without Client Result Cache

Annotate the tables so they are not automatically included in the result cache

```sql
alter table holiday result_cache (mode manual);
alter table chair result_cache (mode manual);

SQL> l
  1  select owner, table_name, result_cache
  2  from dba_tables
  3  where owner = 'JKSTILL'
  4  and table_name in ('CHAIR','HOLIDAY')
  5* order by 1,2
SQL> /

                                                    RESULT
OWNER                TABLE_NAME                     CACHE
-------------------- ------------------------------ ---------------
JKSTILL              CHAIR                          MANUAL
JKSTILL              HOLIDAY                        MANUAL

SQL>
```

Filtering out non-targeted SQL

```text
$ mrskew --where='$dur<1 and $sqlid eq q{9whtn601zbbm7}' trace-no-result-cache-limit-bind-set/*.trc
CALL-NAME                                        DURATION       %      CALLS      MEAN       MIN       MAX
-------------------------------------------  ------------  ------  ---------  --------  --------  --------
SQL*Net message from client                  2,587.578739   96.0%    883,794  0.002928  0.000258  0.293920
EXEC                                            65.454973    2.4%    883,794  0.000074  0.000000  0.003094
FETCH                                           35.980901    1.3%    883,794  0.000041  0.000000  0.001127
cursor: pin S                                    5.166228    0.2%      2,174  0.002376  0.001022  0.021984
SQL*Net message to client                        1.909643    0.1%    883,794  0.000002  0.000000  0.017031
latch: cache buffers chains                      0.227615    0.0%         25  0.009105  0.005459  0.010697
latch: Change Notification Hash table latch      0.001361    0.0%          1  0.001361  0.001361  0.001361
PARSE                                            0.001050    0.0%         50  0.000021  0.000000  0.000066
PGA memory operation                             0.000770    0.0%        150  0.000005  0.000001  0.000075
CLOSE                                            0.000091    0.0%         50  0.000002  0.000000  0.000004
-------------------------------------------  ------------  ------  ---------  --------  --------  --------
TOTAL (10)                                   2,696.321371  100.0%  3,537,626  0.000762  0.000000  0.293920

```


Number of executions of test sql: 883,794

```text
$ head -1 rc.log
SQL-NO-RC-OPCOUNT-20230505152329: 17430
(oci) jkstill@prefect:~/oracle/result-cache
$ grep -c SQL-NO-RC-OPCOUNT-20230505152329 rc.log
50
(oci) jkstill@prefect:~/oracle/result-cache
$ grep SQL-NO-RC-OPCOUNT-20230505152329 rc.log | cut -f2 -d: | ./sum.py
883794.0
```

### Results With Client Result Cache

Annotate the tables so they are automatically included in the result cache

```sql
alter table holiday result_cache (mode force);
alter table chair result_cache (mode force);

SQL> select owner, table_name, result_cache
  2  from dba_tables
  3  where owner = 'JKSTILL'
  4  and table_name in ('CHAIR','HOLIDAY')
  5  order by 1,2
  6  /

                                                    RESULT
OWNER                TABLE_NAME                     CACHE
-------------------- ------------------------------ ---------------
JKSTILL              CHAIR                          FORCE
JKSTILL              HOLIDAY                        FORCE

```

Filtering out non-targeted SQL

```text
$ mrskew --where='$dur<1 and $sqlid eq q{9whtn601zbbm7}' trace-result-cache-limit-bind-set-no-hint/*.trc
CALL-NAME                     DURATION       %  CALLS      MEAN       MIN       MAX
---------------------------  ---------  ------  -----  --------  --------  --------
enq: CN - race with reg      22.509303   91.0%     51  0.441359  0.000084  0.802758
EXEC                          1.102527    4.5%  1,001  0.001101  0.000000  0.043125
reliable message              0.532439    2.2%    415  0.001283  0.000185  0.013910
SQL*Net message from client   0.494142    2.0%    951  0.000520  0.000240  0.012754
PARSE                         0.024834    0.1%     50  0.000497  0.000000  0.009712
latch: shared pool            0.018702    0.1%     11  0.001700  0.000033  0.009439
library cache pin             0.017393    0.1%      7  0.002485  0.000320  0.012905
log file sync                 0.012699    0.1%     13  0.000977  0.000076  0.003112
library cache load lock       0.008697    0.0%      2  0.004349  0.001599  0.007098
library cache lock            0.005271    0.0%      7  0.000753  0.000454  0.001280
9 others                      0.012124    0.0%  2,203  0.000006  0.000000  0.003660
---------------------------  ---------  ------  -----  --------  --------  --------
TOTAL (19)                   24.738131  100.0%  4,711  0.005251  0.000000  0.802758
```

Number of executions of test sql: 12,049,632

```text
$ tail -1 rc.log
SQL-RC-OPCOUNT-20230505152845: 236460
(oci) jkstill@prefect:~/oracle/result-cache
$ grep -c SQL-RC-OPCOUNT-20230505152845 rc.log
50
(oci) jkstill@prefect:~/oracle/result-cache
$ grep SQL-RC-OPCOUNT-20230505152845 rc.log | cut -f2 -d: | ./sum.py
12049632.0
```

## Predicted User Experience Time for an Example Trace File

Get Timestamp for beginning of parse of HOLIDAY query


```text
mrwhen --tim='3590034932935' "C:\Users\jaredstill\Documents\Tufts\work\tracing\10046\trace-fixed\TDFPRD1_ora_42088.trc"

2023-05-11T08:14:01.903343

0.192 seconds


Get timestamp for when the cursor handle was later reused by another SQL statement

mrwhen --tim='3593216139125' "C:\Users\jaredstill\Documents\Tufts\work\tracing\10046\trace-fixed\TDFPRD1_ora_42088.trc"

2023-05-11T09:07:03.109533

0.152 seconds

```

Now crop by these two timestamps and create a new tracefile.

```text

2023-06-02T23:17:36.334  Crop by datetime for given start and end time values

mrcrop --ofile='%d/%t-datetime/%b-%l%e' datetime --start-time='2023-05-11T08:14:01.903343' --end-time='2023-05-11T09:07:03.109533' "C:\Users\jaredstill\Documents\Tufts\work\tracing\10046\trace-fixed\TDFPRD1_ora_42088.trc"

C:\Users\jaredstill\Documents\Tufts\work\tracing\10046\trace-fixed\20230602231736-datetime\TDFPRD1_ora_42088-1975.trc

1.372 seconds

Total runtime for this SQL

$  mrskew  trace-fixed/20230602231736-datetime/TDFPRD1_ora_42088-1975.trc  --where='$sqlid eq "8j53dscbsbqmb" and $dur < 1'
CALL-NAME                     DURATION       %  CALLS      MEAN       MIN       MAX
---------------------------  ---------  ------  -----  --------  --------  --------
SQL*Net message from client  15.040135   97.4%    549  0.027396  0.006381  0.799028
EXEC                          0.276064    1.8%    600  0.000460  0.000395  0.000753
FETCH                         0.100206    0.6%    600  0.000167  0.000000  0.005085
PARSE                         0.012542    0.1%    600  0.000021  0.000010  0.000122
CLOSE                         0.005155    0.0%    600  0.000009  0.000004  0.000034
SQL*Net message to client     0.001327    0.0%    600  0.000002  0.000001  0.000005
---------------------------  ---------  ------  -----  --------  --------  --------
TOTAL (6)                    15.435429  100.0%  3,549  0.004349  0.000000  0.799028

```


How much SNMFC for this query?

```text

$  mrskew  trace-fixed/20230602231736-datetime/TDFPRD1_ora_42088-1975.trc  --where='$sqlid eq "8j53dscbsbqmb" and $dur < 1'
CALL-NAME                     DURATION       %  CALLS      MEAN       MIN       MAX
---------------------------  ---------  ------  -----  --------  --------  --------
SQL*Net message from client  15.040135   97.4%    549  0.027396  0.006381  0.799028
EXEC                          0.276064    1.8%    600  0.000460  0.000395  0.000753
FETCH                         0.100206    0.6%    600  0.000167  0.000000  0.005085
PARSE                         0.012542    0.1%    600  0.000021  0.000010  0.000122
CLOSE                         0.005155    0.0%    600  0.000009  0.000004  0.000034
SQL*Net message to client     0.001327    0.0%    600  0.000002  0.000001  0.000005
---------------------------  ---------  ------  -----  --------  --------  --------
TOTAL (6)                    15.435429  100.0%  3,549  0.004349  0.000000  0.799028

```

Mean SNMFC

```text

$  mrskew  trace-fixed/20230602231736-datetime/TDFPRD1_ora_42088-1975.trc  --rc=p10.rc --where='$sqlid eq "8j53dscbsbqmb" and $dur < 1' --where1='$nam =~ /message from client/'
RANGE {min ? e < max}           DURATION       %  CALLS      MEAN       MIN       MAX
-----------------------------  ---------  ------  -----  --------  --------  --------
 1.     0.000000     0.000001
 2.     0.000001     0.000010
 3.     0.000010     0.000100
 4.     0.000100     0.001000
 5.     0.001000     0.010000   1.716964   11.4%    206  0.008335  0.006381  0.009965
 6.     0.010000     0.100000  11.558294   76.8%    339  0.034095  0.010000  0.092107
 7.     0.100000     1.000000   1.764877   11.7%      4  0.441219  0.320278  0.799028
 8.     1.000000    10.000000
 9.    10.000000   100.000000
10.   100.000000 1,000.000000
11. 1,000.000000         +INF
-----------------------------  ---------  ------  -----  --------  --------  --------
TOTAL (11)                     15.040135  100.0%    549  0.027396  0.006381  0.799028

```

Average is 0.027 ms
15/549 = 0.0273

Only 6 sets of bind values, but executed 549 times.

```text

$  mrskew  trace-fixed/20230602231736-datetime/TDFPRD1_ora_42088-1975.trc  --rc=p10.rc --where='$sqlid eq "8j53dscbsbqmb" and $dur < 1' --where1='$nam =~ /message from client/'
RANGE {min ? e < max}           DURATION       %  CALLS      MEAN       MIN       MAX
-----------------------------  ---------  ------  -----  --------  --------  --------
 1.     0.000000     0.000001
 2.     0.000001     0.000010
 3.     0.000010     0.000100
 4.     0.000100     0.001000
 5.     0.001000     0.010000   1.716964   11.4%    206  0.008335  0.006381  0.009965
 6.     0.010000     0.100000  11.558294   76.8%    339  0.034095  0.010000  0.092107
 7.     0.100000     1.000000   1.764877   11.7%      4  0.441219  0.320278  0.799028
 8.     1.000000    10.000000
 9.    10.000000   100.000000
10.   100.000000 1,000.000000
11. 1,000.000000         +INF
-----------------------------  ---------  ------  -----  --------  --------  --------
TOTAL (11)                     15.040135  100.0%    549  0.027396  0.006381  0.799028

```

Predicted user experience time for this query using client result cache

Initial call to db, 27ms SNMFC * 6

27 * 6 = 162ms

Eliminated 543 SNMFC at 27ms per

27 * 543 = 14,661ms

This section of the app should run 14.661 seconds faster

Predicted user experience time: 0.774429 seconds

15.040135 - 14.661 = 0.379135

User experience for this query goes from 15 seconds to < 1 second.


