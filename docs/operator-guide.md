# Operator guide

What you'll see on the Mac's screen, what each part does, and what to do (and not do) with it. The behavior described for `claude remote-control` comes from Anthropic's [Remote Control docs](https://code.claude.com/docs/en/remote-control) unless marked as observed here.

## The screen

When you look at the Mac (at its screen or over Screen Sharing), Terminal usually has a few tabs. Two kinds matter:

**The `rc` tab: the server.** The tab title says `tmux new -s rc` (or `tmux attach -t rc`), and a green tmux status bar at the bottom reads `[rc] 0:zsh*`. This is the one that keeps your phone sessions alive. It shows something like:

```
✔︎ Connected · my-project
  Capacity: 3/32 · New sessions will be created in an isolated worktree
  My project on Studio
  Code reviews
  Hello

Continue coding in the Claude mobile app or https://claude.ai/code?environment=env_…
space to show QR code · w to toggle spawn mode
```

| Line | Meaning |
|---|---|
| `Connected · my-project` | The server can reach Anthropic and is serving this repo. |
| `Capacity: 3/32` | 3 sessions open, out of a maximum of 32 (`--capacity` changes it). |
| `New sessions will be created in an isolated worktree` | Spawn mode is `worktree`: each session you start from the phone gets its own git worktree, so sessions can't overwrite each other's files. The first session (the one the server pre-creates) works in the repo folder itself. |
| The list of names | The sessions this server is serving. See [known issues](known-issues.md#renamed-sessions-keep-their-old-name-in-some-views): renames may not show here. |
| The `env_…` URL | Opens this machine's environment at claude.ai/code. It only works for your account, but don't post it publicly. |

**Other tabs: ordinary Claude Code sessions.** A tab titled `claude` or `claude --resume <id>` is a normal interactive session, such as one you used to set things up. It isn't part of the server. You can `/exit` it at any time and bring it back later with `claude --resume`.

The menu bar may say **Locked**. That's fine. The server keeps running while the screen is locked.

## Keys in the `rc` window

| Key | Effect | Use it? |
|---|---|---|
| `space` | Show or hide a QR code that opens the session on your phone. | Freely. |
| `w` | Switch spawn mode between `worktree` and `same-dir` for **new** sessions. | Avoid unless you mean it. In `same-dir`, parallel sessions edit the same files. `rc-loop` sets the mode again on its next restart. |
| `Ctrl+C` | Stops the server. Your phone sessions stop responding. If the `Restarting in 30s` line appears, press it again to stop the loop. | Only to stop or restart on purpose. |
| `Ctrl+B`, then `D` | Detach: hide the tmux window and leave everything running. | This is the normal way to "leave". |

Closing the Terminal tab or window, or quitting Terminal, only disconnects your view. tmux keeps the server running.

## Everyday tasks

**Look at the server from anywhere (SSH):**

```sh
ssh studio.local
/opt/homebrew/bin/tmux attach -t rc        # Ctrl+B then D to leave
# or, without attaching:
/opt/homebrew/bin/tmux capture-pane -p -t rc | tail -20
rc-doctor
```

Use the full tmux path in a one-line `ssh host '…'` command, because Homebrew isn't on the PATH there.

**Restart the server on purpose** (picks up a changed `rc-loop` or config):

1. Attach to `rc`, press `Ctrl+C` until you're at a shell prompt.
2. Run `rc-loop`.
3. Detach.

Do this in the existing `rc` pane rather than a new SSH shell. That pane descends from a Terminal opened on the Mac's own screen, which avoids the open question about starting the server over SSH (see [known issues](known-issues.md)). Per Anthropic's docs, after a `Ctrl+C` stop, restarting the server in the same folder within about four hours brings back the sessions it was serving, so phone sessions should reconnect. Don't do this from a session the server is serving: stopping the server ends that session too.

**A phone session stopped responding:** send it another message. In server mode, a crashed session is served again when you message it; no restart needed.

**No green dot on the phone:** probably a network problem at home. If the Mac was offline for more than about 10 minutes, the server gave up and exited, and `rc-loop` restarts it 30 seconds later. Give it a couple of minutes after the network is back. Whether your existing sessions come back after that kind of exit is untested; you may need to start new ones from the Code tab (see [known issues](known-issues.md)).

**Context getting full in a session:** `/context` shows how full it is, `/compact` summarizes and continues, `/clear` starts fresh, or start a new session from the Code tab. These, plus `/model`, `/effort`, `/rename`, `/usage` and `/config key=value`, work from the phone. `/resume` and `/plugin` only work in the Mac's terminal.

**Stop everything** (back home, or for maintenance):

```sh
tmux attach -t rc     # Ctrl+C until you're at a prompt, then:
exit                  # or, from outside: tmux kill-session -t rc
```

**After a reboot or power loss:** nothing restarts on its own yet. Log in on the Mac's screen, open Terminal, and start again from step 6 of the [setup checklist](setup-checklist.md).
