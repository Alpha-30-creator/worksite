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
## <stage> · <YYYY-MM-DD HH:MM> · <device-alias> · <handle>
- did: <what actually changed — files, decisions, commands that mattered>
- next: <the single next step, concrete enough to act on cold>
- rejected: <what was tried and abandoned, and why — this is the part that saves the most time>
- open: <questions, or none>
```

### `<device-alias>`, and why it is not the device name

**Never write the raw `device:` value into a journal entry.** A machine is commonly named after
the person who owns it, and the journal is **mirrored into the project's docs home and pushed**
(below) — which on an open-source project is a public repo. A reader of the mirror needs to tell
one machine from another; they do not need to know whose it is, or what it is called.

So the header carries a **derived alias**: stable for one machine, different for another, and
naming neither.

```bash
alias_file="<state_dir>/device-alias"      # optional, and normally absent

# Derive, never read a hostname: `hostname` is the very string that tends to carry the owner's
# name, which is the leak this exists to avoid.
sha256_of_stdin() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256
  else sha256sum
  fi
}
device_alias() {
  # An explicit alias wins, and it lives in the state dir, which is never pushed. Keeping a
  # hand-written one non-identifying is the author's job; the derived form below is safe
  # without anybody deciding anything, which is why it is the default.
  if [ -r "$alias_file" ] && [ -s "$alias_file" ]; then
    head -1 "$alias_file"; return
  fi
  dev=$(sed -n 's/^device: *//p' "$HOME/.agent-sync/device.yaml" 2>/dev/null | head -1)
  # No device.yaml, or no device line: say so rather than substituting something identifying.
  # "dev-unknown" is a worse journal entry and a correct one.
  [ -n "$dev" ] || { printf 'dev-unknown\n'; return; }
  printf 'dev-%s\n' "$(printf '%s' "$dev" | sha256_of_stdin | cut -c1-6)"
}

device_alias
```

Six hex digits distinguish the handful of machines one person works on, and a collision costs a
reader an ambiguity rather than anything real. The alias is **not** a secret — it is derived from
a name an attacker could guess — so it is not a privacy mechanism. It is narrower than that and
that is the whole claim: a public mirror stops carrying a name nobody chose to publish.

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

**The mirror is a push into a repo that may be public, and the consequence belongs here rather
than in the memory of whoever set the project up.** Everything the journal format carries travels
with it: that is why the entry header uses a derived alias and not the device name (above). A
project that would rather not push the journal at all gitignores `<docs_home>/journal/` and says
why in the ignore file — the reason enforces itself there, and `ws-ship`'s mirror cleanup already
treats a never-tracked mirror as normal rather than as a failure.

## Running several tracks at once

Tracks make this possible; three things make it **safe**, and all three are in `ws-fanout`:

1. **Isolation.** `worktrees: true` gives each track its own checkout. With `worktrees: false`
   every track shares one working tree and two agents editing it overwrite each other silently.
   A cartridge that cannot be **read at all** is a third case, not `false`: it is a **stop**, because
   a gate that cannot find its input must not silently choose the unsafe answer.
2. **File ownership assigned before any work starts.** Two tracks that touch the same file do not
   run in the same batch — the overlapping one is dropped and run afterwards.
3. **One track per shared store.** A worktree is a checkout of a repo in `repos:`, so it isolates
   nothing that lives outside them — a library a tool owns, a shared fixture store. A project
   declares those places in its cartridge's `shared_stores:`, and of the tracks that touch one,
   exactly one runs per batch; the rest are dropped, and so is a track whose use of a store cannot
   be determined. The second failure there is not a file collision at all: where a store has a
   single global `publish:` command, the first track to run it publishes the second track's
   half-finished edits, which no worktree can prevent.

`tracks/current` is for a **single** session on one track. A lead session running several does not
set it; each subagent is told its track explicitly. The same goes for shipping: a lead names the
track id in the invocation — `/ws-ship p3.2` — because with no `tracks/current` written, the id
in the invocation is `ws-ship`'s only source for it.

Cap: **five in flight**, builders and reviewers counted together.

## The worktree root — one definition, resolved absolutely

`worktrees: true` gives each track its own checkout, and those checkouts need somewhere to live.
That somewhere is the **worktree root**, and it is defined here once because the alternative is a
relative path repeated across skills, where `../` means a different directory depending on who
reads it.

### Where it is

| | |
|---|---|
| **Cartridge key** | `worktree_root:`, optional |
| **Default** | `<workspace root>/../<project>-tracks` — the workspace root's **sibling** |
| **A relative value** | relative to the **workspace root**, never to cwd and never to a repo |
| **An absolute value** | used as given; a leading `~` is expanded |
| **Resolved** | **once per session, to an absolute path**, before any command uses it |

The default is the workspace's sibling rather than a folder inside it because of the
**single-repo** layout, where the workspace root *is* the repo: a root inside the workspace would
put every worktree inside that repo, where the main checkout sees them as untracked directories.
Outside is the only answer that holds for both layouts, so it is the answer for both.

### Resolving it

```bash
# inputs: the project id, and the workspace root as an absolute path.
project="<project id>"
ws="<workspace root>"                 # quoted: a workspace path may contain a space
cfg="<the cartridge's worktree_root: value, or empty>"

