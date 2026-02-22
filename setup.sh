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

# ─── Colors ───────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ─── 1. Install Homebrew (if missing) ────────────────────────────────
install_homebrew() {
    if command -v brew &>/dev/null; then
        success "Homebrew already installed"
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add brew to PATH for Apple Silicon Macs
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        success "Homebrew installed"
    fi
    brew update
}

# ─── 2. Install CLI tools ────────────────────────────────────────────
install_packages() {
    info "Installing packages via Homebrew..."

    local packages=(
        git
        vim
        tmux
        zsh
        reattach-to-user-namespace   # tmux + macOS clipboard
    )

    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            success "$pkg already installed"
        else
            info "Installing $pkg..."
            brew install "$pkg"
        fi
    done
}

# ─── 3. Install iTerm2 (cask) ────────────────────────────────────────
install_iterm2() {
    if [[ -d "/Applications/iTerm.app" ]]; then
        success "iTerm2 already installed"
    else
        info "Installing iTerm2..."
        brew install --cask iterm2
        success "iTerm2 installed"
    fi
    warn "Remember to set Solarized Dark in iTerm2:"
    warn "  Profiles → Colors → Color Presets → Solarized Dark"
}

# ─── 4. Clone the dotfiles repo ──────────────────────────────────────
clone_dotfiles() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        info "Dotfiles repo already exists at $DOTFILES_DIR — pulling latest..."
        git -C "$DOTFILES_DIR" pull --rebase || warn "Pull failed; using existing copy"
    else
        info "Cloning dotfiles repo..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
    success "Dotfiles repo ready at $DOTFILES_DIR"
}

# ─── 5. Backup & symlink dotfiles ────────────────────────────────────
link_dotfiles() {
    info "Symlinking dotfiles..."

    local files=(.zshrc .vimrc .tmux.conf)

    mkdir -p "$BACKUP_DIR"

    for f in "${files[@]}"; do
        local src="$DOTFILES_DIR/$f"
        local dest="$HOME/$f"

        if [[ ! -f "$src" ]]; then
            warn "Source file $src not found — skipping"
            continue
        fi

        # Backup existing file (if it's a real file, not already our symlink)
        if [[ -e "$dest" && ! -L "$dest" ]]; then
            info "Backing up existing $dest → $BACKUP_DIR/$f"
            mv "$dest" "$BACKUP_DIR/$f"
        elif [[ -L "$dest" ]]; then
            rm "$dest"
        fi

        ln -s "$src" "$dest"
        success "Linked $dest → $src"
    done

    # Remove backup dir if empty
    rmdir "$BACKUP_DIR" 2>/dev/null && info "No backups needed" || true
}

# ─── 6. Install Oh My Zsh ────────────────────────────────────────────
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        success "Oh My Zsh already installed"
    else
        info "Installing Oh My Zsh..."
        # RUNZSH=no prevents it from switching shell mid-script
        RUNZSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        success "Oh My Zsh installed"
    fi
}

# ─── 7. Set Zsh as default shell ─────────────────────────────────────
set_default_shell() {
    local zsh_path
    zsh_path="$(which zsh)"

    if [[ "$SHELL" == *"zsh"* ]]; then
        success "Zsh is already the default shell"
    else
        info "Setting Zsh as the default shell..."
        # Ensure our zsh is in /etc/shells
        if ! grep -qF "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        fi
        chsh -s "$zsh_path"
        success "Default shell set to $zsh_path"
    fi
}

# ─── 8. Setup Vim + Pathogen ─────────────────────────────────────────
setup_vim() {
    info "Setting up Vim with Pathogen..."

    mkdir -p ~/.vim/autoload ~/.vim/bundle

    if [[ -f ~/.vim/autoload/pathogen.vim ]]; then
        success "Pathogen already installed"
    else
        curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
        success "Pathogen installed"
    fi
}

# ─── 9. Setup Tmux Plugin Manager (TPM) ──────────────────────────────
setup_tmux() {
    info "Setting up Tmux Plugin Manager (TPM)..."

    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        success "TPM already installed"
    else
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        success "TPM installed"
    fi

    warn "After launching tmux, press prefix + I to install plugins"
}

# ─── 10. macOS keyboard repeat speed ─────────────────────────────────
set_macos_defaults() {
    info "Configuring macOS keyboard repeat speed..."

    defaults write -g InitialKeyRepeat -int 10   # default minimum: 15 (225 ms)
    defaults write -g KeyRepeat -int 1            # default minimum: 2 (30 ms)

    success "Key repeat speed configured"
    warn "You may need to log out / restart for key repeat changes to take effect"
}

# ─── Main ─────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   marcelolebre/dot-files — Automated Setup Script   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Confirm before proceeding
    read -rp "This will install packages and overwrite dotfiles. Continue? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }

    install_homebrew
    install_packages
    install_iterm2
    clone_dotfiles
    install_oh_my_zsh
    set_default_shell
    link_dotfiles        # symlink AFTER oh-my-zsh so it doesn't overwrite .zshrc
    setup_vim
    setup_tmux
    set_macos_defaults

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 Setup complete! 🎉                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Open iTerm2 → Profiles → Colors → Solarized Dark"
    echo "  2. Launch tmux and press prefix + I to install tmux plugins"
    echo "  3. Open a new terminal to load your new Zsh config"
    echo "  4. Optionally install Vim plugins into ~/.vim/bundle/"
    echo ""
    echo "Backups of any replaced dotfiles are in: $BACKUP_DIR"
}

main "$@"
