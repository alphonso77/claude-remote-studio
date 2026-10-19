# Migrating a hand-made install to this repo

If you built this setup by pasting scripts into `~/.local/bin` (as we first did), move onto the repo so there's one copy of everything. After migrating, change the scripts by committing to the repo and pulling on the Mac, never by editing them in place. `rc-doctor` flags drift.

Only one step interrupts your phone sessions, and only for about a minute.

## Before you start

- Note what's running: `pgrep -fl "remote-control"` and `tmux ls`.
- Diff your hand-made scripts against the repo's. Anything you changed by hand either goes into the repo first (by PR) or is dropped on purpose.
  ```sh
  diff ~/.local/bin/ask-local ~/code/claude-remote-studio/bin/ask-local
  diff ~/.local/bin/rc-myproject ~/code/claude-remote-studio/bin/rc-loop   # expect differences: rc-loop reads a config file
  ```

## Step 1: clone and install (no downtime)

```sh
git clone https://github.com/alphonso77/claude-remote-studio ~/code/claude-remote-studio
~/code/claude-remote-studio/install.sh
```

`install.sh` moves an existing `~/.local/bin/ask-local` aside to `ask-local.pre-repo` and links the repo's copy in its place. The next `ask-local` call uses the repo's copy, and running sessions don't notice. Your old loop script has a different name from `rc-loop`, so it's untouched and keeps running.

Create `~/.config/rc-loop.env` with the **same** repo path and session name your old script used. If the name changes, the server will show the new title and you may lose track of which session is which.

## Step 2: CLAUDE.md (no downtime)

In `~/.claude/CLAUDE.md`, replace the pasted "Local model" section with:

```
@~/code/claude-remote-studio/claude-md/local-model.md
```

Keep anything specific to you (your project's example data, other sections) in your own file, below the import. Running sessions keep what they loaded at startup. New sessions pick up the import.

## Step 3: switch the server to rc-loop (about 1 minute)

Pick a moment when **no session is in the middle of a task**: anything mid-turn is interrupted.

1. Attach: `tmux attach -t rc`.
2. Press `Ctrl+C`. If the `Restarting in 30s` line appears, press it again, until you're at a shell prompt.
3. Run `rc-loop`. Wait for **Connected**.
4. Check that the session list and capacity match what you had before. From the phone, send a message to an existing session.
5. Detach with `Ctrl+B`, then `D`.

Do this inside the existing `rc` pane rather than a new SSH shell. That pane descends from Terminal on the Mac's own screen. Per Anthropic's docs, restarting the server in the same folder within about four hours brings back the sessions it was serving.

**Rollback:** same steps, but run the old script (`~/.local/bin/rc-myproject`) in step 3.

## Step 4: confirm and clean up

- `rc-doctor`: every line should say `ok`.
- Keep the old script and `*.pre-repo` files for a week or so, then delete them.
