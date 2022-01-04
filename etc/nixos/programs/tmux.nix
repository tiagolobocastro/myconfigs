{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 10000;
    keyMode = "vi";
    terminal = "screen-256color";
    extraConfig = ''
      # So we can use transparency (needed by pretty zsh plugins)
      # set -g default-terminal screen-256color 

      # Le Mice
      setw -g mouse on

      # Use Alt-vim keys without prefix key to switch panes
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D 
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R

      # Use Alt-arrow keys without prefix key to switch panes
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # For vi copy mode bindings
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -i"
    '';
  };
  # Requirements
  environment.systemPackages = with pkgs; [
    xclip
  ];
}
