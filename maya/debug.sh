if [ "$EUID" -ne 0 ]; then
  #echo -e "\e[31mRestarting script as root!\e[0m\n\n"
  sudo -E $(readlink -f $0) $@
  exit
fi

while [ 1 ]
do 
  # simply gets the first one...
  process=$(ps a -o pid --no-headers | xargs -I % readlink -f /proc/%/exe | grep Mayastor\/target | grep -v grep | head -n 1)
  pid=$(pidof "$process")

  if [ "$pid" != "" ]; then
    rust-gdb -p $pid
    exit 0
  fi
done
