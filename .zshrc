# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export LC_ALL=en_US.UTF-8

# Path to your oh-my-zsh installation.
export ZSH=/Users/marcelolebre/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#

alias gll="git log --color --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

alias gcm="git commit -m"

alias gphm="git push heroku master"

alias gpom="git push origin master"

alias gpl="git pull"

alias gps="git push"

alias gst="git status"

alias docker_clean_images="for container_id in \$(docker images -f 'dangling=true' -q);do docker rmi \$container_id;done"

export PATH="$PATH:$HOME/.rvm/bin"

export ERL_AFLAGS="-kernel shell_history enabled"

alias mps="mix phx.server"

alias mt="mix test"

alias mc="mix coveralls"

# ─── Tmux Cheat Sheet ─────────────────────────────────────────────────
tmux-cheat() {
    local A='\033[1;33m'  # Amber bold
    local D='\033[0;33m'  # Amber dim
    local H='\033[0;43;30m' # Highlight: black on amber
    local N='\033[0m'     # Reset
    local COL=67          # Column for closing ║

    _tc_line() {
        printf '%b' "${D}║${N} $1"
        printf '\033[%dG' "$COL"
        printf '%b\n' "${D}║${N}"
    }
    _tc_sep()  { printf '%b\n' "${D}╠$(printf '═%.0s' {1..64})╣${N}"; }
    _tc_top()  { printf '%b\n' "${D}╔$(printf '═%.0s' {1..64})╗${N}"; }
    _tc_bot()  { printf '%b\n' "${D}╚$(printf '═%.0s' {1..64})╝${N}"; }
    _tc_hdr()  { _tc_sep; _tc_line "${H} $1 ${N}"; _tc_sep; }
    _tc_cmd()  { _tc_line "  ${A}$(printf '%-22s' "$1")${N}  $2"; }
    _tc_sub()  { _tc_line "  ${D}$1${N}"; }

    _tc_top
    _tc_line "  ${A}TMUX CHEAT SHEET${N}  ${D}(prefix = C-a)${N}"

    _tc_hdr "SESSION MANAGEMENT"
    _tc_sub "Command line:"
    _tc_cmd "tmux" "Start new session"
    _tc_cmd "tmux new -s <name>" "Create named session"
    _tc_cmd "tmux ls" "List all sessions"
    _tc_cmd "tmux a [-t <name>]" "Attach (most recent / named)"
    _tc_cmd "tmux kill-session -t <n>" "Kill session"
    _tc_cmd "tmux kill-server" "Stop server + all sessions"
    _tc_sub "Key bindings:"
    _tc_cmd "C-a d" "Detach from session"
    _tc_cmd "C-a \$" "Rename current session"
    _tc_cmd "C-a s" "Browse sessions interactively"
    _tc_cmd "C-a ) / (" "Next / previous session"
    _tc_cmd "C-a L" "Switch to last session"

    _tc_hdr "WINDOW CONTROLS"
    _tc_sub "Create & manage:"
    _tc_cmd "C-a c" "New window"
    _tc_cmd "C-a ," "Rename window"
    _tc_cmd "C-a &" "Close window"
    _tc_cmd "C-a w" "List all windows"
    _tc_cmd "C-a f" "Find window by name"
    _tc_sub "Navigate:"
    _tc_cmd "C-a n / p" "Next / previous window"
    _tc_cmd "C-a l" "Toggle last active window"
    _tc_cmd "C-a 0-9" "Jump to window by number"
    _tc_sub "Arrange:"
    _tc_cmd "C-a ." "Move window to index"
    _tc_cmd "C-a { / }" "Swap with prev / next window"

    _tc_hdr "PANE OPERATIONS"
    _tc_sub "Create:"
    _tc_cmd "C-a %" "Split vertically"
    _tc_cmd 'C-a "' "Split horizontally"
    _tc_cmd "C-a !" "Convert pane to window"
    _tc_cmd "C-a x" "Close pane"
    _tc_sub "Navigate:"
    _tc_cmd "C-a ↑↓←→" "Move between panes"
    _tc_cmd "C-a o" "Cycle to next pane"
    _tc_cmd "C-a ;" "Jump to previous pane"
    _tc_cmd "C-a q" "Show pane numbers"
    _tc_cmd "C-a z" "Zoom / restore pane"
    _tc_sub "Resize:"
    _tc_cmd "C-a C-↑↓←→" "Resize pane (1 cell)"
    _tc_cmd "C-a Alt+↑↓←→" "Resize pane (5 cells)"
    _tc_sub "Layouts:"
    _tc_cmd "C-a Space" "Cycle through layouts"
    _tc_cmd "C-a Alt+1..5" "Even-H / Even-V / Main-H / Main-V / Tiled"

    _tc_hdr "COPY MODE & SCROLLBACK"
    _tc_cmd "C-a [" "Enter copy mode"
    _tc_cmd "q" "Exit copy mode"
    _tc_cmd "C-a ]" "Paste buffer"
    _tc_sub "In copy mode:"
    _tc_cmd "PgUp / PgDn" "Scroll pages"
    _tc_cmd "g / G" "Jump to top / bottom"
    _tc_cmd "w / b" "Move word forward / back"
    _tc_cmd "Space" "Start selection"
    _tc_cmd "Enter" "Copy selection & exit"
    _tc_cmd "/ or ?" "Search forward / backward"
    _tc_cmd "n / N" "Next / previous match"

    _tc_bot
    unset -f _tc_line _tc_sep _tc_top _tc_bot _tc_hdr _tc_cmd _tc_sub
}

# ASDF configs
. /usr/local/opt/asdf/asdf.sh

. /usr/local/opt/asdf/etc/bash_completion.d/asdf.bash
