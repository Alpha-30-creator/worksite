# 0001 — The agent-sync library is the source of truth; worksite is a published artifact

**Date:** 2026-11-01
**Status:** accepted
**Supersedes:** —

## Context

The fourteen `ws-*` skills live in a private agent-sync library. That is what `ws-refine` edits,
and what deploys to every agent on every machine. Publishing them as a public repo creates a
second copy, and two copies of the same thing need one of them to be authoritative.

Three candidates were considered. The decision turned on four facts about how this project is
actually meant to work, which were not clear when the options were first written down:

- **Outside contributions are not wanted.** The pack encodes one person's way of working, and it
  is meant to stay that way. The repo is for sharing, not co-developing.
- **The editors are agents**, invoked through `ws-refine`, not a human with a text editor.
- **Friction in refinement is the thing to minimise.** Skills get changed often; that loop is
  used far more than the publish path.
- **The install path still has to be correct**, because people will use it.

## Decision

**The library stays the working copy. This repo is a published artifact, and publishing is a
step inside `ws-refine` rather than something anyone has to remember.**

Concretely:

1. `ws-refine` keeps editing `~/.agent-sync/store/skills/` exactly as it does now, and
   `agent-sync save` keeps deploying to every agent. **The daily loop does not change.**
2. `ws-refine` gains a final step: copy the generic `ws-*` skills into this repo, run the leak
   guard, commit and push. Automatic, not optional.
3. This repo accepts no pull requests. The README says so. Anyone who wants it different forks it.
4. The install path is proven by a clean install from the published repo at each release, not
   continuously.

**This works only because the generalisation in P2 is permanent in the library too.** Once each
project's own specifics have moved into that project's `risks/` file, the library and this repo
hold identical content, so publishing is a plain copy. If the library kept private references,
publishing would be a *transformation* applied on every refinement — fragile, and the place
drift would come back. The de-personalisation is therefore not a cost of publishing; it is what
makes publishing trivial, and it improves the library on its own merits.

## Rejected

**The public repo owns the skills, the library installs from it.** Clean single source of truth,
and the natural choice if contributions were wanted. Rejected because its decisive advantage —
contributor PRs landing in the authoritative place — is worth nothing here, while its cost is
real and daily: every skill tweak would become edit, commit, push, re-deploy instead of edit and
save. Paying a daily cost for a benefit that never arrives is the wrong trade.

**The repo owns the skills and the library installs from it like any user's would.** The most
rigorous option: every refinement would exercise the real install path, so install bugs would be
hit by the author before anyone else. Rejected because it charges the heaviest friction to the
most frequent operation. The same assurance is available far more cheaply from a clean install at
release time, which P7 already requires.

## Consequences

- **Drift is prevented by automation, not by architecture.** Editing the library outside
  `ws-refine` reintroduces it. Acceptable, because the system's own rule is already that it edits
  itself only through `ws-refine` — but it is now load-bearing, so `ws-refine` must say it.
- The leak guard has to run on the publish path, not only as a pre-commit hook, since publishing
  is the only way content reaches this repo.
- A one-way mirror will attract the occasional PR anyway. The README should decline them plainly
  and without ceremony.
- `ws-refine`'s "edit the library, never a deployed copy" instruction now needs a third clause
  about this repo, or an agent will reasonably guess wrong.
