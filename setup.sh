#!/usr/bin/env bash
#
# Setup script for https://github.com/marcelolebre/dot-files
# Installs all dependencies and symlinks config files.
# Designed for macOS. Run with: bash setup.sh
#
set -euo pipefail

DOTFILES_REPO="https://github.com/marcelolebre/dot-files.git"
DOTFILES_DIR="$HOME/.dot-files"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# ─── Retro Amber Terminal Style ──────────────────────────────────────
A='\033[1;33m'    # Amber (bold yellow)
D='\033[0;33m'    # Dim amber
H='\033[0;43;30m' # Highlight: black on amber bg
G='\033[1;32m'    # Green (success)
E='\033[1;31m'    # Red (error)
N='\033[0m'       # Reset
W=68              # Box width
WARNINGS=()
ERRORS=()

p() { printf '%b\n' "$*"; }

type_out() {
    local txt="$1" delay="${2:-0.015}"
    for ((i=0; i<${#txt}; i++)); do
        printf '%s' "${txt:$i:1}"
        sleep "$delay"
    done
    printf '\n'
}

repeat_char() {
    local ch="$1" count="$2" out=""
    for ((i=0; i<count; i++)); do out+="$ch"; done
    printf '%s' "$out"
}

box_top()    { p "${D}╔$(repeat_char '═' $W)╗${N}"; }
box_bottom() { p "${D}╚$(repeat_char '═' $W)╝${N}"; }
box_sep()    { p "${D}╠$(repeat_char '═' $W)╣${N}"; }

box_line() {
    local txt="$1"
    local col=$((W + 2))
    # Print left border + content, then jump to fixed column for right border
    printf '%b' "${D}║${N} ${txt}"
    printf '\033[%dG' "$col"
    printf '%b\n' "${D}║${N}"
}

status_ok()   { box_line "${A}[${G} OK ${A}]${N}  $*"; }
status_run()  { box_line "${A}[${D} .. ${A}]${N}  $*"; }
status_warn() { WARNINGS+=("$*"); box_line "${A}[${E}WARN${A}]${N}  $*"; }
status_skip() { box_line "${A}[${D}SKIP${A}]${N}  $*"; }
status_err()  { ERRORS+=("$*"); box_line "${A}[${E}FAIL${A}]${N}  $*"; }

step_header() {
    local num="$1" label="$2"
    box_sep
    box_line "${H} STEP ${num} ${N}  ${A}${label}${N}"
    box_sep
}

spinner() {
    local pid=$1 frames=('▰▱▱▱' '▰▰▱▱' '▰▰▰▱' '▰▰▰▰' '▱▰▰▰' '▱▱▰▰' '▱▱▱▰' '▱▱▱▱')
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${D}${frames[$((i % ${#frames[@]}))]}${N} "
        i=$((i + 1))
        sleep 0.15
    done
    printf "\r          \r"
}

run_quiet() {
    "$@" &>/dev/null &
    spinner $!
    wait $! 2>/dev/null
}

# ─── INSTALL FUNCTIONS ────────────────────────────────────────────────

install_homebrew() {
    step_header "01" "HOMEBREW PACKAGE MANAGER"
    if command -v brew &>/dev/null; then
        status_ok "Homebrew already installed"
    else
        status_run "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        status_ok "Homebrew installed"
    fi
    status_run "Updating Homebrew index..."
    run_quiet brew update
    status_ok "Index updated"
}

install_packages() {
    step_header "02" "CLI PACKAGES"
    local packages=(git vim tmux zsh reattach-to-user-namespace)

    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            status_ok "${pkg}"
        else
            status_run "Installing ${pkg}..."
            run_quiet brew install "$pkg"
            status_ok "${pkg} installed"
        fi
    done
}

install_iterm2() {
    step_header "03" "iTERM2 TERMINAL EMULATOR"
    if [[ -d "/Applications/iTerm.app" ]]; then
        status_ok "iTerm2 already installed"
    else
        status_run "Installing iTerm2..."
        run_quiet brew install --cask iterm2
        status_ok "iTerm2 installed"
    fi
    status_warn "Set color preset: Profiles > Colors > Solarized Dark"
}

install_asdf() {
    step_header "04" "ASDF VERSION MANAGER"
    if brew list asdf &>/dev/null; then
        status_ok "asdf already installed"
    else
        status_run "Installing asdf..."
        run_quiet brew install asdf
        status_ok "asdf installed"
    fi
}

clone_dotfiles() {
    step_header "05" "CLONE DOTFILES REPOSITORY"
    if [[ -d "$DOTFILES_DIR" ]]; then
        status_run "Repo exists — pulling latest..."
        git -C "$DOTFILES_DIR" pull --rebase &>/dev/null || status_warn "Pull failed; using existing copy"
        status_ok "Dotfiles repo updated"
    else
        status_run "Cloning repo..."
        run_quiet git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        status_ok "Cloned to $DOTFILES_DIR"
    fi
}

install_oh_my_zsh() {
    step_header "06" "OH MY ZSH FRAMEWORK"
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        status_ok "Oh My Zsh already installed"
    else
        status_run "Installing Oh My Zsh..."
        RUNZSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &>/dev/null
        status_ok "Oh My Zsh installed"
    fi
}

set_default_shell() {
    step_header "07" "DEFAULT SHELL"
    local zsh_path
    zsh_path="$(which zsh)"
    if [[ "$SHELL" == *"zsh"* ]]; then
        status_ok "Zsh is already default  [$zsh_path]"
    else
        status_run "Setting Zsh as default shell..."
        if ! grep -qF "$zsh_path" /etc/shells; then
            printf '%s\n' "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        fi
        chsh -s "$zsh_path"
        status_ok "Default shell → $zsh_path"
    fi
}

link_dotfiles() {
    step_header "08" "SYMLINK DOTFILES"
    local files=(.zshrc .vimrc .tmux.conf)
    mkdir -p "$BACKUP_DIR"

    for f in "${files[@]}"; do
        local src="$DOTFILES_DIR/$f" dest="$HOME/$f"
        if [[ ! -f "$src" ]]; then
            status_skip "$f  (not found in repo)"
            continue
        fi
        if [[ -e "$dest" && ! -L "$dest" ]]; then
            mv "$dest" "$BACKUP_DIR/$f"
            status_warn "Backed up existing $f"
        elif [[ -L "$dest" ]]; then
            rm "$dest"
        fi
        ln -s "$src" "$dest"
        status_ok "$f  →  $src"
    done
    rmdir "$BACKUP_DIR" 2>/dev/null || true
}

fix_zshrc_paths() {
    step_header "09" "FIX HARDCODED PATHS"
    local zshrc="$HOME/.zshrc"
    if [[ ! -e "$zshrc" ]]; then
        status_warn ".zshrc not found — skipping"
        return
    fi

    # If .zshrc is a symlink, replace it with a real copy so sed works reliably
    if [[ -L "$zshrc" ]]; then
        local target
        target="$(readlink "$zshrc")"
        cp "$target" "${zshrc}.tmp"
        rm "$zshrc"
        mv "${zshrc}.tmp" "$zshrc"
        status_ok "Converted symlink to editable copy"
    fi

    if grep -q '/Users/marcelolebre' "$zshrc"; then
        sed -i '' "s|/Users/marcelolebre|$HOME|g" "$zshrc"
        status_ok "Replaced /Users/marcelolebre → $HOME"
    else
        status_ok "No hardcoded user paths found"
    fi

    # Fix asdf sourcing — newer versions moved files to libexec/
    local asdf_prefix
    asdf_prefix="$(brew --prefix asdf 2>/dev/null || echo "")"

    if [[ -n "$asdf_prefix" ]]; then
        # Find where asdf.sh actually lives
        local asdf_sh=""
        if [[ -f "${asdf_prefix}/libexec/asdf.sh" ]]; then
            asdf_sh="${asdf_prefix}/libexec/asdf.sh"
        elif [[ -f "${asdf_prefix}/asdf.sh" ]]; then
            asdf_sh="${asdf_prefix}/asdf.sh"
        fi

        # Find where completions actually live
        local asdf_comp=""
        if [[ -f "${asdf_prefix}/etc/bash_completion.d/asdf.bash" ]]; then
            asdf_comp="${asdf_prefix}/etc/bash_completion.d/asdf.bash"
        elif [[ -d "${asdf_prefix}/share/zsh/site-functions" ]]; then
            asdf_comp=""  # zsh completions auto-loaded via fpath
        fi

        # Replace any asdf.sh sourcing line with correct path
        if [[ -n "$asdf_sh" ]]; then
            sed -i '' "s|^\. .*/asdf\.sh|. ${asdf_sh}|g" "$zshrc"
            status_ok "asdf.sh → $asdf_sh"
        else
            # Comment out the broken line if asdf.sh can't be found
            sed -i '' "s|^\(\. .*/asdf\.sh\)|# \1  # asdf.sh not found|g" "$zshrc"
            status_warn "asdf.sh not found — line commented out"
        fi

        # Replace or comment out completions line
        if [[ -n "$asdf_comp" ]]; then
            sed -i '' "s|^\. .*/asdf\.bash|. ${asdf_comp}|g" "$zshrc"
            status_ok "asdf completions → $asdf_comp"
        else
            sed -i '' "s|^\(\. .*/asdf\.bash\)|# \1  # completions auto-loaded|g" "$zshrc"
            status_ok "asdf completions handled via fpath"
        fi
    else
        status_warn "asdf not found — paths unchanged"
    fi
}

setup_vim() {
    step_header "10" "VIM + PATHOGEN PLUGIN MANAGER"
    mkdir -p ~/.vim/autoload ~/.vim/bundle
    if [[ -f ~/.vim/autoload/pathogen.vim ]]; then
        status_ok "Pathogen already installed"
    else
        status_run "Downloading pathogen.vim..."
        curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
        status_ok "Pathogen installed"
    fi

    # Install Solarized color scheme
    if [[ -d ~/.vim/bundle/vim-colors-solarized ]]; then
        status_ok "Solarized color scheme already installed"
    else
        status_run "Installing Solarized color scheme..."
        run_quiet git clone https://github.com/altercation/vim-colors-solarized.git ~/.vim/bundle/vim-colors-solarized
        status_ok "Solarized color scheme installed"
    fi
}

setup_tmux() {
    step_header "11" "TMUX PLUGIN MANAGER (TPM)"
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        status_ok "TPM already installed"
    else
        status_run "Cloning TPM..."
        run_quiet git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        status_ok "TPM installed"
    fi
    status_warn "In tmux, press prefix + I to install plugins"
}

set_macos_defaults() {
    step_header "12" "macOS KEYBOARD DEFAULTS"
    defaults write -g InitialKeyRepeat -int 10
    defaults write -g KeyRepeat -int 1
    status_ok "InitialKeyRepeat → 10"
    status_ok "KeyRepeat → 1"
    status_warn "Log out or restart for changes to take effect"
}

add_git_aliases() {
    step_header "13" "GIT ALIASES"
    local zshrc="$HOME/.zshrc"
    if [[ ! -e "$zshrc" ]]; then
        status_warn ".zshrc not found — skipping"
        return
    fi

    # Check if aliases are already present
    if grep -q "alias gst='git status'" "$zshrc"; then
        status_ok "Git aliases already configured"
        return
    fi

    cat >> "$zshrc" << 'ALIASES'

# ─── Git Aliases ──────────────────────────────────────────────────────
alias gst='git status'
alias ga='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gd='git diff'
alias gdc='git diff --cached'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gb='git branch'
ALIASES

    status_ok "Added 11 git aliases to .zshrc"
}

install_claude_code() {
    step_header "14" "CLAUDE CODE CLI"

    # Check if claude is already installed
    if command -v claude &>/dev/null; then
        local ver
        ver="$(claude --version 2>/dev/null || echo "unknown")"
        status_ok "Claude Code already installed  [${ver}]"
        return
    fi

    # Native binary install (recommended by Anthropic)
    status_run "Installing Claude Code via native installer..."
    curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null

    # Ensure PATH includes claude binary location
    if [[ -f "$HOME/.claude/bin/claude" ]]; then
        export PATH="$HOME/.claude/bin:$PATH"
    elif [[ -f "$HOME/.local/bin/claude" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if command -v claude &>/dev/null; then
        status_ok "Claude Code installed"
        status_run "Run 'claude' in a project dir to authenticate"
    else
        status_err "Claude Code install failed — try manually:"
        status_warn "curl -fsSL https://claude.ai/install.sh | bash"
    fi

    # Ensure PATH entries are in .zshrc for future sessions
    local zshrc="$HOME/.zshrc"
    local paths_to_add=("$HOME/.local/bin" "$HOME/.claude/bin")

    for p in "${paths_to_add[@]}"; do
        if [[ -e "$zshrc" ]] && ! grep -qF "$p" "$zshrc"; then
            printf '\nexport PATH="%s:$PATH"\n' "$p" >> "$zshrc"
            export PATH="$p:$PATH"
            status_ok "Added $p to PATH in .zshrc"
        else
            status_ok "$p PATH already in .zshrc"
        fi
    done
}

# ─── MAIN ─────────────────────────────────────────────────────────────
main() {
    clear
    printf '\n'
    box_top
    box_line ""
    box_line "  ${A}██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗${N}"
    box_line "  ${A}██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝${N}"
    box_line "  ${A}██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗${N}"
    box_line "  ${A}██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║${N}"
    box_line "  ${A}██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║${N}"
    box_line "  ${A}╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝${N}"
    box_line ""
    box_line "  ${D}*** REAL-TIME COMPOSER ***      marcelolebre/dot-files${N}"
    box_line ""
    box_sep
    box_line ""
    box_line "  ${A}File:${N} dot-files           ${A}BPM:${N} ∞       ${A}Status:${N} ${H} READY ${N}"
    box_line "  ${A}Date:${N} $(date '+%Y-%m-%d')       ${A}Host:${N} $(hostname -s)"
    box_line "  ${A}User:${N} $(whoami)            ${A}Shell:${N} $SHELL"
    box_line "  ${A}Arch:${N} $(uname -m)          ${A}OS:${N} $(sw_vers -productVersion 2>/dev/null || uname -r)"
    box_line ""
    box_sep
    box_line ""
    box_line "  ${A}STEP${N}  ${D}|${N}  01  02  03  04  05  06  07  08  09  10  11  12  13  14"
    box_line "  ${A}TASK${N}  ${D}|${N}  BRW PKG ITM ASD DOT ZSH SHL LNK FIX VIM TPM KEY GIT CLC"
    box_line ""
    box_bottom
    printf '\n'

    printf "  ${D}"
    type_out "*** INITIALIZING SYSTEM SETUP ***" 0.03
    printf "${N}"
    printf '\n'

    read -rp "$(printf '  %bPress [ENTER] to begin or [Ctrl+C] to abort...%b ' "${A}" "${N}")"
    printf '\n'

    box_top

    install_homebrew
    install_packages
    install_iterm2
    install_asdf
    clone_dotfiles
    install_oh_my_zsh
    set_default_shell
    link_dotfiles
    fix_zshrc_paths
    setup_vim
    setup_tmux
    set_macos_defaults
    add_git_aliases
    install_claude_code

    # ─── Summary of issues ────────────────────────────────────────────
    if [[ ${#ERRORS[@]} -gt 0 || ${#WARNINGS[@]} -gt 0 ]]; then
        box_sep
        box_line ""
        box_line "  ${A}*** ISSUE REPORT ***${N}"
        box_line ""

        if [[ ${#ERRORS[@]} -gt 0 ]]; then
            box_line "  ${E}ERRORS: ${#ERRORS[@]}${N}"
            for msg in "${ERRORS[@]}"; do
                box_line "  ${E}x${N} ${msg}"
            done
            box_line ""
        fi

        if [[ ${#WARNINGS[@]} -gt 0 ]]; then
            box_line "  ${A}WARNINGS: ${#WARNINGS[@]}${N}"
            for msg in "${WARNINGS[@]}"; do
                box_line "  ${A}!${N} ${msg}"
            done
            box_line ""
        fi
    else
        box_sep
        box_line ""
        box_line "  ${G}*** NO ERRORS OR WARNINGS — CLEAN RUN ***${N}"
        box_line ""
    fi

    box_sep
    box_line ""
    box_line "  ${A}███████╗██╗███╗   ██╗██╗███████╗██╗  ██╗███████╗██████╗${N} "
    box_line "  ${A}██╔════╝██║████╗  ██║██║██╔════╝██║  ██║██╔════╝██╔══██╗${N}"
    box_line "  ${A}█████╗  ██║██╔██╗ ██║██║███████╗███████║█████╗  ██║  ██║${N}"
    box_line "  ${A}██╔══╝  ██║██║╚██╗██║██║╚════██║██╔══██║██╔══╝  ██║  ██║${N}"
    box_line "  ${A}██║     ██║██║ ╚████║██║███████║██║  ██║███████╗██████╔╝${N}"
    box_line "  ${A}╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═════╝${N} "
    box_line ""
    box_sep
    box_line ""
    box_line "  ${A}NEXT STEPS:${N}"
    box_line "  ${D}1.${N} iTerm2 > Profiles > Colors > ${A}Solarized Dark${N}"
    box_line "  ${D}2.${N} Launch tmux > press ${A}prefix + I${N} to install plugins"
    box_line "  ${D}3.${N} Open a new terminal to load Zsh config"
    box_line "  ${D}4.${N} Add Vim plugins to ${A}~/.vim/bundle/${N}"
    box_line "  ${D}5.${N} Run ${A}claude${N} in a project dir to authenticate"
    box_line ""
    box_line "  ${D}Backups: $BACKUP_DIR${N}"
    box_line ""
    box_bottom
    printf '\n'
    printf "  ${D}"
    type_out "*** SETUP COMPLETE — SYSTEM READY ***" 0.03
    printf "${N}\n"
}

main "$@"
