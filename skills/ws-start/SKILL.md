---
name: ws-start
description: Begin or resume one unit of work - sync the repos, show what is open and in progress on whichever tracker the project uses, claim a task, create its track directory and optionally its git worktree, then summarise what it asks for. Ends with a claimed task and a summary, never with a plan and never with code. Use at the start of a session, when picking what to do next, when resuming paused work, or when taking over a task someone else wrapped. Not for changing what the work is, which is ws-task, and not for deciding how to build it, which is ws-plan.
---

# Start or resume a track

Ends with a claimed task, a track directory and a summary. **Not** with a plan, and **not** with
code.

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md) and
   [../ws-shared/tracks.md](../ws-shared/tracks.md).
2. Resolve the workspace root from `device.yaml`; read the cartridge at `<docs_home>/reference.md`.
   No cartridge → offer `ws-setup` in adopt mode, then continue as best you can (R1).
3. Read `<state_dir>/me` if the project has collaborators. Missing → ask once and write it.
4. Read the tracker adapter for `tracker.kind` from `../ws-shared/trackers/`. Unknown kind → ask
   the four questions in that folder's README and carry on.
5. **Assert that the state dir cannot be committed.** `<state_dir>` holds the journal, whose
   entry header identifies the machine, and every track file. On most projects the workspace
   root is not a git repo and the question does not arise. Where it *is* one, the only thing
   standing between those files and a commit is an ignore rule — and an ignore rule is a line
   someone can delete. A project whose own `verify` already asserts this gets it twice, which is
   cheaper than reading the cartridge to work out whether to bother.

   ```bash
   sd="<state_dir>"                                  # from the cartridge
   if ! git rev-parse --git-dir >/dev/null 2>&1; then
     echo "state dir: not inside a git repo, so nothing here can be committed"
   elif git check-ignore -q "${sd%/}/" || git check-ignore -q "${sd%/}"; then
     echo "state dir: $sd is matched by an ignore rule"
   else
     echo "STATE DIR IS NOT IGNORED: $sd sits inside a git repo and git would commit it."
     echo "Add it to .gitignore before creating a track — the journal identifies the machine."
   fi
   ```

   **The trailing slash is not cosmetic.** A rule written `<state_dir>/` matches directories
   only, and git can tell a bare path is a directory only by looking at the filesystem — so the
   bare query answers "ignored" on a checkout where the directory already exists and "NOT
   ignored" on a fresh one. Written the obvious way this check passes on the machine that has
   been running tracks for weeks and fails on every clone and in CI. Measured both ways
   2026-11-02; the bare form is kept as a fallback so a state dir ignored by a non-directory
   rule is still recognised.

## 1. Sync

```bash
while IFS= read -r r; do
  [ -n "$r" ] || continue
  _pfx=$(git -C "$r" rev-parse --show-prefix 2>/dev/null) && [ -z "$_pfx" ] \
    || { echo "NOT A REPO ROOT: $r — run that rev-parse by hand to see why"; continue; }
  if [ -z "$(git -C "$r" remote)" ]; then
    _sync="NO REMOTE — nothing was fetched"
  elif ! git -C "$r" fetch --all --prune -q; then      # git's own reason prints above the table
    _sync="FETCH FAILED — treat what follows as stale"
  else
    _sync=""
  fi
  _br=$(git -C "$r" branch --show-current)
  if _ba=$(git -C "$r" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null); then
    _up="behind/ahead $(printf '%s' "$_ba" | tr '\t' '/')"
  elif [ -n "$(git -C "$r" config "branch.$_br.merge")" ]; then
    _up="upstream [gone] — configured, but its remote-tracking ref is missing"
  else
    _up="no upstream for this branch"
  fi
  printf '%-26s %-18s %s%s · %s changed\n' "$r" "${_br:-DETACHED}" "${_sync:+$_sync · }" "$_up" \
    "$(git -C "$r" status --porcelain | wc -l | tr -d ' ')"
done <<'REPOS'
<repo paths, one per line>
REPOS
```

