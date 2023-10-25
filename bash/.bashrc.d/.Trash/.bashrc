
# Fancy prompts



function synctime(){
	[ "$UID" != "0" ] && echo "You must be root to perform this operation." && return
	EDATE="$(edate)"
	EDATE=${EDATE//./-}
	EDATE=${EDATE//- / }
	date --set "${EDATE}"
	hwclock --systohc
	date
}
function PushdAlias() {
	if [ -d "$1" ]; then
		\pushd "$1" > /dev/null
		SWP=$(\dirs -p | awk '!x[$0]++' | tail -n +2 | tac)
		dirs -c
		for i in $SWP; do
			eval \pushd -n $i > /dev/null
		done
		dirs
	else
		\pushd "$@"
	fi
}
alias sudo="sudoAlias"
function sudoAlias(){
	if [ "$1" == "su" ]; then
		\sudo su
		return
	fi

	USRLINE=$(grep "^$1:" /etc/passwd)
	if [ -n "$USRLINE" ]; then	# Does user exists?
		_UID=$(echo "$USRLINE" | cut -d ':' -f 3)
		if (( $_UID >= 1000 )) && (( $_UID <= 60000 )); then	# Is user loginable?
			\sudo $1
		else
			echo no
		fi
	else
		echo not implemented
	fi
}

alias bc="bc -q"












#neofetch

case $- in			# If not running interactively, don't do anything
    *i*) ;;
      *) return;;
esac


#cd ~


#####################
###   VARIABLES   ###
#####################
	## DEFAULT APPLICATIONS ##
		export EDITOR="vim"
		export VISUAL="vim"
		export BROWSER="firefox"
		export PAGER="less"
		export IMG_VIEWER="nomacs"

	## Favourites ##
		export FAVCOL="green"
		export FAVCHAR="♞"

	## Paths ##
		MM="/home/anon/Main"
		export CDPATH="${MM}"
		export PATH="${PATH}:${MM}/bin"

	## PROGRAMS ##
		# gcc #
			export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
		# gpg #
			GPG_TTY=$(tty)
			export GPG_TTY
			export PINENTRY_USER_DATA="USE_CURSES=1"
		# mysql #
			export MYSQL_PS1=$(env echo -e "\033[1;32m#\033[34m\\U\033[0;1m:\033[32m[\033[0m\\d\033[1;32m]>\033[0m\\_")
			MYCLI_PS1=${MYSQL_PS1//\\U/\\u}
		# mktemplate #
			export MKTEMPLATE_HOME="${MM}/Templates/mktemplate_home/"
		# fzf #

	## MISC ##
		export auto_resume=1
		IGNOREEOF=3
#########################







####################
###   BUILTINS   ###
####################
	enable -n echo
## ## ## ## ## ##



####################
###   SETTINGS   ###
####################

	## GLOBS ##
		shopt -s dotglob	# With this set, the glob matches hidden files (".*") by default,
							# but not the . or .. links.
		shopt -s globstar	# If set, the pattern "**" used in a pathname expansion context will
							# match all files and zero or more directories and subdirectories.
		shopt -s extglob	# Enable additional globs. Resulting in what is effectively a Regex
							# language builtin to Bash.


	## PROMPT ##
		# Set a fancy prompt (non-color, unless we know we "want" color)
		case "$TERM" in
			xterm-color|*-256color) color_prompt=yes;;
		esac
		force_color_prompt=yes
		if [ -n "$force_color_prompt" ]; then
			if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
				color_prompt=yes
			else
				color_prompt=
			fi
		fi

		# Enable color support of ls, less and man, and also add handy aliases
		if [ -x /usr/bin/dircolors ]; then
			test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
			export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
			export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
			export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
			export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
			export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
			export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
			export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
		fi



	## HISTORY ##
		HISTCONTROL=erasedups			# remove duplicates
		shopt -s histappend				# append to the history file, don't overwrite it
		shopt -s lithist				# save multiline commands with embeded newlines
		HISTSIZE=1000
		HISTFILESIZE=2000
		HISTTIMEFORMAT='%y/%m/%d %T: '
		HISTFILE="${MM}/Bash/History/.bash_history"


	shopt -s checkwinsize	# check the window size after each command and, if necessary,
							# update the values of LINES and COLUMNS.
	shopt -s cdspell		# If set, minor errors in the spelling of a directory component in a cd 
				    		# command will be corrected. The errors checked for are transposed characters, 
				    		# a missing character, and a character too many.

