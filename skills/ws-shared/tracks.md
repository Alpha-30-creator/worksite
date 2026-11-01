# Tracks and the journal

The state model every loop skill shares. Read this before `ws-start`, `ws-plan`, `ws-verify`,
`ws-ship`, `ws-wrap`, `ws-debug`.

## Why tracks exist

One active task per workspace breaks the moment you run two chats. A **track** is one unit of
work with its own state, so each session knows which one it is on and they cannot collide.

```
<state_dir>/
  me                      your handle, if the project has collaborators
  tracks/
    current               ONE LINE: the track id this session is on
    <track-id>/
      task.md             the task verbatim, plus metadata — repos, branches, worktree paths
      plan.md             the approved plan
      journal.md          append-only (see below)
      mockup.html         UI tasks only
      verify/             evidence and scratch
```

`tracks/current` is **per session, not per machine**. Two chats on one machine each set it when
they start, and every skill reads it rather than assuming. If it is missing or names a track
that does not exist, ask which track — never guess.

**Track id** = the tracker's own id, lowercased and filesystem-safe: `p3.2`, `issue-116`,
`card-6f2a91`, `t-14`. Never invent a parallel numbering scheme.

## Where the files live

Set by `artifacts:` in the cartridge:

| `artifacts` | Files live in | Crosses machines by |
|---|---|---|
| `workspace-state` (default) | `<state_dir>/tracks/<id>/` — uncommittable | the journal mirror, below |
| `in-repo` | `<repo>/implementation_plans/<id>/` — committed on the task branch | the branch itself |

`in-repo` is a company convention on some projects — the plan is wanted in the repo, with the
code. Respect it; do not argue with it.

## The journal — the cross-session fix

The problem it solves: today a plan is written at the start and a resume note at the end, so a
session that compacts or dies **in the middle** loses exactly the part nobody wrote down —
which plan step you reached, what you already tried, what turned out to be wrong.

**Skills append to it at every stage boundary. Not when asked.** That is the whole point: if it
depends on someone remembering, it is not there when it matters.

One entry per boundary, appended, never rewritten:

```markdown
## <stage> · <YYYY-MM-DD HH:MM> · <device> · <handle>
- did: <what actually changed — files, decisions, commands that mattered>
- next: <the single next step, concrete enough to act on cold>
- rejected: <what was tried and abandoned, and why — this is the part that saves the most time>
- open: <questions, or none>
```

Stages: `claimed`, `planned`, `step <n>` (one per completed plan step), `verified`, `reviewed`,
`paused`, `shipped`.

**Resuming cold** = read `task.md`, then `plan.md`, then the last two or three journal entries.
That is the whole recovery path, and every skill that writes a journal entry owes a reader that
property.

### Crossing machines

`workspace-state` files cannot be committed, so the journal is **mirrored** to
`<docs_home>/journal/<track-id>.md` and pushed — **one commit per stage, not per thought**.
`docs_home` is the project's docs folder or docs repo, so the mirror travels with the project.
`ws-ship` deletes it.

`artifacts: in-repo` projects need no mirror — the task branch already carries the files.
`lite` projects with no `docs_home` get a local journal only; say so once when the track is
created, so nobody expects it on the other machine.

## Running several tracks at once

Tracks make this possible; two things make it **safe**, and both are in `ws-fanout`:

1. **Isolation.** `worktrees: true` gives each track its own checkout. With `worktrees: false`
   every track shares one working tree and two agents editing it overwrite each other silently.
2. **File ownership assigned before any work starts.** Two tracks that touch the same file do not
   run in the same batch — the overlapping one is dropped and run afterwards.

`tracks/current` is for a **single** session on one track. A lead session running several does not
set it; each subagent is told its track explicitly. The same goes for shipping: a lead names the
track id in the invocation — `/ws-ship p3.2` — because with no `tracks/current` written, the id
in the invocation is `ws-ship`'s only source for it.

Cap: **five in flight**, builders and reviewers counted together.

## Artifact lifespan — the rule that keeps docs clean

| Class | What | Lifespan |
|---|---|---|
| **Ephemeral** | plan, mockup, journal, verify scratch | deleted at ship, **always** |
| **Harvested** | one distilled entry per task | permanent, in `docs_home` |
| **Permanent** | the cartridge, `risks/`, `rules/` | permanent, edited deliberately |

So `ws-ship` **harvests then deletes**. Nothing ephemeral survives a shipped task. The exception
is `artifacts: in-repo`, where the company wants the plan kept in the repo — there, ship keeps
the plan and deletes only the journal and scratch.

The harvested entry goes to `<docs_home>/agent/worklog/<track-id>.md`. The PR description and
the tracker item are the project's record; the worklog is the part that keeps the **rejected
alternatives**, which a PR never does. Anything that turned out to be a durable fact about the
system belongs in `engineering/` or `decisions/` instead, in the same change.

