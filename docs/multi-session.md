# Several sessions on one Mac

One Remote Control server can host a small team of sessions that message each other. For example: a lead that coordinates, a reviewer, and a smoke tester that drives a browser. This page covers what we've seen work, what broke, and what's still untested. It describes what we observed on 2026-10-19 with Claude Code 2.1.302 and 2.1.303.

Messaging uses Claude Code's built-in cross-session tools. As we used them, a session lists its peers, then sends a message to one by name.

## Setting up the team

- **Lead: the server's own session**, the one named by `--name` (`RC_NAME`). It came back with its history in both of our restarts (see [known issues](known-issues.md#which-sessions-come-back-after-a-restart)). That makes it the best home for the coordinator.
- **Everyone else: start from the phone.** In the Code tab, start a new session in this Mac's environment. With `--spawn=worktree`, each one gets its own git worktree. Name it right away with `/rename`, then give it a first message stating:
  - its role;
  - which session leads;
  - what it must not touch: the server, the `rc` tmux session, `~/.config/rc-loop.env`, `~/.claude/CLAUDE.md`.
- **A smoke tester also needs a browser.** That means `RC_CHROME=1` and a one-time browser setup on the Mac's screen (see the [setup checklist](setup-checklist.md#optional-a-browser-for-smoke-tests-claude-in-chrome)). Then, in the session, `/chrome` → **Select browser…** → this Mac's browser.

## Messaging

**Between sessions on the Mac: works (observed).** The lead sent the reviewer re-check requests and got answers. It also gave the smoke tester a plan and got a report back. A session restored with `--session-id` in single-session mode also answered messages.

**From another machine: works once that session joins Remote Control (observed).** A session on a laptop only sees the Mac's sessions after it runs `/remote-control` itself. After that:
- it lists them, with "Remote Control" as their type;
- it can message them by their title;
- their replies come back.

The sender only learns that the message was delivered, not whether it was read. A reply is the only confirmation. In the other direction, the laptop's sessions show up in the Mac sessions' lists with "Remote Control" as their type.

**Only Claude can send these.** Peers send messages with their messaging tool. Your own messages go through the phone or the terminal as usual.

## Names

- **Names on the Mac reset when the server restarts** (see [known issues](known-issues.md#session-names-on-the-mac-reset-at-a-restart)). After a restart, the lead should list its peers again and send everyone the current names in one message.
- **Titles seen from another machine held** across the restart.
- **Renames are unreliable.** See [known issues](known-issues.md#renamed-sessions-keep-their-old-name-in-some-views). Don't count on a `/rename` being what peers see.

## Restarts

A server restart interrupts the whole team, so:
1. Check with the lead first, and pick a moment when no one is mid-task.
2. Record session IDs and worktree folders ([operator guide](operator-guide.md#before-a-planned-restart)).
3. Restart from the Mac's screen or the existing `rc` pane, not a fresh SSH shell: Claude Code isn't signed in there.
4. Afterward, check which sessions came back. In our runs it varied (see known issues), so bring back the missing ones and have the lead re-list its peers.

## Handing a role to another session or machine

Roles can move between sessions, or between the Mac and another machine. For example, the lead moves to a laptop session for a day. Stand the old session down with the steps in the [operator guide](operator-guide.md#stand-down-a-session): the handoff goes to the successor as a message, because memory files don't cross machines. The lead then sends every peer the new name for that role in one message.

## Housekeeping

- **One session owns the shared pieces:** the server, tmux, and the config files. The others ask it before touching them, and a person does the restarts.
- **Stand down finished sessions** ([operator guide](operator-guide.md#stand-down-a-session)), so their RAM, worktrees and dev servers don't linger.
- **Watch for leftover processes.** Sessions start dev servers and previews in their worktrees, and those keep running after the work is merged. We found a `vite preview` holding a port hours after its PR merged. The lead can check with `ps -axo pid,lstart,command | grep worktrees` and stop what's no longer needed.

## Still untested

- Whether a browser choice in `/chrome` carries over to new sessions. Expect to pick once per session.
- Whether the server's own session reliably keeps its `--name` title on the Mac after every restart. We saw it come back as a generated name first, then return to its title.
