#!/bin/sh

# load nvme and nvme-tcp kernel modules
sudo modprobe nvme; sudo modprobe nvmet; sudo modprobe nvme-tcp; sudo modprobe nvmet-tcp

# load the fake null block device that just fakes R/W IO -> BIO
sudo insmod ~/git/linux-stable/drivers/block/null_blk.ko nr_devices=1 queue_mode=0 bs=4096

# preload huge pages for the sdk
echo "To allocate spdk huge pages:
  sudo HUGEMEM=4096 ~/git/spdk/scripts/setup.sh"

echo "To start the kernel target with loop:
  sudo nvmetcli restore ~/nvme/nvmet-loop.json"

echo "To start the kernel target with null:
  sudo nvmetcli restore ~/nvme/nvmet-tcp-null.json"

echo "To start the kernel target with malloc: 
  sudo modprobe brd rd_size=256000
  sudo nvmetcli restore ~/nvme/nvmet-tcp-malloc.json"

echo "To discover nvme targets:
  sudo nvme discover -t tcp -a 127.0.0.1 -s 4420"
echo "To connect/disconnect:
  sudo nvme connect -t tcp -a 127.0.0.1 -s 4420 -n testnqn
  sudo nvme disconnect /dev/nvme1"