[ -n "$project" ] || { echo "REFUSING: no project id"; exit 1; }
[ -d "$ws" ]      || { echo "REFUSING: workspace root is not a directory: '$ws'"; exit 1; }
ws=$(cd -P "$ws" && pwd -P) || { echo "REFUSING: cannot resolve '$ws'"; exit 1; }

# Validate the cartridge value BEFORE anything strips it. Stripping first is what made `/`
# dangerous: it emptied the string, and `dirname ""` is `.`, so the root became the CALLER'S
# WORKING DIRECTORY — the one thing this whole section exists to prevent (measured).
cfg_given="$cfg"
while :; do case "$cfg" in ?*/) cfg="${cfg%/}" ;; *) break ;; esac; done
if [ -n "$cfg_given" ]; then
  case "$cfg" in
    ""|"/"|"~"|"."|"..")
      echo "REFUSING: worktree_root '$cfg_given' names no directory of its own"; exit 1 ;;
  esac
fi

case "$cfg" in
  "")      _pd=$(dirname "$ws")                                          # the default
           case "$_pd" in
             /) echo "REFUSING: the workspace root sits directly under '/'"; exit 1 ;;
           esac
           wt_root="$_pd/$project-tracks" ;;
  "~"/*)   wt_root="$HOME/${cfg#\~/}" ;;                                 # ~ is not expanded
  /*)      wt_root="$cfg" ;;                                             #   inside quotes
  *)       wt_root="$ws/$cfg" ;;                                         # relative to $ws
esac

# One physical directory, one string. -P everywhere: `cd`/`pwd` are logical by default, so a
# symlinked workspace path otherwise resolves to a different root than the real path does — one
# project, two roots, each with half the tracks (measured). An existing root is canonicalised
# WHOLE, because a symlink in its last segment is not covered by canonicalising the parent.
if [ -d "$wt_root" ]; then
  wt_root=$(cd -P "$wt_root" && pwd -P) || { echo "REFUSING: cannot resolve '$wt_root'"; exit 1; }
else
  _p=$(cd -P "$(dirname "$wt_root")" 2>/dev/null && pwd -P) \
    && wt_root="$_p/$(basename "$wt_root")"
fi
case "$wt_root" in
  //*) echo "REFUSING: implausible worktree root: '$wt_root'"; exit 1 ;;
  /*/*) : ;;
  *)   echo "REFUSING: implausible worktree root: '$wt_root'"; exit 1 ;;
