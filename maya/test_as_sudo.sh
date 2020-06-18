path=$(readlink -f "$1")
exe=${1##*/} 
pwd=$(readlink -f "$PWD")
if [[ 
    "$path" = $(readlink -f ~/git/Mayastor/target/*/deps/"$exe") ]]; then
    #"$path" = $(readlink -f ~/git/Mayastor/target/*/deps/mayastor) ]]; then
    #echo -e "\e[31m[sudo]\e[0m $@"
    sudo -E "$@"
else
    "$@"
fi

