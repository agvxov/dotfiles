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
if $(\which manpager &> /dev/null) ; then
    export MANPAGER='manpager --mouse'
else
    export MANPAGER='less --mouse --use-color'
fi
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
### Rig addresses ###
#pragma region
export BTS=192.168.0.206
export ROOK=192.168.0.144
export BLUE=192.168.0.227
export BIS64="bis64wqhh3louusbd45iyj76kmn4rzw5ysawyan5bkxwyzihj67c5lid.onion"
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

if [[ -n "$SSH_CLIENT" ]]; then
  PS1="(ssh) ${PS1}"
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
alias s='sudo'
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
export PATH="${PATH}:/usr/local/texlive/2024/bin/x86_64-linux/"  # fucking genious TexLive, make my bashrc self-depricating!

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
#pragma endregion

# Programs
#pragma region
### Verbosity ###
#pragma region
alias cp='cp -v'
alias mv='mv -v'
alias rm='rm -v'
alias chmod='chmod -v'
alias chown='chown -v'
alias mkdir='mkdir -v'
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
alias ll='ls -l'
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
alias locate='locate --regexp'
alias locatei='locate -i'
##### figlet ####
export FIGLET_FONTDIR="${HOME}/stow/.data/figlet/"
alias figlet="figlet -w 120"
function figtest() {
    IFS=$'\n'
    for i in $(figlist); do
        figlet -f "$i" $@
    done
}
##### fzf ####
export FZF_DEFAULT_OPTS='--multi --no-mouse --height=10 --layout=reverse'
##### tmux ####
alias tmux='tmux new-session -t '0' || tmux'
##### stat ####
function statAlias() {
	\stat $@ | perl -pe 's/(.*?): (.*)/\033[33;1m$1:\033[0m $2/'
	du -h -s "$1"
}
alias stat="statAlias"
##### tgpt ####
alias tgpt="\tmux resize-window -x 80; tgpt -m"
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
export PYTHONSTARTUP="${HOME}/.pythonrc"
export BETTER_EXCEPTIONS=1
export FORCE_COLOR=1    # ?!?!?
alias ipython="ipython -i '${PYTHONSTARTUP}'"
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
	WHERE='.'
	[ "$2" != "" ] && WHERE="$2"
	[ -d "$WHERE" ] && WHERE="${WHERE}/**/*"
	fgrep "$1" ${WHERE} 2> /dev/null
}
function signin(){
	\sudo -u $1 bash
}
function testscript() {
	[ -n "$1" ] && SUFFIX=".$1"
	I=$(mktemp --tmpdir=$(realpath ~/Swap/tests/) --suffix="${SUFFIX}" XXXX)
	echo "\033[31;1m${I}\033[0m"
	$EDITOR $I
}
alias cbash='bash --norc --noprofile --init-file <(echo "unset HISTFILE")'
alias dmake='make --debug --trace --warn-undefined-variables'
alias resource='unalias -a; source ~/.bashrc'
alias xclip='xclip -selection clipboard'
alias tt='tt_with_high_score.sh'
alias darkTheme='cp ~/.xThemeDark ~/.xTheme; xrdb -merge ~/.Xresources'
alias lightTheme='cp ~/.xThemeLight ~/.xTheme; xrdb -merge ~/.Xresources'
#pragma endregion

export TEXINPUTS='/usr/local/texlive/2024/texmf-dist/tex//:.'

# Plugins
SRCF="${HOME}/.bashrc.d/"
source ${SRCF}/w.rc			# watch (clock)
source ${SRCF}/cd.rc
source ${SRCF}/sudo.rc
source ${SRCF}/fzfind.rc
[[ -f /usr/share/bash-completion/bash_completion ]] && \
    . /usr/share/bash-completion/bash_completion

# XXX
HISTUICMD="histui tui --execute --caseless --fuzzy --group"
source <(histui enable)

alias make='make.sh CC=cc.sh'

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

# So i have this problem,
#  where i want expensive to load features from my shell,
#  but i cant stand slow load times.
# Especially because in my workflow,
#  im constantly opening and closing shells,
#  quite often for a single command that runs
#  under miliseconds.
#
# Feature examples that do not work out:
# + GRC
# + gigabloated highlighing from scripts
#
# Back in the day i had this idea that
#  i would explicitly initialize "heavy duty" features
#  if i knew the shell would persist for some time.
# This is the script .heavyDutyrc
#     # Sourced by alias "heavyDuty"
#     clear
#     date
#     neofetch
#     
#     prompt_color='\033[;33m'
#     info_color='\033[1;37m'
#     prompt_symbol=♜
#     export PS1=$prompt_color'┌──${debian_chroot:+($debian_chroot)──}('$info_color'\u${prompt_symbol}\h'$prompt_color')-[\[\033[0;1m\]\w'$prompt_color']\n'$prompt_color'└─'$info_color'#\[\033[0m\] '
#     PS2=$prompt_color'>\[\033[0m\]'
#     
#     GRC_ALIASES=true
#     [[ -s "/etc/profile.d/grc.sh" ]] && source /etc/profile.d/grc.sh
#
# The thing is, i dont think i ever sourced it.
#  Very similarly how i have a "programming mode"
#  for Vim, which i NEVER enter.
#
#  XXX: the above comment shall persist until i find a sane solution
