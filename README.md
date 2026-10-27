# claude-remote-studio

Run Claude Code on a Mac at home and drive it from your phone. The Mac keeps working on your repo while you're on a plane or in another city. Claude can also hand bulk text work to a model running locally in Ollama. The input you pipe to it is processed on the Mac and never sent to Anthropic; only what the local model writes back goes into the Claude session, so ask it for aggregate or redacted answers when the input is private.

This is a working setup, not a product. It ran a full weekend of remote work from an iPhone, including a flight, with no restarts. Everything here is plain zsh, tmux and Claude Code's own Remote Control feature.

Built while building [Fratelli Software](https://fratellisoftware.com).

```
 iPhone (Claude app, Code tab)              Mac at home ("the Studio")
 or claude.ai/code in a browser            ┌──────────────────────────────────────────┐
            │                              │ tmux session "rc"                        │
            │   Anthropic relays           │  └─ rc-loop  (restarts on exit)          │
            └──────── messages ───────────▶│      └─ claude remote-control            │
                     (outbound HTTPS       │           --spawn=worktree --name …      │
                      only; no open ports) │           ├─ session 1  (repo dir)       │
                                           │           ├─ session 2  (git worktree)   │
                                           │           └─ …  up to 32                 │
                                           │                                          │
                                           │  any session ──▶ ask-local ──▶ Ollama    │
                                           │                  (localhost:11434)       │
                                           └──────────────────────────────────────────┘
```

## What's in here

| Path | What it is |
|---|---|
| `bin/rc-loop` | Runs `claude remote-control` in your repo and restarts it 30s after it exits. |
| `bin/ask-local` | Sends one prompt (plus anything piped in) to a local Ollama model and prints the answer. |
| `bin/rc-doctor` | Read-only health check: links, clone state, server, tmux, Ollama, and the tunnel if you use one. |
| `bin/ollama-tunnel` | Optional: exposes Ollama to a hosted app through ngrok, behind Basic auth, and rotates its password. |
| `install.sh` | Symlinks `bin/*` into `~/.local/bin`, so this clone is the only copy of the scripts. |
| `config/rc-loop.env.example` | Settings for `rc-loop`. Copy it to `~/.config/rc-loop.env`. |
| `claude-md/local-model.md` | A CLAUDE.md section that tells Claude when to use `ask-local` and when not to. |
| `config/ollama-tunnel.env.example` | Settings for `ollama-tunnel`. Copy it to `~/.config/ollama-tunnel.env`. |
| `launchd/` | Optional: start the server at login, and keep `ollama-tunnel` running. Together they bring everything back after a reboot. |
| [`docs/setup-checklist.md`](docs/setup-checklist.md) | Step-by-step setup, plus a recurring "is it running as expected?" check. |
| [`docs/operator-guide.md`](docs/operator-guide.md) | What's on the Mac's screen and what to do with it. Start here if you're running it. |
| [`docs/known-issues.md`](docs/known-issues.md) | Open problems, unverified claims and gotchas. |
| [`docs/multi-session.md`](docs/multi-session.md) | Running several cooperating sessions (lead, reviewer, smoke tester) on the Mac. |
| [`docs/ollama-tunnel.md`](docs/ollama-tunnel.md) | Optional: setting up the tunnel, rotating its password, checking who used it. |

## Requirements

- A Mac that stays on, online and **awake**: Remote Control can't serve sessions while the Mac sleeps. Ours is a Mac Studio running macOS 26.
- On a Team or Enterprise plan, an Owner must first turn on Remote Control in Claude Code admin settings.
- Claude Code (native install) signed in with a **claude.ai subscription** (Pro, Max, Team or Enterprise). Remote Control doesn't work with an API key, and it refuses to connect if `ANTHROPIC_BASE_URL` points anywhere other than Anthropic. So a command that routes Claude Code to Ollama can't be used through Remote Control. Environment variables that turn off feature-flag fetching (such as `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` or `DISABLE_GROWTHBOOK`) also block it. That's why the local model is reached through `ask-local` instead.
- `tmux` (`brew install tmux`).
- For `ask-local`: [Ollama](https://ollama.com) running on `localhost:11434` with at least one model pulled.
- The Claude app on your phone, signed in to the same account.

## Quick start

The full walkthrough, with checks, is the [setup checklist](docs/setup-checklist.md). The short version, on the Mac, in Terminal on its own screen (or over Screen Sharing):

```sh
git clone https://github.com/alphonso77/claude-remote-studio ~/code/claude-remote-studio
~/code/claude-remote-studio/install.sh

cp ~/code/claude-remote-studio/config/rc-loop.env.example ~/.config/rc-loop.env
$EDITOR ~/.config/rc-loop.env           # set RC_REPO and RC_NAME

tmux new -s rc                           # then, inside tmux:
rc-loop
```

The first run asks `Enable Remote Control? (y/n)`. Answer `y`. When it shows **Connected** and your session name, detach with `Ctrl+B` then `D`. The server keeps running.

On the phone: Claude app → **Code** → tap your session name. Press space in the server window to show a QR code if you'd rather scan.

To let Claude use the local model, add one line to `~/.claude/CLAUDE.md`:

```
@~/code/claude-remote-studio/claude-md/local-model.md
```

Then run `/permissions` in a session and allow `Bash(~/.local/bin/ask-local:*)` so hand-offs don't need a tap each time.

Check everything with `rc-doctor`.

## Before you leave the house

- Test from the phone **with Wi-Fi off**, so you're testing the same path you'll use when you're away.
- Turn on push notifications: in a session, run `/config` and turn on **Push when actions required** and **Push when Claude decides**. Permission prompts then reach your phone.
- Know what a reboot or power loss does. With the launch agents in `launchd/` installed, everything comes back at login. With FileVault on, someone has to unlock the Mac (over SSH works) and log in (Screen Sharing works) first. See the [operator guide](docs/operator-guide.md#after-a-reboot-or-power-loss), and turn on "Start up automatically after a power failure".

## Exposing Ollama to a hosted app (optional)

If an app you host elsewhere (on Railway, say) should use the Mac's model too, `ollama-tunnel` publishes Ollama at a reserved ngrok URL and turns away any request without the right Basic-auth credentials. Sessions on the Mac don't need this; they reach Ollama on localhost. Setup, password rotation and how to check who used it: [docs/ollama-tunnel.md](docs/ollama-tunnel.md).

## Why it's built this way

**Remote Control server mode, not a cloud environment.** The work needs the Mac's own checkout, tools, credentials and local model. Remote Control keeps execution on the Mac and only relays the conversation through Anthropic, with no open ports and no VPN. Server mode (`claude remote-control`) beats a single interactive session because one process serves many sessions, and you can start new ones from the phone when a session's context fills up.

**Worktree spawn mode.** Each session you start from the phone gets its own git worktree, so two sessions working at once can't edit the same files.

**tmux plus a restart loop.** The server has to outlive the Terminal window it was started in, so it runs in tmux. Anthropic documents that server mode exits after about 10 minutes without network, so `rc-loop` restarts it. A home internet blip becomes a short gap instead of a dead weekend.

**`ask-local` instead of routing Claude Code to Ollama.** Remote Control refuses to connect when `ANTHROPIC_BASE_URL` points at Ollama. So sessions run on Anthropic's models and hand self-contained work to the local model through a small script. The CLAUDE.md snippet says when that's appropriate (bulk text work, synthetic test data, data that shouldn't leave the machine) and when it isn't (design, code edits, security logic).

## License

MIT
