# dot-files

Personal macOS development environment setup for [marcelolebre](https://github.com/marcelolebre/dot-files).

## Quick Start

```bash
bash setup.sh
```

Safe to re-run at any time — it skips steps that are already complete and re-applies patches after every run.

---

## What `setup.sh` Does

The script runs 14 steps in order. Each step is skipped if already done.

### Step 01 — Homebrew
Installs [Homebrew](https://brew.sh) if not present, then runs `brew update` to refresh the package index.

### Step 02 — CLI Packages
Installs the following packages via Homebrew (skips any already installed):
- `git` — version control
- `vim` — text editor
- `tmux` — terminal multiplexer
- `zsh` — shell
- `reattach-to-user-namespace` — tmux clipboard integration on macOS

### Step 03 — iTerm2
Installs the [iTerm2](https://iterm2.com) terminal emulator via `brew install --cask iterm2`.

> **Manual step after install:** Go to `Profiles > Colors > Color Presets` and choose **Solarized Dark**.

### Step 04 — asdf Version Manager
Installs [asdf](https://asdf-vm.com) via Homebrew — a single tool to manage multiple runtime versions (Node, Ruby, Python, etc.).

### Step 05 — Clone / Update Dotfiles Repo
Clones this repo to `~/.dot-files`. If it already exists, runs `git pull --rebase` to pull the latest changes.

### Step 06 — Oh My Zsh
Installs [Oh My Zsh](https://ohmyz.sh) without overwriting any existing `.zshrc`.

### Step 07 — Default Shell
Sets Zsh as the default shell (`chsh -s`). Adds the Zsh path to `/etc/shells` first if needed.

### Step 08 — Symlink Dotfiles
Creates symlinks from `$HOME` to every dotfile in `~/.dot-files/` (e.g. `~/.zshrc → ~/.dot-files/.zshrc`).

- If a real (non-symlink) file already exists at a destination, it is **backed up** to `~/.dotfiles-backup/<timestamp>/` before being replaced.
- Existing symlinks are replaced without backup.

### Step 09 — Patch `.zshrc`
Re-applied on every run after `git pull`. Makes the repo's `.zshrc` work on the local machine:

1. **Hardcoded paths** — replaces any `/Users/marcelolebre` references with the actual `$HOME`.
2. **asdf sourcing** — updates the `asdf.sh` and completion paths to match the local Homebrew install location.
3. **Git aliases** — appends a set of short git aliases (`gst`, `ga`, `gc`, `gp`, etc.) if not already present.
4. **PATH entries** — adds `~/.local/bin` and `~/.claude/bin` to `$PATH` if not already there.

### Step 10 — Patch `.tmux.conf`
Re-applied on every run. The keyboard-layout prompt at the start of the script picks the tmux prefix:

| Choice | Prefix | Notes |
| --- | --- | --- |
| 1) Ergodox keyboard | `Home` | Uses the dedicated Home key |
| 2) Regular Mac keyboard | **CapsLock** (bound as `F13`) | See step 13 — CapsLock is remapped to F13 at the OS level so tmux can bind it |
| 3) Server | `C-b` | tmux default, safe over SSH |
| 4) ANSI keyboard | `C-a` | |

Options 1 and 2 also bind `C-a` as `prefix2`, a failsafe that works even when the OS-level remap isn't in place (e.g. inside a remote shell).

### Step 11 — Vim + Pathogen
Sets up Vim plugin management:
- Creates `~/.vim/autoload/` and `~/.vim/bundle/` directories.
- Downloads [Pathogen](https://github.com/tpope/vim-pathogen) to `~/.vim/autoload/pathogen.vim`.
- Clones the [Solarized color scheme](https://github.com/altercation/vim-colors-solarized) into `~/.vim/bundle/`.

### Step 12 — Tmux Plugin Manager (TPM)
Clones [TPM](https://github.com/tmux-plugins/tpm) to `~/.tmux/plugins/tpm`.

> **Manual step after install:** Inside a tmux session, press `Ctrl+a` then `Shift+I` to install plugins.

### Step 13 — macOS Keyboard Defaults
Speeds up key repeat for a better coding experience:
- `InitialKeyRepeat` → `10` (delay before repeat starts, ~150 ms)
- `KeyRepeat` → `1` (repeat interval, ~15 ms)

If **CapsLock** was chosen as the tmux prefix in step 10, this step also:
- Applies a `hidutil` remap of CapsLock (HID `0x700000039`) → F13 (HID `0x700000068`) for the current session.
- Installs `~/Library/LaunchAgents/com.marcelolebre.capslock-to-f13.plist` so the remap reapplies on every login. No third-party tools (no Karabiner) are required — `hidutil` ships with macOS.
- If a different prefix is picked on a later run, the LaunchAgent is removed and the remap is cleared so CapsLock isn't left silently non-functional.

To undo the CapsLock remap manually:

```bash
launchctl unload ~/Library/LaunchAgents/com.marcelolebre.capslock-to-f13.plist
rm ~/Library/LaunchAgents/com.marcelolebre.capslock-to-f13.plist
hidutil property --set '{"UserKeyMapping":[]}'
```

> Log out or restart for these changes to take effect.

### Step 14 — Claude Code CLI
Installs the [Claude Code](https://claude.ai) CLI tool via its official installer script. Adds the binary to `$PATH`.

> **After install:** Run `claude` inside any project directory to authenticate.

---

## After Running Setup

1. Open **iTerm2** → `Profiles > Colors > Color Presets` → choose **Solarized Dark**
2. Start tmux and press `Ctrl+a` then `Shift+I` to install tmux plugins
3. Open a **new terminal window** to load the updated Zsh config
4. Drop Vim plugins into `~/.vim/bundle/`
5. Run `claude` in a project directory to log in to Claude Code
