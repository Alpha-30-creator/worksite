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
| How a change arrives | an agent edits it, `agent-sync save` deploys | the publish step in `ws-refine` (task p6.1) |

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
