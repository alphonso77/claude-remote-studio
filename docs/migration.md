# Migrating a hand-made install to this repo

If you built this setup by pasting scripts into `~/.local/bin` (as we first did), move onto the repo so there's one copy of everything. After migrating, change the scripts by committing to the repo and pulling on the Mac, never by editing them in place. `rc-doctor` flags drift.

Only one step interrupts your phone sessions. The server itself is back in about a minute; any phone-started sessions have to be brought back one at a time afterward (see step 3).

## Before you start

- Note what's running: `pgrep -fl "remote-control"` and `tmux ls`.
- In the commands below, `rc-myproject` stands for whatever you named your hand-made loop script.
- **Record each session's ID.** Open each session at claude.ai/code and copy the part of its URL between `/code/` and any `?`. For each session you started from the phone, also note its worktree folder (`git worktree list`; the folder name contains the same ID). If a session doesn't come back after the restart in step 3, `claude remote-control --session-id <id>`, run from that folder within about four hours, brings it back. This is the last resort for both the switch and the rollback.
- Do the steps from a terminal on the Mac or over SSH, **not from a session this server is serving**. Step 3 stops the server, which ends that session mid-step.

## Step 1: clone and install (no downtime)

```sh
git clone https://github.com/alphonso77/claude-remote-studio ~/code/claude-remote-studio
```

Before installing, diff your hand-made scripts against the clone. Anything you changed by hand either goes into the repo first (by PR) or is dropped on purpose.

```sh
diff ~/.local/bin/ask-local ~/code/claude-remote-studio/bin/ask-local
diff ~/.local/bin/rc-myproject ~/code/claude-remote-studio/bin/rc-loop   # expect differences: rc-loop reads a config file
```

Then install:

```sh
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

If your old script didn't pass `--spawn`, this is also the first run with `--spawn=worktree` set explicitly. It should match what you chose at the first-run prompt, but check the `Capacity` line says new sessions get an isolated worktree.

1. Attach: `tmux attach -t rc`.
2. Press `Ctrl+C`. If the `Restarting in 30s` line appears, press it again, until you're at a shell prompt.
3. Run `rc-loop`. Wait for **Connected**.
4. Check that the server's own session is listed and answers a message from the phone. Expect phone-started sessions to be missing (below).
5. Detach with `Ctrl+B`, then `D`.

Do this inside the existing `rc` pane rather than a new SSH shell, because Claude Code reports "Not logged in" over SSH. That pane descends from Terminal on the Mac's own screen.

**Expect sessions you started from the phone not to come back.** In our run, only the server's own session returned. For each missing one, open a new tmux window (`Ctrl+B`, then `C`), `cd` into its worktree folder, and run `claude remote-control --session-id <id>` with the ID you recorded. Leave it running in that window: it serves only that session and exits when the session ends. Don't run it in the main repo folder; only one server can run per folder, and the command fails there.

**Rollback:** same steps, but run the old script (`~/.local/bin/rc-myproject`) in step 3. Rolling back doesn't bring the phone-started sessions back either; the same `--session-id` fallback applies.

## Step 4: confirm and clean up

- `rc-doctor`: every line should say `ok`.
- Keep the old script and `*.pre-repo` files for a week or so, then delete them.