Read line by line, never `for r in <repos>`: a workspace path containing a space word-splits
under bash, every `git -C` fails on a fragment, and this block still prints a row per fragment
and exits 0 — so a dirty repo reports `0 changed`. The same rule and the same reason as the
orphan sweep below, which carries the same two lines and prints the same refusal. The `rev-parse`
line is the second half of the same fix: it turns every wrong *fill* — a stray space, a tab, a
CRLF, a glob character, an unexpanded `~`, every path on one line, a path that is a
*subdirectory* of a repo rather than its root, or the placeholder left in verbatim — into a named
`NOT A REPO ROOT` line instead of another reassuring `0 changed`. **That line is not a result**:
fix the fill and run it again before reporting anything. It is loud but **not fatal** — a fill
where every path is wrong still exits 0, so read the output, not the status. The delimiter is
quoted (`<<'REPOS'`) so a path containing `$` or a backtick is not rewritten on the way in.

The sync state is a new column, and it is named rather than assumed. The old form ran
`git fetch --all --prune -q` and printed path, branch and `N changed` — it made no claim about
freshness, which was the problem: `fetch` **exits 0 in a repo with no remote**, establishing
nothing, and the instruction below it to "report any repo that is dirty, behind, diverged,
`[gone]`" had nothing behind the last three. Now: `NO REMOTE — nothing was fetched` when there is no remote at
all, `FETCH FAILED — treat what follows as stale` when the fetch itself failed, `no upstream
for this branch` when the branch was never pushed, `upstream [gone]` when the config names one but
its remote-tracking ref is missing — which is what `fetch --prune` leaves behind after someone
deletes the branch on the remote, and the state the paragraph below asks you to report — and
`behind/ahead N/M` when the upstream resolved. The remote state and the upstream state are
**separate facts** and both are printed: a branch tracking a purely local branch in a repo with no
remote reads `NO REMOTE — nothing was fetched · behind/ahead 0/0`, which is exactly true. **A repo with no remote is not an error** — a stranger's first project is exactly that, and
the pack's rule is degrade, never fail. It is a fact the row has to carry.

Report any repo that is dirty, behind, diverged, `[gone]`, or not on its integration branch.
**Do not discard anything** — report and ask. Pull the docs repo if the tracker lives there.

## 2. Is something already yours — and is anything stale?

Check in this order, because the answer changes what you ask:

```bash
cat <state_dir>/tracks/current 2>/dev/null          # this session's track
ls <state_dir>/tracks/ 2>/dev/null                  # every track on this machine
```

- **`current` is set** → say which track, its stage from the last journal entry, and its "next"
  line. Ask: continue it, or switch? Continuing → re-read the journal and stop here.
- **Other tracks exist** → list them with their last stage, so you can see what you have open.
- **`current` names a directory that does not exist** → ask which track, and offer to clear the
  file. One line.
- **The tracker shows work claimed by you that has no local track** → you claimed it on the
  other machine. Say so, and offer to recreate the track from the journal mirror.

### The stale sweep

Nothing else in the loop ever looks at a track directory it did not create, so stale state
accumulates silently until a `worktree add` fails at step 6 — a few lines below this one. This is
the only sweep, and it runs here because step 3's board fetch gives it everything it needs for
free.

Gather the facts per directory under `<state_dir>/tracks/`, then print the table **with the board
in step 3**, before the claim:

| Looks at | How |
|---|---|
| is the task still open? | its id **absent** from the adapter's open + claimed + blocked ids |
| what stage it reached | the last journal entry heading in `journal.md` |
| does a worktree exist | `git -C <repo> worktree list --porcelain`, per repo, matched as in *Retiring a track* |
| does that worktree hold work | `status --porcelain` non-empty, **or** the separate upstream check *Retiring a track* uses: no upstream at all counts as holding work, and only where one exists does `rev-list --count '@{u}..HEAD'` decide. Never `log --oneline @{u}..HEAD` — with no upstream that exits 128, an agent reading failure as "empty" concludes the worktree holds nothing, and the track is then offered for removal |
| age | mtime of the newest file in the track directory |

