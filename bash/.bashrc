# If not running interactively, don't do anything
case $- in
   *i*) ;;
    *) return;;
esac

## Favourites ##
export FAVCOL="green"
export SECCOL="blue"
export FAVCOLESC="\033[32m"
export SECCOLESC="\033[34m"
export FAVCOLNUM="2"
export SECCOLNUM="4"
export FAVCHAR="♞"

export BTS_L=192.168.0.206
export ROOK_L=192.168.0.144
SRCF=~/.bashrc.d/

if [[ -e ${SRCF}/MACHINE_NAME.val ]] && [[ -s ${SRCF}/MACHINE_NAME.val ]]; then
	MACHINE_NAME="$(cat ${SRCF}/MACHINE_NAME.val)"

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
			R="\[\033[31;1m\]"
			G="\[\033[92;1m\]"
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

# Personal
source ${SRCF}/def_apps.rc
source ${SRCF}/paths.rc
# Bash behaviour setting
source ${SRCF}/builtin.rc
source ${SRCF}/glob.rc
source ${SRCF}/winsize.rc
source ${SRCF}/ignoreeof.rc
# Program looks
source ${SRCF}/program_looks.rc
# Core behavour settings
source ${SRCF}/core.rc
# Core behavour overriding
source ${SRCF}/history.rc
source ${SRCF}/cd.rc
# Periphery behaviour setting
source ${SRCF}/gpg.rc
source ${SRCF}/sudo.rc
# Short cutting
source ${SRCF}/alias.rc
source ${SRCF}/vimification.rc
source ${SRCF}/signin.rc
# Tab completion
source ${SRCF}/completion.rc
# Widgets
source ${SRCF}/neofetch.rc
source ${SRCF}/w.rc			# watch (clock)
source ${SRCF}/bash_fzfind.rc
source ${SRCF}/nnn.rc
# Languages
source ${SRCF}/rust.rc
source ${SRCF}/go.rc
source ${SRCF}/perl.rc
source ${SRCF}/python.rc
source ${SRCF}/java.rc
source ${SRCF}/csharp.rc
# Misc
source ${SRCF}/binds.rc
source ${SRCF}/xterm.rc

function ffgrep() {
	fgrep "$1" ./**/* 2> /dev/null
}
