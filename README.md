# dot-files

Personal macOS development environment setup for [marcelolebre](https://github.com/marcelolebre/dot-files).

## Quick Start

```bash
bash setup.sh
```

Safe to re-run at any time — it skips steps that are already complete and re-applies patches after every run.

---

## What `setup.sh` Does

The script runs 17 steps in order. Each step is skipped if already done.

### Step 01 — Homebrew
Installs [Homebrew](https://brew.sh) if not present, then runs `brew update` to refresh the package index.

### Step 02 — CLI Packages
Installs the following packages via Homebrew (skips any already installed):
- `git` — version control
- `vim` — text editor
- `tmux` — terminal multiplexer
- `zsh` — shell
- `reattach-to-user-namespace` — tmux clipboard integration on macOS
- `glab` — GitLab CLI
- `gh` — GitHub CLI

> Neovim and its LazyVim dependencies (`ripgrep`, `fd`, `lazygit`, `node`) are installed later in step 15, not here.

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
2. **asdf sourcing** — if Homebrew reports an asdf prefix, rewrites the `asdf.sh` and completion source paths to match it (commenting a line out if its file is missing under that prefix). If asdf isn't installed at all, the lines are left unchanged.
3. **Git aliases** — appends 11 short git aliases (`gst`, `ga`, `gc`, `gcm`, `gd`, `gdc`, `gp`, `gpl`, `gco`, `gcob`, `gb`) if not already present.
4. **PATH entries** — adds `~/.local/bin` and `~/.claude/bin` to `$PATH` if not already there.
5. **Tmux cheat-sheet prefix** — rewrites the `tmux-cheat` helper's `(prefix = …)` header and its keybinding hints (those using `C-a`, `C-b`, `Home`, or `⇪`) to match the prefix chosen in step 10.

### Step 10 — Patch `.tmux.conf`
Re-applied on every run. The keyboard-layout prompt at the start of the script picks the tmux prefix:

| Choice | Prefix | Notes |
| --- | --- | --- |
| 1) Ergodox keyboard | `Home` | Uses the dedicated Home key |
| 2) Regular Mac keyboard | `§` | The key above Tab on ISO Mac keyboards — single press, no modifier |
| 3) Server | `C-b` | tmux default, safe over SSH |
| 4) ANSI keyboard | **CapsLock** (Karabiner remap → `F18`) | See step 13 — Karabiner-Elements remaps CapsLock to F18 and tmux binds the F18 escape sequence as a user-key prefix |

Options 1, 2, and 4 also bind `C-a` as `prefix2`, a failsafe that works even when the primary key isn't available (e.g. a remote shell or a keyboard without `§`).

