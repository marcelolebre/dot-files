#!/bin/sh
# Render a tmux pane-border label: "<project> @ <branch>", colored by a stable
# hash of the project name so every pane in the same project shares one color
# (active pane = filled background, inactive = colored text). The project is
# the folder under ~/Projects/<project>, so it's right even after cd'ing into a
# subdirectory; outside ~/Projects it falls back to the current dir's basename.
#
# Args:  $1 = pane_current_path   $2 = pane_active (1 when the pane is active)
# Used by pane-border-format in ~/.tmux.conf.
#
# Why a separate file: tmux's #() parser counts parentheses to find the end of
# the command, and the unmatched ')' in a `case` pattern makes it stop early
# and print the rest of the script as literal text. Keeping the logic here
# means tmux only ever sees a balanced `#(pane-label.sh "$path" $active)`.

path=$1
active=$2

case "$path" in
    */Projects/*) proj=${path##*/Projects/}; proj=${proj%%/*} ;;
    *)            proj=${path##*/} ;;
esac

# Stable per-project color: hash the bare project name (cksum) into the palette.
# The branch is deliberately NOT part of the hash, so switching branch keeps the
# color. Palette colors read well both as a fg on a dark border and as a bg
# behind black text; edit the list to taste.
pal="196 202 208 214 220 190 154 118 82 46 51 45 39 75 99 129 165 201 207 213"
nc=$(echo "$pal" | wc -w | tr -d ' ')
n=$(printf '%s' "$proj" | cksum | cut -d' ' -f1)
col=$(echo "$pal" | cut -d' ' -f$(( n % nc + 1 )))

branch=$(cd "$path" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
label=$proj
[ -n "$branch" ] && label="$proj @ $branch"

# tmux re-parses the #[...] in this output as a real style.
if [ "$active" = 1 ]; then
    printf '#[fg=colour16,bg=colour%s,bold] %s #[default]' "$col" "$label"
else
    printf '#[fg=colour%s,bold] %s #[default]' "$col" "$label"
fi