```markdown
## <track-id> — <title> · <date> · <handle>
**What changed:** <2–4 lines>
**Decisions:** <what was chosen, and what was rejected and why>
**Evidence:** <summary, not raw logs — point at the PR and the checks>
**Risks learned:** <added to risks/ or a stack pack, or none>
**Docs touched:** <files>
**PRs:** <urls>
```

That "decisions, including rejected" line is the thing currently lost every time. It is why the
harvest is mandatory rather than optional.

## Retiring a track

**Retiring** a track means removing its **session state**: the directory under
`<state_dir>/tracks/`, the worktrees it was given, and `tracks/current` if it names that track.
It never touches a branch, a commit, a pushed PR or the tracker item.

Four callers need this, and four copies would drift, so this is the one definition and they point
here: `ws-ship` after the harvest, `ws-task` after a drop, `ws-fanout` on an abandoned batch,
`ws-start`'s stale sweep.

### Read this before you run anything

Three properties of the block below are not stylistic, and losing any of them turns a cleanup
into data loss:

1. **It is ONE block and one shell. Do not split it, and do not run a later part on its own.**
   Each fenced block an agent runs is a fresh shell with none of the previous one's variables, so
   a `rm -rf "$state_dir/tracks/$id"` lifted out of context runs with `$id` **empty** — and
   `rm -rf <state_dir>/tracks/` deletes *every* track on the machine, including claimed ones
   holding uncommitted work. The guard on the first line is what makes the line safe; they travel
   together.
2. **An unresolved id is a stop, never a quiet no-op.** The caller must have an id before it gets
   here. If `$id` is empty the block refuses and removes nothing.
3. **Repo paths are newline-separated and read with `while IFS= read -r`, never `for r in $repos`.**
   A workspace path containing a space (`~/My Projects/app`) word-splits under `for`, every
   `git -C` then fails on a path fragment, and the verification at the end finds no worktrees and
   prints `clean` while the worktrees are still there. A false `clean` is worse than a crash.
   `zsh` does not word-split, so this bug is invisible on a zsh machine and appears on a bash one.

### What it does, step by step

1. **Guard the id**, then resolve the worktrees the track touched. `ws-start` creates one **per
   repo the task touches**, so everything here is per repo. Primary source: `task.md`'s
   `- Repos:` and `- Worktrees:` lines; the block re-derives them from `git worktree list` in
   every case, so an abandoned track whose `task.md` was never updated is recovered from git
   alone.
2. **Refuse if any worktree holds work**, before removing anything. Uncommitted changes, commits
   that are not pushed, **or no upstream at all** — all three are refusals, not warnings, because
   the whole point of a worktree holding work is that nobody else knows it is there. It reports
   what it found and removes nothing. Offer `ws-wrap` instead.
3. **Show what will go, then wait for a yes. Every caller, no exceptions.** This is the house
   rule — *show it, then wait for a yes before any delete* — and retirement is a delete.

   An earlier draft carved out `ws-ship` on the happy path, reasoning that the user had already
   said ship and that one more prompt at the end is where a session dies with the track still on
   disk. That reasoning is real but it points the wrong way: a track left on disk is **visible
   and recoverable**, and the stale sweep in `ws-start` now finds it. Session state deleted
   without an answer is neither. The cheap failure is the one to prefer.

   So the prompt stays, and it is one line: name the worktrees, the track directory and the
   branches that survive, and wait.
4. **Remove**: `worktree remove` per repo — never `rm -rf` a worktree folder — then `worktree
   prune` **per repo** after that repo's removals. "Once" means once per repository: a single
   global prune leaves every other repo's metadata stale, and stale metadata is exactly what makes
   the next `worktree add` fail. Then the track directory, `tracks/current` only if it names this
   track, and the journal mirror if it is tracked.
5. **Verify, in one line.** `clean: track <id> removed`, or `NOT REMOVED:` naming every survivor.
   Nothing else is printed on success — verification that chatters is verification that gets
   skipped.
6. **`artifacts: in-repo`**: keep `implementation_plans/<id>/plan.md`, retire the journal, the
   verify scratch and the worktree, and say the plan was kept.

### The block