### Step 11 — Vim + Pathogen
Sets up Vim plugin management:
- Creates `~/.vim/autoload/` and `~/.vim/bundle/` directories.
- Downloads [Pathogen](https://github.com/tpope/vim-pathogen) to `~/.vim/autoload/pathogen.vim`.
- Clones the [Solarized color scheme](https://github.com/altercation/vim-colors-solarized) into `~/.vim/bundle/`.

### Step 12 — Tmux Plugin Manager (TPM)
Clones [TPM](https://github.com/tmux-plugins/tpm) to `~/.tmux/plugins/tpm` and then runs TPM's headless installer (`~/.tmux/plugins/tpm/bin/install_plugins`) to fetch every `@plugin` entry declared in `.tmux.conf` — `tmux-sensible`, `tmux-resurrect`, `tmux-continuum`, `tmux-battery`, and `tmux-colors-solarized`. This means `tmux-continuum` starts auto-saving sessions immediately on first tmux launch; no `prefix + Shift+I` needed.

> If you add a new `@plugin` line later, press the tmux prefix then `Shift+I` inside a tmux session to pick it up — or just re-run `setup.sh`.

### Step 13 — macOS Keyboard Defaults
Speeds up key repeat for a better coding experience:
- `InitialKeyRepeat` → `10` (delay before repeat starts, ~150 ms)
- `KeyRepeat` → `1` (repeat interval, ~15 ms)

If **CapsLock** was chosen as the tmux prefix in step 10 (option 4), this step also:
- Installs **Karabiner-Elements** via `brew install --cask karabiner-elements`.
- Symlinks `karabiner/capslock-to-f18.json` into `~/.config/karabiner/assets/complex_modifications/` so the rule shows up in Karabiner's UI under **Settings → Complex Modifications → Add predefined rule** as *"Remap Caps Lock to F18"*. You enable it there once.
- Karabiner-Elements needs **Input Monitoring** and **Accessibility** permissions on first launch — grant them in **System Settings → Privacy & Security** when prompted.

Why Karabiner instead of `hidutil`: macOS rewrites HID `0x49` (Insert) into `NSHelpFunctionKey` on its way to apps, so a `hidutil` CapsLock→Insert remap shows up in the terminal as a private-use Unicode codepoint (U+F746) that tmux can't bind. Karabiner sits low enough to remap CapsLock to F18 cleanly, and tmux 3.6 binds the F18 escape sequence (`\e[17;2~`) via `user-keys[0]` since `F18` itself isn't a tmux key name.

Older versions of this script used `hidutil` plus a LaunchAgent. Both are now purged on every run regardless of the prefix choice — so re-running `setup.sh` after upgrading is enough.

To undo the CapsLock remap manually: open Karabiner-Elements → **Complex Modifications**, remove the *"Remap Caps Lock to F18"* rule (or quit Karabiner-Elements entirely). Optionally:

```bash
rm ~/.config/karabiner/assets/complex_modifications/capslock-to-f18.json
brew uninstall --cask karabiner-elements
```

> Log out or restart for the keyboard repeat changes to take effect.

### Step 14 — Agent Gossip Repository
Clones [agent-gossip](https://github.com/marcelolebre/agent-gossip) to `~/Projects/agent-gossip` (runs `git pull --rebase` if it already exists), then runs the repo's bundled `setup-agent-gossip` script, if present, to symlink it onto `$PATH`.

### Step 15 — Neovim + LazyVim
Sets up the [Neovim](https://neovim.io) / [LazyVim](https://www.lazyvim.org) editor:
- Installs `neovim` plus the LazyVim dependencies `ripgrep`, `fd`, `lazygit`, and `node` via Homebrew.
- Symlinks the repo's `nvim/` directory to `~/.config/nvim` (an existing real config is backed up to `~/.config/nvim.backup.<timestamp>` first; a wrong symlink is repaired).
- When `elixir-ls` isn't already installed under Mason, headlessly bootstraps plugins (`nvim --headless +Lazy! restore`) to the `lazy-lock.json` versions, then installs the `elixir-ls` LSP via Mason (`+MasonInstall elixir-ls`).

> First `nvim` launch finishes any remaining LazyVim plugin setup. If the Elixir LSP install failed, run `:MasonInstall elixir-ls` inside nvim.

### Step 16 — Claude Code CLI
Installs the [Claude Code](https://claude.ai) CLI tool via its official installer script. Adds the binary to `$PATH`.

> **After install:** Run `claude` inside any project directory to authenticate.

### Step 17 — Codex CLI
Installs the [Codex](https://github.com/openai/codex) CLI via Homebrew (`brew install codex`).

> **After install:** Run `codex` and sign in to authenticate.

### Step 18 — Anti-Slopper Skill
Clones [anti-slopper](https://github.com/marcelolebre/anti-slopper) to `~/Projects/anti-slopper` (runs `git pull --rebase` if it already exists), then wires it into both agents from the same checkout:
- **Claude Code** — symlinks `~/.claude/skills/anti-slopper` to the checkout so it loads the writing-style skill from `SKILL.md`. The global `~/.claude/CLAUDE.md` rules point at this path.
- **Codex** — symlinks `~/.codex/prompts/anti-slopper.md` to `SKILL.md`, exposing it as the `/anti-slopper` prompt.

Both are symlinks, so a `git pull` in the repo updates both at once.

### Step 19 — Shared Skills (Claude + Codex)
Installs every skill kept in this repo under `claude/skills/<name>/SKILL.md` into both agents from a single source — no copies:
- **Claude Code** — symlinks `~/.claude/skills/<name>` to the repo dir (the whole skill, frontmatter and any helper files).
- **Codex** — symlinks `~/.codex/prompts/<name>.md` to the same `SKILL.md`, exposing it as the `/<name>` prompt.

Drop a new `claude/skills/<name>/SKILL.md` into the repo and it ships to both tools on the next setup run. A `git pull` updates both at once. anti-slopper is skipped here — it has its own published repo (Step 18).

---

## After Running Setup

1. Open **iTerm2** → `Profiles > Colors > Color Presets` → choose **Solarized Dark**
2. Open a **new terminal window** to load the updated Zsh config
3. Run `nvim` to finish LazyVim plugin installation
4. Run `claude` in a project directory to log in to Claude Code
5. Run `codex` and sign in to authenticate
6. Check `~/Projects/agent-gossip` for agent-gossip
7. The anti-slopper writing skill lives at `~/Projects/anti-slopper`
