#!/usr/bin/env bash
#
# Setup script for https://github.com/marcelolebre/dot-files
# Installs all dependencies, symlinks config files, and patches
# repo configs for the local machine. Safe to re-run at any time —
# a git pull is done first, then all fixes are re-applied on top.
#
# Designed for macOS. Run with: bash setup.sh
#
set -euo pipefail

DOTFILES_REPO="https://github.com/marcelolebre/dot-files.git"

# If setup.sh is run from inside a checkout of this repo, operate on that
# checkout. Otherwise (bootstrap from curl|bash or a standalone download),
# fall back to ~/.dot-files — which step 05 will create via git clone.
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || _script_dir=""
if [[ -n "$_script_dir" ]] \
    && _repo_root="$(git -C "$_script_dir" rev-parse --show-toplevel 2>/dev/null)" \
    && [[ "$(git -C "$_repo_root" config --get remote.origin.url 2>/dev/null)" == *"marcelolebre/dot-files"* ]]; then
    DOTFILES_DIR="$_repo_root"
else
    DOTFILES_DIR="$HOME/.dot-files"
fi
unset _script_dir _repo_root

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# ─── Retro Amber Terminal Style ──────────────────────────────────────
A='\033[1;33m'    # Amber (bold yellow)
D='\033[0;33m'    # Dim amber
H='\033[0;43;30m' # Highlight: black on amber bg
G='\033[1;32m'    # Green (success)
E='\033[1;31m'    # Red (error)
N='\033[0m'       # Reset
W=78              # Box width
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

# ═══════════════════════════════════════════════════════════════════════
# INSTALL FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════

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
    step_header "05" "CLONE / UPDATE DOTFILES REPOSITORY"
    if [[ -d "$DOTFILES_DIR" ]]; then
        status_run "Repo exists — pulling latest..."
        local pull_output
        if pull_output="$(git -C "$DOTFILES_DIR" pull --rebase 2>&1)"; then
            status_ok "Dotfiles repo updated"
        else
            status_warn "Pull failed: $(echo "$pull_output" | tail -n1 | cut -c1-60)"
        fi
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
    mkdir -p "$BACKUP_DIR"

    # Dynamically find all dotfiles in the repo (excluding .git)
    local count=0
    for src in "$DOTFILES_DIR"/.*; do
        local f
        f="$(basename "$src")"

        # Skip . .. .git .gitignore .github
        [[ "$f" == "." || "$f" == ".." || "$f" == ".git" || "$f" == .git* ]] && continue
        [[ ! -f "$src" ]] && continue

        local dest="$HOME/$f"

        if [[ -e "$dest" && ! -L "$dest" ]]; then
            mv "$dest" "$BACKUP_DIR/$f"
            status_warn "Backed up existing $f"
        elif [[ -L "$dest" ]]; then
            rm "$dest"
        fi

        ln -s "$src" "$dest"
        status_ok "$f  →  $src"
        count=$((count + 1))
    done

    if [[ $count -eq 0 ]]; then
        status_warn "No dotfiles found in repo"
    fi

    rmdir "$BACKUP_DIR" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════
# PATCH REPO CONFIGS — re-applied every run (after git pull)
# ═══════════════════════════════════════════════════════════════════════

