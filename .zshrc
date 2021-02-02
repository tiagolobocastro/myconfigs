# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	archlinux
	history-substring-search
	colored-man-pages
	zsh-autosuggestions
	zsh-syntax-highlighting
	git
)

bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

if [[ -z $ZSH ]]; then
    export ZSH="/home/tiago/.oh-my-zsh"
    source $ZSH/oh-my-zsh.sh
fi

# No shared history!
setopt no_share_history

# Non NixOS fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# NixOS fzf
if [ -n "${commands[fzf-share]}" ]; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi
# toggle preview window using '?'
export FZF_DEFAULT_OPTS="--bind '?:preview:cat {}' --preview-window hidden --preview 'cat {}'"

setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_BEEP

# Not great to hide erros though :(
source $ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme 2>/dev/null

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Manjaro only
POWERLEVEL9K_LINUX_MANJARO_ICON='\uF312'
if [ -e /home/tiago/.nix-profile/etc/profile.d/nix.sh ]; then . /home/tiago/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
export EDITOR=vim


# k8s mayastor workspace specific
alias ww=$'watch '
alias mk=$'sudo /home/tiago/git/myconfigs/maya/clean_pids.sh'
alias k=$'kubectl'
alias kk=$'kubectl -n mayastor'
alias p=$'kk get pods -o wide'
alias pp=$'k get pods -A'
alias dmm=$'kk describe pod -l app=moac | head'
alias fm=$'kk logs --follow -lapp=moac -c moac --tail=-1'
alias dms=$'kk get pods -l app=mayastor -o name | xargs -I % sh -c "kubectl -n mayastor describe % | head -n 4"'
alias dmn=$'kk get pods -l app=nats -o name | xargs -I % sh -c "kubectl -n mayastor describe % | head -n 4"'
alias dm=$'dmm;dmn;echo -e "\n";dms'
alias dmc=$'dmm;dmn'
alias wv=$'watch -d "kubectl -n mayastor describe msv | tail -n 30"'

alias fms='f(){
kk logs --follow $1 mayastor --tail=-1
unset -f f;
}; f'
alias ss='f(){
kk exec $1 -c mayastor --stdin --tty -- /sbin/sh 
unset -f f;
}; f'

alias nix-cargo='f(){
bin=$(/usr/bin/which cargo)
if [ $bin = "/home/tiago/.cargo/bin/cargo" ]; then
  ( cd ~/git/Mayastor && nix-shell --run "cargo $*" )
else
  $bin $* 
fi
unset -f f;
}; f'

export PATH=$PATH:~/git/myconfigs/maya:~/git/Mayastor/target/debug
export RUST_SRC_PATH=~/.rustup/toolchains/nightly-2020-07-26-x86_64-unknown-linux-gnu/lib/rustlib/src

