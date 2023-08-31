
## Without Result Cache

Note how much time is required to process these files.

That is due to the large size of the trace files:

```text
$  du -sh trace/manual-20230830153724
15G     trace/manual-20230830153724
```

```text
$  time mrskew --where='$dur < 1' --thinktime=1.0 trace/manual-20230830153724/*.trc
CALL-NAME                         DURATION       %       CALLS      MEAN       MIN       MAX
---------------------------  -------------  ------  ----------  --------  --------  --------
SQL*Net message from client  18,681.266376   88.2%  18,253,315  0.001023  0.000169  0.063483
FETCH                         1,529.259314    7.2%  18,253,235  0.000084  0.000000  0.001037
EXEC                            902.449553    4.3%  18,253,275  0.000049  0.000000  0.005300
log file sync                    29.196260    0.1%         742  0.039348  0.005203  0.919955
SQL*Net message to client        19.594399    0.1%  18,253,335  0.000001  0.000000  0.011659
resmgr:cpu quantum               13.547097    0.1%      17,186  0.000788  0.000010  0.050825
cursor: pin S                     6.535397    0.0%       4,852  0.001347  0.001009  0.024545
ADR block file read               0.244540    0.0%          40  0.006114  0.000068  0.010877
library cache: mutex X            0.051236    0.0%          14  0.003660  0.000004  0.045247
buffer busy waits                 0.010421    0.0%          22  0.000474  0.000002  0.002212
11 others                         0.016493    0.0%         402  0.000041  0.000000  0.004231
---------------------------  -------------  ------  ----------  --------  --------  --------
TOTAL (21)                   21,182.171086  100.0%  73,036,418  0.000290  0.000000  0.919955

real    2m23.688s
user    2m7.184s
sys     0m16.332s
```


### Client Result Cache Stats

These statistics were collected after the sessions had completed the test, but before disconnecting from the database.

These results just serve as a control, because as you can see, there was no caching:

```text
SYS@lestrade/orcl.jks.com AS SYSDBA> @crc-stats
                                                                                    Block  Block         Create  Create  Delete Delete            Hash
                                                                                    Count  Count  Block   Count   Count   Count  Count     Find Bucket Invalidation
USERNAME               SID SERIAL# MACHINE                        OSUSER          Current    Max   Size Failure Success Invalid  Valid    Count  Count        Count
-------------------- ----- ------- ------------------------------ --------------- ------- ------ ------ ------- ------- ------- ------ -------- ------ ------------
JKSTILL                 37   60891 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                 39   18623 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                 43   12909 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                 44   45488 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                 46   36630 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                 50   52132 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                135   32647 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                142     484 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                152   44430 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                160    8770 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                175   62433 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                280    6238 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                284   15317 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                288   19910 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                296   62730 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                299   39149 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                393    3114 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                396   47784 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                407   44754 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
JKSTILL                410   15816 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0
SYS                    173   49359 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0

21 rows selected.

```

### The RC log

Each client kept track of the number of transactions performed, and wrote them out to a log file.

The results when no Client Result Cache is used:

```text
RC-20230830153724-20230703153724: 914535
RC-20230830153724-20230703153724: 917220
RC-20230830153724-20230703153724: 926713
RC-20230830153724-20230703153724: 912156
RC-20230830153724-20230703153724: 902782
RC-20230830153724-20230703153724: 903334
RC-20230830153724-20230703153724: 932879
RC-20230830153724-20230703153724: 926055
RC-20230830153724-20230703153724: 903622
RC-20230830153724-20230703153724: 908904
RC-20230830153724-20230703153724: 900843
RC-20230830153724-20230703153724: 921625
RC-20230830153724-20230703153724: 902627
RC-20230830153724-20230703153724: 910225
RC-20230830153724-20230703153724: 913760
RC-20230830153724-20230703153724: 907505
RC-20230830153724-20230703153724: 898638
RC-20230830153724-20230703153724: 916200
RC-20230830153724-20230703153724: 912823
RC-20230830153724-20230703153724: 920769
```

