---
name: ws-sync
description: Make this machine current - sync skills and MCP servers, fetch every repo of every linked project and report what is behind, diverged or uncommitted, pull and decrypt credentials, then refresh the generated workspace instruction files. Ends with one drift table and a question wherever something needs deciding; it never discards work. Sets up a brand new device with --new-device, cloning workspaces that do not exist there yet. Use at the start of a session on a machine you have not used in a while, when two computers are out of sync, after changing a skill on the other machine, or when onboarding a new device. Not for configuring one project, which is ws-setup.
---

# Make this machine current

Ends with a drift table and, where something needs a decision, a question. **It never discards
anything.**

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md).
2. Decide the mode. `--new-device` (or an empty `projects:` map, or missing workspace folders)
   → jump to **New device** at the bottom, then come back and run steps 1–5.

```bash
# $proj, and never a positional parameter: one inside a skill body is replaced by the caller's
# argument before an agent ever sees it. Set proj, then call ws_root with no arguments.
ws_root() { sed -n '/^projects:/,$p' "$HOME/.agent-sync/device.yaml" | sed -n "s|^  $proj: *||p" | head -1; }
projects() { sed -n '/^projects:/,$p' "$HOME/.agent-sync/device.yaml" | sed -n 's|^  \([a-z0-9-]*\):.*|\1|p'; }
echo "device: $(sed -n 's/^device: *//p' "$HOME/.agent-sync/device.yaml")"
```

## 1. Skills and MCP servers

```bash
agent-sync sync          # pull, apply, push
agent-sync status        # expect no drift
```

A hand-edited deployed file makes this stop with a distinct exit code rather than overwriting —
that is deliberate. Report it and ask: keep the edit (`agent-sync apply --adopt`) or replace it
(`agent-sync apply --overwrite`). **Never pick for the user.**

If `agent-sync status` shows drift it cannot explain, `agent-sync status --why` names the rule
behind every cell.

## 2. Every repo of every linked project

Read-only. Fetch, then report — no checkouts, no pulls, no stashes.

```bash
for p in $(projects); do
  proj="$p"; root=$(ws_root); [ -d "$root" ] || { echo "== $p: FOLDER MISSING at $root"; continue; }
  echo "== $p ($root)"
  n=0
  # "$root" first: on a single-repo project the workspace root IS the repo, and a children-only
  # glob then skips every source directory and prints nothing, which reads as nothing to report.
  for r in "$root" "$root"/*/; do
    [ -d "$r/.git" ] || continue
    n=$((n + 1))
    name=$(basename "$r")
    git -C "$r" fetch --all --prune -q 2>/dev/null
    br=$(git -C "$r" branch --show-current)
    counts=$(git -C "$r" rev-list --left-right --count "@{u}...HEAD" 2>/dev/null || echo "no-upstream")
    dirty=$(git -C "$r" status --porcelain | wc -l | tr -d ' ')
    untracked=$(git -C "$r" ls-files --others --exclude-standard | wc -l | tr -d ' ')
    printf '   %-26s %-26s behind/ahead=%-12s dirty=%-4s untracked=%s\n' \
      "$name" "$br" "$counts" "$dirty" "$untracked"
  done
  [ "$n" -gt 0 ] || echo "   NO REPO FOUND at $root, or one level under it — nothing was examined, which is not the same as nothing to report"
done
```

**An empty sweep announces itself.** A project that printed its header and no rows used to be
indistinguishable from one with nothing to say; it now prints `NO REPO FOUND`. Surface that
line rather than swallowing it — on a project that *should* have repos it means the workspace
root in `device.yaml` points somewhere wrong.

**Flag, and ask about, each of these — never act on them unprompted:**

| Finding | Why it matters | Ask |
|---|---|---|
| `dirty` or `untracked` > 0 | may be work made on this machine and never pushed | commit, stash, or leave it? |
| `ahead` > 0 | local commits that exist nowhere else | push? |
| `behind` > 0 and clean | safe to fast-forward | pull? |
| `behind` > 0 **and** `ahead` > 0 | diverged — a pull would merge or conflict | show the two logs, then ask |
| `no-upstream` or `[gone]` | the remote branch was deleted or never pushed | leave it and say so |
| not on the integration branch | may be mid-task | leave it; just report |

On a machine untouched for months, expect most repos to be far behind **and** possibly dirty.
That combination is exactly where work gets lost, so go repo by repo and wait for an answer
each time.

## 3. Credentials

```
ws-env pull
```

Report what it wrote, what it skipped because a project is not linked, and anything where the
local file differed from the store (by variable **name** only — never a value).

### 3b. Service access, on **this** machine

