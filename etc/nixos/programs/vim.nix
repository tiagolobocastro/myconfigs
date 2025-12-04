{ config, pkgs, lib, ... }:
let
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
    elseif filereadable($pkgsVimPlug."/share/vim-plugins/vim-plug/plug.vim")
      source $pkgsVimPlug/share/vim-plugins/vim-plug/plug.vim
    endif
    if filereadable($myvim."/vim/vim.vim")
      source $myvim/vim/vim.vim
    endif
  '';
in
{
  environment.systemPackages = with pkgs; [
    (vim-full.customize {
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
