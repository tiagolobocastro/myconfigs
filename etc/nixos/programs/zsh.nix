{ config, pkgs, lib, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellInit = ''
      export EDITOR=vim
      export LIBVIRT_DEFAULT_URI=qemu:///system
      export REAL_PAGER=$PAGER
      export NIX_PAGER=cat
    '';
    promptInit =
      "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    ohMyZsh.enable = true;
    ohMyZsh.plugins = [
      "sudo"
      "docker"
      "history-substring-search"
      "git"
      "vi-mode"
      "kubectl"
      "colored-man-pages"
      "systemd"
      "man"
      "command-not-found"
      "extract"
    ];
  };
}
