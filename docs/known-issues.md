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

## The server showed Connected but stopped starting new sessions

**Status:** open, cause unknown. Seen once.

**Observed (2026-10-27):** the server's window showed **Connected**, but it stopped starting new sessions. The phone said to run `claude rc`, and prompts sent from the desktop app landed in an existing session. Restarting the server fixed it.

Two things happened shortly before. Either may be related, or neither:
- At 9:49, Claude Code updated itself to 2.1.311 while the server was still running 2.1.309.
- At 9:52, a `/login` over SSH created `~/.claude/.credentials.json`, a plain-text sign-in file (see [signing in](operator-guide.md#signing-in-again)).

**Next time:** `rc-loop` now gives the server a debug log, one file per start, in `~/Library/Logs/rc-loop/` (or `RC_DEBUG_DIR`). A restart starts a new file, but `rc-loop` deletes files older than 14 days, so copy the file from the bad run somewhere else. Note the time it stopped working and the Claude Code version (`claude --version`, and the version `rc-loop` printed at its start).

## The desktop app's drop-down opens the server's own session

**Observed (2026-10-27):** choosing the Mac from the Claude desktop app's drop-down opens the server's pre-made session (the one named by `--name`, such as "My project on Studio") instead of starting a new one.

**Documented:** the server creates that session at startup "so you have somewhere to type immediately" (`claude remote-control --help`).

**Workaround:** start new sessions from the phone, or from the environment's URL at claude.ai/code (`https://claude.ai/code?environment=env_…`, shown in the server's window). `claude remote-control --no-create-session-in-dir` would stop the server pre-making that session; we haven't tried it.

## Coming back after a reboot or power loss

**Status:** works remotely with the launch agents installed (tested 2026-10-26). Someone still has to type the password twice, and sessions started from the phone don't come back.

`rc-loop` handles the server exiting. A restart of the Mac takes tmux and everything in it away. With the two launch agents in `launchd/`, they come back at login. The [operator guide](operator-guide.md#after-a-reboot-or-power-loss) has the steps.

**Observed (2026-10-26), a planned restart with FileVault on and the `rc-loop` and tunnel launch agents installed:**
- **FileVault can be unlocked over SSH.** Before macOS starts, `ssh` to the Mac shows `This system is locked. To unlock it, use a local account name and password.` Your SSH key is refused at that stage (the key list is on the encrypted disk); your account password works.
- **That unlock only boots to the login window.** Nobody is logged in (`who` is empty), so no launch agents run: no Ollama, no tunnel, no server. SSH works normally from then on.
- **Logging in through Screen Sharing** (`vnc://<mac>.local`) **starts everything.** Ollama and the tunnel started at login. The `rc-loop` agent started the `rc` tmux session about 40 seconds after login (it waits 20 seconds first), and the server came up **Connected** and signed in. A server started by launchd inside the desktop login can use the keychain, unlike one started from an SSH shell.
- **The server's own session came back** (same session ID). A session started from the phone didn't, as after a server restart (see [which sessions come back](#which-sessions-come-back-after-a-restart)); `--session-id` from its worktree brought it back.
- **Brave reopened at login** and showed a prompt asking to name the Claude Code session, which needed an **OK** click in Screen Sharing.

**Observed (2026-10-26), after a power loss on a Mac with FileVault on:**
- **The Mac stayed off until someone pressed the power button.** "Start up automatically after a power failure" was off (`pmset -g` showed `autorestart 0`).
- **It left no clean shutdown record.** `last` showed the old login ending in `crash`, and there was no shutdown cause or panic report. That's what a power cut looks like, as opposed to a deliberate shutdown.
- **Nothing ran until someone entered the password at the Mac's FileVault screen.** SSH worked a few minutes after that. (The later test showed the unlock can also be done over SSH, above.)
- **After the login at the screen:**
  - Ollama came back by itself, from its own launch agent.
  - A tunnel that had been started by hand stayed down, and the hosted app's model calls failed until someone noticed.
  - The server didn't come back. (Neither launch agent was installed yet.)

What's left:

- **Turn on `autorestart`** (System Settings → Energy → "Start up automatically after a power failure", or `sudo pmset -a autorestart 1`; check with `pmset -g | grep autorestart`). Without it, the Mac stays off after a power cut until someone presses the button. With it, the Mac comes back to the FileVault prompt, ready for the SSH unlock. Not yet seen after a real power cut.
- **Away from home**, the SSH unlock and Screen Sharing both need a way onto your home network, such as Tailscale. Tailscale as an app only runs after login, so it can't help with the unlock; running it as a system daemon might. Untested.
- macOS can log in automatically after a power failure only if FileVault is off.

## Credentials stored in the keychain don't work over SSH

**Observed (2026-10-19):** over SSH, `gh auth status` on the Mac reported "The token in default is invalid" and `gh repo view` of a private repo failed with HTTP 401. Meanwhile, sessions on the same Mac pushed to GitHub without trouble. `gh` keeps its token in the macOS keychain, so the most likely cause is that an SSH login can't unlock the keychain. So do sign-ins, and anything that needs them (cloning a private repo, `gh` calls), from Terminal on the Mac's screen or from a session.

**Observed for Claude Code too (2026-10-19):** over SSH, `claude -p` printed `Not logged in · Please run /login`, while sessions on the same Mac were signed in and working. So start or restart the server from Terminal on the Mac's screen, or inside the existing `rc` tmux pane, never from a fresh SSH shell. Attaching to `rc` over SSH and restarting there should work, because that pane's shell was started from the Mac's screen, but it's untested.

**Workaround from SSH (observed 2026-10-26):** this works while someone is logged in at the Mac's screen (`who` lists a `console` login). Have Terminal on the Mac run the start commands: write them to a `.command` file and run `open -a Terminal <file>`. Terminal runs inside the screen login, where the keychain is unlocked. The server it started came up signed in and **Connected**. The [operator guide](operator-guide.md#after-a-reboot-or-power-loss) has the exact file. A server started by the `rc-loop` launch agent at login is signed in too (observed 2026-10-26), and so is anything started in a new window of its tmux session, even from SSH (the `--session-id` command [below](#which-sessions-come-back-after-a-restart) worked that way). Two other ways didn't work:
- `launchctl asuser <uid> …` from SSH failed with `Could not switch to audit session … Operation not permitted`.
- `claude auth status` in a plain SSH shell reported `"loggedIn": false`.

**Don't `/login` over SSH (observed 2026-10-27).** It saved the sign-in to `~/.claude/.credentials.json`, a plain-text file. It also happened just before the [half-broken server](#the-server-showed-connected-but-stopped-starting-new-sessions). See [signing in again](operator-guide.md#signing-in-again) for what to do instead.

## Server mode exits after about 10 minutes offline

**Status:** documented by Anthropic, not yet observed here.

If the Mac is awake but can't reach the network, `claude remote-control` gives up after roughly 10 minutes and exits. (An interactive `claude` session keeps retrying instead.) That's the reason `rc-loop` exists. A weekend of uptime with no outage doesn't exercise it. To test it: note the session IDs (see the [operator guide](operator-guide.md#before-a-planned-restart)), unplug the Mac's network for 15 minutes, plug it back in, and confirm the loop restarted the server. Then check whether the existing sessions answer from the phone or whether you only get new ones.

## Which sessions come back after a restart

**Observed (2026-10-19, Claude Code 2.1.301 to 2.1.302):** we stopped the server with `Ctrl+C` and started `rc-loop` in the same folder about a minute later.

- The session the server created when it started (the one named by `--name`) came back as the same conversation, history intact.
- A session that had been started from the phone did **not** come back. It showed as offline, and the server's capacity line read `1/32`.

Anthropic's docs say a restart in the same folder within about four hours brings back every session the server was serving, so this differs from the docs. We don't know why.

Possible causes, all unverified:
- Restore records may be kept per folder, and phone-started sessions live in worktree folders. Anthropic's docs on `--continue` describe looking in "this directory" first and then in other worktrees. That would also explain why `--session-id` worked only from the worktree folder (below). But at the next restart the main server took that same session over from the repo folder, which this explanation doesn't account for.
- Claude Code updated from 2.1.301 to 2.1.302 at the same restart.

If it reproduces, it's worth reporting upstream at [anthropics/claude-code](https://github.com/anthropics/claude-code/issues).

**After the server exits because the network was down:** untested. The docs only say to run it again "to start a new session". Check it as part of the unplug test above.

**Bringing a session back (observed working):** run `--session-id` from **the session's own worktree folder**, in its own tmux window (`Ctrl+B`, then `C`):

```sh
cd ~/code/my-project/.claude/worktrees/bridge-cse_<…> && claude remote-control --session-id session_<…>
```

The session ID is the part of its claude.ai/code URL between `/code/` and any `?`. Its worktree folder name carries the same ID after `bridge-cse_` (for example, `session_01Abc…` runs in `bridge-cse_01Abc…`); `git worktree list` shows them all. The process shows `Single session · exits when complete`: it serves only that session, exits when the session ends, and isn't restarted by `rc-loop`. The docs give a window of about four hours after the server stopped.

**If its worktree folder is gone (observed 2026-10-27):** stopping the server deleted a phone-started session's worktree folder and its branch. The worktree had no uncommitted changes. We recreated the worktree and branch at the session's last commit and ran `--session-id` from it, and the session came back up **Connected** in that folder:

```sh
cd ~/code/my-project
git worktree add -b worktree-bridge-cse_<…> .claude/worktrees/bridge-cse_<…> <commit>
```

So record each session's commit before a planned restart (see the [operator guide](operator-guide.md#before-a-planned-restart)). We don't know whether a worktree with uncommitted changes is kept.

**What happened to it at the next restart (observed 2026-10-19):** about a minute after we restarted the main server, the main server started serving that session itself, from its worktree folder. The single-session process exited at the same time. So the session ended up under `rc-loop` after all. We don't know what triggered the takeover; it may have been the first message to that session.

## Session names on the Mac reset at a restart

**Observed (2026-10-19):** sessions on the Mac address each other by a local name, and those names didn't survive a server restart:
- the server's own session showed as `my-project-1a` right after the restart, then went back to its `--name` title;
- a session that had been renamed with `/rename` came back under a generated name, `bridge-cse-<id>-<suffix>`.

The short reference in brackets (such as `[abc123]`) changed at every restart. From another machine, the same sessions kept showing their titles ("My project on Studio", the renamed title).

So after a restart, have each session list its peers again before messaging by name. This is probably related to the rename issue at the top of this page.

## Archiving a session ends it like a crash

**Observed (2026-10-27):** archiving a session from the Claude desktop app ends it the way a crash does, and the server keeps its worktree. So `/exit` a session before archiving it, and remove its worktree yourself (see [stand down a session](operator-guide.md#stand-down-a-session)).

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
