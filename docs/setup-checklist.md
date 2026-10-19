# Setup checklist

Go through this once on a new machine, and again (the last two sections) whenever you want to confirm the setup is healthy. It takes about 45 minutes the first time. Copy it into an issue or a note if you want to tick the boxes as you go.

Do every step in Terminal **on the Mac itself**, at its screen or over Screen Sharing. Some sign-ins open a browser on that machine.

## 1. Claude Code

- [ ] **Install Claude Code** (the native installer keeps itself updated and needs no Node):
  ```sh
  curl -fsSL https://claude.ai/install.sh | bash
  grep -q '.local/bin' ~/.zshrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
  exec zsh
  claude --version
  ```
- [ ] **Sign in with your claude.ai subscription**, not an API key. Remote Control only works with a subscription login.
  ```sh
  claude auth login
  claude doctor
  ```
- [ ] **Make sure nothing routes Claude Code away from Anthropic.** Both lines should print `clean`:
  ```sh
  env | grep -E '^(ANTHROPIC_|CLAUDE_CODE_USE_|CLAUDE_CODE_DISABLE_NONESSENTIAL|DISABLE_GROWTHBOOK)' || echo "env: clean"
  grep -nE 'ANTHROPIC_|apiKeyHelper|CLAUDE_CODE_DISABLE_NONESSENTIAL|DISABLE_GROWTHBOOK' ~/.claude/settings.json 2>/dev/null || echo "settings: clean"
  ```
  The last two variables turn off feature-flag fetching, which Remote Control needs. If you have a command that points `ANTHROPIC_BASE_URL` at Ollama (a "claude-local" style alias), that's fine to keep, but it can't be used for Remote Control sessions.

- [ ] **On a Team or Enterprise plan:** an Owner has turned on Remote Control in Claude Code admin settings.
- [ ] **The Mac won't sleep.** Remote Control can't serve sessions while it sleeps. In System Settings → Energy, turn on "Prevent automatic sleeping when the display is off", then check that this prints `0`:
  ```sh
  pmset -g | awk '$1=="sleep"{print $2}'
  ```

## 2. Your repo and tools

- [ ] **GitHub CLI**, so sessions can push and open PRs from your phone:
  ```sh
  brew install gh
  gh auth login        # GitHub.com, HTTPS, yes to authenticating Git
  gh auth status
  ```
- [ ] **Any other CLIs your sessions will need** (issue tracker, cloud provider), installed and signed in now. You can't complete a browser sign-in from your phone.
- [ ] **Your project repo is cloned** on this machine, with dependencies installed and any local env files it needs to run its tests.
- [ ] **Start from a clean, pushed tree**, so anything done remotely is easy to review or roll back:
  ```sh
  cd ~/code/my-project && git status -sb && git push
  ```

## 3. The local model (optional)

- [ ] **Ollama is up and has a model:**
  ```sh
  curl -sf http://localhost:11434/api/tags >/dev/null && echo "ollama: up" || echo "ollama: NOT running"
  ollama list
  ```
  A mid-size instruct or coder model is the sweet spot. Set `ASK_LOCAL_MODEL` if you don't want the default in `bin/ask-local`.
- [ ] **`ask-local` works:**
  ```sh
  ask-local "Reply with one word: ready"
  echo "jon smith, JSmith@example.com, (555) 555-0142" | ask-local "Normalize this contact to JSON with first, last, email, phone. Output only JSON."
  ```
  The first call can take a while as the model loads.
- [ ] **Claude knows when to use it.** Add this line to `~/.claude/CLAUDE.md`, then edit the snippet's examples to suit your work:
  ```
  @~/code/claude-remote-studio/claude-md/local-model.md
  ```

## 4. This repo

- [ ] **Clone and install:**
  ```sh
  git clone https://github.com/alphonso77/claude-remote-studio ~/code/claude-remote-studio
  ~/code/claude-remote-studio/install.sh
  ```
- [ ] **Configure `rc-loop`:**
  ```sh
  mkdir -p ~/.config
  cp ~/code/claude-remote-studio/config/rc-loop.env.example ~/.config/rc-loop.env
  $EDITOR ~/.config/rc-loop.env      # RC_REPO, RC_NAME
  ```
  Point `RC_REPO` at a git repository, not your home folder: worktree mode needs a git repo, and starting in your home folder can bring up the folder-trust question on every start.
  ```sh
  rc-doctor   # expect failures for the server and tmux until step 6
  ```
- [ ] **tmux is installed:** `command -v tmux || brew install tmux`

## 5. One-time session settings

- [ ] Start a normal session in your repo (`cd ~/code/my-project && claude`) and say yes if it asks to trust the folder.
- [ ] `/config`: turn on **Push when actions required** and **Push when Claude decides**.
- [ ] `/permissions`: add an allow rule `Bash(~/.local/bin/ask-local:*)` (optional; otherwise approve from the phone each time).
- [ ] `/exit`.

## 6. Start the server

- [ ] **Start it inside tmux, from the Mac's own Terminal:**
  ```sh
  tmux new -s rc
  rc-loop            # inside the tmux window
  ```
  Answer `y` to `Enable Remote Control?`. `rc-loop` passes `--spawn` for you, so you won't be asked for a spawn mode.
- [ ] **Wait for `Connected`** and your session name in the list.
- [ ] **Detach:** `Ctrl+B`, then `D`. You can close the Terminal window now.

## 7. Test from your phone

Turn **Wi-Fi off** on the phone first, so you're testing the same path you'll use away from home.

- [ ] Claude app → **Code** → your session name. It should show the computer icon with a green dot.
- [ ] Send:
  > Quick check: run ~/.local/bin/ask-local "Reply with one word: ready" and tell me exactly what came back. Then tell me which git branch this repo is on.

  You should get a permission push (unless you allowed `ask-local`), then `ready` and the branch.
- [ ] **Start a second session** from the Code tab, choosing this machine. Send it anything, then `/clear`. That's your escape hatch for when a session's context gets too full.

## 8. Is it running as expected?

Run this any time, on the Mac or over SSH:

```sh
rc-doctor
```

- [ ] Every line says `ok` (`note` lines are informational, for example when you don't use Ollama).
- [ ] In the `rc` tmux window (`tmux attach -t rc`), the top line says **Connected**, and the capacity count matches the number of sessions you expect.
- [ ] The phone shows your sessions with a green dot.

If something's off, see the [operator guide](operator-guide.md) and [known issues](known-issues.md).