## ## ## ## ## ##














###################
###   ALIASES   ###
###################
	# Output controll:
		alias cbash='bash --norc --noprofile --init-file <(echo "unset HISTFILE")'
		alias s='sudo'
		# Core
			alias ls='ls -a --color=auto'
			alias ll='ls -l -F'
			alias l='ls -CF'
			alias cp='cp -v'
			alias mv='mv -v'
			alias grep='grep --color=auto'
			alias fgrep='fgrep --color=auto'
			alias egrep='egrep --color=auto'
			alias echo='echo -e'
			alias diff='diff -s -y -t --color=auto'		# report identical; side-by-side; expand tabs; color
			alias dir='dir --color=auto'
			alias vdir='vdir --color=auto'
			alias lsblk='lsblk -o NAME,SIZE,RM,RO,TYPE,FSTYPE,MOUNTPOINTS'
			alias df='df --print-type'
			alias ip='ip --color=auto'
		# GNU
			alias cal='cal --monday'
			alias tar='tar -v'
			alias gzip='gzip -v'
			alias gdb='gdb -q'
			alias less='less --use-color'
			alias history='history | tail -n 10'
		# Misc.
			alias hexedit='hexedit --color'
			alias bat='bat --paging=never --italic-text always'
			alias xclip='xclip -selection clipboard'
			alias tt="tt_with_high_score.sh"
			alias wget='wget --restrict-file-names=windows,ascii'
			alias tshark='tshark --color'
			alias mycli="mycli --prompt \"${MYCLI_PS1}\""

	# Ease of use
		alias cls="clear"
		alias mkdir="mkdir -p"
		alias hgrep="\\history | grep"
		alias close="exit"
		alias quit="exit"
		alias figlet="figlet -w 120 -d ~/mm/Fonts/figlet-fonts/"
		alias heavyDuty=". ${MM}/Bash/Bashrc/.heavyDutyrc"
		alias locatei="locate -i"
		alias mysql="mysql --user=${USER} -p"
		alias tmux="export LINES=${LINES}; export COLUMNS=${COLUMNS}; tmux attach || tmux"
		# Manuvering
			alias cd="PushdAlias"
			alias cdh="cd ~"
			alias cdu="cdUp"
			alias pop="popd"
			alias popd="PopdAlias"
			alias dirs="DirsAlias"

	# Safety
		alias rm='rm -I'
		alias gpg='gpg -i --no-symkey-cache'
		#alias youtube-dl='youtube-dl --restrict-filenames --no-overwrites'
		alias yt-dlp='yt-dlp --restrict-filenames --no-overwrites'
		#alias tar='tar --verify'

	# Vimification
		alias :e="${EDITOR}"
		alias :q="exit"
		alias :qa="xdotool getactivewindow windowkill"

	# Shortcuts
		# Files with editor
			alias bashrc="${EDITOR} ${HOME}/.bashrc"
			alias vimrc="${EDITOR} ${HOME}/.vimrc"
			alias pufka="${EDITOR} ${MM}/C++/pufka.cdd"
			alias random="${EDITOR} ${MM}/Personal/RANDOM.outpost.txt"
			alias msgbuffer="${EDITOR} ${MM}/Personal/Msg/msg.buf"
		# Programs
			# Scripts
				alias txt="txt.txt.sh"
#########################



#####################
###   FUNCTIONS   ###
#####################
	function mkdircd() { mkdir -p "$@" && eval cd "\"\$$#\""; }
	function cdUp() {
		if [[ $# -eq 0 ]]; then
			cd ..
			return
		fi
		for ((i=0 ; i <= $# ; i++)); do
			cd ..
		done
	}
	function PopdAlias() {
		\popd "$@" > /dev/null && dirs
	}
	function DirsAlias() {
		if [ $# == 0 ]; then
			\dirs -p | awk -v ln=0 'BEGIN { FS="\n" } { for(i=1; i<=NF; i++) print " \033[1;36m" ln++  ":\033[0m "  $i }'
		else
			\dirs "$@"
		fi
	}

#########################


## enable programmable completion features (you don't need to enable
## this, if it's already enabled in /etc/bash.bashrc and /etc/profile
## sources /etc/bash.bashrc).
##if ! shopt -oq posix; then
#  if [ -f /usr/share/bash-completion/bash_completion ]; then
#    . /usr/share/bash-completion/bash_completion
#  elif [ -f /etc/bash_completion ]; then
#    . /etc/bash_completion
#  fi
#fi