A project's cartridge may declare `services:` — the managed services the agent itself has to
drive. **Access to them is per machine, and that is exactly why it belongs in a machine
catch-up**: a `cli-session` service is signed in on the laptop it was set up on and signed in
nowhere else, and a token pulled in step 3 is useless until the CLI it feeds is installed here.
Without this step the answer arrives mid-task as a failed deploy.

Readable first, then the content, the same order as every other gate in this pack — `grep` prints
nothing both when a key is absent and when the file is not there, and those two must not reach the
same branch:

```bash
cartridge="<docs_home>/reference.md"       # quoted: a workspace path may contain a space
if [ ! -e "$cartridge" ]; then
  # Absent and unreadable are DIFFERENT, and this block said so two paragraphs down while
  # conflating them: `[ ! -r ]` is true for both. A project with no cartridge is the ordinary case
  # the pack promises to work in, so it is a row and not an alarm.
  echo "   services: none declared (no cartridge at $cartridge — the pack runs without one)"
elif [ ! -r "$cartridge" ]; then
  echo "   services: UNREADABLE cartridge at $cartridge — access is UNKNOWN, not ok"
else
  # EVERYTHING below reads the FRONTMATTER ONLY — the lines between the first two `---`. The
  # cartridge is a Markdown file whose prose may illustrate any of these keys in a fenced block,
  # and this step RUNS commands out of what it finds: a `services:` example in the prose would
  # otherwise be executed. Bounding one key and not the others is how that happened once already.
  fm=$(awk 'NR==1&&/^---[[:space:]]*$/{f=1;next} f&&/^---[[:space:]]*$/{exit} f' "$cartridge")
  if [ -z "$fm" ]; then
    echo "   services: no YAML frontmatter in $cartridge — access is UNKNOWN, not ok"
  else
    # One comment-stripper, used for every value. It has to handle BOTH shapes: a trailing
    # ` # …` after a value, and a line that is ONLY a comment. The second was missed, and
    # `services:   # none yet` then read as a flow-style list, which is the opposite answer.
    sc() { sed -e 's/^[[:space:]]*#.*$//' -e 's/[[:space:]]#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

    sline=$(printf '%s\n' "$fm" | sed -n 's/^services:[[:space:]]*//p' | head -1 | sc)
    case "$sline" in ""|"[]") flow=0 ;; *) flow=1 ;; esac

    blk=$(printf '%s\n' "$fm" | awk '/^services:/{f=1;next} f&&/^[^ \t#]/{exit} f&&/^[ \t]*#/{next} f{print}')

    if ! printf '%s\n' "$fm" | grep -q '^services:'; then
      echo "   services: none declared (no services: key — this project predates it, or declares none)"
    elif [ "$flow" = "1" ]; then
      echo "   services: written in a flow style this step cannot parse — UNKNOWN, not none. Rewrite it as block rows, one key per line"
    elif [ -z "$(printf '%s' "$blk" | tr -d '[:space:]')" ]; then
      echo "   services: none declared (services: is empty — a positive answer)"
    else
      # ---- the credential file, so a `token` service's check can actually pass ----
      # Its check reads the credential from the ENVIRONMENT and `ws-env pull` only wrote it to
      # disk, so without this a correct machine reports every token service as unset.
      aenv=$(printf '%s\n' "$fm" | sed -n 's/^agent_env:[[:space:]]*//p' | head -1 | sc | sed -e 's/^"//' -e 's/"$//')
      secret_names=$(printf '%s\n' "$blk" | sed -n 's/^[[:space:]]*credential:[[:space:]]*//p' \
                     | sc | sed -e 's/^"//' -e 's/"$//' | grep -E '^[A-Za-z_][A-Za-z0-9_]*$')
      case "$aenv" in ""|null|"~") : ;; *)
        if [ -r "<workspace root>/$aenv" ]; then
          # EVERY name the file assigns, not only the declared ones: `set -a` exports all of them,
          # so a check that echoes an undeclared variable would print it in clear.
          secret_names="$secret_names
