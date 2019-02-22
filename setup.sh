#!/bin/bash

echo -e "installing common dotfiles\n"
# symlink files from within dotfiles/common into their correct places within ~/

# clone and install vimfiles
echo -e "installing vimfiles\n"
git clone https://github.com/toozej/vimfiles.git ~/.vim
ln -s ~/.vim/vimrc ~/.vimrc
vim +PlugInstall +qall

echo -e "determining OS and distro, then installing related dotfiles\n"
if [ "$(uname)" == "Darwin" ]; then
    # symlink files from within ./mac/ to their correct location

    # ensure .oh-my-zsh is installed

    # symlink ./mac/.oh-my-zsh/custom/themes/agnoster.zsh-theme to ~/.oh-my-zsh/.custom/themes/agnoster.zsh-theme

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
 

    # if running Gnome
    if [ "$(which gnome-shell)" == "/usr/bin/gnome-shell" ]; then
        echo -e "installing dotfiles for Gnome"
        # symlink files from within dotfiles/gui/gnome
        dconf load /org/gnome/terminal/legacy/profiles:/ < ./gui/gnome/gnome-terminal-profiles.dconf

    # if running i3-wm
    elif [ "$(which i3)" == "/usr/bin/i3" ]; then
        echo -e "installing dotfiles for i3-wm"
        # symlink files from within dotfiles/gui/i3
    fi

    if [ "$(which gvim)" == "/usr/bin/vim.gtk3"] || [ "$(which gvim)" == "/usr/bin/vim.gnome" ]; then
        echo -e "installing dotfiles for gvim"
        # symlink files from dotfiles/gui/.gvimrc to ~/.gvimrc
fi


# reminders
echo -e "Don't forget to set secret things like in the following files:\n"
echo -e "dotfiles/common/.gitconfig\n"
echo -e "~/.ssh/config\n"
