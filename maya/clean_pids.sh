
if [ "$EUID" -ne 0 ]; then
  #echo -e "\e[31mRestarting script as root!\e[0m\n\n"
  sudo -E $(readlink -f $0) $@
  exit
fi

SIGNAL=${1:-KILL}

# grep -v grep ignores the grep itself though there must be a 
# nicer way of doing this...
all=$(ps -u | grep Mayastor\/target | grep -v grep)
echo "$all" | awk '{print $2}' | xargs -I % kill -$SIGNAL %
