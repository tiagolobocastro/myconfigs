#!/usr/bin/env bash

if [ -n "$N" ]; then
  FIO="fio-$N"
else
  FIO="fio"
fi

SZ=${SZ:-50m}

kubectl exec -it $FIO -- fio --name=benchtest --size="$SZ" --filename=/volume/test --direct=1 --rw=randrw --ioengine=libaio --bs=4k --iodepth=16 --numjobs=1 --time_based --runtime=60
