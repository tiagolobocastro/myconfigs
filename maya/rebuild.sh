set -ex

#export UUID=`uuidgen -r`
export UUID=be8d0ecf-ed31-497e-a554-56c47d401b4c

set +x
trap 'echo "$PS4$BASH_COMMAND"' DEBUG

#mctl create --children "aio:///tmp/disk1.img?blk_size=512" -s 100MiB $UUID
mctl create --children aio:///dev/ram0 -s 100MiB $UUID

mctl publish $UUID NBD

#echo "Tiago" | sudo tee /dev/nbd0 1>/dev/null
echo "Please run DiskTest: (on on your clipboard, you're welcome)"
echo "sudo ~/Downloads/DiskTest -e /dev/nbd0" | tee /dev/tty | tr -d '\n' | xclip -selection clipboard
sleep 10

mctl raw add_child_nexus '{"uuid": "'$UUID'", "uri": "aio:///dev/ram1", "rebuild": true }'
#mctl raw add_child_nexus '{"uuid": "'$UUID'", "uri": "aio:///dev/ram2", "rebuild": true }'
#mctl raw pause_rebuild '{"uuid": "'$UUID'", "uri": "aio:///dev/ram1"}'
#mctl raw pause_rebuild '{"uuid": "'$UUID'", "uri": "aio:///dev/ram1"}'
#mctl raw remove_child_nexus '{"uuid": "'$UUID'", "uri": "aio:///dev/ram2"}'
#mctl raw remove_child_nexus '{"uuid": "'$UUID'", "uri": "aio:///dev/ram1"}'

#echo "sudo xxd -s `numfmt 5M --from=iec` -l 8 /dev/ram1"

