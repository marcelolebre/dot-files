# Shared skills (Claude Code + Codex)

Skills here are the single source of truth for both agents. `setup.sh`
(`install_skills`) symlinks each one into both tools, so there are no copies and
a `git pull` of dot-files updates both at once:

- Claude Code reads the whole skill directory at `~/.claude/skills/<name>`.
- Codex reads the same `SKILL.md` as the `/<name>` prompt at
  `~/.codex/prompts/<name>.md`.

## Add a skill

Create `claude/skills/<name>/SKILL.md` and run `setup.sh`. The YAML frontmatter
(`name`, `description`) drives Claude's auto-discovery; Codex ignores it and uses
the body as the prompt. Helper files alongside `SKILL.md` are visible to Claude
(it gets the directory) but not to Codex (it gets only `SKILL.md`), so keep
single-file skills if you want both tools to behave the same.

## anti-slopper

Not here on purpose. It's a published standalone repo
(github.com/marcelolebre/anti-slopper) with its own LICENSE/NOTICE, cloned to
`~/Projects/anti-slopper` and symlinked by `clone_anti_slopper`. `install_skills`
skips the name so the two paths never collide.
