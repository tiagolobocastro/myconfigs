set -ex

#export UUID=`uuidgen -r`
export UUID=be8d0ecf-ed31-497e-a554-56c47d401b4c

set +x
trap 'echo "$PS4$BASH_COMMAND"' DEBUG

mctl create --children aio:///dev/ram0 -s 100MiB $UUID

mctl publish $UUID NBD

echo "Tiago" | sudo tee /dev/nbd0 1>/dev/null

mctl raw add_child_nexus '{"uuid": "'$UUID'", "uri": "aio:///dev/ram1"}'

mctl raw start_rebuild '{"uuid": "'$UUID'", "uri": "aio:///dev/ram1"}'

echo "sudo xxd -s `numfmt 5M --from=iec` -l 8 /dev/ram1"
