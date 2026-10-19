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

**Observed (2026-10-19):** over SSH, `gh auth status` on the Mac reported "The token in default is invalid" and `gh repo view` of a private repo failed with HTTP 401. Meanwhile, sessions on the same Mac pushed to GitHub without trouble. `gh` keeps its token in the macOS keychain, which an SSH login usually can't unlock. So do sign-ins, and anything that needs them (cloning a private repo, `gh` calls), from Terminal on the Mac's screen or from a session.

**Still unverified for Claude Code itself:** the original setup notes said to start `claude remote-control` from the Mac's screen, not over SSH, for the same keychain reason. The `gh` result makes that likely, but Claude Code hasn't been tested over SSH. Until it is, restart the server inside the existing `rc` tmux pane (see the operator guide).

## Server mode exits after about 10 minutes offline

**Status:** documented by Anthropic, not yet observed here.

If the Mac is awake but can't reach the network, `claude remote-control` gives up after roughly 10 minutes and exits. (An interactive `claude` session keeps retrying instead.) That's the reason `rc-loop` exists. A weekend of uptime with no outage doesn't exercise it. To test it: note the session IDs (see [migration](migration.md#before-you-start)), unplug the Mac's network for 15 minutes, plug it back in, and confirm the loop restarted the server. Then check whether the existing sessions answer from the phone or whether you only get new ones.

## Do sessions come back after a restart? (documented for Ctrl+C only)

Our original notes said each restart of the loop opens a brand-new session. Anthropic's docs describe two cases:

- **Stopped with `Ctrl+C`:** the sessions aren't archived, and running `claude remote-control` again in the same folder within about four hours brings back every session it was serving. Not yet observed here. The migration's step 3 will be the first time.
- **Exited after about 10 minutes offline:** the docs say to run `claude remote-control` again "to start a new session". Whether the old sessions also come back in this case is **untested**. Check it as part of the unplug test above: after the loop restarts the server, see whether the phone's existing sessions answer.

If a session doesn't come back, `claude remote-control --session-id <id>` brings back one session by ID (the part of its claude.ai/code URL between `/code/` and any `?`), within the same four-hour window.

## `claude remote-control --help` doesn't exit

**Observed (2026-10-16, Claude Code 2.1.301):** `claude remote-control --help` printed its help and then kept running until killed. Run it in a terminal you can `Ctrl+C`, not inside a script.

## First-run questions can block a restart

`claude remote-control` asks two questions on first run: whether to enable Remote Control, and which spawn mode to use. If either is asked again after the loop restarts it, the server sits waiting for a key press in the tmux window, which you can't see from your phone. `rc-loop` passes `--spawn`, which removes the spawn-mode question. The enable question is supposed to be one-time, but that's untested across restarts.

## Some small models print their reasoning anyway

**Observed (2026-10-19):** with `qwen3:4b`, `ask-local` output includes the model's reasoning and a `</think>` tag before the answer, despite `--think=false`. With `qwen3.6:35b-a3b` (the default) the output is just the answer. If you switch models, check the output is clean before scripts depend on it, or take the text after the last `</think>`.
