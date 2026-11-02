---
name: ws-env
description: Sync credentials between machines from the private encrypted secrets store - pull and decrypt them into each workspace, re-encrypt and push local changes, run a command with secrets injected into the process and never written to disk, add a new file to the store, or report what is encrypted versus what exists locally. Never prints a value. Ends with a report of variable names and counts only; when it was not asked for by name it runs the read-only status mode and offers the rest rather than performing it, because decrypting credentials to disk during an unrelated task is never the right default. Use when credentials are missing or stale, after setting up a machine, when a key is rotated, or when a workspace needs its env files materialised.
---

# Sync credentials

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md).
2. Check the tools and the key, and say plainly which is missing rather than guessing:

```bash
for c in sops age git; do printf '%-6s %s\n' "$c" "$(command -v $c || echo MISSING)"; done
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
[ -f "$SOPS_AGE_KEY_FILE" ] && echo "agent key present" || echo "agent key MISSING -> see 'New machine' below"
[ -d "$HOME/.agent-secrets" ] && echo "store present" || echo "store MISSING -> git clone it"
```

3. **Never print a value.** Everything below reports variable *names* and counts only.

## Mode

**Was this skill asked for by name?** If it loaded on its own rather than being invoked as
`/ws-env`, run **status** and stop there — report what is missing or stale by variable *name*
and count, then offer `pull`, `push` or `run`. Decrypting credentials onto disk, re-encrypting
them, or injecting them into a process is never the right thing to do unprompted during a task
that was about something else. `status` is read-only and always safe.


| The user says | Mode |
|---|---|
| "my env is missing / stale", "set up this workspace", after a new machine | **pull** |
| "I changed a key", "start syncing this file", after rotating a credential | **push** |
| "run X with the staging credentials" | **run** |
| "what's where", "is anything out of sync" | **status** |

Unclear → run **status** first; it is read-only.

## pull — decrypt into the workspaces

```bash
cd "$HOME/.agent-secrets" && git pull --ff-only
```

Then walk `manifest.tsv`, resolving each project's workspace root from `device.yaml`. No `yq`
or `jq` — neither is installed, and the Windows laptop would need them too:

```bash
D="$HOME/.agent-secrets"
# $proj, and never a positional parameter: one inside a skill body is replaced by the caller's
# argument before an agent ever sees it. Set proj, then call ws_root with no arguments.
ws_root() { sed -n '/^projects:/,$p' "$HOME/.agent-sync/device.yaml" | sed -n "s|^  $proj: *||p" | head -1; }

grep -v '^#' "$D/manifest.tsv" | while IFS=$'\t' read -r src type project dest; do
  proj="$project"; root=$(ws_root)
  [ -n "$root" ] && [ -d "$root" ] || { echo "skip $project — not linked on this device"; continue; }
mkdir -p "$(dirname "$root/$dest")"
case "$type" in
  dotenv) sops -d --input-type dotenv --output-type dotenv "$src" > "$root/$dest" ;;
  json)   sops -d --input-type json   --output-type json   "$src" > "$root/$dest" ;;
  binary) sops -d --input-type json   --output-type binary "$D/$src" > "$root/$dest" ;;
esac
  chmod 600 "$root/$dest"      # no-op on Windows; say so if asked
done
```

(The `dotenv` and `json` lines take `"$D/$src"` too — the store path, not a bare `src`.)

**Never pipe a decrypted file through a shell variable.** `x=$(sops -d …)` strips trailing
newlines, which silently corrupts SSH keys and CSVs. Always redirect straight to the
destination, and compare with `sops -d … | shasum` rather than `$( )`.

**Before overwriting anything, compare and ask.** A local file that differs from the store may
be a change made on this machine that was never pushed — overwriting it loses work:

```bash
# differs? report by NAME only, never by value
diff <(sops -d --input-type dotenv --output-type dotenv "$src" | grep -oE '^[A-Za-z_][A-Za-z0-9_]*')          \
     <(grep -oE '^[A-Za-z_][A-Za-z0-9_]*' "$root/$dest")
```

Report per file: `written` / `unchanged` / `differs — keep local, overwrite, or push local?`
Only overwrite on an explicit yes. For an SSH key also `chmod 600`, or ssh will refuse it.

**Then report**: files written, files skipped because the project is not linked, and any
variable that is present in the store but absent locally (or vice versa), by name.

## push — encrypt a changed or new local file

