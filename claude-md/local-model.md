<!-- Append this section to ~/.claude/CLAUDE.md on the machine that runs Ollama.
     Adjust the default model and the examples to your own work. -->

## Local model on this machine (Ollama)
This machine runs Ollama on localhost:11434. Hand self-contained subtasks to it with
`~/.local/bin/ask-local "instruction"`. Pipe input in for context, e.g.
`cat logs/worker.log | ~/.local/bin/ask-local "List the distinct errors with counts"`.
Default model: qwen3.6:35b-a3b. Use `-m <name>` for another (`ollama list` shows what's installed).

Use it when it saves time or keeps data on this machine:
- Bulk, repetitive text work: summarizing long logs or test output, classifying or tagging many records, first-pass extraction.
- Generating synthetic test data, e.g. fake contact records with realistic duplicates and near-matches.
- Anything involving real customer or personal data. Pipe the file straight to ask-local instead of reading it yourself, and only bring back aggregate or redacted results.

Don't use it for architecture or design decisions, editing code in the repo, security-sensitive logic, or anything where a subtle mistake would be hard to catch.

Treat its output as a draft. Check it before relying on it, never commit it unreviewed, and tell me when you've used it.
If ask-local says Ollama isn't responding, tell me and continue without it. Don't try to start or restart Ollama.
ask-local runs with thinking off (`--think=false`), so stdout is just the answer; the spinner goes to stderr.
