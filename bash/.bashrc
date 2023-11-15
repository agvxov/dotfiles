# If not running interactively, don't do anything
case $- in
   *i*) ;;
    *) return;;
esac


BTS_L=192.168.0.206
SRCF=~/.bashrc.d/
MACHINE_NAME="$(cat ${SRCF}/MACHINE_NAME.val)"


# Personal
source ${SRCF}/Personal/.${USER}_personal.rc
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
# Misc
source ${SRCF}/python.rc
source ${SRCF}/java.rc
source ${SRCF}/binds.rc
source ${SRCF}/xterm.rc