esac
echo "worktree root: $wt_root"
```

**Echo it.** Every later command substitutes it, and a root that resolved to the wrong place is
cheap to see and expensive to discover.

Four things in that block are there because the obvious version is wrong:

- **The cartridge value is validated before anything strips it.** Strip first and `worktree_root: /`
  becomes the empty string, after which `dirname ""` is `.` and the root is the **caller's working
  directory** — cwd-dependence introduced by the very line meant to tidy the value. Measured: the
  same cartridge gave `/private/etc/` from `/etc` and the repo path from the repo. `/`, `~`, `~/`,
  `.` and `..` all name no directory of their own and are refused by name.
- **`cd -P` and `pwd -P` everywhere, and an existing root canonicalised whole.** `cd` and `pwd`
  are *logical* by default: they keep the symlink you came through. A workspace path reached by
  symlink then resolves to a different root than the real path does — one project, two roots, each
  with half the tracks (measured, both ways). Canonicalising only the root's *parent* leaves the
  same bug in its last segment, so a root that exists is resolved whole.
- **A workspace root at or directly under `/` is refused.** Not for tidiness: `dirname /Users` is
  `/`, so the default root becomes `//<project>-tracks`, which is the same directory as
  `/<project>-tracks` under a second spelling.
- **The plausibility test rejects a leading `//` as well as a single segment.** A root directly
  under the filesystem root is far more likely to be a resolution that went wrong than a choice.

What that block does **not** promise is one spelling for every input. When the root does not exist
yet only its parent can be canonicalised, so a `worktree_root` carrying a `..` in the middle keeps
it — and a value with leading whitespace keeps that too. Both are absolute and both are honest
about where they point; neither is tidy.

The workspace root itself comes from `device.yaml` where the project is linked there. **Where it is
not** — a single-repo project nobody has linked, which this pack's own repo is — the cartridge is
the source, and `docs/agent/reference.md` saying *the workspace root is the repo* is what the
caller passes. With neither, `ws` is empty, the block refuses, and the `ws-start` sweep says
`SWEEP SKIPPED` rather than inventing ids.

### Before creating the first worktree: is there already a root under the other reading?

`../<project>-tracks` has two readings — the workspace's sibling and a folder inside the
workspace — and **both exist in the wild**, because the pack's own command text read literally
produces one and real projects hold the other. A cartridge that names a third place does not make
the first two go away. So check **every** candidate that is not the one in use, and **report
rather than create a second beside it**:

```bash
for cand in "$(dirname "$ws")/$project-tracks" "$ws/$project-tracks"; do
  [ "$cand" = "$wt_root" ] && continue
  [ -d "$cand" ] || continue
  ids=$(ls -1 "$cand" 2>/dev/null)
  [ -n "$ids" ] || continue
  echo "ANOTHER worktree root for this project already exists, and it is not the one in use:"
  echo "  in use: $wt_root"
  echo "  found:  $cand"
  printf '%s\n' "$ids" | sed 's/^/    holds: /'
  echo "  Adopt it with worktree_root: in the cartridge, or move its tracks. Not both at once."
done
```

Two roots for one project is the state worth preventing: each is half the tracks, the stale sweep
walks one of them, and the other is invisible for as long as nobody opens that folder. The loop is
**not** gated on the root in use being absent, because a project acquires its second root long
after its first track and a check that fires only on an empty workspace would stop looking exactly
when it starts mattering. Note what this check is *not*: it says nothing about the root in use,
which it skips by design — stale tracks sitting in the configured root are `ws-start`'s sweep's
job, not this one's.

## Artifact lifespan — the rule that keeps docs clean

| Class | What | Lifespan |
|---|---|---|
| **Ephemeral** | plan, mockup, journal, verify scratch | deleted at ship, **always** |
| **Harvested** | one distilled entry per task | permanent, in `docs_home` |
| **Permanent** | the cartridge, `risks/`, `rules/` | permanent, edited deliberately |

So `ws-ship` **harvests then deletes**. Nothing ephemeral survives a shipped task. The exception
is `artifacts: in-repo`, where the company wants the plan kept in the repo — there, ship keeps
the plan and deletes only the journal and scratch.