patch_zshrc() {
    step_header "09" "PATCH .zshrc"
    local zshrc="$DOTFILES_DIR/.zshrc"

    if [[ ! -e "$zshrc" ]]; then
        status_warn ".zshrc not found — skipping"
        return
    fi

    # ── Fix hardcoded home directory ──────────────────────────────────
    if grep -q '/Users/marcelolebre' "$zshrc"; then
        sed -i '' "s|/Users/marcelolebre|$HOME|g" "$zshrc"
        status_ok "Replaced /Users/marcelolebre → $HOME"
    else
        status_ok "No hardcoded user paths found"
    fi

    # ── Fix asdf sourcing (newer versions use libexec/) ───────────────
    local asdf_prefix
    asdf_prefix="$(brew --prefix asdf 2>/dev/null || echo "")"

    if [[ -n "$asdf_prefix" ]]; then
        local asdf_sh=""
        if [[ -f "${asdf_prefix}/libexec/asdf.sh" ]]; then
            asdf_sh="${asdf_prefix}/libexec/asdf.sh"
        elif [[ -f "${asdf_prefix}/asdf.sh" ]]; then
            asdf_sh="${asdf_prefix}/asdf.sh"
        fi

        local asdf_comp=""
        if [[ -f "${asdf_prefix}/etc/bash_completion.d/asdf.bash" ]]; then
            asdf_comp="${asdf_prefix}/etc/bash_completion.d/asdf.bash"
        fi

        if [[ -n "$asdf_sh" ]]; then
            sed -i '' "s|^\. .*/asdf\.sh|. ${asdf_sh}|g" "$zshrc"
            status_ok "asdf.sh → $asdf_sh"
        else
            sed -i '' "s|^\(\. .*/asdf\.sh\)|# \1  # asdf.sh not found|g" "$zshrc"
            status_warn "asdf.sh not found — line commented out"
        fi

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

    # ── Git aliases ───────────────────────────────────────────────────
    if grep -q "alias gst='git status'" "$zshrc"; then
        status_ok "Git aliases already present"
    else
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
        status_ok "Added 11 git aliases"
    fi

    # ── Update tmux cheat sheet prefix ──────────────────────────────
    if grep -q 'tmux-cheat' "$zshrc"; then
        # TMUX_PREFIX_CHEAT is what users see in the cheat sheet (e.g. "⇪" for
        # CapsLock, since tmux actually binds IC/Insert under the hood).
        local cheat="${TMUX_PREFIX_CHEAT:-$TMUX_PREFIX}"
        # Update the header line showing the prefix
        sed -i '' "s/(prefix = [^)]*)/(prefix = ${cheat})/g" "$zshrc"
        # Update all keybinding references in the cheat sheet
        # First normalize all possible prefixes to a placeholder, then set the correct one
        sed -i '' 's/"C-a /"__PREFIX__ /g' "$zshrc"
        sed -i '' 's/"C-b /"__PREFIX__ /g' "$zshrc"
        sed -i '' 's/"Home /"__PREFIX__ /g' "$zshrc"
        sed -i '' 's/"⇪ /"__PREFIX__ /g' "$zshrc"
        sed -i '' "s/\"__PREFIX__ /\"${cheat} /g" "$zshrc"
        status_ok "Tmux cheat sheet prefix → ${cheat}"
    fi

    # ── Claude Code PATH ──────────────────────────────────────────────
    local paths_to_add=("$HOME/.local/bin" "$HOME/.claude/bin")
    for p in "${paths_to_add[@]}"; do
        if ! grep -qF "$p" "$zshrc"; then
            printf '\nexport PATH="%s:$PATH"\n' "$p" >> "$zshrc"
            export PATH="$p:$PATH"
            status_ok "Added $p to PATH"
        else
            status_ok "$p PATH already present"
        fi
    done
}

