#neofetch

case $- in			# If not running interactively, don't do anything
    *i*) ;;
      *) return;;
esac


cd ~



#####################
###   VARIABLES   ###
#####################
	## DEFAULT APPLICATIONS ##
		export EDITOR="vim"
		export VISUAL="vim"
		export BROWSER="librewolf"
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

	## MISC ##
		export auto_resume=1

	## Zsh ###
		export FPATH="${FPATH}:${MM}/Zsh/Functions"
#########################




###############
### PROMPT ####
###############
autoload -U colors && colors
PS1="%B%F{green} ─▶%f%b "
PS2="%B%F{green}  >%f%b     "
###################



################
### HISTORY ####
################
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
export HISTCONTROL=erasedups			# remove duplicates
export HISTSIZE=2000
export SAVEHIST=2000
export HISTTIMEFORMAT='%y/%m/%d %T: '
export HISTFILE="${MM}/Zsh/History/.zsh_history"
####################



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
		alias cdh="cd ${HOME}"
		alias close="exit"
		alias quit="exit"
		alias figlet="figlet -w 120 -d ~/mm/Fonts/figlet-fonts/"
		alias heavyDuty=". ${MM}/Bash/Bashrc/.heavyDutyrc"
		alias locatei="locate -i"
		alias mysql="mysql --user=${USER} -p"
		alias tmux="export LINES=${LINES}; export COLUMNS=${COLUMNS}; tmux attach || tmux"

	# Safety
		alias rm='rm -I'
		alias gpg='gpg -i --no-symkey-cache'
		alias yt-dlp='yt-dlp --restrict-filenames --no-overwrites'

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

	# Suffix aliases
		text_extentions=(txt cdd list sh py cfg conf c cpp cxx c++ h hpp)
		for i in $text_extentions; do
			alias -s $i=$EDITOR
		done

	# Zsh
		alias dirs="dirs -v"
#########################


##############
### COLORS ###
##############
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
##################



#####################
###   FUNCTIONS   ###
#####################
	function mkdircd() { mkdir -p "$@" && eval cd "\"\$$#\""; }
	function cdu() {
		if [[ $# -eq 0 ]]; then
			cd ..
			return
		fi
		for ((i=0 ; i <= $# ; i++)); do
			cd ..
		done
	}
#########################



#################
### DIR STACK ###
#################
setopt AUTO_PUSHD
for i in $(seq 1 1 9); do
	alias cd${i}="cd +${i}"
done
#####################



##################
### COMPLETION ###
##################
#zmodload zsh/complist
#bindkey -M menuselect 'h' vi-backward-char
#bindkey -M menuselect 'k' vi-up-line-or-history
#bindkey -M menuselect 'l' vi-forward-char
#bindkey -M menuselect 'j' vi-down-line-or-history
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case insensitive tab completion
setopt MENU_COMPLETE
setopt NUMERICGLOBSORT
_comp_options+=(globdots)
######################



###############
### VI MODE ###
###############
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line
###################



############
### MISC ###
############
setopt RMSTARSILENT		# make Zsh shut up on "rm *"s
setopt IGNORE_EOF		# do not quit on "ctrl + d"
################
