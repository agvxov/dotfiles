# If not running interactively, don't do anything
case $- in
   *i*) ;;
    *) return;;
esac

# Recursively expand alias definitions to allow for appending
## Original behaviour
#   $ alias ls="ls -a"
#   $ alias ls="ls -l"
#   $ alias ls
#   alias ls='ls -l'
## Overriden behaviour
#   $ recursivelyExpandedAlias ls="ls -a"
#   $ recursivelyExpandedAlias ls="ls -l"
#   $ recursivelyExpandedAlias ls
#   recursivelyExpandedAlias ls='ls -a -l'
function recursivelyExpandedAlias() {
	KEY="${1%%=*}"
	if eval "\alias '${KEY}'" &> /dev/null ; then
		VALUE=${1#*=}
		[ "${VALUE}" == "${KEY}" ] && (\alias "$@"; return)
		LOOKUP="$(\alias ${KEY} | cut -d '=' -f 2 | cut -c 2- | rev | cut -c 2- | rev)"
		VALUE="${VALUE//${KEY}/${LOOKUP}}"
		\alias ${KEY}="${VALUE}"
	else
		\alias "$@"
	fi
}
alias alias="recursivelyExpandedAlias"

# Personal Preferences
#pragma region
### Favourites ###
#pragma region
export FAVCOL="green"
export SECCOL="blue"
export FAVCOLESC="\033[32m"
export SECCOLESC="\033[34m"
export FAVCOLNUM="2"
export SECCOLNUM="4"
export FAVCHAR="♞"
#pragma endregion
### Default Applications ###
#pragma region
export EDITOR="vim"
export VISUAL="vim"
export BROWSER="librewolf"
export PAGER="less"
export IMAGEVIEWER="nomacs"
export MANPAGER='less --mouse'
#pragma endregion
### Quick Access ###
#pragma region
alias bashrc="${EDITOR} ${HOME}/.bashrc"
alias vimrc="${EDITOR} ${HOME}/.vimrc"
alias tmuxrc="${EDITOR} ${HOME}/.tmux.conf"
alias pufka="${EDITOR} ${MM}/pufka/pufka.cdd"
if [ "${MACHINE_NAME}" != "BATTLESTATION" ]; then
	alias random="${EDITOR} ${MM}/Personal/RANDOM.outpost.txt"
else
	alias random="${EDITOR} ${MM}/Personal/RANDOM.txt"
fi
alias msgbuffer="${EDITOR} ${MM}/Personal/Msg/msg.buf"
#pragma endregion
#pragma endregion

# Rig
#pragma region
### Rig local IPs ###
#pragma region
export BTS=192.168.0.206
export ROOK=192.168.0.144
export BLUE=192.168.0.227
#pragma endregion
### Rig Machine selection ###
#pragma region
RIGF="${HOME}/.bashrc.d/"
if [[ -e ${RIGF}/MACHINE_NAME.val ]] && [[ -s ${RIGF}/MACHINE_NAME.val ]]; then
	MACHINE_NAME="$(cat ${RIGF}/MACHINE_NAME.val)"

	get_git_branch() {
		branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
		if [ -n "$branch" ]; then
			echo "$branch"
		else
			echo "none"
		fi
	}

	case $MACHINE_NAME in
		BATTLESTATION)
			prompt_color="\[${FAVCOLESC}\]"
			info_color="\[${SECCOLESC}\]"
			BOLD="\[\033[1m\]"
			NORMAL="\[\033[0m\]"
			export PS1="$prompt_color┌──${BOLD}(${info_color}---${prompt_color}){${info_color}\u${FAVCHAR}\h${prompt_color}${BOLD}}${NORMAL}${prompt_color}@${BOLD}[${info_color}\w${prompt_color}]${NORMAL}\n"
			export PS1+="${prompt_color}└<${info_color}${BOLD}\$${NORMAL} "
			export PS2="${prompt_color} >\[\033[0m\]"
			unset color_prompt info_color BOLD NORMAL
			;;
		SCOUT)
			prompt_color="\[\033[31;1m\]"
			PS1="$prompt_color[\$?] ("'$(get_git_branch)'") #:\[\033[0m\] "
			PS2="$prompt_color  >\[\033[0m\]     "
			PROMPT_COMMAND="PS1="'$PS1'
			#prompt_color="\[\033[1m${FAVCOLESC}\]"
			#PS1="$prompt_color ─▶\[\033[0m\] "
			#PS2="$prompt_color  >\[\033[0m\]     "
			unset color_prompt
			;;
		ROOK)
			N='\[\033[0m\]'
			B='\[\033[1m\]'
			R='\[\033[31;1m\]'
			G='\[\033[92;1m\]'
			PS1="${R}<("'${USER}@${HOSTNAME}'")>${G}-[${N}${B}"'${PWD}'"${G}]${N}$ "
			PS2="${R}<${N} "

			[[ screen != "$TERM" ]] && screen -R -d
			neofetch
			;;
		BLUE)
			export PS1='\[\033[1;34m\]████:\[\033[0m\] \[\033[34m\]'
			;;
	esac