$(sed -n 's/^[[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' "<workspace root>/$aenv")"
          set -a; . "<workspace root>/$aenv"; set +a
          echo "   services: loaded $aenv for the checks"
        else
          echo "   services: $aenv is declared and NOT readable here — a token check will fail for that reason, not for being unset"
        fi ;;
      esac
      # Longest value first, so a value that is a PREFIX of another cannot redact the short one and
      # leave the rest of the long one in clear under the wrong name. Measured.
      ranked=$(for cn in $secret_names; do
                 eval "cv=\${$cn:-}"            # safe: filtered to identifier characters above
                 [ -n "$cv" ] && printf '%s %s\n' "$(printf '%s' "$cv" | wc -c | tr -d ' ')" "$cn"
               done | sort -rn | cut -d' ' -f2)
      credlist=""                                # dedupe, keeping the longest-first order
      for cn in $ranked; do
        case " $credlist " in *" $cn "*) : ;; *) credlist="${credlist:+$credlist }$cn" ;; esac
      done

      # A secret is NOT a regex. Interpolating a value into `sed` leaked it three ways, all
      # measured: a value containing `|` or `[` made sed print the value in its own error message;
      # a value containing a backslash silently failed to match itself; `a*b` matched the bare `b`
      # and printed `a*` in clear. `index()` is a literal search, so none of that applies.
      scrub() {
        for cn in $credlist; do
          eval "cv=\${$cn:-}"
          [ -n "$cv" ] || continue
          # `getline line` rather than a field reference: a skill body may contain no positional
          # parameter at all — the harness substitutes the caller's argument for one — and
          # `ws-refine`'s audit fails a skill containing the sigil anywhere, awk's own record
          # variable included. This reads each line into a named variable instead.
          so=$(printf '%s' "$so" | CV="$cv" RP="[REDACTED $cn]" awk '
                 BEGIN { cv = ENVIRON["CV"]; rp = ENVIRON["RP"]
                         while ((getline line) > 0) {
                           out = ""
                           while ((i = index(line, cv)) > 0) {
                             out = out substr(line, 1, i - 1) rp
                             line = substr(line, i + length(cv))
                           }
                           print out line
                         } }')
        done
        printf '%s' "$so"
      }
      # SCRUB FIRST, then shorten. Cutting first leaves the first 60 characters of a long secret in
      # the row: the truncated value no longer matches itself, so nothing is replaced. Measured.
      tail1() { so="$out"; so=$(scrub); printf '%s' "$so" | tail -1 | cut -c1-60; }

      t() {
        tv=$(printf '%s' "${tl#*:}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        # ORDER MATTERS. A quoted scalar is unwrapped FIRST — single or double, since YAML allows
        # both — and only an UNQUOTED value then has a comment stripped, because YAML does not end
        # a quoted value at a hash. Stripping first destroyed the closing quote the balance test
        # looks for, so `check: "printf 'x # y'"` became `"printf 'x` and the row then asserted
        # CLI MISSING about a command that was present. Measured in both orders, and with both
        # quote characters.
        case "$tv" in
          \"*\")  tv=${tv#\"}; tv=${tv%\"} ;;
          \'*\')  tv=${tv#\'}; tv=${tv%\'} ;;
          *)      tv=$(printf '%s' "$tv" | sc) ;;
        esac
        printf '%s' "$tv"
      }

      CHK_LIMIT=${CHK_LIMIT:-20}
      # A check must not be able to hold the catch-up open. Two independent ways it can: it reads
      # stdin (an interactive login prompt), or it spins (a device-code flow polling). So stdin is
      # /dev/null and the command is bounded. `timeout` is GNU and absent on macOS; perl's alarm is
      # in the base system on both and exits 142 when it fires.
      if command -v timeout >/dev/null 2>&1; then
        runchk() { timeout "$CHK_LIMIT" sh -c "$rc_cmd" </dev/null 2>&1; }
      elif command -v perl >/dev/null 2>&1; then
        runchk() { perl -e 'alarm shift; exec @ARGV' "$CHK_LIMIT" sh -c "$rc_cmd" </dev/null 2>&1; }
      else
        runchk() { sh -c "$rc_cmd" </dev/null 2>&1; }   # UNBOUNDED — said out loud below
        echo "   services: no timeout and no perl here, so a check that spins will hold this step open"
      fi

      n=0
      rep() {
        n=$((n+1))
        if [ -z "$acc" ]; then
          printf '   %-22s %-12s UNKNOWN — no access: on this row, so nothing is run\n' "$id" "(none)"
        elif [ "$acc" = "none" ]; then
          # `access: none` says there is no programmatic way in, so a check recorded against it is
          # not run even when present — running it would contradict the declaration just read.
          printf '   %-22s %-12s UNPROVED — access: none, so nothing is run; the agent asks you\n' "$id" "$acc"
        elif [ -z "$chk" ] || [ "$chk" = "null" ]; then
          printf '   %-22s %-12s UNPROVED — no check recorded, so nothing was run\n' "$id" "$acc"
        elif ! command -v "${chk%% *}" >/dev/null 2>&1; then
          printf '   %-22s %-12s CLI MISSING — %s\n' "$id" "$acc" "${ins:-no install command recorded}"
        else
          # Capture the status ONCE, on the line after the command. Testing it twice tests the
          # first `[` the second time, so every non-zero check reported exit 1 and a GNU `timeout`
          # kill (124) was laundered into an ordinary failure. Measured.
          rc_cmd="$chk"; out=$(runchk); rc=$?
          case "$rc" in
            0)       printf '   %-22s %-12s ok — %s\n' "$id" "$acc" "$(tail1)" ;;
            124|142) printf '   %-22s %-12s TIMED OUT after %ss — it wanted input or kept polling; not a pass\n' "$id" "$acc" "$CHK_LIMIT" ;;
            *)
              case "$acc" in
                cli-session) printf '   %-22s %-12s NOT SIGNED IN (exit %s) — run %s\n' "$id" "$acc" "$rc" "${hum:-its login command}" ;;
                token)       printf '   %-22s %-12s CHECK FAILED (exit %s) — is %s loaded? %s\n' "$id" "$acc" "$rc" "${cred:-the credential}" "$(tail1)" ;;
                *)           printf '   %-22s %-12s CHECK FAILED (exit %s) — %s\n' "$id" "$acc" "$rc" "$(tail1)" ;;
              esac ;;
          esac
        fi
      }

      id=""; acc=""; chk=""; cred=""; hum=""; ins=""
      while IFS= read -r l; do
        tl="$l"
        case "$l" in
          *-\ id:*)          [ -n "$id" ] && rep; id=$(t); acc=""; chk=""; cred=""; hum=""; ins="" ;;
          *[\ ]access:*)     acc=$(t) ;;
          *[\ ]check:*)      chk=$(t) ;;
          *[\ ]credential:*) cred=$(t) ;;
          *[\ ]human_step:*) hum=$(t) ;;
          *[\ ]install:*)    ins=$(t) ;;
        esac
      done <<SVC