The total number of transactions is 18,253,215


## With Result Cache

Calculating the results from the trace files is much faster when Client Result Cache is used.

This is due to the much smaller size of the trace files:

```text
$  du -sh trace/force-20230830160541
54M     trace/force-20230830160541
```

```text
$  time mrskew --where='$dur < 1' --thinktime=1.0 trace/force-20230830160541/*.trc
CALL-NAME                                     DURATION       %    CALLS      MEAN       MIN       MAX
-------------------------------------------  ---------  ------  -------  --------  --------  --------
SQL*Net message from client                  47.964188   71.3%   59,741  0.000803  0.000174  0.045564
log file sync                                16.691914   24.8%      460  0.036287  0.005590  0.265968
EXEC                                          1.809924    2.7%   60,081  0.000030  0.000000  0.035868
FETCH                                         0.380603    0.6%   60,041  0.000006  0.000000  0.000844
enq: CN - race with txn                       0.060869    0.1%       16  0.003804  0.000678  0.007635
buffer busy waits                             0.059058    0.1%       58  0.001018  0.000001  0.010705
latch free                                    0.051608    0.1%       96  0.000538  0.000001  0.001328
latch: Change Notification Hash table latch   0.051364    0.1%       17  0.003021  0.000559  0.006974
SQL*Net message to client                     0.050983    0.1%   60,141  0.000001  0.000000  0.002998
enq: RC - Result Cache: Contention            0.047657    0.1%      398  0.000120  0.000002  0.002926
17 others                                     0.086466    0.1%      644  0.000134  0.000000  0.011544
-------------------------------------------  ---------  ------  -------  --------  --------  --------
TOTAL (27)                                   67.254634  100.0%  241,693  0.000278  0.000000  0.265968

real    0m0.471s
user    0m0.454s
sys     0m0.015s
```


### Client Result Cache Stats

These statistics were collected after the sessions had completed the test, but before disconnecting from the database.

```text
SYS@lestrade/orcl.jks.com AS SYSDBA> @crc-stats

                                                                                    Block  Block         Create  Create  Delete Delete            Hash
                                                                                    Count  Count  Block   Count   Count   Count  Count     Find Bucket Invalidation
USERNAME               SID SERIAL# MACHINE                        OSUSER          Current    Max   Size Failure Success Invalid  Valid    Count  Count        Count
-------------------- ----- ------- ------------------------------ --------------- ------- ------ ------ ------- ------- ------- ------ -------- ------ ------------
JKSTILL                 32   11668 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6319978   1024            0
JKSTILL                 33   44549 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6238234   1024            0
JKSTILL                 39   64812 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6293694   1024            0
JKSTILL                 44   21994 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6257028   1024            0
JKSTILL                 47   33300 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6237394   1024            0
JKSTILL                 50   12436 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6282581   1024            0
JKSTILL                135    6758 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6254996   1024            0
JKSTILL                152   63737 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6254007   1024            0
JKSTILL                160   49626 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6251309   1024            0
JKSTILL                169   19117 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6311561   1024            0
JKSTILL                175   54689 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6332953   1024            0
JKSTILL                280   29671 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6250219   1024            0
JKSTILL                282   52605 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6285713   1024            0
JKSTILL                284   14842 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6305114   1024            0
JKSTILL                288   60461 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6283873   1024            0
JKSTILL                290   28698 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6281226   1024            0
JKSTILL                393   44619 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6253926   1024            0
JKSTILL                396   52145 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6245423   1024            0
JKSTILL                404   29082 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6288019   1024            0
JKSTILL                422   11804 poirot.jks.com                 jkstill            3072   4096    256       0    2982       0      0  6272817   1024            0
SYS                    173   49359 poirot.jks.com                 jkstill             128   4096    256       0       0       0      0        0   1024            0

21 rows selected.
```

### The RC log

Each client kept track of the number of transactions performed, and wrote them out to a log file.

