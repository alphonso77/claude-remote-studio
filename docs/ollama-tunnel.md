# Ollama tunnel

Use this only if an app you host elsewhere (on Railway, say) calls the Mac's model. Sessions on the Mac don't need it: they reach Ollama on localhost through `ask-local`.

`bin/ollama-tunnel` publishes Ollama at a reserved ngrok URL and turns away any request without the right HTTP Basic-auth credentials. The credentials live in an ngrok traffic policy file that only your user can read (mode 600). They're never on ngrok's command line, so they stay out of shell history and the process list. The script refuses to start if that file is missing, has no `basic-auth` action, or is readable by others.

| Piece | Where |
|---|---|
| Settings (URL, port) | `~/.config/ollama-tunnel.env` (from `config/ollama-tunnel.env.example`) |
| Credentials | `~/.config/ollama-tunnel/policy.yml`, mode 600, written by `ollama-tunnel new-password` |
| Launch agent | `~/Library/LaunchAgents/<your label>.plist` (from `launchd/com.example.ollama-tunnel.plist`) |
| Log | `~/Library/Logs/ollama-tunnel.log` |
| Client side | the `Authorization` header value, usually an environment variable on your host |

The examples below use the label `com.example.ollama-tunnel`. Use your own label everywhere you see it.

## Set up

1. Install ngrok, sign it in, and reserve a domain in the ngrok dashboard:
   ```sh
   brew install ngrok
   ngrok config add-authtoken <token>
   ```
2. Configure and create the credentials:
   ```sh
   cp ~/code/claude-remote-studio/config/ollama-tunnel.env.example ~/.config/ollama-tunnel.env
   $EDITOR ~/.config/ollama-tunnel.env              # OLLAMA_TUNNEL_URL
   ollama-tunnel new-password myapp                 # prints the Authorization header value
   ```
3. Set the printed `Basic …` value as the client's `Authorization` header.
4. Install the launch agent:
   ```sh
   sed 's/com\.example\./com.yourname./' ~/code/claude-remote-studio/launchd/com.example.ollama-tunnel.plist \
     > ~/Library/LaunchAgents/com.yourname.ollama-tunnel.plist
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.yourname.ollama-tunnel.plist
   ```
5. Check it:
   ```sh
   rc-doctor
   ```
   Expect `ok` for "tunnel policy file is private", "ollama-tunnel is running" and "tunnel asks for credentials".

This works over SSH, because the tunnel doesn't need the keychain. `launchctl bootstrap gui/…` from an SSH shell loads the agent into the logged-in user's session (observed 2026-10-26).

## Rotate the password

Rotate when your host reports a leak of environment variables, when someone who knew the password leaves, or on a schedule. Model calls from the client fail with 401 between step 2 and step 4, so do it all at once.

1. **Write new credentials.** Keep the same user name unless you want to change it:
   ```sh
   ollama-tunnel new-password myapp
   ```
   This prints the new `Basic …` header value once. Copy it straight into the next step. Don't save it in a note or a chat.
2. **Restart the tunnel** so it loads the new file:
   ```sh
   launchctl kickstart -k gui/$(id -u)/com.example.ollama-tunnel
   ```
3. **Check the tunnel** from the Mac, without printing the password:
   ```sh
   url=$(source ~/.config/ollama-tunnel.env; echo $OLLAMA_TUNNEL_URL)
   cred=$(grep -oE '"[^"]+:[^"]+"' ~/.config/ollama-tunnel/policy.yml | tr -d '"')
   curl -s -o /dev/null -w 'no creds:  %{http_code}\n' "$url/api/version"                  # 401
   curl -s -o /dev/null -w 'new creds: %{http_code}\n' -u "$cred" "$url/api/version"       # 200
   ```
4. **Update every client** that holds the old value. For example, on Railway, set it for each service and environment that calls the model:
   ```sh
   railway variables -s <service> -e <environment> --set "OLLAMA_AUTH=Basic …"
   ```
   On Railway, setting a variable redeploys that service.
5. **Confirm a real call works.** Use the app feature that calls the model, then look for the request in `~/Library/Logs/ollama-tunnel.log`.
6. **Clean up old copies.** If the old password was ever typed on a command line (the old `ngrok http … --basic-auth "user:pass"` way), remove those lines from `~/.zsh_history`. It no longer works, but it shouldn't sit in plain text.

## Check who used it

Ollama logs every request with the caller's IP in `~/Library/Logs/ollama.log` (lines starting `[GIN]`). Requests through the tunnel show the original caller's IP, which Ollama takes from ngrok's `X-Forwarded-For` header. Local calls show `127.0.0.1` or `::1`. To list outside callers by day and endpoint:

```sh
grep '^\[GIN\]' ~/Library/Logs/ollama.log | awk -F'|' '{split($1,d," "); gsub(/ /,"",$4); print d[2], $4, $5}' \
  | grep -vE ' (127\.0\.0\.1|::1) ' | sort | uniq -c
```

`whois <ip>` tells you whose network an address belongs to; compare against your host's egress ranges and your own home IP (`curl -s https://api.ipify.org`). A caller can set its own `X-Forwarded-For`, so treat the IP as a strong hint, not proof. Failed logins never reach Ollama: ngrok turns them away first.

## Notes

- **ngrok's `--basic-auth` flag:** ngrok 3.39's `ngrok http --help` no longer lists it. Basic auth now goes through a traffic policy, which is what `ollama-tunnel` writes.
- **The tunnel doesn't need Ollama on all interfaces.** ngrok connects to `localhost`. If Ollama's launch agent sets `OLLAMA_HOST=0.0.0.0:11434`, anyone on your home network can use the model with no password. Use `127.0.0.1:11434` unless something else on your network needs it.
- **After a reboot:** the agent starts at login (observed 2026-10-26). With FileVault on, someone has to unlock the Mac and log in first; both can be done remotely (see the [operator guide](operator-guide.md#after-a-reboot-or-power-loss)).