The harvested entry goes to `<docs_home>/worklog/<track-id>.md`. The PR description and
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
2. **Refuse if any worktree holds work**, before removing anything. Uncommitted changes, and
   commits that are on **no remote-tracking ref** — both are refusals, not warnings, because the
   whole point of a worktree holding work is that nobody else knows it is there. It reports what
   it found and removes nothing. Offer `ws-wrap` instead.

   The second test asks the question the guard is actually for. It used to ask a different one —
   *is an upstream configured* — and refused when none was, which reads as cautious and is wrong
   in a common case: a branch `worktree add -b` created and never committed to has no upstream and
   carries nothing, so every library-only track was unretirable by a guard protecting commits that
   did not exist. Counting commits on no remote covers the no-upstream case and the
   pushed-then-committed-again case with one test, and a repo with **no remote at all** still
   refuses every commit, which is correct and is the open question p8.40 holds.
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

   **Then the directory the worktrees sat in.** `git` removes worktrees and leaves `<id>/`; a
   successful removal leaves it empty, so one `rmdir` finishes the job and the residue is never
   created. It is looked for in two independent ways — the real parent of every worktree git
   reported, collected *before* the removal, and `<id>/` under every root the project could be
   using — because each finds what the other misses, and only a directory named for **this**
   track is ever considered. A **non-empty** one is reported with its size and contents and
   **nothing is deleted**: it means an earlier removal did not finish, and `rm -rf` is the one
   unrecoverable act here. Anything still holding a `.git` is not touched at all. The one thing
   it does delete is `.DS_Store` and `Thumbs.db`, which are OS metadata rather than work and
   would otherwise block a retirement, and through it the tracker transition, on 4K of Finder
   bookkeeping.
5. **Verify, in one line.** `clean: track <id> removed`, or `NOT REMOVED:` naming every survivor
   — **including the parent directory**, which the block did not look at before p8.32 and which is
   why `clean` was once printed over 9.6M of orphaned build output. Since `ws-ship` holds the
   tracker transition until this line is clean, residue under `<id>/` now blocks marking the task
   done, which is the intended cost: it is this track's own id, so the residue is this track's.
   Nothing else is printed on success — verification that chatters is verification that gets
   skipped.
6. **`artifacts: in-repo`**: keep `implementation_plans/<id>/plan.md`, retire the journal, the
   verify scratch and the worktree, and say the plan was kept.

### The block