$blk
SVC
      [ -n "$id" ] && rep
      echo "   services: read $cartridge, $n declared, $n checked"
    fi
  fi
fi
```

**It counts what it read and prints that count**, so `0 declared` and "I never found the block"
are different lines. The parse is deliberately dumb — `sed` and `case`, no `yq` or `jq`, neither of
which can be assumed on every machine, which is the same reason `manifest.tsv` is tab-separated.
Two shapes it does not parse, each with its own honest output: a **flow-style** list
(`services: [{…}]`) is caught before the block scan and reported as **`UNKNOWN`, not none**,
because the block scan cannot see that line at all; and a row whose first key is not `id:` is
dropped, leaving `0 declared` against a block that is not empty — which is why the count is
printed beside the block's presence rather than instead of it. Both measured 2026-11-04.

| What came back | What it means | Say |
|---|---|---|
| the check succeeds | access works **here** | `ok`, with the command's own last line |
| the CLI is missing | nothing is signed in, because nothing is installed | `CLI MISSING — <install>` |
| the CLI is there and the check fails, `cli-session` | present and not authenticated — the case that looks like working access | `NOT SIGNED IN — run <human_step>` |
| the check fails, `token` | the credential is absent or wrong on this machine | `CHECK FAILED — is <VAR> loaded?` |
| the check wants input, or polls | an interactive or device-code flow, which must never hold a sync open | `TIMED OUT after <n>s` — **not** a pass, and the `check:` is the wrong command |
| `check: null` | there is nothing to run | `UNPROVED — no check recorded`, never `ok` |
| `access: none` | the cartridge says there is no programmatic way in, so a check recorded against it is **not run** | `UNPROVED — access: none, so nothing is run` |
| no `access:` on the row | the row does not say how access works, so nothing can be concluded | `UNKNOWN — no access: on this row`, never `ok` |
| `services:` absent or empty | the project declares none | `none declared`, **as a row** |
| the cartridge is unreadable | you do not know what the project declares | `UNREADABLE — access is UNKNOWN, not ok` |

**`none declared` is printed rather than omitted.** Silence makes "this project declares no
services" and "this step never ran" render identically, and the second is the one worth knowing.
Same for the unreadable cartridge: it is `UNKNOWN`, never `ok`, and never the `none` branch.

**Projects with no cartridge yet**: the first branch above covers it and says so in one line.
This skill works from `device.yaml` and `manifest.tsv` alone for everything else, and a project
with no cartridge simply declares no services — it is not an error and not a stop.

**Every printed line is scrubbed, and the threat model is wider than the declared credentials.**
Sourcing `agent_env` puts its values in the checks' environment, and `set -a` exports **everything**
that file assigns — so the scrub list is every name the file assigns *plus* every `credential:` the
cartridge declares, longest value first, matched literally. Three measured reasons for each of
those words: a value that is a prefix of another redacted the short one and left the rest of the
long one in clear under the wrong name; cutting the line to 60 characters before scrubbing printed
the first 60 characters of a long secret, because a truncated value no longer matches itself; and
interpolating a value into a `sed` expression leaked it three ways — `|` or `[` in the value made
`sed` print the value in its own error message, a backslash made it silently fail to match itself,
and `a*b` matched the bare `b`. A secret is not a regex.

**A check that times out is a defect in the cartridge, not in the machine.** Measured while this
step was written: a real platform CLI, installed and unauthenticated, **blocked indefinitely** on
its own interactive login prompt and held the whole step open. That is why stdin is `/dev/null` and
the command is bounded, and why the row says so instead of waiting: the right repair is a `check:`
that cannot prompt, or `check: null`.

**Run it; never infer it.** A CLI on `PATH` is not access, and reporting it as access is the
failure this step exists to catch. And as everywhere else in this skill: **report and ask.** Do
not run a `login`, do not open a browser flow, do not write a credential — those are the user's,
and `human_step` is what you print.

**What makes running these safe is a rule rather than a mechanism**: `ws-setup` refuses to record
a `check:` that is not read-only, at the one point a human is in the conversation. A hand-edited
cartridge can still put anything there, and this step will run it — which is written down in the
worksite docs' limitations record rather than left for someone to discover.

## 4. Deployed workspace instruction files

For any project whose cartridge sets `agents_file: copy`, the workspace `AGENTS.md` is a
generated copy of a file versioned in the docs repo. Refresh it, and report drift rather than
silently overwriting:

```bash
# source = <docs_home>/workspace/AGENTS.md   deployed = <root>/AGENTS.md
diff -q "$src" <(tail -n +2 "$deployed") >/dev/null || echo "   AGENTS.md differs from its source"
```

A deployed copy that differs means someone edited the copy. Say so and ask whether to overwrite
it or to carry the edit back to the source. Each generated copy starts with:

```
<!-- Generated by ws-sync from <source path>. Edit the source, not this. -->
```

Projects with no cartridge yet: skip this step and say nothing. (Degrade, never fail.)

## 5. The drift table

One table, then the questions. Nothing else.

```markdown
| Project | Repos | Skills/MCP | Credentials | Services | Instructions | Needs you |
|---|---|---|---|---|---|---|
| northwind | 3 ok | synced | 2 written | 2 ok | n/a | — |
| kestrel | 1: 1 dirty | synced | 10 written | none declared | n/a | `kestrel-ai` has 4 uncommitted files |
| atlas | 2: 1 diverged | not deployed | 5 written | 1 NOT SIGNED IN | n/a | `atlas-infra` diverged; no skills included yet; run `<cli> login` for `<service>` |
```

Then: every question from steps 1–4 (3b included), numbered, each answerable with one word. If nothing needs
a decision, say "clean" and stop.

## New device

**Full procedure: [../ws-shared/new-device.md](../ws-shared/new-device.md).** Follow it in order.

The shape of it: the human installs the tooling, clones the library with
`agent-sync setup --clone`, and carries the age key over by hand — that last step is irreducible.
Then **print an inventory and stop**, because a machine untouched for months may hold work worth
more than the convenience of a fast setup.

For every project whose workspace folder is missing or sits somewhere different from the other
machine, **ask where it should go** — with concrete candidates found by looking for a
`Development`-style folder first. Never invent a path and never reuse the other machine's; the
paths are per device by design.

Create each workspace in the documented shape — a root that is **not** a git repo, the repos
cloned inside it, `.<project>/tracks/`, and the workspace `AGENTS.md` written as a **copy**,
never a symlink. Then `ws-env pull`, then catch up the pre-existing repos one at a time.

## Rules

- Read-only until the user answers. No pull, checkout, stash, reset, clean or push without a yes.
- `git fetch` and `git status` are always safe. `git pull` is not — it can merge.
- Never `git checkout -- .`, never `git clean`, never `--force`, never `--no-verify`.
- Never print a secret value.
- A repo that is behind *and* dirty gets a per-repo question, never a batch "pull everything?".
- Report what you could not check rather than assuming it is fine.
- **Never run a service's `login`, never open a browser flow, never write a credential** (3b).
  Those are the user's; print `human_step` and move on.
- **A service's access is run, never inferred.** A CLI on `PATH` is not access, and an unreadable
  cartridge is `UNKNOWN` rather than `ok`.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-env` — credentials alone, without the repo sweep
- `agent-sync status --why` — if skills drift and the reason is unclear