```bash
# ---------- inputs ----------
id=<track-id>                       # the resolved track id
state_dir=<state_dir>
docs=<docs repo>                    # only used for the journal mirror
repos=$(cat <<'REPOS'
<repo path>
<another repo path, spaces are fine>
REPOS
)

# ---------- 1. the guard. Without it the rm -rf below is unbounded ----------
[ -n "$id" ] || { echo "REFUSING: no track id resolved. Nothing was touched."; exit 1; }

wts_for() {    # the worktree paths in repo $1 that belong to this track
  git -C "$1" worktree list --porcelain | sed -n 's|^worktree ||p' \
    | awk -F/ -v id="$id" '{for (i = 1; i <= NF; i++) if ($i == id) { print; next }}'
}

# ---------- 1 + 2. what exists, and does any of it hold work ----------
bad=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  if ! wts=$(wts_for "$r"); then
    echo "REFUSE: cannot list worktrees in $r"; bad=1; continue
  fi
  while IFS= read -r wt; do
    [ -n "$wt" ] || continue
    echo "worktree: $r -> $wt"
    if ! st=$(git -C "$wt" status --porcelain); then
      echo "REFUSE: cannot read $wt"; bad=1; continue
    fi
    if [ -n "$st" ]; then
      echo "REFUSE: uncommitted work in $wt"; bad=1; continue
    fi
    up=$(git -C "$wt" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    if [ -z "$up" ]; then
      echo "REFUSE: $wt has no upstream — its commits exist nowhere else"; bad=1; continue
    fi
    if ! ahead=$(git -C "$wt" rev-list --count '@{u}..HEAD'); then
      echo "REFUSE: cannot compare $wt against $up"; bad=1; continue
    fi
    if [ "$ahead" -gt 0 ]; then
      echo "REFUSE: $ahead unpushed commit(s) in $wt"; bad=1; continue
    fi
  done <<WT
$wts
WT
done <<REPOS
$repos
REPOS
[ "$bad" -eq 0 ] || { echo "NOT RETIRED: that work exists nowhere else. Nothing was removed."; exit 1; }

# ---------- 3. show the lines above, and wait for a yes (see step 3) -------
# ---------- 4. remove ----------
while IFS= read -r r; do
  [ -n "$r" ] || continue
  while IFS= read -r wt; do
    [ -n "$wt" ] || continue
    git -C "$r" worktree remove "$wt" || echo "could not remove worktree $wt"
  done <<WT
$(wts_for "$r")
WT
done <<REPOS
$repos
REPOS
while IFS= read -r r; do
  [ -n "$r" ] && git -C "$r" worktree prune       # per repo, after that repo's removals
done <<REPOS
$repos
REPOS

rm -rf "$state_dir/tracks/$id"                    # safe only because of the guard above
if [ -f "$state_dir/tracks/current" ] && [ "$(cat "$state_dir/tracks/current")" = "$id" ]; then
  rm -f "$state_dir/tracks/current"
fi
git -C "$docs" rm -q <docs_home>/journal/"$id".md 2>/dev/null   # the mirror, if it is tracked

# ---------- 5. verify ----------
left=""
[ -e "$state_dir/tracks/$id" ] && left="$left tracks/$id"
if [ -f "$state_dir/tracks/current" ] && [ "$(cat "$state_dir/tracks/current")" = "$id" ]; then
  left="$left tracks/current"
fi
while IFS= read -r r; do
  [ -n "$r" ] || continue
  if ! wts=$(wts_for "$r"); then
    left="$left unreadable:$r"; continue
  fi
  [ -n "$wts" ] && left="$left worktree:$r"
done <<REPOS
$repos
REPOS
[ -n "$left" ] && echo "NOT REMOVED:$left" || echo "clean: track $id removed"
```

### Why each awkward part is that way

- **The `awk`, instead of a `grep` on the id.** Both shortcuts give a wrong answer with no error:
  `grep "$id"` treats the dot in `p3.1` as any character and matches a `p3.10` worktree, and
  `grep -F "/$id/"` fixes that but misses the **single-repo layout**, where the worktree path ends
  at the id (`../<project>-tracks/p3.1`) with no `/<repo>` after it. The `awk` compares whole
  `/`-separated segments, so it matches `…/p3.1` and `…/p3.1/<repo>`, and neither `p3.10` nor
  `xp3.1`.
- **A separate upstream check, not `log @{u}..HEAD 2>/dev/null`.** That idiom is the trap this
  section exists to avoid: on a branch with **no** upstream it prints `fatal: no upstream
  configured` to stderr, which `2>/dev/null` discards, and the empty output is then
  indistinguishable from "clean and pushed". So the one case where the commits exist nowhere else
  is the one case the check waves through. `git worktree remove` does not refuse it either.
- **No `| head` anywhere.** A pipe into `head` replaces git's exit status with `head`'s, so a
  failed command reads as a successful empty one.
- **It asks git about worktrees, not the filesystem.** `[ -d <path> ]` is the wrong test: the
  state this guards against is git still *believing* a worktree exists after its folder was
  removed by hand, which is what breaks the next `worktree add`. Only `worktree list` after
  `prune` sees it.
- **The journal mirror is checked softly.** The `git rm` runs with `2>/dev/null` because some
  projects gitignore the mirror, so a missing mirror is normal and is not a failure. Its test is
  absence from `git ls-files` in the docs repo; a never-tracked mirror passes.
- **`NOT REMOVED` does not retry and does not escalate.** It reports, naming each survivor, and
  the skill says what finishing it would take. Retrying a delete in a loop is how a bug becomes
  data loss.