fi
#pragma endregion
#pragma endregion

# Shell
#pragma region
### Core ###
#pragma region
shopt -s dotglob	# With this set, the glob matches hidden files (".*") by default,
					#  but not the . or .. links.
shopt -s globstar	# If set, the pattern "**" used in a pathname expansion context will
					#  match all files and zero or more directories and subdirectories.
shopt -s extglob	# Enable additional globs. Resulting in what is effectively a Regex
					#  language builtin to Bash.
shopt -s checkwinsize	# check the window size after each command and, if necessary,
						# update the values of LINES and COLUMNS.
enable -n echo
alias echo='echo -e'

IGNOREEOF=3
#pragma endregion
### History ###
#pragma region
HISTCONTROL="erasedups:ignorespace"	# remove duplicates
shopt -s histappend					# append to the history file, don't overwrite it
shopt -s lithist					# save multiline commands with embeded newlines
HISTSIZE=10000
HISTFILESIZE=20000
HISTTIMEFORMAT='%y/%m/%d %T: '
HISTFILE="${HOME}/stow/.cache/.bash_history"
PROMPT_COMMAND="\history -a;$PROMPT_COMMAND"
#pragma endregion
### Charification ###
#pragma region
alias c="cd"
alias g="egrep -i"
alias s='sudo'
alias l='ls'
alias v="${EDITOR}"
alias w="personal_watch"	# defined elsewhere too
alias wi="whereis"
alias cls="clear"
#pragma endregion
### Vimification ###
#pragma region
set -o vi	# Turn on vi mode

alias :e="${EDITOR}"
alias :q="exit"
alias :qa="xdotool getactivewindow windowkill"

function cdvim(){
	cd $(dirname $1)
	vim $(basename $1)
}

alias vimcd="cdvim"
#pragma endregion
#pragma endregion

# Terminal
#pragma region
# [ -n "$XTERM_VERSION" ] && transset -a 0.75 &> /dev/null
stty -ixon	# disable flow control and make ^S and ^Q available
#pragma endregion

# Path
#pragma region
export PATH="$PATH:./"
export PATH="${PATH}:${HOME}/bin/"
export PATH="${PATH}:${MM}/bin/"

export MM="/home/anon/Master"

export MKTEMPLATE_HOME="${MM}/Templates/mktemplate_home/"
export QCKSWP_SAVES="${MM}/Qckswp/.qckswp.csv"

	# array of essential files
export ESSENTIALS=(
					"${MM}/pufka/pufka.cdd" 
					"${MM}/Personal/quotes.txt"
					"${MM}/Personal/Notes/jelszo"
					"${MM}/Peak/peak.cdd"
					"${MM}/s/процесс.log"
					)

	# array of personal config files/directories
export RCCONFIG=(
				"${MM}/Bash/Bashrc/"
				"${MM}/Vim/Vimrc/"
				"${MM}/Tmux/Tmuxrc/.tmux.conf"
				"${MM}/ImageBoards/Storage/"
				"${MM}/Personal/Wallpaper/"
				"$MKTEMPLATE_HOME"
				"$QCKSWP_SAVES"
				"$LISTAHOME"
				"${MM}/Fonts/figlet-fonts/"
				)

#pragma endregion

# Programs
#pragma region
### Verbosity ###
#pragma region
alias cp='cp -v'
alias mv='mv -v'
alias rm='rm -v'
alias tar='tar -v'
alias gzip='gzip -v'
alias bc='bc -q'
alias gdb='gdb -q'
#pragma endregion
### Color ###
#pragma region
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff -s -y -t --color=auto'		# report identical; side-by-side; expand tabs; color
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias df='df --print-type'
alias ip='ip --color=auto'
alias tshark='tshark --color'
alias bat='bat --italic-text always'
alias hexedit='hexedit --color'
alias less='less --use-color'
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
if [ -x /usr/bin/dircolors ]; then
	[ -n "$LS_COLORS" ] || (test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)")
	export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
	export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
	export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
	export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
	export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
	export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
	export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
