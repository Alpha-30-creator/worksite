---
name: ws-env
description: Sync credentials between machines from the private encrypted secrets store - create that store from nothing on a first machine, pull and decrypt credentials into each workspace, re-encrypt and push local changes, run a command with secrets injected into the process and never written to disk, add a new file to the store, or report what is encrypted versus what exists locally. Never prints a value. Ends with a report of variable names and counts only; when it was not asked for by name it runs the read-only status mode and offers the rest rather than performing it, because decrypting credentials to disk during an unrelated task is never the right default. Use when credentials are missing or stale, after setting up a machine, when a key is rotated, or when a workspace needs its env files materialised.
---

# Sync credentials

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md).
2. Check the tools and the key, and say plainly which is missing rather than guessing:

```bash
for c in sops age git; do printf '%-6s %s\n' "$c" "$(command -v $c || echo MISSING)"; done
export SOPS_AGE_KEY_FILE="${KEY:-$HOME/.config/sops/age/keys.txt}"   # KEY: init's --key, if one was given
[ -f "$SOPS_AGE_KEY_FILE" ] && echo "agent key present at $SOPS_AGE_KEY_FILE" || echo "agent key MISSING at $SOPS_AGE_KEY_FILE -> init generates one on a FIRST machine; 'New machine' carries an existing one across"
[ -d "${STORE:-$HOME/.agent-secrets}" ] && echo "store present at ${STORE:-$HOME/.agent-secrets}" || echo "store MISSING at ${STORE:-$HOME/.agent-secrets} -> clone it, or there has never been one: see init below"
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
| "I have no store", "set this up from scratch", first machine ever, `ws-env` reported the store missing and no clone exists anywhere | **init** |
| "my env is missing / stale", "set up this workspace", after a new machine | **pull** |
| "I changed a key", "start syncing this file", after rotating a credential | **push** |
| "run X with the staging credentials" | **run** |
| "what's where", "is anything out of sync" | **status** |

Unclear → run **status** first; it is read-only.

## init — create the store from nothing

The only mode that writes where nothing exists yet, and the one that was missing: every other mode
assumes the store is already somewhere to be cloned. **A second machine does not need this** — that
is *New machine* at the bottom, which carries an existing store across. This is the first machine
ever.

```
ws-env init [--store <dir>] [--key <path>] [--repair]
```

`ws-env` is a skill rather than a binary, so those are the words the user says and the block below
is what you run. **Map them first, in the same shell as everything else:** `--store` → `STORE`,
`--key` → `KEY`, `--repair` → `REPAIR=1`.

**Run the whole block in one shell.** Its first lines are the guard, and the same reason applies
here as to the retirement block in `../ws-shared/tracks.md`: a fragment run on its own has no
`$STORE`, and `[ -e "$STORE" ]` with `STORE` unset is **false**, so the one guard protecting a real
credential store does not fire and prints nothing. A gate that passes on no input is this pack's
characteristic defect, and an unset variable is how it gets in.

**`--store` isolates the store and nothing else.** Every line of output names the store it acted
on, so a trial run cannot be mistaken for a run against the real one — but the age key lives at
`--key`, outside any store, and on a machine that has none a trial **generates the real key**.
That is why `--key` exists: point both at throwaway paths to try the mode, and say which you did.

```bash
# ---------- the guard: an unset STORE must never reach the lines below ----------
STORE="${STORE:-$HOME/.agent-secrets}"
KEY="${KEY:-$HOME/.config/sops/age/keys.txt}"
REPAIR="${REPAIR:-0}"
[ -n "$STORE" ] && [ -n "$KEY" ] || { echo "REFUSING: STORE or KEY is empty. Nothing was touched."; exit 1; }
case "$STORE" in /*) : ;; *) echo "REFUSING: --store must be an absolute path, got '$STORE'"; exit 1 ;; esac
echo "store: $STORE"
echo "key:   $KEY"
[ "$REPAIR" = "1" ] && echo "mode:  repair — writes only what is missing"

# ---------- 1. tools, named, and a stop rather than an install ----------
miss=""
for c in sops age age-keygen git; do command -v "$c" >/dev/null 2>&1 || miss="${miss:+$miss }$c"; done
if [ -n "$miss" ]; then
  echo "MISSING: $miss"
  echo "install with: brew install sops age   (Windows: winget install … / scoop install …)"
  echo "init wrote NOTHING to $STORE."
  exit 1
fi

# ---------- 2. an existing store is a refusal unless repairing ----------
if [ -e "$STORE" ] && [ "$REPAIR" != "1" ]; then
  echo "REFUSING: $STORE already exists, and init does not write into a store it did not create."
  echo "  --repair  writes only what is missing and never touches an existing key"
  echo "  or: this is a second machine — see 'New machine', which clones instead"
  exit 1
fi

# ---------- 3. the key: reuse before you generate, and never overwrite ----------
if [ -f "$KEY" ]; then
  echo "key: reusing $KEY — not touched"
else
  mkdir -p "$(dirname "$KEY")" && age-keygen -o "$KEY" && chmod 600 "$KEY" \
    || { echo "FAILED to create $KEY — init stopped, $STORE left as it was"; exit 1; }
  echo "key: generated $KEY (mode 600)"
fi
nkeys=$(age-keygen -y "$KEY" | grep -c .)
AGENT_PUB=$(age-keygen -y "$KEY" | head -1)
[ "$nkeys" -gt 1 ] && echo "key: $KEY holds $nkeys keys; using the FIRST as the recipient — say so, and stop if that is wrong"
[ -n "$AGENT_PUB" ] || { echo "REFUSING: could not read a public half out of $KEY"; exit 1; }
echo "recipient: $AGENT_PUB"

# ---------- 4. write only what is absent ----------
mkdir -p "$STORE/.githooks"
wrote=""; kept=""
# Set `wp` to the relative path, then pipe the content in. It reads a NAMED variable rather than a
# positional one on purpose: a positional parameter in a skill body is replaced by the caller's
# argument when the skill is delivered, so this function would receive the agent's invocation text
# instead of a path (p8.35 — and ws-refine's audit fails a skill containing one, this comment
# included, which is why the sigil is not written out here).
w() {
  if [ -e "$STORE/$wp" ]; then kept="${kept:+$kept }$wp"; cat >/dev/null
  else cat > "$STORE/$wp"; wrote="${wrote:+$wrote }$wp"; fi
}

# Order matters: sops takes the FIRST matching rule, so ^personal/ must come BEFORE .*
wp=.sops.yaml; w <<EOF
# Which age keys may decrypt which paths.
# Order matters: the FIRST matching rule wins, so a narrower path_regex goes ABOVE .*
#
# Uncomment the ^personal/ rule once a personal key exists — see "Activating personal/" below.
# Its recipient is the PERSONAL key ALONE: adding the agent key here would let an unattended
# agent read those files, which is the opposite of what the folder is for.
creation_rules:
#  - path_regex: ^personal/
#    age: <personal recipient>
  - path_regex: .*
    age: $AGENT_PUB
EOF

wp=manifest.tsv; w <<EOF
# $STORE/manifest.tsv — every encrypted file, and where it is materialised.
#
# Tab-separated on purpose, not YAML: the consumer is a bash loop, and neither \`yq\` nor \`jq\`
# can be assumed on every machine.
#
# src	type	project	dest
#   src     path inside the secrets store
#   type    dotenv | json | binary
#   dest    path RELATIVE TO THE WORKSPACE ROOT, resolved per device via device.yaml
#
# \`dotenv\` encrypts values but leaves names and comments readable, so a diff shows WHICH
# variable changed without revealing it. \`binary\` makes the whole file opaque — use it for
# SSH keys, certificates, and any file whose bytes must come back exactly.
EOF

wp=.githooks/pre-commit; w <<'EOF'
#!/bin/sh
# Refuse any staged file that carries no sops ciphertext. Metadata and docs are exempt by name.
fail=0
for f in $(git diff --cached --name-only --diff-filter=ACM); do
  case "$f" in manifest.tsv|.sops.yaml|.gitignore|.githooks/*|*.md) continue ;; esac
  [ -r "$f" ] || { echo "UNREADABLE, so not provably encrypted: $f"; fail=1; continue; }
  grep -q '"sops"\|^sops_\|sops:' "$f" || { echo "PLAINTEXT: $f"; fail=1; }
done
[ "$fail" -eq 0 ] || { echo "refusing — encrypt it with 'ws-env push'. Never --no-verify."; exit 1; }
EOF

chmod +x "$STORE/.githooks/pre-commit"
hookmode=$([ -x "$STORE/.githooks/pre-commit" ] && echo "executable" || echo "NOT EXECUTABLE — git will IGNORE it")

# ---------- 5. the repo, the hooks path, and one commit so a push has something to push ----------
[ -d "$STORE/.git" ] || git -C "$STORE" init -q
git -C "$STORE" config core.hooksPath .githooks
BR=$(git -C "$STORE" symbolic-ref --short HEAD 2>/dev/null || echo "?")
if [ -z "$(git -C "$STORE" rev-list -n1 --all 2>/dev/null)" ]; then
  git -C "$STORE" add .sops.yaml manifest.tsv .githooks/pre-commit \
    && git -C "$STORE" commit -q -m "chore: initialise the credential store" \
    && echo "first commit: made on $BR (the hook exempts these three by name)" \
    || echo "first commit: FAILED — a push will have nothing to send"
else
  echo "first commit: already present, none made"
fi

# ---------- 6. the key is not where sops looks by default, so print the export ----------
echo "put this in your shell profile, or every later sops command will say the key is missing:"
echo "  export SOPS_AGE_KEY_FILE=\"$KEY\""

# ---------- 7. the closing line, read from what happened ----------
echo "init: store $STORE · key $([ -f "$KEY" ] && echo present || echo MISSING) · wrote[${wrote:-nothing}] · kept[${kept:-nothing}] · hook $hookmode · branch $BR · no remote yet · $(grep -c '^[^#[:space:]]' "$STORE/manifest.tsv" || true) rows"
```

**Why the hook is `chmod +x` and why the mode is then reported.** Git **silently ignores** a hook
that is not executable — it prints a hint and **creates the commit anyway**. Measured on git 2.54:
a non-executable `pre-commit` that exits 1 let `git commit` succeed. So a store written without
that one line has a guard that never runs, while the closing line would have said `hook installed`.
The mode is read back with `[ -x ]` rather than assumed, for the same reason every check in this
pack names what it read: a step that reports what it *intended* is the failure, not the typo.

**Why it prints the `SOPS_AGE_KEY_FILE` export.** The key goes to `--key`
(`~/.config/sops/age/keys.txt` by default), which is **not** where sops looks on its own: its macOS
default is `~/Library/Application Support/sops/age/keys.txt`. Every mode of this skill exports the
variable in its preamble, so an agent following the skill is fine — but a human whose next step is
`sops -d` in a fresh shell gets `failed to load age identities`, which reads like a lost key rather
than an unset variable. Measured 2026-11-04 on a store this mode had just created: the round trip
failed on the first attempt for exactly that reason and succeeded with the variable exported.

**Why it writes the manifest header rather than copying the example.**
`../ws-shared/examples/manifest.tsv` is a worked **example**: fourteen lines of header and **six
data rows** for three invented projects. Copying it gives a new store six rows pointing at
workspaces that do not exist, which the next `pull` iterates. The header above is also written with
`$STORE` in its first line, so a store created with `--store` does not describe a directory it is
not in.

The row count is a `grep` rather than an `awk` with a whole-record reference, because
`ws-refine`'s audit fails a skill whose body contains a positional parameter *anywhere* — and
awk's own record variable looks like one to a text scan. Measured: the audit went from one finding
to two on this line alone.

**Why `w` exists.** `--repair` promises to add what is absent and change nothing that is present,
and a table of files to write does not implement that — it overwrites. `w` writes only when the
path is absent **in both modes**, and the closing line prints `wrote[…]` and `kept[…]` separately,
so a repair says which it did. Without it, repairing a real store would replace `.sops.yaml` —
losing recipients, including an activated personal rule — and truncate `manifest.tsv` to the
header, taking every sync row with it, while reporting success.

### Then the remote, which is the user's to create

```bash
echo "git -C \"$STORE\" remote add origin <the PRIVATE repo you create>"
echo "git -C \"$STORE\" push -u origin $BR"
```

**Print those two lines and stop.** Creating a repository on someone's GitHub account, or any
account anywhere, is not this skill's to do — and a credential store pushed to the wrong place is
not recoverable by deleting it again. Say in the same breath that the repo must be **private**.

The branch is substituted rather than written as `main`: `git init` names it from
`init.defaultBranch`, which differs by git version and by machine, and `push -u origin main` on a
store whose branch is `master` fails. So does a push from a store with **no commit** — measured:
`error: src refspec main does not match any` — which is why step 5 makes one.

### Then say the two-key model, and offer the first row

Two keys, because they answer different questions:

- the **agent key** at `$KEY`, with no passphrase, which is what lets a skill decrypt without a
  human present — every rotatable credential lives behind it;
- the **personal key**, passphrase-protected, an explicit opt-in that costs a passphrase every
  read. Nothing is written into `personal/` until it exists, and *Activating `personal/`* below is
  that step. It is the user's to run: `age -p` refuses to read a passphrase from anything but a
  terminal, which is what makes the boundary real rather than advisory.

Then the join to the rest of the pack. **Where you know the project's `agent_env:`** — the file
`ws-setup` generates for the credentials the agent itself needs — offer it as the store's first
row, which is what makes those pasted credentials reach the second machine at all:

```
<project>/agents.env	dotenv	<project>	<state_dir>/env/agents.env
```

`init` is not project-scoped and cannot find a cartridge on its own: it resolves nothing but
`device.yaml`. So this applies when the user names the project, or when `ws-setup` reached `init`
from its own services step and already has the value — and otherwise you say that the row is added
later by `ws-env push`, naming the command, rather than going looking for a cartridge.

Offer it; do not add it unasked, and **never add a row for a file whose values are still empty** —
there is nothing to encrypt yet, and a row that decrypts to blanks overwrites a filled-in copy on
the next `pull`. Say that is why, and come back after the user has pasted.

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

**Say which columns you could not answer, rather than printing them clean.** The match column is
computed by decrypting, so **without the agent key it is unknown, not equal** — and "unverified" and
"matches" must never render the same. Same for a store that has no remote: `no remote` is a fact,
while a blank ahead/behind reads as "in sync". With no store at all, the whole table is one line
pointing at `init`.

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

**A store created by `init` has no `bin/`** — `init` writes three files (`.sops.yaml`,
`manifest.tsv`, `.githooks/pre-commit`) and nothing else, so that script does not exist there. The
age key is a fourth thing it may create, and it is **outside** the store by design. The same job is three commands the user runs **themselves**, in their
own terminal, because `age -p` will not read a passphrase from anywhere else:

```bash
age-keygen | age -p > ~/.config/sops/age/personal.age   # prompts for a passphrase, twice
age -d ~/.config/sops/age/personal.age | age-keygen -y  # prints the PUBLIC half; prompts again
# then put that public half on the ^personal/ rule in .sops.yaml and uncomment the rule
```

The rule takes the **personal recipient alone**. Adding the agent key to it would let an
unattended agent read those files, and the whole point of the folder is that reading one costs a
passphrase.

**You cannot run this for him.** `age -p` refuses to read a passphrase from anything but a
terminal, by design — that refusal is exactly what makes the boundary real. Give him the
command, then do the commit afterwards.

Reading a personal secret always costs a passphrase, which is the point:

```bash
export SOPS_AGE_KEY="$(age -d ~/.config/sops/age/personal.age)"   # prompts
sops -d "personal/<file>"
```

Until that key exists, refuse to write into `personal/` and say why.

Keep **non-rotatable** identity data out of the store entirely — passport, bank account and
national ID numbers cannot be rotated, so "rewrite history" is not a remedy for them. Rotatable
secrets (API keys, tokens, passwords) are what this store is for.

## Rules

- Never print, echo, log or paste a secret value, not even partially. Names and counts only.
- **`init` never overwrites an existing key, and never writes into a store it did not create** —
  that is what `--repair` is for, and it adds only what is missing.
- **`init` creates no repository on any host and no account anywhere.** It prints the two commands
  and stops.
- **`init` runs as one block, and writes only what is absent.** A fragment of it has no `$STORE`,
  and the guard that protects an existing store cannot fire on an empty one.
- **Never run an interactive login or a passphrase prompt on the user's behalf.** `age -p` and a
  service's `login` both need a terminal the agent is not; print the command.
- Never overwrite a local env file that differs from the store without an explicit yes.
- Never commit without a passing round-trip check. Never bypass the pre-commit hook.
- Never write a decrypted file anywhere except its `dest` inside a workspace root.
- Leave the plaintext originals alone; this skill adds a sync path, it does not take over.
- Rotate at the source — the service's own dashboard — first, then `push`.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-sync` — the full machine catch-up, which calls `pull` for every project, and re-checks the
  services a cartridge declares, because access to those is per machine
- `ws-env status` — confirm it landed
- `ws-setup` — after `init`, the project side: which services the agent must drive, and the
  `agent_env` file whose first manifest row `init` offered