patch_tmux_conf() {
    step_header "10" "PATCH .tmux.conf"
    local tmuxconf="$DOTFILES_DIR/.tmux.conf"

    if [[ ! -e "$tmuxconf" ]]; then
        status_warn ".tmux.conf not found — skipping"
        return
    fi

    # ── Set prefix based on keyboard choice ──────────────────────────
    # Replace the entire prefix block with the correct one for this environment.
    # This removes any stale prefix/prefix2 lines so there are no conflicts.
    local prefix_block
    case "$TMUX_PREFIX" in
        Home)
            prefix_block=$(cat <<'BLOCK'
# ─── Prefix ───────────────────────────────────────────────────────────
# Remove default prefix
unbind C-b

# Set Home as new prefix
set -g prefix Home
bind-key Home send-prefix

# C-a as failsafe alternate prefix
set -g prefix2 C-a
bind-key C-a send-prefix -2

# Double-tap Home to switch to last window
bind-key Home last-window
# ─── /Prefix ──────────────────────────────────────────────────────────
BLOCK
)
            ;;
        IC)
            prefix_block=$(cat <<'BLOCK'
# ─── Prefix ───────────────────────────────────────────────────────────
# Remove default prefix
unbind C-b

# CapsLock is remapped to Insert at the macOS level via hidutil (see
# setup.sh). tmux binds IC (Insert) here — pressing CapsLock sends Insert
# to the terminal. Mac keyboards don't have an Insert key, so IC is a
# safe, otherwise-unused prefix.
set -g prefix IC
bind-key IC send-prefix

# C-a as failsafe alternate prefix (works without the hidutil remap)
set -g prefix2 C-a
bind-key C-a send-prefix -2

# Double-tap CapsLock to switch to last window
bind-key IC last-window
# ─── /Prefix ──────────────────────────────────────────────────────────
BLOCK
)
            ;;
        §)
            prefix_block=$(cat <<'BLOCK'
# ─── Prefix ───────────────────────────────────────────────────────────
# Remove default prefix
unbind C-b

# § is the key above Tab on ISO Mac keyboards — rarely used for typing,
# so it makes a clean, single-press prefix with no modifier.
set -g prefix §
bind-key § send-prefix

# C-a as failsafe alternate prefix (for keyboards without a § key)
set -g prefix2 C-a
bind-key C-a send-prefix -2

# Double-tap § to switch to last window
bind-key § last-window
# ─── /Prefix ──────────────────────────────────────────────────────────
BLOCK
)
            ;;
        C-b)
            prefix_block=$(cat <<'BLOCK'
# ─── Prefix ───────────────────────────────────────────────────────────
# Keep default prefix (C-b) for server environment
set -g prefix C-b
bind-key C-b send-prefix

# Double-tap C-b to switch to last window
bind-key C-b last-window
# ─── /Prefix ──────────────────────────────────────────────────────────
BLOCK
)
            ;;
        *)
            prefix_block=$(cat <<'BLOCK'
# ─── Prefix ───────────────────────────────────────────────────────────
# Remove default prefix
unbind C-b

# Set C-a as new prefix
set -g prefix C-a
bind-key C-a send-prefix

# Double-tap C-a to switch to last window
bind-key C-a last-window
# ─── /Prefix ──────────────────────────────────────────────────────────
BLOCK
)
            ;;
    esac

    # Remove any existing prefix block. Each block starts with
    # "# ─── Prefix" and ends with "# ─── /Prefix" (new-style) OR, for
    # legacy configs written before the closing sentinel existed, runs
    # until the first line that doesn't look like a prefix-block line
    # (comment, blank, or a prefix/bind-key directive). This handles
    # multi-paragraph blocks cleanly — the old sed range `/^$/` stopped
    # at the first blank line and stranded later comments.
    local tmpfile
    tmpfile=$(mktemp)
    awk '
        /^# ─── Prefix/               { in_block = 1; next }
        in_block && /^# ─── \/Prefix/ { in_block = 0; next }
        in_block && /^$/              { next }
        in_block && /^#/              { next }
        in_block && /^unbind /        { next }
        in_block && /^set -g prefix/  { next }
        in_block && /^bind-key /      { next }
        in_block                      { in_block = 0 }
        { print }
    ' "$tmuxconf" > "$tmpfile"
    mv "$tmpfile" "$tmuxconf"

    # Insert the new prefix block at the top of the file
    tmpfile=$(mktemp)
    printf '%s\n\n' "$prefix_block" | cat - "$tmuxconf" > "$tmpfile"
    mv "$tmpfile" "$tmuxconf"

    status_ok "Tmux prefix → ${TMUX_PREFIX}"
    if [[ "$TMUX_PREFIX" == "Home" || "$TMUX_PREFIX" == "IC" ]]; then
        status_ok "Failsafe alternate prefix → C-a"
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# SETUP TOOLS
# ═══════════════════════════════════════════════════════════════════════