The results when Client Result Cache is used:

```text
RC-20230830160541-20230703160541: 6623000
RC-20230830160541-20230703160541: 6554524
RC-20230830160541-20230703160541: 6599641
RC-20230830160541-20230703160541: 6532840
RC-20230830160541-20230703160541: 6557806
RC-20230830160541-20230703160541: 6584949
RC-20230830160541-20230703160541: 6581603
RC-20230830160541-20230703160541: 6557942
RC-20230830160541-20230703160541: 6551515
RC-20230830160541-20230703160541: 6611476
RC-20230830160541-20230703160541: 6549693
RC-20230830160541-20230703160541: 6573529
RC-20230830160541-20230703160541: 6559698
RC-20230830160541-20230703160541: 6586878
RC-20230830160541-20230703160541: 6590372
RC-20230830160541-20230703160541: 6544219
RC-20230830160541-20230703160541: 6612925
RC-20230830160541-20230703160541: 6593495
RC-20230830160541-20230703160541: 6561719
RC-20230830160541-20230703160541: 6639638
```

The total number of transactions is 131,567,462

This is 7.2 times more transactions than were accomplished without Client Result Cache.

### 60 Second SQL*Net Message From Client

From here on the term SNMFC will be used.

```text
$  time mrskew --where='$dur >= 1 and $dur < 65' --thinktime=1.0 --group='qq{$basename:$line}'   trace/force-20230830160541/*.trc
qq{$basename:$line}                                             DURATION       %  CALLS       MEAN        MIN        MAX
---------------------------------------------------------  -------------  ------  -----  ---------  ---------  ---------
orcl_ora_30561_RC-20230830160541-20230703160541.trc:58081      60.002586    0.3%      1  60.002586  60.002586  60.002586
orcl_ora_30574_RC-20230830160541-20230703160541.trc:57602      60.002578    0.3%      1  60.002578  60.002578  60.002578
orcl_ora_30572_RC-20230830160541-20230703160541.trc:57550      60.002518    0.3%      1  60.002518  60.002518  60.002518
orcl_ora_30559_RC-20230830160541-20230703160541.trc:58275      60.002420    0.3%      1  60.002420  60.002420  60.002420
orcl_ora_30572_RC-20230830160541-20230703160541.trc:58278      60.002338    0.3%      1  60.002338  60.002338  60.002338
orcl_ora_30559_RC-20230830160541-20230703160541.trc:57791      60.002131    0.3%      1  60.002131  60.002131  60.002131
orcl_ora_30566_RC-20230830160541-20230703160541.trc:53907      60.002048    0.3%      1  60.002048  60.002048  60.002048
orcl_ora_30566_RC-20230830160541-20230703160541.trc:54640      60.002029    0.3%      1  60.002029  60.002029  60.002029
orcl_ora_30537_RC-20230830160541-20230703160541.trc:55696      60.002002    0.3%      1  60.002002  60.002002  60.002002
orcl_ora_30563_RC-20230830160541-20230703160541.trc:55373      60.001989    0.3%      1  60.001989  60.001989  60.001989
370 others                                                 22,200.553583   97.4%    370  60.001496  60.001281  60.001951
---------------------------------------------------------  -------------  ------  -----  ---------  ---------  ---------
TOTAL (380)                                                22,800.576222  100.0%    380  60.001516  60.001281  60.002586

real    0m0.308s
user    0m0.294s
sys     0m0.013s
```

There is a reason for checking the range of 1-65 seconds.  The value of `client_result_cache_lag` was set to  60000, which is measured in milliseconds.

Every 60 seconds, the oracle client is checking for any updates to the tables where results are being cached at the client.


Consider just one of the trace files:

