set -e

mctl create --children aio:///dev/ram0 -s 10MiB `uuidgen -r`

export UUID=`mctl list | jq ".nexus_list[0].uuid" | tr -d '"'`

mctl publish $UUID NBD

echo "Tiago" | sudo tee /dev/nbd0 1>/dev/null

mctl raw add_child_nexus '{"uuid": "'$UUID'", "uri": "aio:///dev/ram1"}'

mctl raw start_rebuild '{"uuid": "'$UUID'", "uri": "aio:///dev/ram1"}'

echo "sudo xxd -s `numfmt 5M --from=iec` -l 8 /dev/ram1"
