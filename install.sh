#!/bin/zsh
# install.sh: link this repo's scripts into ~/.local/bin so the clone is the only copy.
# An existing regular file is moved aside to <name>.pre-repo, never overwritten.
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
    mv "$target" "$target.pre-repo"
    echo "moved    $target -> $name.pre-repo"
  fi
  ln -s "$src" "$target"
  echo "linked   $target -> $src"
done
[[ -f "$HOME/.config/rc-loop.env" ]] || echo "note     no ~/.config/rc-loop.env yet; copy config/rc-loop.env.example there"