```bash
# ---------- inputs ----------
id=<track-id>                       # the resolved track id. A bare id takes no quotes: it is
                                    # constrained to [a-z0-9-.] by convention and cannot hold a
                                    # space. The two PATHS below must be quoted.
state_dir="<state_dir>"             # a workspace path may contain a space, and an unquoted
docs="<docs repo>"                  # assignment does not merely split: bash reads
                                    # `state_dir=/x/My Projects/.p` as a prefix assignment for
                                    # the command `Projects/.p`, which fails — and a prefix
                                    # assignment does not persist, so state_dir is left EMPTY.
                                    # `rm -rf "$state_dir/tracks/$id"` is then one argument,
                                    # `/tracks/$id`, at the filesystem root: it exits 0, the
                                    # verification below checks that same wrong path, and this
                                    # block prints `clean: track removed` over a track it never
                                    # touched. The error on the assignment line is printed, so
                                    # this one is loud and then falsely reassuring rather than
                                    # silent (p8.39, measured).
                                    # `docs` is only used for the journal mirror.
wt_root="<worktree root>"           # resolved absolutely, per *The worktree root* above. Empty
ws="<workspace root>"              # both quoted: used to name the OTHER readings of the
project="<project id>"              # worktree root in step 4b. Empty is tolerated there.
                                    # only on a project with `worktrees: false`, where there is
                                    # no root and step 4b does nothing.
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
bad=0; wt_parents=""
while IFS= read -r r; do
  [ -n "$r" ] || continue
  if ! wts=$(wts_for "$r"); then
    echo "REFUSE: cannot list worktrees in $r"; bad=1; continue
  fi
  while IFS= read -r wt; do
    [ -n "$wt" ] || continue
    echo "worktree: $r -> $wt"
    wt_parents="$wt_parents
$(dirname "$wt")"
    if ! st=$(git -C "$wt" status --porcelain); then
      echo "REFUSE: cannot read $wt"; bad=1; continue
    fi
    if [ -n "$st" ]; then
      echo "REFUSE: uncommitted work in $wt"; bad=1; continue
    fi
    # Does this worktree hold commits that exist nowhere else? That is the question the guard
    # is for, and it is asked directly: commits reachable from HEAD and from no remote-tracking
    # ref. "No upstream" is not that question — a branch created by `worktree add -b` and never
    # committed to carries nothing, and refusing it strands every library-only track (p8.32).
    up=$(git -C "$wt" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    if ! git -C "$wt" rev-parse --verify -q HEAD >/dev/null; then
      orphan=0                                      # unborn HEAD: no commits at all to lose
    elif ! orphan=$(git -C "$wt" rev-list --count HEAD --not --glob=refs/remotes); then
      echo "REFUSE: cannot count unpushed commits in $wt"; bad=1; continue
    fi
    case "$orphan" in
      ''|*[!0-9]*) echo "REFUSE: unreadable commit count for $wt"; bad=1; continue ;;
    esac
    if [ "$orphan" -gt 0 ]; then
      echo "REFUSE: $orphan commit(s) in $wt are on no remote${up:+ (upstream $up)}"; bad=1; continue
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

# ---------- 4b. the directory that held the worktrees ----------
# git removes worktrees; it does not remove the `<id>/` directory they sat in, and nothing else in
# the pack ever looked at it. A successful `worktree remove` leaves it empty (ignored build output
# goes with the worktree — measured), so the normal case is one rmdir.
#
# The parent is looked for in TWO independent ways, because each misses what the other finds:
#   - the actual parent of every worktree git reported, collected in the loop above BEFORE step 4
#     removed them. Finds a track created under a root nobody configured.
#   - `<id>/` under every root this project could be using — only when there IS a root, since a
#     project with `worktrees: false` has no worktrees and nothing here to clean. Finds residue
#     when git has already forgotten the worktree, which is the state the 9.6M on a real project
#     was in, and the state in which asking git alone returns nothing and the old block said
#     `clean`.
# Only a directory named for THIS track is ever considered, and the only things deleted are empty
# directories and OS metadata.
left_parents=""   # what 4b could not remove. The verification below reads THIS, so the
                  # two answers cannot disagree: a reported LEFT is a NOT REMOVED.
cands=$(
  { printf '%s\n' "$wt_parents"
    if [ -n "$wt_root" ]; then
      printf '%s\n' "$wt_root/$id"
      [ -n "$ws" ] && [ -n "$project" ] && printf '%s\n%s\n' \
        "$(dirname "$ws")/$project-tracks/$id" "$ws/$project-tracks/$id"
    fi
  } | sed '/^[[:space:]]*$/d' | sort -u
)
while IFS= read -r parent; do
  [ -n "$parent" ] || continue
  case "$parent" in */"$id") : ;; *) continue ;; esac
  [ -d "$parent" ] || continue
  # A worktree's gitlink is a `.git` FILE, so -name catches both. Depth 2 is the only place a
  # track's checkouts live (`<id>/.git` single-repo, `<id>/<repo>/.git` multi-repo); a `.git`
  # deeper than that is a vendored dependency inside leftover build output, not a checkout, and
  # must not make the residue permanently unremovable.
  live=$(find "$parent" -maxdepth 2 -name .git 2>/dev/null)
  if [ -n "$live" ]; then
    echo "LEFT: $parent still holds a git checkout — not touched:"
    printf '%s\n' "$live" | sed 's|^|    |'
    left_parents="$left_parents parent:$parent"
    continue
  fi
  # OS metadata is not work, and neither is the empty directory it was the only thing inside.
  # \( \) around the -o: without them -delete binds to the last term only, a find precedence trap.
  junk=$(find "$parent" \( -name .DS_Store -o -name Thumbs.db \) 2>/dev/null)
  [ -n "$junk" ] && find "$parent" \( -name .DS_Store -o -name Thumbs.db \) -delete 2>/dev/null
  find "$parent" -mindepth 1 -depth -type d -empty -delete 2>/dev/null
  if rmdir "$parent" 2>/dev/null; then
    if [ -n "$junk" ]; then
      echo "removed the parent and the OS metadata inside it: $parent"
    else
      echo "removed the parent, which held no files: $parent"
    fi
  else
    echo "LEFT: $parent is not empty ($(du -sh "$parent" 2>/dev/null | cut -f1)) — nothing else deleted:"
    find "$parent" -mindepth 1 -maxdepth 2 2>/dev/null | sed 's|^|    |'
    left_parents="$left_parents parent:$parent"
  fi
done <<CANDS
$cands
CANDS

rm -rf "$state_dir/tracks/$id"                    # safe only because of the guard above
if [ -f "$state_dir/tracks/current" ] && [ "$(cat "$state_dir/tracks/current")" = "$id" ]; then
  rm -f "$state_dir/tracks/current"
fi
git -C "$docs" rm -q "<docs_home>/journal/$id.md" 2>/dev/null   # the mirror, if it is tracked

# ---------- 5. verify ----------
left=""
[ -e "$state_dir/tracks/$id" ] && left="$left tracks/$id"
if [ -f "$state_dir/tracks/current" ] && [ "$(cat "$state_dir/tracks/current")" = "$id" ]; then
  left="$left tracks/current"
fi
left="$left$left_parents"            # every parent step 4b reported, verbatim
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
  at the id (`<wt_root>/p3.1`) with no `/<repo>` after it. The `awk` compares whole
  `/`-separated segments, so it matches `…/p3.1` and `…/p3.1/<repo>`, and neither `p3.10` nor
  `xp3.1`.
- **`rev-list --count HEAD --not --glob=refs/remotes`, not `log @{u}..HEAD 2>/dev/null` and not a
  test for an upstream.** The `2>/dev/null` idiom is the original trap: on a branch with **no**
  upstream it prints `fatal: no upstream configured` to stderr, which the redirect discards, and
  the empty output is then indistinguishable from "clean and pushed" — so the one case where the
  commits exist nowhere else is the one case it waves through. `git worktree remove` does not
  refuse it either. Refusing whenever an upstream is *absent* closes that hole and opens another,
  because the commonest branch with no upstream is one that was never committed to. Counting
  commits that are on no remote-tracking ref asks the real question once. Five states measured:

  | State | Count | Right? |
  |---|---|---|
  | a fresh `worktree add -b` branch, nothing of its own | 0 | yes — retires |
  | one commit that was never pushed | 1 | yes — refuses |
  | a repo with **no remote at all** | every commit on `HEAD` | yes — refuses, and see p8.40 |
  | an **unborn HEAD** | `rev-list` exits 128 and prints no number | handled before the count |
  | pushed, then the remote branch deleted, **no prune since** | 0 | **no — waved through** |

  The unborn case is why `HEAD` is verified first and why a non-numeric count is its own refusal
  rather than something `-gt 0` quietly reads as false. The last row is a genuine fail-open, and
  it costs nothing here: retirement removes no branch and no commit, and after a `fetch --prune`
  the count is right again. Five states measured is not five states proved sufficient.
- **No `| head` anywhere.** A pipe into `head` replaces git's exit status with `head`'s, so a
  failed command reads as a successful empty one.
- **It asks the filesystem about the parent, having asked git about the worktrees.** Those are two
  different questions and the block needs both. The residue this task was filed for is a `<id>/`
  directory whose git metadata is already gone, so `worktree list` truthfully reports nothing, the
  old verification asked only git, and `clean` was printed over 9.6M. `rmdir` is the removal
  because it cannot take anything with it: it refuses a non-empty directory, which is the same
  refusal leftover build output deserves.
- **Mid-rebase and mid-bisect state is a gap none of this sees.** The tree is clean and the commits
  are pushed, so retirement proceeds and `worktree remove` discards an in-progress rebase. Lost
  work, not lost commits — and not something a commit count can be made to catch.
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
