#!/bin/bash

DIR="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd  )"

# symlink files from within ./common into their correct places within ~/
echo -e "installing common dotfiles\n"
for item in $(ls -a "${DIR}"/common/)
do
    echo "${item}"
    ln -snf "${DIR}"/common/"${item}" ~
done
echo -e "setting correct permissions on ~/.gnupg\n"
chmod 0700 ~/.gnupg
echo -e "enabling git-template dir\n"
git config --global init.templateDir ~/.git-template

echo -e "installing ~/.config/ subdirectories and configs\n"
mkdir ~/.config/
for item in $(ls -a "${DIR}"/config/)
do
    echo "${item}"
    ln -snf "${DIR}"/config/"${item}" ~/.config/
done

echo -e "installing local binaries\n"
mkdir ~/bin
for item in $(ls -a "${DIR}"/bin/)
do
    echo "${item}"
    ln -snf "${DIR}"/bin/"${item}" ~/bin/
done
curl https://raw.githubusercontent.com/toozej/git-peak-extended/main/git-peak-extended > ~/bin/git-peak-extended && chmod ug+x ~/bin/git-peak-extended
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh > ~/.git-prompt.sh

echo -e "installing local Templates\n"
mkdir ~/Templates
for item in $(ls -a "${DIR}"/Templates/)
do
    echo "${item}"
    ln -snf "${DIR}"/Templates/"${item}" ~/Templates/
done

# clone and install vimfiles
echo -e "installing vimfiles\n"
git clone https://github.com/toozej/vimfiles.git ~/.vim
ln -s ~/.vim/vimrc ~/.vimrc
# Pull most recent version of vim-plug plugin manager
curl https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim > ~/.vim/autoload/plug.vim
/usr/bin/vim +PlugInstall +qall

echo -e "determining OS and distro, then installing related dotfiles\n"
if [ "$(uname)" == "Darwin" ]; then
    # ensure .oh-my-zsh is installed
    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh

        # install powerline patched fonts for use in iTerm
        git clone https://github.com/powerline/fonts.git --depth=1 ~/dotfiles/mac/fonts
        ~/dotfiles/mac/fonts/install.sh && rm -rf ~/dotfiles/mac/fonts/
    fi

    # symlink oh-my-zsh theme in place
    ln -sf "${DIR}"/mac/.oh-my-zsh/custom/themes/agnoster.zsh-theme ~/.oh-my-zsh/custom/themes/agnoster.zsh-theme
    # remove default .zshrc
    rm -f ~/.zshrc

    # copy karabiner config in place since the symlink gets overwritten when opening Karabiner-Elements 
    cp "${DIR}"/mac/.config/karabiner/karabiner.json ~/.config/karabiner/karabiner.json

    # tell iTerm to use my default dynamic profile
    ln -sf "${DIR}"/mac/iterm_default_profile.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/iterm_default_profile.json

    # symlink files from within ./mac/ to their correct location
    echo -e "installing dotfiles for MacOS"
    for item in $(ls -a "${DIR}"/mac/)
    do
        echo "${item}"
        ln -snf "${DIR}"/mac/"${item}" ~
    done

elif [ "$(uname -s)" == "Linux" ]; then
    if [ "$(command -v pycharm-community)" == "/usr/bin/pycharm-community" ]; then
        ln -s /usr/bin/pycharm-community /usr/local/bin/pycharm
    fi

    # if running i3-wm
    if [ "$(command -v i3)" == "/usr/bin/i3" ]; then
        echo -e "installing dotfiles for i3-wm"
        for item in $(ls -a "${DIR}"/gui/i3)
        do
            echo "${item}"
            ln -snf "${DIR}"/gui/i3/"${item}" ~
        done
    fi

    if [ "$(command -v gvim)" == "/usr/bin/vim.gtk3" ] || [ "$(command -v gvim)" == "/usr/bin/vim.gnome" ]; then
        echo -e "installing dotfiles for gvim"
        ln -sf "${DIR}"/gui/.gvimrc ~/.gvimrc
    fi
fi


# reminders
echo -e "\nDon't forget to set secret things in the following files:"
echo -e "${HOME}/.ssh/config\n"
