#!/bin/bash

DIR="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd  )"

# symlink files from within ./common into their correct places within ~/
echo -e "installing common dotfiles\n"
for item in `ls -a $DIR/common/`
do
    echo $item
    ln -snf $DIR/common/$item ~
done

echo -e "installing local binaries\n"
mkdir ~/bin
for item in `ls -a $DIR/bin/`
do
    echo $item
    ln -snf $DIR/bin/$item ~/bin/
done

echo -e "installing local Templates\n"
mkdir ~/Templates
for item in `ls -a $DIR/Templates/`
do
    echo $item
    ln -snf $DIR/Templates/$item ~/Templates/
done

# clone and install vimfiles
echo -e "installing vimfiles\n"
git clone https://github.com/toozej/vimfiles.git ~/.vim
ln -s ~/.vim/vimrc ~/.vimrc
# Pull most recent version of vim-plug plugin manager
curl https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim > ~/.vim/autoload/plug.vim
vim +PlugInstall +qall

echo -e "determining OS and distro, then installing related dotfiles\n"
if [ "$(uname)" == "Darwin" ]; then
    # ensure .oh-my-zsh is installed
    if [[ ! -d "~/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

        # install powerline patched fonts for use in iTerm
        sh -c "$(git clone https://github.com/powerline/fonts.git --depth=1 ~/dotfiles/mac/fonts)"
        sh -c "$(~/dotfiles/mac/fonts/install.sh && rm -rf ~/dotfiles/mac/fonts/)"
    fi

    # symlink oh-my-zsh theme in place
    ln -sf $DIR/mac/.oh-my-zsh/custom/themes/agnoster.zsh-theme ~/.oh-my-zsh/custom/themes/agnoster.zsh-theme
    # remove default .zshrc
    rm -f ~/.zshrc

    # copy karabiner config in place since the symlink gets overwritten when opening Karabiner-Elements 
    cp $DIR/mac/.config/karabiner/karabiner.json ~/.config/karabiner/karabiner.json

    # tell iTerm to use my default dynamic profile
    ln -sf $DIR/mac/iterm_default_profile.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/iterm_default_profile.json

    # symlink files from within ./mac/ to their correct location
    echo -e "installing dotfiles for MacOS"
    for item in `ls -a $DIR/mac/`
    do
        echo $item
        ln -snf $DIR/mac/$item ~
    done

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # if running i3-wm
    if [ "$(which i3)" == "/usr/bin/i3" ]; then
        echo -e "installing dotfiles for i3-wm"
        for item in `ls -a $DIR/gui/i3`
        do
            echo $item
            ln -snf $DIR/gui/i3/$item ~
        done
    fi

    if [ "$(which gvim)" == "/usr/bin/vim.gtk3" ] || [ "$(which gvim)" == "/usr/bin/vim.gnome" ]; then
        echo -e "installing dotfiles for gvim"
        ln -sf $DIR/gui/.gvimrc ~/.gvimrc
    fi
fi


# reminders
echo -e "\nDon't forget to set secret things in the following files:"
echo -e "~/.ssh/config\n"
