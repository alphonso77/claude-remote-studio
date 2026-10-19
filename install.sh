#!/bin/zsh
# install.sh: link this repo's scripts into ~/.local/bin so the clone is the only copy.
# An existing file is moved aside to <name>.pre-repo (or .pre-repo.<timestamp> if that
# name is taken), so no backup is ever overwritten.
# It doesn't touch running processes, ~/.claude/CLAUDE.md or ~/.config/rc-loop.env.
set -e
repo="${0:A:h}"
dest="$HOME/.local/bin"
mkdir -p "$dest"
for src in "$repo"/bin/*; do
  name="${src:t}"
  target="$dest/$name"
  if [[ -L "$target" && "${target:A}" == "${src:A}" ]]; then
    echo "ok       $name (already linked)"; continue
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    backup="$target.pre-repo"
    [[ -e "$backup" || -L "$backup" ]] && backup="$backup.$(date +%Y%m%d-%H%M%S)"
    mv -n "$target" "$backup"
    echo "moved    $target -> ${backup:t}"
  fi
  ln -s "$src" "$target"
  echo "linked   $target -> $src"
done
[[ -f "$HOME/.config/rc-loop.env" ]] || echo "note     no ~/.config/rc-loop.env yet; copy config/rc-loop.env.example there"
