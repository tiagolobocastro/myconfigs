mctl create --children aio:///dev/ram0 -s 10MiB `uuidgen -r`

export UUID=`mctl list | jq ".nexus_list[0].uuid" | tr -d '"'`

mctl publish $UUID

mctl raw add_child_nexus '{"uuid": "'$UUID'", "uri": "aio:///dev/ram1"}'

mctl raw start_rebuild '{"uuid": "'$UUID'", "uri": "aio:///dev/ram1"}'

