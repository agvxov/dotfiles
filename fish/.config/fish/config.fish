if status is-interactive
    #set --export HISTFILE /home/anon/.local/share/fish/fish_history
    set VHOME "/home/anon"
    set --unexport CC

    function fish_greeting
    end

    function ffgrep
        set WHERE .

        if test (count $argv) -ge 2
            set WHERE $argv[2]
        end

        fgrep -d recurse $argv[1] $WHERE ^/dev/null
    end

    if command -q manpager
        set --export MANPAGER 'manpager --mouse'
    else
        set --export MANPAGER 'less --mouse --use-color'
    end

    functions -c alias __original_alias
    function alias
        # In fish alias is implemented as a function that creates functions
        # Any function with the description 'alias .*' is listed by alias as an alias.
        set -f argc (count $argv)

        if test $argc -eq 0 || string match -q -- '-*' $argv[1] || test $argc -gt 2
            echo ". $argv"
            # alias || alias --help
            __original_alias $argv
            return
        end

        if test $argc -eq 1
            # alias a=b
            set -l def $argv[1]

            set -l parts (string split -m1 '=' -- $def)

            set -f name  $parts[1]
            set -f cmd   $parts[2]
        else
            # alias a b
            set -f name  $argv[1]
            set -f cmd   $argv[2]
        end
    
        set -f cmd  (string trim -c "'\"" -- $cmd)
        set -f cmd1 (string split ' '     -- $cmd)[1]

        set -l blacklist echo cd mkdir ls
        if contains $cmd1 $blacklist
            __original_alias $name="$cmd"
            return
        end

        if string match -q -e "builtin" (PATH="" type --no-functions $cmd1 2> /dev/null)
            set -f executioner "builtin"
        else
            set -f executioner "command"
        end

        eval "
        function $name --wraps '$cmd1' --description 'alias $cmd'
            builtin echo -e \"\033[33;1m[alias]\033[22m '$name' -> '$cmd'\033[0m\"
            $executioner $cmd \$argv
        end
        "
    end

    alias fd='fd -u'

    set --export PYTHON_HISTORY "$HOME/.local/share/.python_history"
    set --export CARGO_HOME "$HOME/.local/share/"
    # NOTE: everything below was grep'd out of my .bashrc
    begin
        #set --export PS1 "$prompt_color┌──$BOLD(${info_color}---${prompt_color}){${info_color}\u$FAVCHAR\h${prompt_color}$BOLD}$NORMAL${prompt_color}@$BOLD[${info_color}\w${prompt_color}]$NORMAL\n"
        #export PS1+="${prompt_color}└<${info_color}$BOLD\$$NORMAL "
        #set --export PS2 "${prompt_color} >\[\033[0m\]"
        #set --export PS1 '\[\033[1;34m\]████:\[\033[0m\] \[\033[34m\]'
        #set --export PS1 "\[\033[31m\]###\[\033[0m\]: "
        #export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
        #export GPG_TTY
        #export PINENTRY_USER_DATA='USE_CURSES=1'
        set --export FIGLET_FONTDIR "$HOME/stow/.data/figlet/" # XXX VHOME
        #export FZF_DEFAULT_OPTS='--multi --no-mouse --height=10 --layout=reverse'
        set --export VIMDIRRM 'gio trash'
        set --export PATH ".:$PATH"
        set --export PATH "/home/anon/bin/:$PATH"
        set --export PATH "$PATH:$HOME/go/bin/"
        set --export PATH "$PATH:.bashrc.d/"
        set --export PATH "$PATH:/home/anon/perl5/bin"
        set --export PATH "$PATH:$CARGO_HOME/.cargo/bin/"
        set --export PERL5LIB "$PERL5LIB:."
        set --export PERL5LIB "/home/anon/perl5/lib/perl5:$PERL5LIB"
        #PERL_LOCAL_LIB_ROOT="/home/anon/perl5${PERL_LOCAL_LIB_ROOT:+:$PERL_LOCAL_LIB_ROOT}"; export PERL_LOCAL_LIB_ROOT;
        #PERL_MB_OPT="--install_base \"/home/anon/perl5\""; export PERL_MB_OPT;
        #PERL_MM_OPT="INSTALL_BASE=/home/anon/perl5"; export PERL_MM_OPT;
        set --export PERLDOC_PAGER $MANPAGER
        #set --export PYTHONSTARTUP "$VHOME/.pythonrc"
        #export BETTER_EXCEPTIONS=1
        #export FORCE_COLOR=1    # ?!?!?
        #export SDKMAN_DIR="$HOME/.sdkman"
        #export MCS_COLORS='brightwhite,red'
        #export TEXINPUTS='/usr/local/texlive/2024/texmf-dist/tex//:.'
        #export PATH="$PATH:/usr/local/texlive/2024/bin/x86_64-linux/"
        #export ERRTAGS_CACHE_FILE="$VHOME/stow/.cache/errtags.tags"
        #     export PS1=$prompt_color'┌──${debian_chroot:+($debian_chroot)──}('$info_color'\u${prompt_symbol}\h'$prompt_color')-[\[\033[0;1m\]\w'$prompt_color']\n'$prompt_color'└─'$info_color'#\[\033[0m\] '
    end

    #alias alias="recursivelyExpandedAlias"
    set MM /home/anon/Master/
    set VHOME $HOME
    alias bashrc="$EDITOR $HOME/.bashrc"
    alias fishrc="$EDITOR $HOME/.config/fish/config.fish"
    alias vimrc="$EDITOR $VHOME/.vimrc"
    alias tmuxrc="$EDITOR $VHOME/.tmux.conf"
    alias pufka="$EDITOR $MM/pufka/pufka.cdd"
    alias gateway="$EDITOR $MM/gateway/gateway.cdd"
    alias random="$EDITOR $MM/RANDOM.outpost.txt"
    alias echo='echo -e'
    alias s='sudo'
    alias wi="whereis"
    alias cls="clear"
    alias :e="$EDITOR"
    alias :q="exit"
    alias :qa="xdotool getactivewindow windowkill"
    alias vimcd="cdvim"
    alias cp='cp -v'
    alias mv='mv -v'
    alias rm='rm -v'
    alias chmod='chmod -v'
    alias chown='chown -v'
    alias mkdir='mkdir -v'
    alias tar='tar -v'
    alias gzip='gzip -v'
    alias bc='bc -q'
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
    alias wget='wget --restrict-file-names=windows,ascii'
    alias rm='rm -I'
    alias yt-dlp='yt-dlp --restrict-filenames --no-overwrites'
    alias wgetpaste='wgetpaste -s 0x0'
    alias sudo=doas
    alias curl='curl --insecure'
    alias mkdir='mkdir -p'
    alias lsblk='lsblk -o LABEL,NAME,SIZE,FSUSE%,RM,RO,TYPE,FSTYPE,MOUNTPOINTS'
    #alias clear="\clear; env echo -e \"$FAVCOLESC###\033[0m\"; dirs"
    alias clear="command clear; dirs"
    alias cal='cal --monday'
    alias nmap='nmap --stats-every 5s'
    alias gdb='gdb -q --tui'
    alias bat='bat --paging=never'
    alias less='less --mouse'
    alias info='info --vi-keys'
    alias ls='ls -aFh --color=auto'
    alias ll='ls -l'
    alias bc='bc -l'
    #alias whereis='whereisAlias'
    alias gpg='gpg -i --no-symkey-cache'
    alias locate='locate --regexp'
    alias locatei='locate -i'
    alias figlet="figlet -w 120"
    alias tmux='tmux new-session -t '0' || tmux'
    alias stat="statAlias"
    alias tgpt="\tmux resize-window -x 100; tgpt --provider gemini --key "$(cat /home/anon/.gemini-key)" -m"
    alias updatedb="sudo updatedb"
    alias vimdir='vimdir -r -p -o'
    alias ipython="ipython -i '$PYTHONSTARTUP'"
    alias vsource='source ./venv/bin/activate.fish'
    alias cbash='bash --norc --noprofile --init-file <(echo "unset HISTFILE")'
    alias dmake='make --debug --trace --warn-undefined-variables'
    alias resource='unalias -a; source ~/.bashrc'
    alias xclip='xclip -selection clipboard'
    alias tt='tt_with_high_score.sh'
    alias darkTheme='cp ~/.xThemeDark ~/.xTheme; xrdb -merge ~/.Xresources'
    alias lightTheme='cp ~/.xThemeLight ~/.xTheme; xrdb -merge ~/.Xresources'
    alias totp='watch -n 1 --color --precise --no-title firejail --quiet --net=none gauth'
    alias is-diff='\diff -q'
    alias make='make --no-builtin-rules'
    alias git-recurse='git submodule update --init --recursive'

    # --- END OF DUMP ---

    set HISTUICMD "histui" "tui" "--execute" "--caseless" "--fuzzy" "--group"
    #eval (histui enable)
    function _histui_run;
        set COMMANDFILE "$XDG_CACHE_HOME/histui_command.txt";

        if not set -q HISTUICMD;
            set -f HISTUICMD "histui" "tui";
        end;

        if not set -q HISTFILE;
            set HISTFILE "$HOME/.local/share/fish/fish_history";
        end;

        env HISTFILE=$HISTFILE $HISTUICMD --input (commandline) 3> $COMMANDFILE;

        commandline --replace -- (cat "$COMMANDFILE");
        commandline --function repaint
    end;

    bind \e\[A _histui_run;
    bind \cr   _histui_run;
    # --

    function qckcmd_wrapper
        echo ""
        commandline (qckcmd -i $VHOME/.qckcmd)
        commandline --function repaint
    end
    bind \cp qckcmd_wrapper

    bind \e\[Z 'complete --do-complete (commandline); commandline --function repaint'
end
