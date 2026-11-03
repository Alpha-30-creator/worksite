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

**One test became two, and only one of them refuses.**

- **The refusal asks whether this removal would make a commit unreachable**:
  `rev-list --count HEAD --not --branches --tags --remotes`, keeping p8.32's unborn-`HEAD` and
  non-numeric guards. It consults no remote, so a local-only project is never blocked by it, and
  it refuses exactly the shape where the commits have no other ref — with the remedy in the
  message, which is to give them a branch.
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
  exactly the projects this task is about, and `ws-ship` already pushes in step 2 and merges in
  step 3, so by the time retirement runs a shipped branch is pushed. Where it is not, the note
  says so.

## Consequences

- A worktree with unpushed commits on a branch now retires. That is a **deliberate relaxation**,
  and the one case where it costs something is a machine that dies with a branch never pushed —
  which retirement never protected against anyway, because the branch and its commits stay in the
  repository after the worktree is gone.
- `ws-start`'s sweep stops reporting such a track as holding work, which is what p8.40's second
  criterion asks for: a remoteless track stops being re-offered because it becomes retirable.
- A detached-HEAD worktree is now refused for a reason an agent can act on.
- `ws-wrap`'s push still cannot work without a remote. It now says so instead of emitting a raw
  git fatal, because the sweep names it as the exit for a track that holds work.

## What this does not claim

- **Not that the remote is unimportant.** It is the only thing that puts work on another machine,
  and the note says when it has not.
- **Not that `status --porcelain` plus this count sees everything.** A stash was measured to
  survive (`refs/stash` is shared across worktrees), but mid-rebase and mid-bisect state is still
  invisible to every check retirement makes — recorded, unchanged, in
  [`records/known-limitations.md`](../records/known-limitations.md).
- **Not that the fenced block is executed by `verify`.** It is not, on any platform. The five
  shapes above were exercised by extracting the block from the shipped document and running it.