1. Identify the local file and its `manifest.tsv` row. No row → this is a **new** file:
   ask for the project and the destination path, then append a tab-separated row.
2. Stage inside the store so `.sops.yaml` resolves — this is the step that silently fails if
   skipped (see ws-shared):

```bash
D="$HOME/.agent-secrets"
cp "$root/$dest" "$D/$proj/.staging-$name"
( cd "$D" && sops -e --input-type "$it" --output-type "$ot" "$proj/.staging-$name" ) > "$D/$proj/$name"
rm -f "$D/$proj/.staging-$name"
```

3. **Verify the round-trip before committing.** For `dotenv`, compare `KEY=sha256(value)` pairs
   and the comment count; for `binary`, compare a whole-file hash. Nothing is ever printed:

```bash
a=$(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$root/$dest" | while IFS= read -r l; do
      printf '%s=%s\n' "${l%%=*}" "$(printf '%s' "${l#*=}" | shasum -a256 | cut -d' ' -f1)"; done | sort)
b=$(sops -d --input-type dotenv --output-type dotenv "$D/$proj/$name" \
    | grep -E '^[A-Za-z_][A-Za-z0-9_]*=' | while IFS= read -r l; do
      printf '%s=%s\n' "${l%%=*}" "$(printf '%s' "${l#*=}" | shasum -a256 | cut -d' ' -f1)"; done | sort)
[ "$a" = "$b" ] && echo "round-trip ok" || echo "ROUND-TRIP FAILED — do not commit"
```

A failed round-trip stops everything. Do not commit a file you could not verify.

4. Show which variables changed **by name**, then wait for a yes, then:

```bash
cd "$D" && git add -A && git commit -m "chore(<project>): update <file> (<VAR_A>, <VAR_B>)" && git push
```

The pre-commit hook refuses anything without sops ciphertext. If it fires, something plaintext
reached the index — remove it, do not bypass the hook.

## run — never touch disk

```bash
sops exec-env "$HOME/.agent-secrets/<proj>/<file>" '<command>'
```

Values live only in that child process. Prefer this for anything one-off: a psql session, a
migration against staging, a curl with a token.

## status — read-only

Report a table: every manifest row, whether its project is linked on this device, whether the
destination exists locally, and whether it matches the store (by variable names, never values).
Plus: tools present, agent key present, `personal/` active or not, and whether the store is
ahead of or behind its remote.

## New machine

1. Install `sops` and `age` (`brew install sops age`, or `winget`/`scoop` on Windows).
2. **Copy `~/.config/sops/age/keys.txt` over by hand** — AirDrop or Keychain. This is the one
   manual step and no scheme avoids it. `chmod 600` it (no-op on Windows).
3. `git clone <your secrets repo url> ~/.agent-secrets`
4. `git -C ~/.agent-secrets config core.hooksPath .githooks`
5. `ws-env pull`

## Activating `personal/`

One command. You type a passphrase twice; the script does the rest — generates the key,
encrypts it, extracts the public half and activates the `^personal/` rule in `.sops.yaml`:

```bash
~/.agent-secrets/bin/setup-personal-key.sh
```

**You cannot run this for him.** `age -p` refuses to read a passphrase from anything but a
terminal, by design — that refusal is exactly what makes the boundary real. Give him the
command, then do the commit afterwards.

Reading a personal secret always costs a passphrase, which is the point:

```bash
export SOPS_AGE_KEY="$(age -d ~/.config/sops/age/personal.age)"   # prompts
sops -d personal/<file>
```

Until that key exists, refuse to write into `personal/` and say why.

Keep **non-rotatable** identity data out of the store entirely — passport, bank account and
national ID numbers cannot be rotated, so "rewrite history" is not a remedy for them. Rotatable
secrets (API keys, tokens, passwords) are what this store is for.

## Rules

- Never print, echo, log or paste a secret value, not even partially. Names and counts only.
- Never overwrite a local env file that differs from the store without an explicit yes.
- Never commit without a passing round-trip check. Never bypass the pre-commit hook.
- Never write a decrypted file anywhere except its `dest` inside a workspace root.
- Leave the plaintext originals alone; this skill adds a sync path, it does not take over.
- Rotate at the source (Vercel, Supabase, Stripe) first, then `push`.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-sync` — the full machine catch-up, which calls `pull` for every project
- `ws-env status` — confirm it landed
