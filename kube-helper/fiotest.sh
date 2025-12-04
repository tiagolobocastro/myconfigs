#!/usr/bin/env bash

if [ -n "$N" ]; then
  FIO="fio-$N"
else
  FIO="fio"
fi

SZ=${SZ:-50m}
BLK=${BLK:-"0"}

if [ "$BLK" = "1" ]; then
  FILE="/dev/xvda"
else
  FILE="/volume/test"
fi

kubectl exec -it $FIO -- fio --name=benchtest --filename=$FILE --direct=1 --rw=randrw --ioengine=libaio --bs=4k --iodepth=16 --numjobs=1 --time_based --runtime=60
