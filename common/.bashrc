# /etc/bash/bashrc
#
PS1_art="$>"

# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.

if [[ $- != *i* ]] ; then
    # Shell is non-interactive.  Be done now!
    return
fi

# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.  #65623
# http://cnswww.cns.cwru.edu/~chet/bash/FAQ (E11)
shopt -s checkwinsize

# History management.
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it
# Does magic that makes Ctrl+S cycle forwards through history.
stty -ixon
# include timestamp in shell history
export HISTTIMEFORMAT="%Y-%m-%d %T "

# Change the window title of X terminals 
case ${TERM} in
    xterm*|rxvt*|Eterm|aterm|kterm|gnome*|interix)
        PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~}\007"'
        ;;
    screen)
        PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/$HOME/~}\033\\"'
        ;;
esac

use_color=true

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
    && type -P dircolors >/dev/null \
    && match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
    # Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
    if type -P dircolors >/dev/null ; then
        if [[ -f ~/.dir_colors ]] ; then
            eval $(dircolors -b ~/.dir_colors)
        elif [[ -f /etc/DIR_COLORS ]] ; then
            eval $(dircolors -b /etc/DIR_COLORS)
        fi
    fi

    if [[ ${EUID} == 0 ]] ; then
        PS1="\[\e[1;31m\]\u@\h\[\033[01;34m\] \W \\$ \[\033[00m\]\[\e[1;31m\] "
    else
        # Source git-prompt script
        if [ -f ~/.git-prompt.sh ]; then
            source ~/.git-prompt.sh
            export GIT_PS1_SHOWDIRTYSTATE=1
        fi
        PS1="\[\033[01;32m\]\h\[\033[01;34m\] \t \w\$(__git_ps1) ${PS1_art}\[\033[00m\] "
    fi

    if [ "$(uname)" != "Darwin" ]; then
        alias ls='ls --color=auto'
        alias grep='grep --color=auto'
    fi
else
    if [[ ${EUID} == 0 ]] ; then
        # show root@ when we don't have colors
        PS1='\u@\h \W \& '
    else
        PS1='\h \t \w ${PS1_art}'
    fi
fi

LS_COLORS='di=1;35' ; export LS_COLORS

#setup ssh agent for non-root logins
if [[ ${EUID} -ne 0 ]] ; then
    SSH_ENV="$HOME/.ssh/environment"

    function start_agent {
        echo "Initialising new SSH agent..."
        /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
        echo succeeded
        chmod 600 "${SSH_ENV}"
         . "${SSH_ENV}" > /dev/null
        /usr/bin/ssh-add;
    }

    # Source SSH settings, if applicable
    if [ -f "${SSH_ENV}" ]; then
         . "${SSH_ENV}" > /dev/null
        #ps ${SSH_AGENT_PID} doesn't work under cywgin
        ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
            start_agent;
        }
    else
        start_agent;
    fi
fi

# Invoke GnuPG-Agent the first time we login.
if [[ ${EUID} -ne 0 ]] ; then
    # Does `~/.gpg-agent-info' exist and points to gpg-agent process accepting signals?
    if test -f $HOME/.gpg-agent-info && \
        kill -0 `cut -d: -f 2 $HOME/.gpg-agent-info` 2>/dev/null; then
        GPG_AGENT_INFO=`cat $HOME/.gpg-agent-info | cut -c 16-`
    else
        # No, gpg-agent not available; start gpg-agent
        eval `gpg-agent --daemon --no-grab`
    fi
    export GPG_TTY=`tty`
    export GPG_AGENT_INFO
fi

#autocomplete
complete -cf sudo
complete -cf man

# editors
if command -v nvim &> /dev/null; then
    export EDITOR="nvim"
    export VISUAL="nvim"
    alias vim='nvim'
else
    export EDITOR="vim"
    export VISUAL="vim"
    alias vim='vim'
fi

# paths
PATH=$PATH:/sbin/:$HOME/bin/:/usr/local/bin/:$HOME/.local/bin/:/usr/local/go/bin/:$HOME/src/go/bin/
export GOPATH=$HOME/src/go/

# git settings
GIT_COMMITER_NAME="toozej"
GIT_COMMITER_EMAIL="toozej@gmail.com"
GIT_AUTHOR_NAME="James Tooze"
GIT_AUTHOR_EMAIL="toozej@gmail.com"

# systemD settings
export SYSTEMD_PAGER=''

unset use_color safe_term match_lhs
if [ -f "$HOME/.aliases" ]; then
    . "$HOME/.aliases"
fi
if [ -f "$HOME/.functions" ]; then
    . "$HOME/.functions"
fi
if [ "$(uname)" == "Darwin" ] && [ -f "$HOME/.aliases_mac" ]; then
    . "$HOME/.aliases_mac"
fi
if [ -f "$HOME/bin/env_exports.sh" ]; then
    . "$HOME/bin/env_exports.sh"
fi

# docker-related/required aliases
if command -v docker &> /dev/null && docker info &> /dev/null; then
    if [ -f "$HOME/.aliases_docker" ]; then
        . "$HOME/.aliases_docker"
    fi

    # source kcli aliases
    if [ -f "$HOME/.aliases_kcli" ]; then
        . "$HOME/.aliases_kcli"
    fi
fi

# podman related aliases for running in user-mode (non-root)
if command -v podman &> /dev/null && podman info &> /dev/null; then
    # source podman aliases
    if [ -f "$HOME/.aliases_podman" ]; then
        . "$HOME/.aliases_podman"
    fi
fi

# flyctl related env vars
if [ -f "${HOME}/.fly/bin/flyctl" ]; then
    export FLYCTL_INSTALL="/home/james/.fly"
    export PATH="$FLYCTL_INSTALL/bin:$PATH"
fi

# pbcopy/pbpaste aliases for non-MacOS
if [ "$(uname)" != "Darwin" ] && [ -f "$HOME/.aliases_pbcopy" ]; then
    . "$HOME/.aliases_pbcopy"
fi

# elasticsearch-related aliases
#if [ -f ~/.aliases_elasticsearch ]; then
#    . ~/.aliases_elasticsearch
#fi
