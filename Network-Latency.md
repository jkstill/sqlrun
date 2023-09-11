
Set a latency of 6ms

This simulates ~ 120 miles distance from client to server

  tc qdisc add dev enp0s3 root netem delay 6ms 1ms 25%

To change later, use 'change'

  tc qdisc change dev enp0s3 root netem delay 6ms 1ms 25%

see: https://wintelguy.com/wanlat.html