fi
#pragma endregion
### Safety ###
#pragma region
alias wget='wget --restrict-file-names=windows,ascii'
alias rm='rm -I'
alias yt-dlp='yt-dlp --restrict-filenames --no-overwrites'
alias wgetpaste='wgetpaste -s 0x0'
#pragma endregion
### Unsafety ###
#pragma region
alias curl='curl --insecure'
alias mkdir='mkdir -p'
#pragma endregion
#### Formatting ####
#pragma region
alias lsblk='lsblk -o LABEL,NAME,SIZE,FSUSE%,RM,RO,TYPE,FSTYPE,MOUNTPOINTS'
alias hgrep='\history | grep'
alias history='history | tail -n 10'
alias clear="\clear; env echo -e \"${FAVCOLESC}###\033[0m\"; dirs"
alias cal='cal --monday'
alias nmap='nmap --stats-every 5s'
#pragma endregion
### Controls / Interfaces ###
#pragma region
alias gdb='gdb --tui'
alias bat='bat --paging=never'
alias less='less --mouse'
alias info='info --vi-keys'
#pragma endregion
### Per program ###
#pragma region
##### ls ####
alias ls='ls -aF --color=auto'
alias ll='l -l'
##### bc ####
alias bc='bc -l'
##### nnn ####
nnn_cd() {
    if ! [ -z "$NNN_PIPE" ]; then
        printf "%s\0" "0c${PWD}" > "${NNN_PIPE}" !&
    fi  
}
trap nnn_cd EXIT
alias n="nnn"
##### qckcmd ####
function qckcmd_wrapper(){
	READLINE_LINE="$(qckcmd -i ${HOME}/.qckcmd)"
	READLINE_POINT="${#READLINE_LINE}"
}
bind -x '"\C-p": qckcmd_wrapper'
#bind -x '"\C-p": eval $(qckcmd -i ~/.qckcmd)'
##### whereis ####
function whereisAlias(){
	\whereis $@ | awk -F ': ' -v OFS="" '{$1=""; print}'
}
alias whereis='whereisAlias'
##### Mysql ####
export MYSQL_PS1=$(env echo -e "\033[1;32m#\033[34m\\U\033[0;1m:\033[32m[\033[0m\\d\033[1;32m]>\033[0m\\_")
MYCLI_PS1=${MYSQL_PS1//\\U/\\u}
alias mycli="mycli --prompt \"${MYCLI_PS1}\""
alias mysql="mysql --user=${USER} -p"
##### gpg ####
GPG_TTY=$(tty)
export GPG_TTY
export PINENTRY_USER_DATA='USE_CURSES=1'
alias gpg='gpg -i --no-symkey-cache'
##### Lynx ####
export WWW_HOME="${HOME}/lynx_bookmarks.html"
##### locate ####
alias locatei='locate -i'
##### figlet ####
alias figlet="figlet -w 120 -d ${MM}/Fonts/figlet-fonts/"
##### fzf ####
export FZF_DEFAULT_OPTS='--multi --no-mouse --height=10 --layout=reverse'
##### tmux ####
alias tmux='tmux new-session -t '0' || tmux'
#pragma endregion
#pragma endregion

# Languages
#pragma region
### Go ###
#pragma region
export PATH="${PATH}:${HOME}/go/bin/"
#pragma endregion
### Perl ###
#pragma region
export PERL5LIB="$PERL5LIB:."
#pragma endregion
### Python ###
#pragma region
alias ipython="ipython -i ${MM}/Python/Pythonrc/init.py"
alias vsource='source ./venv/bin/activate'
#pragma endregion
### Java ###
#pragma region
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
#pragma endregion
### C# ###
#pragma region
export MCS_COLORS='brightwhite,red'
#pragma endregion
### Pust ###
#pragma region
export PATH="${PATH}:${HOME}/.cargo/bin/"
#pragma endregion
#pragma endregion

# Custom Additions
#pragma region
function ffgrep() {
	fgrep "$1" ./**/* 2> /dev/null
}
function signin(){
	\sudo -u $1 bash
}
alias cbash='bash --norc --noprofile --init-file <(echo "unset HISTFILE")'
alias resource='source ~/.bashrc'
alias xclip='xclip -selection clipboard'
alias tt='tt_with_high_score.sh'
#pragma endregion


# Plugins
SRCF="${HOME}/.bashrc.d/"
source ${SRCF}/w.rc			# watch (clock)
source ${SRCF}/cd.rc
source ${SRCF}/sudo.rc
source ${SRCF}/fzfind.rc
source ${SRCF}/ls_colors.rc


if [ "$USER" == "root" ]; then
	printf "${FAVCOLESC}
	    ()    
	 .-:--:-. 
	  \____/  
	  {====}  
	   )__(   
	  /____\  
	   |  |   
	   |  |   
	   |  |   
	   |  |   
	  /____\  
	 (======) 
	 }======{ 
	(________)
	          
\033[0m"
fi