Match the worktree path **one whole segment at a time**, as *Retiring a track* in
[../ws-shared/tracks.md](../ws-shared/tracks.md) does — never with a `grep` on the id. A bare
`grep` treats the dot in `p3.1` as a wildcard and matches a `p3.10` worktree; `grep -F "/<id>/"`
fixes that and then misses the single-repo layout, where the path ends at the id. Both are wrong
answers with no error.

**How strong "absent from the list" is depends on the tracker, and you must say which you have.**
On `roadmap-files` and `tasks-file` the list greps the status markers explicitly, so absence does
mean closed — done, dropped, or never real. On `github-projects` and `trello` the list is
**status-filtered** (github-projects defaults to the project's to-do equivalent), so an item
merely moved to another status is absent too. There, absence is a weaker signal and the question
says so: "no longer in the board's list — closed, or moved?" rather than "closed".

**Orphan worktrees need a second pass, in the other direction.** The loop above walks the track
directories, so a worktree whose directory is already gone is never enumerated by it — and that
is precisely the residue of a folder deleted by hand, and the thing that breaks the next
`worktree add`. List the worktrees per repo, take the id segment of each, and subtract the set of
track directories:

```bash
# every worktree id under the project's track root, per repo
while IFS= read -r r; do
  [ -n "$r" ] || continue
  _pfx=$(git -C "$r" rev-parse --show-prefix 2>/dev/null) && [ -z "$_pfx" ] \
    || { echo "NOT A REPO ROOT: $r — run that rev-parse by hand to see why"; continue; }
  git -C "$r" worktree list --porcelain | sed -n 's|^worktree ||p' \
    | awk -F/ -v root="<project>-tracks" '
        { for (i = 1; i < NF; i++) if ($i == root) { print $(i+1); next }
          if ($NF == root) next }'
done <<'REPOS'
<repo paths, one per line>
REPOS
# then: any id printed here with no <state_dir>/tracks/<id>/ is an orphan worktree
```

Repo paths are read line by line, never `for r in $repos`: a workspace path with a space in it
word-splits under `for` in bash, every `git -C` fails on a fragment, and the sweep then reports
**nothing stale** while the stale state is still there. Report each orphan on one line, with the
same asking rules as the table.

### What it prints, and how it asks

One table, **only when there is something in it**. Silent otherwise: a sweep that prints "nothing
stale" on every `ws-start` is a sweep people stop reading.

The `Tracker` column says only what **this** adapter can actually tell you, and the question is
worded to match. With a marker-based adapter (`roadmap-files`, `tasks-file`) absence is exact:

```markdown
### Stale track state  ·  tracker: roadmap-files (status read directly)

| Track | Tracker | Stage | Worktree | Holds work | Age |
|---|---|---|---|---|---|
| p3.2 | done | shipped | ../<project>-tracks/p3.2 | no | 6d |
| p4.1 | dropped | planned | — | — | 11d |
| p5.4 | claimed | step 3 | ../<project>-tracks/p5.4 | **2 uncommitted** | 2d |

p3.2 and p4.1 are closed. Retire both? (removes the track directory and the worktree; branches,
commits and PRs are untouched)
p5.4 is still claimed and holds uncommitted work — left alone. `ws-wrap` pushes it and notes it.
```

With a status-filtered adapter (`github-projects`, `trello`) the same two rows can say no more
than "absent", and the question must not launder that into "closed":

```markdown
### Stale track state  ·  tracker: github-projects (list is status-filtered — absence is not proof)

| Track | Tracker | Stage | Worktree | Holds work | Age |
|---|---|---|---|---|---|
| p3.2 | not in the board's list | shipped | ../<project>-tracks/p3.2 | no | 6d |
| p4.1 | not in the board's list | planned | — | — | 11d |

p3.2 and p4.1 are no longer in the board's list — closed, or moved to another status? If they are
finished, retire both (track directory and worktree only).
```

- **It reports and asks. It never removes anything on its own**, not even for a task the tracker
  shows as done. Retiring is **Retiring a track** in
  [../ws-shared/tracks.md](../ws-shared/tracks.md), run only after a yes, **per track and with
  that track's id** — never once over a list, because the id guards the `rm -rf`.
- **One question for the clearly-finished set** — closed task, no uncommitted and no unpushed
  work — answerable in one word. Five separate prompts is how a sweep becomes an obstacle.
- **A per-track question for anything that holds work** — and that question is never "remove
  it?". A track holding uncommitted or unpushed work is reported and offered `ws-wrap`, which
  pushes it and writes the note; offering removal is an invitation to lose it.
- **A still-claimed track is never offered**, whatever its age. It is your open work.
- **Declining is remembered for this session only.** No new state file; a second `ws-start` in
  the same session does not re-ask.

## 3. Show the board

Via the adapter: in progress first (and by whom), then blocked, then pickable now. Recommend one
and say why in a line. **The user picks.** Flag anything that touches the same files as someone
else's in-progress task.

The adapter's lists are also what step 2's sweep needs, so print its table here, under the board
and before the claim — once, and only if it has rows.

## 4. Claim it

Only once the user has chosen. Follow the adapter exactly, including its retry rule — for a
pushed claim that is **rejected → pull --rebase → re-check it is still open → retry or pick
another**. Never take a task someone else holds. For a handover, only on the user's word that
the other person agreed.

## 5. Create the track

```bash
id=<track-id>                       # the tracker's own id, lowercased, fs-safe
mkdir -p <state_dir>/tracks/"$id"/verify
printf '%s\n' "$id" > <state_dir>/tracks/current
```

Write `task.md`. `<device-alias>` is the derived alias from
[../ws-shared/tracks.md](../ws-shared/tracks.md) — `task.md` is not mirrored, but its only
protection is the ignore rule asserted above, and that is not a reason to write a name into it:

```markdown
# <id> — <title>
- Tracker: <kind> · <url or path>
- Claimed: <date> by <handle> on <device-alias>
- Repos: <which this touches>
- Branches: none yet
- Worktrees: none yet
- Plan: none yet
- PRs: none

## Task, verbatim from the tracker
<the whole thing: description, acceptance criteria, dependencies, links>
```

Then the first journal entry (`claimed`), per `../ws-shared/tracks.md`. If the project has a
`docs_home`, mirror the journal and push it — one commit.

**Taking over a wrapped task**: keep the previous journal entries, add a new `claimed` entry
saying you took it over, and check out the branch the note names.

## 6. Worktree, if the project opted in

Only when `worktrees: true`. Create one **per repo the task actually touches**, not all of them
— the cost is a dependency install per worktree:

```bash
git -C <repo> worktree add "../<project>-tracks/$id/<repo>" -b <branch-pattern-filled-in>
```

**Write every path you create into `task.md`'s `- Worktrees:` line**, repo by repo:

```markdown
- Worktrees: <repo> → ../<project>-tracks/<id>/<repo>, <repo> → ../<project>-tracks/<id>/<repo>
```

That line is what later retires the track without guessing. It is one line now and a git sweep
later: *Retiring a track* in [../ws-shared/tracks.md](../ws-shared/tracks.md) falls back to
`git worktree list --porcelain` when it is missing, which is slower and only works while the repo
list is still known.

Then materialise env into it — a fresh worktree has **no** gitignored files, so nothing runs
until you do:

```
ws-env pull        # writes the env files the cartridge's manifest maps into this tree
```

Say plainly that dependencies need installing in the new worktree, and that every later command
runs against `<worktree>/<repo>`, not the main checkout.

## 7. Summarise, then stop

Three to five bullets: what the task asks for, which repos it touches, which spec or source
applies, and anything unclear or blocked. **Do not plan. Do not write code.**

## Rules

- Never code on an unclaimed task.
- Never claim without the adapter's re-check-after-rejection step.
- Never set `current` for a track you did not just claim or resume.
- Never discard uncommitted work to make a clean start — ask.
- **A stale track is reported and offered, never removed unasked** — and a track holding
  uncommitted or unpushed work is never offered at all.
- One track is current per session; several tracks may exist at once.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-plan` — plan it before writing code
- `ws-setup` — the project has no cartridge yet, in adopt mode
- `ws-fanout` — run two to five tracks at once instead of one
- `ws-debug` — it is a bug with an unknown cause
- `ws-task` — it is too big, unclear, or something is missing from the tracker
- `ws-wrap` — stopping again already
