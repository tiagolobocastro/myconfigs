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
    sudo
    docker
    vi-mode
    systemd
    command-not-found
    kubectl
    extract
    man
)

export ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

bindkey -e
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

if [[ -z $ZSH ]]; then
    export ZSH="$HOME/.oh-my-zsh"
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
HISTSIZE=100000

# Not great to hide erros though :(
source $ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme 2>/dev/null

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [ -n "$IN_NIX_SHELL" ]; then
  [[ ! -f ~/.p10k-nix-shell.zsh ]] || source ~/.p10k-nix-shell.zsh
  POWERLEVEL9K_LINUX_NIXOS_ICON='\uE619'
else
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi

# Manjaro only
POWERLEVEL9K_LINUX_MANJARO_ICON='\uF312'
if [ -e /home/tiago/.nix-profile/etc/profile.d/nix.sh ]; then . /home/tiago/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
export EDITOR=vim


# k8s mayastor workspace specific
alias ww=$'watch '
alias mk=$'sudo /home/tiago/git/myconfigs/maya/clean_pids.sh'
alias k=$'kubectl'
alias kb=$'kubectl -n bolt'
alias km=$'kubectl -n mayastor'
alias p=$'kb get pods -o wide'
alias pp=$'k get pods -A'
alias dms=$'kb get pods -l app=bolt -o name | xargs -I % sh -c "kubectl -n bolt describe % | head -n 4"'
alias dm=$'dmm;dmn;echo -e "\n";dms'
alias dmc=$'dmm;dmn'
alias ks='kubectl -n kube-system'

alias fms='f(){
km logs --follow $1 bolt--tail=-1
unset -f f;
}; f'
alias ss='f(){
km exec $1 -c mayastor --stdin --tty -- /sbin/sh 
unset -f f;
}; f'

export PATH=$PATH:~/git/myconfigs/maya:/home/tiago/git/mayastor/controller/target/debug:/home/tiago/git/mayastor/extensions/target/debug:/home/tiago/git/mayastor/io-engine/target/debug

alias ls='exa '

eval "$(direnv hook zsh)"