setup_vim() {
    step_header "11" "VIM + PATHOGEN PLUGIN MANAGER"
    mkdir -p ~/.vim/autoload ~/.vim/bundle
    if [[ -f ~/.vim/autoload/pathogen.vim ]]; then
        status_ok "Pathogen already installed"
    else
        status_run "Downloading pathogen.vim..."
        curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
        status_ok "Pathogen installed"
    fi

    if [[ -d ~/.vim/bundle/vim-colors-solarized ]]; then
        status_ok "Solarized color scheme already installed"
    else
        status_run "Installing Solarized color scheme..."
        run_quiet git clone https://github.com/altercation/vim-colors-solarized.git ~/.vim/bundle/vim-colors-solarized
        status_ok "Solarized color scheme installed"
    fi
}

setup_tmux() {
    step_header "12" "TMUX PLUGIN MANAGER (TPM)"
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        status_ok "TPM already installed"
    else
        status_run "Cloning TPM..."
        run_quiet git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        status_ok "TPM installed"
    fi
    status_warn "In tmux, press ${TMUX_PREFIX_DISPLAY} then Shift+I to install plugins"
}

set_macos_defaults() {
    step_header "13" "macOS KEYBOARD DEFAULTS"
    defaults write -g InitialKeyRepeat -int 10
    defaults write -g KeyRepeat -int 1
    status_ok "InitialKeyRepeat → 10"
    status_ok "KeyRepeat → 1"

    # CapsLock → Insert remap lives with the keyboard defaults. Applied only
    # when the chosen tmux prefix is IC (Insert); otherwise any prior remap
    # is cleaned up so we don't leave CapsLock silently non-functional.
    if [[ "${TMUX_PREFIX:-}" == "IC" ]]; then
        setup_capslock_remap
    else
        cleanup_capslock_remap
    fi

    status_warn "Log out or restart for changes to take effect"
}

# CapsLock (HID 0x700000039) → Insert (HID 0x700000049). hidutil is a
# macOS built-in (since Sierra), so no third-party tools are required. A
# LaunchAgent re-applies the remap on every login. Insert is picked (not
# F13/F14/etc.) because tmux 3.x only recognizes F1–F12 as key names, but
# it does recognize IC (Insert) — and Mac keyboards have no physical
# Insert key, so nothing else is claiming it.
CAPSLOCK_AGENT_LABEL="com.marcelolebre.capslock-to-insert"
CAPSLOCK_AGENT_LEGACY_LABELS=("com.marcelolebre.capslock-to-f13")
CAPSLOCK_MAPPING='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000049}]}'

setup_capslock_remap() {
    local agent="$HOME/Library/LaunchAgents/${CAPSLOCK_AGENT_LABEL}.plist"

    if ! command -v hidutil &>/dev/null; then
        status_warn "hidutil not available — skipping CapsLock remap"
        return
    fi

    # Remove any legacy CapsLock LaunchAgents so we don't have two mappings fighting.
    local legacy
    for legacy in "${CAPSLOCK_AGENT_LEGACY_LABELS[@]}"; do
        local legacy_plist="$HOME/Library/LaunchAgents/${legacy}.plist"
        if [[ -f "$legacy_plist" ]]; then
            launchctl unload "$legacy_plist" 2>/dev/null || true
            rm -f "$legacy_plist"
            status_ok "Removed legacy LaunchAgent → ${legacy}"
        fi
    done

    hidutil property --set "$CAPSLOCK_MAPPING" >/dev/null
    status_ok "CapsLock → Insert applied for current session"

    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$agent" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${CAPSLOCK_AGENT_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>${CAPSLOCK_MAPPING}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST

    launchctl unload "$agent" 2>/dev/null || true
    if launchctl load "$agent" 2>/dev/null; then
        status_ok "LaunchAgent installed → CapsLock remap persists across reboots"
    else
        status_warn "LaunchAgent install failed — remap is active this session only"
    fi
}

