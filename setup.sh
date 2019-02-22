#!/bin/bash

# symlink files from within ./common into their correct places within ~/
echo -e "installing common dotfiles\n"
for item in ./common
do
    ln -snf $item ~
done

# clone and install vimfiles
echo -e "installing vimfiles\n"
git clone https://github.com/toozej/vimfiles.git ~/.vim
ln -s ~/.vim/vimrc ~/.vimrc
vim +PlugInstall +qall

echo -e "determining OS and distro, then installing related dotfiles\n"
if [ "$(uname)" == "Darwin" ]; then
    # ensure .oh-my-zsh is installed
    if [[ ! -d "~/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    fi
    
    # symlink files from within ./mac/ to their correct location
    echo -e "installing dotfiles for MacOS"
    for item in ./mac
    do
        ln -snf $item ~
    done

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # if running Gnome
    if [ "$(which gnome-shell)" == "/usr/bin/gnome-shell" ]; then
        echo -e "installing dotfiles for Gnome"
        # symlink files from within dotfiles/gui/gnome
        dconf load /org/gnome/terminal/legacy/profiles:/ < ./gui/gnome/gnome-terminal-profiles.dconf

    # if running i3-wm
    elif [ "$(which i3)" == "/usr/bin/i3" ]; then
        echo -e "installing dotfiles for i3-wm"
        for item in ./gui/i3
        do
            ln -snf $item ~
        done
    fi

    if [ "$(which gvim)" == "/usr/bin/vim.gtk3"] || [ "$(which gvim)" == "/usr/bin/vim.gnome" ]; then
        echo -e "installing dotfiles for gvim"
        ln -sf ./gui/.gvimrc ~/.gvimrc
    fi
fi


# reminders
echo -e "Don't forget to set secret things in the following files:\n"
echo -e "dotfiles/common/.gitconfig\n"
echo -e "~/.ssh/config\n"
