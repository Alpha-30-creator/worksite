# 0006 — Retirement refuses what its own removal would lose, not what is missing from a remote

**Date:** 2026-11-03
**Status:** accepted
**Supersedes:** the stated *reason* for the retirement guard in *Retiring a track*, and the two
entries in [`records/known-limitations.md`](../records/known-limitations.md) that called the
remoteless refusal correct. It does **not** overturn [ADR 0001](0001-library-is-the-source-of-truth.md)–[ADR 0005](0005-the-graph-audit-is-a-script-in-the-library.md).
**Task:** p8.40, which asked for a decision on how a local-only project retires a track.

## Context

*Retiring a track* refuses to remove a worktree that holds commits the rest of the world has not
seen. The test has been rewritten twice:

1. **Is an upstream configured?** Refused every branch `worktree add -b` created and never
   committed to — a branch carrying nothing — and so stranded every library-only track. Replaced
   by p8.32.
2. **Are there commits reachable from `HEAD` and from no remote-tracking ref?** Correct for the
   cases that motivated it, and the test shipped today.

Both ask about a **remote**, and the sentence under both — *"those commits exist nowhere else"* —
is the justification. Three records, this task's own `Why` included, repeat that the refusal is
correct and must not be weakened. p8.32 then found and documented the one way a remoteless
project can satisfy it: push to a `--bare` repo on the same disk.

That is all true, and it is answering the wrong question.

## What was measured

`git worktree remove` removes a **checkout**. It does not remove a branch. Measured in a
remoteless fixture: after removing a worktree whose branch held an unpushed commit,
`refs/heads/<branch>` still points at that commit and `for-each-ref --contains` names it. The
commits were never at risk from the removal.

The shape where removal **does** lose commits is a **detached HEAD** that committed: nothing
references the result, `rev-list --all` cannot reach it, and the worktree's own reflog goes with
the directory. Five shapes, two tests — `old` is the shipped remote-based count, `new` is
`rev-list --count HEAD --not --branches --tags --remotes`:

| worktree shape | old | new | what removal actually does |
|---|---|---|---|
| fresh branch, no commits of its own | 1 → **REFUSE** | 0 → allow | loses nothing |
| branch + 1 commit, never pushed | 2 → **REFUSE** | 0 → allow | branch survives; loses nothing |
| detached HEAD + 1 commit | 2 → REFUSE | 1 → **REFUSE** | commit becomes unreachable from every ref |
| detached HEAD, nothing of its own | 1 → **REFUSE** | 0 → allow | loses nothing |
| branch + 1 commit, after a push to a local bare mirror | 0 → allow | 0 → allow | the two agree |

In a repo with no remote the old test refuses **all four** unpushed shapes, three of which have
nothing to lose, and it refuses the fresh worktree before any work exists. Its count also
overstates on its own terms: the `2` in row two includes `main`'s own commit, shared with the
main checkout.

## Decision

**One test became four refusals and a note, and the refusals ask about the removal rather than
about a remote.**

- **Would this removal make a commit unreachable?**
  `rev-list --count HEAD --not --branches --tags --remotes`, keeping p8.32's unborn-`HEAD` and
  non-numeric guards. It consults no remote, so a local-only project is never blocked by it.
- **Did this worktree make a commit and then step off it?** The question above reads only what the
  worktree is *standing on*, so an experiment committed and then abandoned
  (`switch --detach`, `reset --hard`) is reachable from no ref **and** absent from that count. Its
  last remaining name is the worktree's own per-worktree reflog, deleted with the directory. The
  block walks `rev-list -g HEAD` and asks `for-each-ref --contains` per entry — and **reports what
  it finds as a note, never as a refusal.** That is the one place this decision deliberately
  accepts a possible loss, and the reason is measurable: a reflog is full of commits no ref
  contains **by design**. Every `commit --amend`, every `pull --rebase` — which this pack's own
  tracker adapters instruct — and every `reset --hard` that drops a mistake leaves the superseded
  commit there. As a refusal it fired on the ordinary path on every project, remote or not, and
  since `ws-ship` holds the tracker transition on the verification line, the track could not ship
  at all; the only remedy on offer was to create a branch naming a commit the author had
  deliberately replaced. An abandoned experiment and an amended-away commit are indistinguishable
  from inside this block, so the agent is told and the human decides at the yes. Both the refusal
  version and this one were found by review, not by the measurement that produced the decision.
- **Is an operation in progress?** A rebase, cherry-pick, merge, revert or bisect stopped half-way
  leaves `status --porcelain` empty and every commit count at zero, and `worktree remove` discards
  it. Asked separately, via `rev-parse --git-path`, because no commit count can be made to see it.
- **Uncommitted changes**, unchanged.
- **The off-machine question becomes a note, printed and never blocking.** "These commits are on
  no remote" is a **backup** fact, not a retirement one: the commits survive the removal either
  way. With no remote at all the note says that in one line.

So a local-only project retires a track the same way every other project does, and the guard
keeps its meaning — it is the same meaning, asked of the operation actually being performed.

## Why not the alternatives

- **Document the local bare mirror as the answer** (p8.32's finding, and the obvious reading of
  this task). Rejected as the *primary* answer: it asks every local-only project to create and
  maintain a second repository to satisfy a test whose premise does not hold. It stays in the
  records as the answer to the **backup** question, which is a real one.
