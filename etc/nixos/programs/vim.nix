{ config, pkgs, lib, ... }:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
  myplugins = with pkgs.vimPlugins; {
    start = [ vim-lastplace vim-plug ];
    # manually loadable by calling `:packadd $plugin-name`
    opt = [
      vim-nix
      pkgs.fzf
      fzf-vim
      ack-vim
      vim-airline
      vim-airline-themes
      nerdtree
    ];
  };
  customRC = ''
    set backspace=indent,eol,start
    let $pkgsVimPlug = '${pkgs.vimPlugins.vim-plug}'
    let $myvim = '/home/tiago/git/myconfigs'
    let g:vimplugged = '/home/tiago/.vim/plugged'
    if filereadable($pkgsVimPlug."/plug.vim")
      source $pkgsVimPlug/plug.vim
    endif
    if filereadable($myvim."/vim/vim.vim")
      source $myvim/vim/vim.vim
    endif
  '';
in
{
  environment.systemPackages = with pkgs; [
    ((vim_configurable.override { python = python3; }).customize {
      name = "vim";
      vimrcConfig.packages.myplugins = myplugins;
      vimrcConfig.customRC = customRC;
    })
    (neovim.override {
      configure = {
        customRC = customRC;
        packages.myVimPackage = myplugins;
      };
    })

    # used by vim plugins
    nodejs
    yarn
    fzf
    silver-searcher
  ];
}
