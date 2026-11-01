# Which copy is the real one

There are two copies of the `ws-*` skills. **The private agent-sync library is the working copy;
this repo is a published artifact.** Changes travel one way only: the library is edited — by
`ws-refine`, never by hand — and this repo receives a copy. Nothing is ever edited here and
carried back, and the next publish overwrites anything that was.

| | Library | This repo |
|---|---|---|
| Role | the working copy | a published artifact |
| Edited by | `ws-refine` | nothing — it receives a copy |
| Visibility | private | public |
| How a change arrives | an agent edits it, `agent-sync save` deploys | `ws-refine`'s publish step runs [`scripts/publish.sh`](../../scripts/publish.sh) |

## Pull requests

Not accepted. This repo is a one-way mirror of one person's working setup; a merge here would be
overwritten by the next publish. Fork it if you want it different.

## Where the detail is

- [layout.md](./layout.md) — the direction diagram, and what a publish does step by step
- [ADR 0001](../decisions/0001-library-is-the-source-of-truth.md) — why the library owns the
  skills, and the two alternatives rejected
- [ADR 0002](../decisions/0002-publishing-is-a-guarded-copy-from-the-library.md) — why a publish
  is a guarded copy, and why its commits land on `main` directly

**This page is scheduled for deletion.** Its content now lives in the three pages above; it
remains only until the inbound links in `CONTRIBUTING.md`, `docs/decisions/0002-*.md`,
`docs/engineering/stacks.md`, `docs/engineering/trackers.md` and `docs/roadmap/P2-depersonalise.md`
are repointed by whoever owns those files.
