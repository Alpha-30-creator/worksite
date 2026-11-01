# worksite status

**Updated:** 2026-11-01

**Where it is:** the pack is in the repo and generic — 46 files, no private names. Not yet
installable: there is no README or install path (P3, P4). Public at
[github.com/Alpha-30-creator/worksite](https://github.com/Alpha-30-creator/worksite). The pack
itself has not been moved in, so there is nothing installable yet.

**Decided:** [ADR 0001](decisions/0001-library-is-the-source-of-truth.md) — the agent-sync
library stays the working copy, this repo is a published artifact, and publishing is a step
inside `ws-refine` rather than something anyone remembers to do.

## In progress

Nothing claimed. The three-track fanout batch is closed: p3.1, p3.2 and p6.1 all shipped, each
harvested, each track retired and verified. Publishing is now live — `ws-refine` ends by running
`scripts/publish.sh`, and the amended skill reached this repo through that mechanism rather than
by hand.

## Blocked

Nothing. p2.1 was unblocked by ADR 0001.

## Next up

Highest value first. **P8 is independent of publishing** — those tasks improve every project
today, so they do not have to wait for P1–P7.

| id | title | why now |
|---|---|---|
| p8.17 | `docs_home` doubles in four sites | **live**: `ws-fanout`'s isolation gate reads the cartridge at a path that does not exist, finds nothing, and takes the shared-working-tree branch |
| p8.3 | Close the `ws-setup` profile gap | found by using the pack on itself |
| p8.5 | `ws-fanout` cannot isolate work outside the project's repos | found by invoking `ws-fanout` here; blocks safe parallel work on the pack |
| p8.8 | The journal mirror leaks the device name into a public docs home | caught by the guard refusing a real commit |
| p8.9 | The graph audit cannot see whether a referenced file reached each agent | the audit passed while a pack was missing from one agent |
| p1.2 | Prove the leak guard refuses a private name | it has now refused four real commits, and missed two whole classes; worth recording properly |
| p8.13 | `for r in <repos>` survives in three skills, one of which warns against it | reports false success, which is worse than crashing |
| p8.14 | Nothing ever enumerates the track root | 9.6M of orphaned worktree on a real project, invisible to both sweep passes |
| p8.15 | The worktree root has no defined base | two defensible readings of one `../`, and two roots on one project |
| p8.16 | State dir inside a repo rests on one gitignore line | a public repo, a device name in the journal, and nothing asserting the line |
| p8.18 | Two rules in `tracks.md` rest on wrong premises | both found by using the retirement path; one refuses safe work, one exempts a mirror on a false reason |
| p8.19 | The cartridge cannot hold what the pack already asks for | five things read, collected or named with no key to land in |
| p8.20 | Keys that exist but cannot express the ordinary shape | a three-list Trello board, a two-person team; an author invents schema and is never told it was ignored |
| p8.21 | `machine:` has no merge semantics and no reader | the cartridge advertises per-device config and delivers a comment field |
| p8.22 | `lite` and the tracker: two files disagree | costs an agent a wrong decision rather than an error |
| p3.4 | The docs tree has no index | three reference pages landed and two are unreachable except from the root README |
| p3.5 | Stale pointers and the skill count in the cartridge | three one-line fixes in files that were frozen during the batch |

## Shipped

| id | title | date |
|---|---|---|
| p1.1 | Create the public repo and push the scaffold | 2026-11-01 |
| p2.1 | Apply the source-of-truth decision | 2026-11-01 |
| p2.2 | Translate the fourteen skills, do not strip them | 2026-11-01 |
| p8.10 | Cleanup exists on exactly one path, and nothing ever sweeps | 2026-11-01 |
| p8.1 | Make every skill model-invocable | 2026-11-01 |
| p8.2 | Teach review and planning where documentation belongs | 2026-11-01 |
| p8.6 | worktrees defaulted to false | 2026-11-01 |
| p8.7 | settings.json: the pack is not the cause | 2026-11-01 |
| p3.1 | Write the cartridge schema | 2026-11-01 |
| p3.2 | Write the concepts page | 2026-11-01 |
| p6.1 | Build publishing into ws-refine | 2026-11-01 |

## Phases

| Phase | Goal | Independent of publishing? |
|---|---|---|
| [P1](roadmap/P1-scaffold.md) | A public repo with guard rails | no |
| [P2](roadmap/P2-depersonalise.md) | The pack in the repo, generic | no |
| [P3](roadmap/P3-reference.md) | The docs a stranger needs | no |
| [P4](roadmap/P4-install.md) | README and an agent-readable install | no |
| [P5](roadmap/P5-secrets.md) | Credentials sync that starts from nothing | no |
| [P6](roadmap/P6-updates.md) | Publishing, and how users take updates | no |
| [P7](roadmap/P7-release.md) | Proven by a stranger, then tagged | no |
| [P8](roadmap/P8-pack.md) | Pack improvements | **yes** |
