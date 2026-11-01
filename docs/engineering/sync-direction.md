# Which copy is the real one

There are two copies of the `ws-*` skills. This page says which is authoritative and which way
changes travel. Decided in [ADR 0001](../decisions/0001-library-is-the-source-of-truth.md).

## The direction

```
  agent-sync library                 this repo                      your agents
  (private, the working copy)        (public, a published artifact)
  ~/.agent-sync/store/skills/   ──→  skills/                   ──→  Claude, Codex, Cursor
          ▲                                                              ▲
          │ ws-refine edits here                                         │ agent-sync save
          └──────────────────────────────────────────────────────────────┘
```

**One direction only.** The library is edited; this repo receives. Nothing is ever edited here and
carried back.

| | Library | This repo |
|---|---|---|
| Role | the working copy | a published artifact |
| Edited by | `ws-refine` | nothing — it receives a copy |
| Visibility | private | public |
| How a change arrives | an agent edits it, `agent-sync save` deploys | `ws-refine`'s publish step runs [`scripts/publish.sh`](../../scripts/publish.sh) |

## How a publish actually works

`ws-refine` ends by reading `~/.agent-sync/publish.targets` — one absolute workspace path per
line — and running each target's own `scripts/publish.sh`. No such file means no targets, and
nothing to publish. The target's path is never written into a skill: this repo's own location is
one of the private names the guard looks for, so a hardcoded target would be caught by the very
check it runs.

[`scripts/publish.sh`](../../scripts/publish.sh) then:

1. **refuses up front** on a missing library, a library with no `ws-*` skills, a tree that is not
   on `main`, a dirty tree, a `check.sh` that is already failing here, or a skill published here
   that the library no longer has (`--prune` is how a deletion is meant);
2. assembles the candidate — the library's `skills/ws-*`, selected **by glob, never by a list** —
   inside a throwaway `git clone` of this repo, and runs
   [`scripts/check.sh`](../../scripts/check.sh) **there**. So a leak is refused before a single
   byte is written here: no commit, no staged change, no new file;
3. asserts the copy is plain, with `diff -rq` of library against candidate having to be silent —
   the property below, turned into an assertion;
4. writes this tree, commits (the pre-commit hook runs the same guard a second time, on exactly
   the staged bytes) and pushes. Nothing to copy means "nothing to publish" and a clean exit.

Publish commits land on `main` directly rather than through a pull request. That carve-out, and
its residual risk, are recorded in
[ADR 0002](../decisions/0002-publishing-is-a-guarded-copy-from-the-library.md), which also holds
the mechanism's rejected alternatives.

**What a green publish does not mean.** The guard bounds the patterns listed in
`scripts/leak-patterns.txt`. A private name nobody has added to that file passes it — twice over,
since both runs use the same pattern list. Green means "no known pattern", not "no private data".

## Why this way round

The short version: the author edits skills often and publishes rarely, so friction belongs on the
rare path. Outside contributions are not wanted — the pack encodes one person's way of working and
is meant to stay that way — which removes the main argument for the public repo owning the skills.
The full reasoning, including the two rejected alternatives, is in the ADR.

## What makes it safe

**Publishing is a plain copy, never a transformation.** That is the load-bearing property, and it
is only true because the generalisation in task p2.2 is permanent in the library as well. If the
library kept private project names, every publish would have to rewrite them on the way out — a
transformation re-applied on every refinement, which is exactly where drift would return.

So the de-personalisation is not a cost of publishing. It is what makes publishing trivial, and it
improves the library on its own merits.

Two consequences worth stating plainly:

- **Drift is prevented by automation, not by architecture.** Editing the library outside
  `ws-refine` reintroduces it. That was always the system's rule; it is now load-bearing, so
  `ws-refine` says so.
- **The leak guard must run on the publish path**, not only as a pre-commit hook, because
  publishing is the only way content reaches this repo.

## Pull requests

Not accepted. This repo is a one-way mirror of one person's working setup; a merge here would be
overwritten by the next publish. Fork it if you want it different.
