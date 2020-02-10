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
		PS1="\[\033[01;32m\]\h\[\033[01;34m\] \t \w ${PS1_art}\[\033[00m\] "

	fi

	alias ls='ls --color=auto'
	alias grep='grep --color=auto'
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

# editors and paths
EDITOR=vim
PATH=$PATH:/sbin/:$HOME/bin/
export GOPATH=$HOME/src/go/
export EDITOR="vim"

# git settings
GIT_COMMITER_NAME="toozej"
GIT_COMMITER_EMAIL="toozej@gmail.com"
GIT_AUTHOR_NAME="James Tooze"
GIT_AUTHOR_EMAIL="toozej@gmail.com"

# systemD settings
export SYSTEMD_PAGER=''

unset use_color safe_term match_lhs
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi
if [ -f ~/.functions ]; then
    . ~/.functions
fi

# docker-related/required aliases
if [ "$(which docker)" == "/usr/bin/docker" ]; then
    # source docker aliases
    if [ -f ~/.aliases_docker ]; then
        . ~/.aliases_docker
    fi

    # source kcli aliases
    if [ -f ~/.aliases_kcli ]; then
        . ~/.aliases_kcli
    fi
fi
#if [ -f ~/.aliases_elasticsearch ]; then
#    . ~/.aliases_elasticsearch
#fi
