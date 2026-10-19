# Known issues and open questions

Each item says what's been **observed** on our machine, what's **documented** by Anthropic, and what's still **unverified**. When an item gets resolved, update it here with the date and how, rather than deleting it.

## Renamed sessions keep their old name in some views

**Status:** open, cause unknown.

**Observed (2026-10-19):** renaming a Remote Control session from the Claude desktop app, either with `/rename <name>` or in the app's UI, doesn't change the name shown inside the session itself, or the name its peer sessions see.

**Documented:** the remote title is chosen in this order: the `--name` passed to `claude remote-control`, then a `/rename` title, then the latest message, then an auto-generated name. Anthropic's docs also say that renaming from claude.ai or the Claude app updates the local title shown in `claude --resume`.

**Unverified ideas:**
- `rc-loop` passes `--name`, which ranks above `/rename`. It may only apply to the session the server pre-creates, so test that session and an on-demand session separately.
- The list in the server's terminal window may be captured when each session starts and never refreshed.
- What peer sessions see may be the local session name rather than the remote title.

**To reproduce, record:** which session (pre-created or started from the phone), where you renamed it, and where the old name still shows (server window, `claude --resume` on the Mac, the peer list, the phone). If it reproduces with a minimal setup, report it upstream at [anthropics/claude-code](https://github.com/anthropics/claude-code/issues).

## Nothing restarts after a reboot or power loss

**Status:** open, by design for now.

`rc-loop` handles the server exiting. It doesn't handle the Mac restarting: tmux and everything in it are gone, and someone has to log in and start it again. Pieces for fixing this, none tested yet:

- `launchd/com.example.rc-loop.plist` starts the tmux session at login.
- macOS can log in automatically after a power failure only if FileVault is off. With FileVault on, the Mac waits at a pre-boot unlock screen before the network is up.
- Tailscale running as a system daemon plus a VNC app on the phone would let you log in remotely, if FileVault allows it.

## Credentials stored in the keychain don't work over SSH

**Observed (2026-10-19):** over SSH, `gh auth status` on the Mac reported "The token in default is invalid" and `gh repo view` of a private repo failed with HTTP 401. Meanwhile, sessions on the same Mac pushed to GitHub without trouble. `gh` keeps its token in the macOS keychain, so the most likely cause is that an SSH login can't unlock the keychain. So do sign-ins, and anything that needs them (cloning a private repo, `gh` calls), from Terminal on the Mac's screen or from a session.

**Observed for Claude Code too (2026-10-19):** over SSH, `claude -p` printed `Not logged in · Please run /login`, while sessions on the same Mac were signed in and working. So start or restart the server from Terminal on the Mac's screen, or inside the existing `rc` tmux pane, never from a fresh SSH shell. Attaching to `rc` over SSH and restarting there should work, because that pane's shell was started from the Mac's screen, but it's untested.

## Server mode exits after about 10 minutes offline

**Status:** documented by Anthropic, not yet observed here.

If the Mac is awake but can't reach the network, `claude remote-control` gives up after roughly 10 minutes and exits. (An interactive `claude` session keeps retrying instead.) That's the reason `rc-loop` exists. A weekend of uptime with no outage doesn't exercise it. To test it: note the session IDs (see the [operator guide](operator-guide.md#before-a-planned-restart)), unplug the Mac's network for 15 minutes, plug it back in, and confirm the loop restarted the server. Then check whether the existing sessions answer from the phone or whether you only get new ones.

## Which sessions come back after a restart

**Observed (2026-10-19, Claude Code 2.1.301 to 2.1.302):** we stopped the server with `Ctrl+C` and started `rc-loop` in the same folder about a minute later.

- The session the server created when it started (the one named by `--name`) came back as the same conversation, history intact.
- A session that had been started from the phone did **not** come back. It showed as offline, and the server's capacity line read `1/32`.

Anthropic's docs say a restart in the same folder within about four hours brings back every session the server was serving, so this differs from the docs. We don't know why.

Possible causes, all unverified:
- Restore records may be kept per folder, and phone-started sessions live in worktree folders. Anthropic's docs on `--continue` describe looking in "this directory" first and then in other worktrees. That would also explain why `--session-id` worked only from the worktree folder (below).
- Claude Code updated from 2.1.301 to 2.1.302 at the same restart.

If it reproduces, it's worth reporting upstream at [anthropics/claude-code](https://github.com/anthropics/claude-code/issues).

**After the server exits because the network was down:** untested. The docs only say to run it again "to start a new session". Check it as part of the unplug test above.

**Bringing a session back (observed working):** run `--session-id` from **the session's own worktree folder**, in its own tmux window (`Ctrl+B`, then `C`):

```sh
cd ~/code/my-project/.claude/worktrees/bridge-cse_<…> && claude remote-control --session-id session_<…>
```

The session ID is the part of its claude.ai/code URL between `/code/` and any `?`. Its worktree folder name carries the same ID after `bridge-cse_` (for example, `session_01Abc…` runs in `bridge-cse_01Abc…`); `git worktree list` shows them all. The process shows `Single session · exits when complete`: it serves only that session, exits when the session ends, and isn't restarted by `rc-loop`. The docs give a window of about four hours after the server stopped.

**What happened to it at the next restart (observed 2026-10-19):** about a minute after we restarted the main server, the main server started serving that session itself, from its worktree folder. The single-session process exited at the same time. So the session ended up under `rc-loop` after all. We don't know what triggered the takeover; it may have been the first message to that session.

## Session names on the Mac reset at a restart

**Observed (2026-10-19):** sessions on the Mac address each other by a local name, and those names didn't survive a server restart:
- the server's own session showed as `my-project-1a` right after the restart, then went back to its `--name` title;
- a session that had been renamed with `/rename` came back under a generated name, `bridge-cse-<id>-<suffix>`.

The short reference in brackets (`[10f36b]`) changed at every restart. From another machine, the same sessions kept showing their titles ("My project on Studio", the renamed title).

So after a restart, have each session list its peers again before messaging by name. This is probably related to the rename issue at the top of this page.

## Only one server per folder

**Observed (2026-10-19):** running `claude remote-control --session-id …` in the repo folder while `rc-loop`'s server was running there failed with:

```
Error: Environment env_… is already being served by another `claude remote-control` instance (pid …) in /Users/…/my-project. Use that terminal, or stop it first.
```

Running it from a session's worktree folder works (see above).

## Claude in Chrome: the browser list covers your whole account

**Observed (2026-10-19):** after running `claude --chrome` on the Mac, `/chrome` listed three browsers, though the Mac had one Brave window open. The other two had connected hours earlier, matching when the browser on another of our Macs connected, so the list appears to include every browser where the extension is signed in to your account, on any machine. That's our reading of what we saw; Anthropic's docs only say you choose when more than one browser is connected. The names are generic ("Browser 1") and all three said macOS. The way to tell them apart is the connection time: the Mac's browser connected when you ran `claude --chrome` there.

Pick the Mac's browser in `/chrome` under **Select browser…**. Otherwise a session on the Mac can drive a browser on another machine, with everything you're signed into there. Then ask the session to open a tab and check it appears on the right machine.

**Unverified:** whether that choice carries over to new sessions started from the phone. The docs say Claude prompts you to pick a browser when none is chosen, so expect to pick once per session.

Also observed:
- That first `claude --chrome` wrote the extension's connection file for both Brave and Chrome, even though only Brave was installed.
- It also opened browser windows during setup, including one in another Brave profile with an unrelated old tab.
- The browser has to be running. Claude Code doesn't start it.

Documented: sessions started by `claude remote-control` begin with Chrome off unless the server runs with `--chrome`, even if Chrome is enabled by default. Set `RC_CHROME=1` in `~/.config/rc-loop.env` for that.

## `claude remote-control --help` doesn't exit

**Observed (2026-10-16, Claude Code 2.1.301):** `claude remote-control --help` printed its help and then kept running until killed. Run it in a terminal you can `Ctrl+C`, not inside a script.

## First-run questions can block a restart

`claude remote-control` asks two questions on first run: whether to enable Remote Control, and which spawn mode to use. If either is asked again after the loop restarts it, the server sits waiting for a key press in the tmux window, which you can't see from your phone. `rc-loop` passes `--spawn`, which removes the spawn-mode question. The enable question is supposed to be one-time, but that's untested across restarts.

## Some small models print their reasoning anyway

**Observed (2026-10-19):** with `qwen3:4b`, `ask-local` output includes the model's reasoning and a `</think>` tag before the answer, despite `--think=false`. With `qwen3.6:35b-a3b` (the default) the output is just the answer. If you switch models, check the output is clean before scripts depend on it, or take the text after the last `</think>`.