- **`git bundle`.** Same objection, with more moving parts.
- **An explicit acknowledgement — "yes, I accept losing this".** Rejected: it would be asked in
  all four unpushed shapes, three of which lose nothing, so it would train an agent to click
  through the one case that matters.
- **A stated refusal with a reason — "a local-only project cannot retire a track".** Rejected
  once the measurement was in: nothing is lost, so there is nothing to refuse.
- **Keeping the remote test as a second refusal.** Rejected: it would reinstate the block for
  exactly the projects this task is about. Where a track *does* ship through `ws-ship`, step 2
  pushes and step 3 merges, so by retirement the branch is pushed anyway. The honest caveat is the
  other two callers: `ws-task`'s drop path and `ws-start`'s stale sweep retire tracks that never
  went through `ws-ship` and so were never pushed — which is exactly when the note matters, and
  why it prints rather than being derived from a skill's happy path.

## What the first cut got wrong

The decision above is the reviewed version. The first cut replaced the remote test with the
`HEAD`-based count alone, and review measured **three sequences that passed it and lost
something**, each of which the remote-based test had refused in a remoteless repo:

| sequence | old (remoteless) | first cut | what was lost |
|---|---|---|---|
| detached, commit, then step back onto a branch | refuse | **allow** | the commit, unreachable and named in no reflog afterwards |
| worktree parked mid-`rebase -i` | refuse | **allow** | `rebase-merge/`, the todo list, `refs/rewritten` |
| ignored files in the worktree (`.env`, `dist/`) | refuse | **allow** | the files, which `worktree remove` takes |

The pattern is worth naming, because it is the real lesson of this task: **the old test was
fail-closed for reasons that had nothing to do with its subject.** In a remoteless project it
refused *everything*, so it incidentally protected against rebases, stepped-off commits and
ignored files — none of which it knew about. Replacing a blanket refusal with a precise one removes
the accidental coverage along with the wrong justification, and the only way to see that is to
enumerate what the blanket was catching. A narrower test is not automatically a better one; it is
better only once what it stopped catching is accounted for.

One of the three became a refusal of its own: the in-progress operation. The other two are notes,
and the second review round is why. Removal lists the ignored files it will delete, so the yes in
step 3 is informed — a built `dist/` going with the worktree is documented behaviour and an `.env`
is recoverable with `ws-env pull`. And the stepped-off commit is a note rather than the refusal the
first fix made it, because that refusal could not be satisfied on the ordinary path (above).

**The second round's lesson is the first round's, one layer in.** Round one found that a narrower
test loses the blanket's accidental coverage. Round two found that *restoring* the coverage with a
refusal costs more than the loss it prevents, because the signal it keys on — a commit no ref
contains — is produced constantly by the workflow this pack prescribes. Both rounds are the same
question asked about a different thing: what else does this test catch, and what else does it
block?

## Consequences

- A worktree with unpushed commits on a branch now retires. That is a **deliberate relaxation**,
  and what it costs is this: a machine that dies with a branch never pushed loses that branch.
  Retirement never protected against that anyway — the branch and its commits stay in the
  repository after the worktree is gone — but it is no longer refused on the way past.
- **Two sequences lose a commit where the old test refused, and they print `clean`.** Both were
  measured by the second review round, and both are a consequence of the reflog sweep being a note:
  a stepped-off commit whose reflog entries have **expired** (`gc` expires unreachable entries at
  30 days by default, which is inside the staleness band `ws-start`'s sweep is aimed at), and a
  commit named only by a `refs/worktree/*` ref under the same condition. With the reflog gone there
  is nothing left for any check here to read. This is the price of the paragraph above, stated where
  the cost belongs rather than only under *What this does not claim*.
- **The three refusals are one list, in one place**, because four callers run this block and a
  caller that tests a subset offers a track the block then refuses — which is p8.40's own loop,
  reached from `ws-start`'s sweep on any project. The second round found exactly that: `ws-start`
  was still testing two of the three.
- `ws-start`'s sweep stops reporting such a track as holding work, which is what p8.40's second
  criterion asks for: a remoteless track stops being re-offered because it becomes retirable.
- A detached-HEAD worktree is now refused for a reason an agent can act on.
- `ws-wrap`'s push still cannot work without a remote. It now says so instead of emitting a raw
  git fatal, because the sweep names it as the exit for a track that holds work.

## What this does not claim

- **Not that the remote is unimportant.** It is the only thing that puts work on another machine,
  and the note says when it has not.
- **Not that `status --porcelain` plus these checks see everything.** A stash was measured to
  survive (`refs/stash` is shared across worktrees, so the main checkout still lists it). Mid-rebase
  state *is* now refused, closing the gap p8.32 recorded. What remains, beyond the two losses under
  *Consequences*: the reflog sweep **over**-reports as well, because `for-each-ref` asked of the
  repository does not list any worktree's `HEAD`, so a commit another worktree is standing on is
  named here although it survives — which a note can afford and a refusal could not. Recorded in
  [`records/known-limitations.md`](../records/known-limitations.md).
- **Not that the fenced block is executed by `verify`.** It is not, on any platform. The five
  shapes above were exercised by extracting the block from the shipped document and running it.
