
sudo dd if=/dev/zero of=/dev/ram1 conv=nocreat,notrunc 2>/dev/null
mayastor-client pool create ahoy /dev/ram1
mayastor-client replica create ahoy replica1 --size 40MiB
mayastor-client replica share replica1 iscsi
mayastor-client replica create ahoy replica2 --size 40MiB
mayastor-client replica share replica2 nvmf
mayastor-client replica list