cleanup_capslock_remap() {
    local removed=0
    local label
    for label in "$CAPSLOCK_AGENT_LABEL" "${CAPSLOCK_AGENT_LEGACY_LABELS[@]}"; do
        local agent="$HOME/Library/LaunchAgents/${label}.plist"
        if [[ -f "$agent" ]]; then
            launchctl unload "$agent" 2>/dev/null || true
            rm -f "$agent"
            removed=1
        fi
    done
    if (( removed )); then
        hidutil property --set '{"UserKeyMapping":[]}' >/dev/null 2>&1 || true
        status_ok "Removed previous CapsLock remap"
    fi
}

clone_agent_gossip() {
    step_header "14" "AGENT GOSSIP REPOSITORY"
    local repo_url="https://github.com/marcelolebre/agent-gossip.git"
    local repo_dir="$HOME/Projects/agent-gossip"

    mkdir -p "$HOME/Projects"

    if [[ -d "$repo_dir" ]]; then
        status_run "Repo exists — pulling latest..."
        git -C "$repo_dir" pull --rebase &>/dev/null || status_warn "Pull failed; using existing copy"
        status_ok "agent-gossip updated"
    else
        status_run "Cloning agent-gossip..."
        run_quiet git clone "$repo_url" "$repo_dir"
        status_ok "Cloned to $repo_dir"
    fi

    # Run the setup script to symlink agent-gossip to PATH
    if [[ -x "$repo_dir/setup-agent-gossip" ]]; then
        status_run "Running agent-gossip setup..."
        bash "$repo_dir/setup-agent-gossip" &>/dev/null
        status_ok "agent-gossip installed to PATH"
    else
        status_warn "setup-agent-gossip script not found"
    fi
}

setup_lazyvim() {
    step_header "15" "NEOVIM + LAZYVIM"
    local nvim_config="$HOME/.config/nvim"
    local nvim_src="$DOTFILES_DIR/nvim"

    # Install neovim
    if brew list neovim &>/dev/null; then
        status_ok "Neovim already installed"
    else
        status_run "Installing Neovim..."
        run_quiet brew install neovim
        status_ok "Neovim installed"
    fi

    # Install LazyVim dependencies
    local lazy_deps=(ripgrep fd lazygit node)
    for dep in "${lazy_deps[@]}"; do
        if brew list "$dep" &>/dev/null; then
            status_ok "${dep} already installed"
        else
            status_run "Installing ${dep}..."
            run_quiet brew install "$dep"
            status_ok "${dep} installed"
        fi
    done

    # Symlink nvim config
    mkdir -p "$HOME/.config"

    if [[ ! -d "$nvim_src" ]]; then
        status_warn "nvim/ missing from $DOTFILES_DIR — skipping symlink (check pull output above)"
        return
    fi

    if [[ -L "$nvim_config" ]]; then
        local current_target
        current_target="$(readlink "$nvim_config")"
        if [[ "$current_target" == "$nvim_src" && -d "$nvim_config/" ]]; then
            status_ok "~/.config/nvim already symlinked correctly"
        else
            rm "$nvim_config"
            ln -s "$nvim_src" "$nvim_config"
            status_ok "Repaired ~/.config/nvim → $nvim_src"
        fi
    elif [[ -e "$nvim_config" ]]; then
        local bk="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$nvim_config" "$bk"
        status_warn "Backed up existing nvim config → $bk"
        ln -s "$nvim_src" "$nvim_config"
        status_ok "~/.config/nvim → $nvim_src"
    else
        ln -s "$nvim_src" "$nvim_config"
        status_ok "~/.config/nvim → $nvim_src"
    fi

    status_warn "Run 'nvim' to finish — LazyVim will install plugins on first launch"
}

