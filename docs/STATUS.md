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

Nothing claimed.


## Blocked

Nothing. p2.1 was unblocked by ADR 0001.

## Next up

Highest value first. **P8 is independent of publishing** — those tasks improve every project
today, so they do not have to wait for P1–P7.

| id | title | why now |
|---|---|---|
| p8.3 | Close the `ws-setup` profile gap | found by using the pack on itself |
| p8.5 | `ws-fanout` cannot isolate work outside the project's repos | found by invoking `ws-fanout` here; blocks safe parallel work on the pack |
| p8.8 | The journal mirror leaks the device name into a public docs home | caught by the guard refusing a real commit |
| p8.9 | The graph audit cannot see whether a referenced file reached each agent | the audit passed while a pack was missing from one agent |
| p8.10 | Cleanup exists on exactly one path, and nothing ever sweeps | reported from real use: track files and worktrees survive a finished task, especially under fanout |
| p1.2 | Prove the leak guard refuses a private name | now pickable; nothing else is safe until this is proven |
| p3.1 | Write the cartridge schema | the highest-value doc, and it does not exist in any form |
| p1.2 | Prove the leak guard refuses a private name | it has now refused three real commits; worth recording properly |

## Shipped

| id | title | date |
|---|---|---|
| p1.1 | Create the public repo and push the scaffold | 2026-11-01 |
| p2.1 | Apply the source-of-truth decision | 2026-11-01 |
| p2.2 | Translate the fourteen skills, do not strip them | 2026-11-01 |
| p8.1 | Make every skill model-invocable | 2026-11-01 |
| p8.2 | Teach review and planning where documentation belongs | 2026-11-01 |
| p8.6 | worktrees defaulted to false | 2026-11-01 |
| p8.7 | settings.json: the pack is not the cause | 2026-11-01 |

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
