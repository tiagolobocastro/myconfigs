{ config, lib, pkgs, ... }:

let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
in
{
  environment.systemPackages = with pkgs; [
    # Basic
    wget git nixfmt manpages unzip tree
    ((vim_configurable.override { python = python3; }).customize{
      name = "vim";
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [ vim-lastplace vim-plug ];
        # manually loadable by calling `:packadd $plugin-name`
        opt = [ vim-nix fzf fzf-vim ack-vim vim-airline vim-airline-themes nerdtree ];
      };
      vimrcConfig.customRC = ''
        set backspace=indent,eol,start
        let $pkgsVimPlug = '${pkgs.vimPlugins.vim-plug}'
        let $myvim = '/home/tiago/git/myconfigs'
        let g:vimplugged = '/home/tiago/.vim/plugged'
        if filereadable($pkgsVimPlug."/share/vim-plugins/vim-plug/plug.vim")
          source $pkgsVimPlug/share/vim-plugins/vim-plug/plug.vim
        endif
        if filereadable($myvim."/vim/vim.vim")
          source $myvim/vim/vim.vim
        endif
      '';
    }) neovim
    nodejs yarn fzf silver-searcher # used by vim plugins

    # Sync Data 
    onedrive 

    bitwarden

    ntfs3g

    teamviewer

    latencytop
  ];

  services.teamviewer.enable = false;
  services.onedrive.enable = false;
}