install_claude_code() {
    step_header "16" "CLAUDE CODE CLI"

    if command -v claude &>/dev/null; then
        local ver
        ver="$(claude --version 2>/dev/null || echo "unknown")"
        status_ok "Claude Code already installed  [${ver}]"
        return
    fi

    status_run "Installing Claude Code via native installer..."
    curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null

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
}

# ═══════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════
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
    box_line "  ${A}STEP${N}  ${D}|${N}  01  02  03  04  05  06  07  08  09  10  11  12  13  14  15  16"
    box_line "  ${A}TASK${N}  ${D}|${N}  BRW PKG ITM ASD DOT ZSH SHL LNK ZRC TMX VIM TPM KEY GSP NVim CLC"
    box_line ""
    box_bottom
    printf '\n'

    printf "  ${D}"
    type_out "*** INITIALIZING SYSTEM SETUP ***" 0.03
    printf "${N}"
    printf '\n'

    read -rp "$(printf '  %bPress [ENTER] to begin or [Ctrl+C] to abort...%b ' "${A}" "${N}")"
    printf '\n'

    # ── Keyboard layout prompt ───────────────────────────────────────
    printf "  ${A}What setup are you using?${N}\n"
    printf "  ${D}1)${N} Ergodox keyboard\n"
    printf "  ${D}2)${N} Regular Mac keyboard  ${D}(§ as tmux prefix)${N}\n"
    printf "  ${D}3)${N} Server\n"
    printf "  ${D}4)${N} ANSI keyboard  ${D}(remaps CapsLock → tmux prefix)${N}\n"
    printf "  ${A}Choose [1/2/3/4]:${N} "
    read -r setup_answer
    case "$setup_answer" in
        1)
            TMUX_PREFIX="Home"
            TMUX_PREFIX_DISPLAY="Home"
            TMUX_PREFIX_CHEAT="Home"
            ;;
        2)
            TMUX_PREFIX="§"
            TMUX_PREFIX_DISPLAY="§"
            TMUX_PREFIX_CHEAT="§"
            ;;
        3)
            TMUX_PREFIX="C-b"
            TMUX_PREFIX_DISPLAY="C-b"
            TMUX_PREFIX_CHEAT="C-b"
            ;;
        4)
            TMUX_PREFIX="IC"
            TMUX_PREFIX_DISPLAY="⇪ CapsLock"
            TMUX_PREFIX_CHEAT="⇪"
            ;;
        *)
            TMUX_PREFIX="C-a"
            TMUX_PREFIX_DISPLAY="C-a"
            TMUX_PREFIX_CHEAT="C-a"
            ;;
    esac
    printf "  ${D}Tmux prefix set to: ${A}${TMUX_PREFIX_DISPLAY}${N}\n\n"

    box_top

    # ── Install dependencies ──────────────────────────────────────────
    install_homebrew
    install_packages
    install_iterm2
    install_asdf

    # ── Clone/pull repo (gets latest from git) ────────────────────────
    clone_dotfiles

    # ── Shell & framework setup ───────────────────────────────────────
    install_oh_my_zsh
    set_default_shell

    # ── Symlink configs (HOME → repo) ─────────────────────────────────
    link_dotfiles

    # ── Patch repo configs (re-applied after every git pull) ──────────
    patch_zshrc
    patch_tmux_conf

    # ── Tool setup ────────────────────────────────────────────────────
    setup_vim
    setup_tmux
    set_macos_defaults
    clone_agent_gossip
    setup_lazyvim
    install_claude_code

    # ── Issue summary ─────────────────────────────────────────────────
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
    box_line "  ${D}2.${N} Launch tmux > press ${A}${TMUX_PREFIX_DISPLAY}${N} then ${A}Shift+I${N}"
    box_line "  ${D}3.${N} Open a new terminal to load Zsh config"
    box_line "  ${D}4.${N} Run ${A}nvim${N} to finish LazyVim plugin installation"
    box_line "  ${D}5.${N} Run ${A}claude${N} in a project dir to authenticate"
    box_line "  ${D}6.${N} Check ${A}~/Projects/agent-gossip${N} for agent-gossip"
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