```text
$  mrskew --top=0 --sort=1a --where='$dur >= 1 and $dur < 65' --thinktime=1.0 --group='qq{$basename:$line}'   trace/force-20230830160541/orcl_ora_30561_RC-20230830160541-20230703160541.trc
qq{$basename:$line}                                            DURATION       %  CALLS       MEAN        MIN        MAX
---------------------------------------------------------  ------------  ------  -----  ---------  ---------  ---------
orcl_ora_30561_RC-20230830160541-20230703160541.trc:53959     60.001474    5.3%      1  60.001474  60.001474  60.001474
orcl_ora_30561_RC-20230830160541-20230703160541.trc:54208     60.001473    5.3%      1  60.001473  60.001473  60.001473
orcl_ora_30561_RC-20230830160541-20230703160541.trc:54450     60.001613    5.3%      1  60.001613  60.001613  60.001613
orcl_ora_30561_RC-20230830160541-20230703160541.trc:54692     60.001452    5.3%      1  60.001452  60.001452  60.001452
orcl_ora_30561_RC-20230830160541-20230703160541.trc:54934     60.001459    5.3%      1  60.001459  60.001459  60.001459
orcl_ora_30561_RC-20230830160541-20230703160541.trc:55176     60.001465    5.3%      1  60.001465  60.001465  60.001465
orcl_ora_30561_RC-20230830160541-20230703160541.trc:55418     60.001504    5.3%      1  60.001504  60.001504  60.001504
orcl_ora_30561_RC-20230830160541-20230703160541.trc:55660     60.001584    5.3%      1  60.001584  60.001584  60.001584
orcl_ora_30561_RC-20230830160541-20230703160541.trc:55902     60.001390    5.3%      1  60.001390  60.001390  60.001390
orcl_ora_30561_RC-20230830160541-20230703160541.trc:56144     60.001480    5.3%      1  60.001480  60.001480  60.001480
orcl_ora_30561_RC-20230830160541-20230703160541.trc:56386     60.001525    5.3%      1  60.001525  60.001525  60.001525
orcl_ora_30561_RC-20230830160541-20230703160541.trc:56628     60.001404    5.3%      1  60.001404  60.001404  60.001404
orcl_ora_30561_RC-20230830160541-20230703160541.trc:56870     60.001481    5.3%      1  60.001481  60.001481  60.001481
orcl_ora_30561_RC-20230830160541-20230703160541.trc:57112     60.001385    5.3%      1  60.001385  60.001385  60.001385
orcl_ora_30561_RC-20230830160541-20230703160541.trc:57354     60.001557    5.3%      1  60.001557  60.001557  60.001557
orcl_ora_30561_RC-20230830160541-20230703160541.trc:57596     60.001628    5.3%      1  60.001628  60.001628  60.001628
orcl_ora_30561_RC-20230830160541-20230703160541.trc:57838     60.001434    5.3%      1  60.001434  60.001434  60.001434
orcl_ora_30561_RC-20230830160541-20230703160541.trc:58081     60.002586    5.3%      1  60.002586  60.002586  60.002586
orcl_ora_30561_RC-20230830160541-20230703160541.trc:58323     60.001456    5.3%      1  60.001456  60.001456  60.001456
---------------------------------------------------------  ------------  ------  -----  ---------  ---------  ---------
TOTAL (19)                                                 1,140.029350  100.0%     19  60.001545  60.001385  60.002586
```

If I pick one of the SNMFC lines, and get the lines following, we can see that the client is consulting with the database to see if the cache needs to be synced.

The following has about 200 lines elided in the name of brevity:

```text
$ mrskew --sort=1a --top=0 --alldep --name=:all -where='$line >= 55660 and $line <= 55660+230' --group='qq{$line:$text}' -gl='LINE:TEXT'   trace/force-20230830160541/orcl_ora_30561_RC-20230830160541-20230703160541.trc

LINE:TEXT                                                                                                                                    DURATION       %  CALLS       MEAN        MIN        MAX
------------------------------------------------------------------------------------------------------------------------------------------  ---------  ------  -----  ---------  ---------  ---------
55660:WAIT #140661336887528: nam='SQL*Net message from client' ela= 60001584 driver id=1952673792 #bytes=1 p3=0 obj#=-1 tim=14522473254855  60.001584   99.9%      1  60.001584  60.001584  60.001584
55661:BINDS #140661335857648:                                                                                                                                                                        
55662:                                                                                                                                                                                               
55663: Bind#0                                                                                                                                                                                        
55664:  oacdty=01 mxl=128(49) mxlc=00 mal=00 scl=00 pre=00                                                                                                                                           
55665:  oacflg=00 fl2=0000 frm=01 csi=873 siz=152 off=0                                                                                                                                              
55666:  kxsbbbfp=7fee4504b8e8  bln=128  avl=10  flg=05                                                                                                                                               
55667:  value="Block Size"                                                                                                                                                                           
55668: Bind#1                                                                                                                                                                                        
55669:  oacdty=02 mxl=22(22) mxlc=00 mal=00 scl=00 pre=00                                                                                                                                            
55670:  oacflg=00 fl2=0000 frm=00 csi=00 siz=0 off=128                                                                                                                                               
55671:  kxsbbbfp=7fee4504b968  bln=22  avl=03  flg=01                                                                                                                                                
55672:  value=256                                                                                                                                                                                    
55673: Bind#2                                                                                                                                                                                        
55674:  oacdty=02 mxl=22(03) mxlc=00 mal=00 scl=00 pre=00                                                                                                                                            
55675:  oacflg=10 fl2=0000 frm=00 csi=00 siz=24 off=0                                                                                                                                                
55676:  kxsbbbfp=7fee4a41ae68  bln=22  avl=03  flg=09                                                                                                                                                
55677:  value=5497                                                                                                                                                                                   
55678: Bind#3                                                                                                                                                                                        
55679:  oacdty=02 mxl=22(22) mxlc=00 mal=00 scl=00 pre=00                                                                                                                                            
55680:  oacflg=00 fl2=0000 frm=00 csi=00 siz=24 off=0                                                                                                                                                
55681:  kxsbbbfp=7fee4504b8b8  bln=22  avl=02  flg=05                                                                                                                                                
55682:  value=1                                                                                                                                                                                      
55683:BINDS #140661335857648:                                                                                                                                                                        
...
55876: Bind#3                                                                                                                                                                                        
55877:  oacdty=02 mxl=22(22) mxlc=00 mal=00 scl=00 pre=00                                                                                                                                            
55878:  oacflg=00 fl2=0000 frm=00 csi=00 siz=24 off=0                                                                                                                                                
55879:  kxsbbbfp=7fee4504b8b8  bln=22  avl=02  flg=05                                                                                                                                                
55880:  value=10                                                                                                                                                                                     
55881:EXEC #140661335857648:c=964,e=964,p=0,cr=15,cu=11,mis=0,r=10,dep=1,og=4,plh=1807565214,tim=14522473255889                              0.000964    0.0%      1   0.000964   0.000964   0.000964
55882:WAIT #140661335857648: nam='log file sync' ela= 40174 buffer#=158 sync scn=38725244627216 p3=0 obj#=-1 tim=14522473296109              0.040174    0.1%      1   0.040174   0.040174   0.040174
55883:BINDS #140661336887528:                                                                                                                                                                        
55884:                                                                                                                                                                                               
55885: Bind#0                                                                                                                                                                                        
55886:  oacdty=01 mxl=32(30) mxlc=00 mal=00 scl=00 pre=00                                                                                                                                            
55887:  oacflg=05 fl2=1000000 frm=01 csi=873 siz=160 off=0                                                                                                                                           
55888:  kxsbbbfp=7fee45046890  bln=32  avl=04  flg=05                                                                                                                                                
55889:  value="1742"                                                                                                                                                                                 
55890: Bind#1                                                                                                                                                                                        
------------------------------------------------------------------------------------------------------------------------------------------  ---------  ------  -----  ---------  ---------  ---------
TOTAL (231)                                                                                                                                 60.042722  100.0%      3  20.014241   0.000964  60.001584




