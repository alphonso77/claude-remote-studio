# How this setup came about

## The goal (October 2026)

A weekend trip out of town, with work in progress on a software project. The aim was to keep working from an iPhone: on a plane and then in another city. A Mac Studio at home already ran Ollama for local inference. It became the machine Claude Code runs on.

## Design decisions

**Remote Control server mode instead of a cloud environment.** The work needed the Mac's own checkout, tools and credentials (GitHub, an issue tracker CLI) and its local model. Remote Control keeps execution on the Mac and only relays the conversation through Anthropic. That needs no open ports and no VPN. Server mode (`claude remote-control`) was chosen over a single interactive session because it serves many sessions from one process and lets you start new ones from the phone, which is the escape hatch when a session's context fills up.

**Worktree spawn mode.** Sessions started from the phone each get their own git worktree, so two sessions working at once can't edit the same files.

**tmux plus a restart loop.** The server has to outlive the Terminal window it was started in, so it runs in tmux. Anthropic documents that server mode exits after about 10 minutes without network, so a loop restarts it, turning a home internet blip into a short gap instead of a dead weekend.

**`ask-local` instead of routing Claude Code to Ollama.** A command that points `ANTHROPIC_BASE_URL` at Ollama already existed on another machine, but Remote Control refuses to connect when that's set. So the sessions run on Anthropic's models and hand self-contained work to the local model through a small script. A CLAUDE.md section says when that's appropriate: bulk text work, synthetic test data, and data that shouldn't leave the machine. It also says when not to use it: design, code edits, security logic.

**Peer review by sub-agent.** With no second machine and no laptop, reviews that would normally be a separate review session were done by sub-agents inside the remote session.

## Timeline

- **Before the trip:** a Claude Desktop chat produced a step-by-step setup checklist (the basis of [setup-checklist.md](setup-checklist.md)): install and sign in, tools, `ask-local`, the CLAUDE.md section, the launcher, tmux, a phone test with Wi-Fi off, and an optional section on surviving power loss.
- **Friday morning:** each step was pasted into Terminal on the Mac, and a Claude Code session on the Mac checked each one: the script matched, ran end to end, and the PATH and Ollama were in order. It found that the model's reasoning was showing in `ask-local` output; that was fixed later the same day with `--think=false`. The server was started in tmux; the first launch asked to enable Remote Control (yes) and for a spawn mode (worktree).
- **Friday to Sunday:** used from the phone all weekend, including in flight, with no restarts. Several sessions ran at once, including design-doc and docs work with PRs reviewed and merged from GitHub mobile.
- **Monday:** this repo, to write the setup down, make it repeatable, and track what's still open.

## Corrections since then

- The Friday notes said each loop restart opens a new session and that `--continue` was too risky to use. Anthropic's docs say that after a `Ctrl+C` stop, a plain restart within about four hours brings back all the server's sessions. After the server exits on its own because the network was down, though, the docs say to "start a new session", so whether the loop brings sessions back in that case is untested. See [known issues](known-issues.md).
- The Friday notes said `--spawn=worktree` should be added to the script so a restart can't stall on the spawn-mode question. It wasn't added at the time. `rc-loop` now does it.
