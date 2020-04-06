
if [ "$EUID" -ne 0 ]; then
  #echo -e "\e[31mRestarting script as root!\e[0m\n\n"
  sudo -E $(readlink -f $0) $@
  exit
fi

SIGNAL=${1:-KILL}

all=$(ps aux | grep Mayastor\/target | grep -v 'sudo -E')
lcount=$(echo "$all" | wc -l)
echo "$all" | head -n $(($lcount-1)) | awk '{print $2}' | xargs -I % kill -$SIGNAL %
