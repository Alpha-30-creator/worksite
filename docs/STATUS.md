# worksite status

**Updated:** 2026-11-01

**Where it is:** pre-release and public at
[github.com/Alpha-30-creator/worksite](https://github.com/Alpha-30-creator/worksite). The pack
itself has not been moved in, so there is nothing installable yet.

**Decided:** [ADR 0001](decisions/0001-library-is-the-source-of-truth.md) — the agent-sync
library stays the working copy, this repo is a published artifact, and publishing is a step
inside `ws-refine` rather than something anyone remembers to do.

## In progress

| id | title | who | since | note |
|---|---|---|---|---|
| p8.1 | Make every skill model-invocable | @Alpha-30-creator | 2026-11-01 | 13 workflow skills invocable and deployed, no drift; `ws-env` gate, trigger narrowing and the `ws-refine` rules done. **Description tuning is all that remains** |

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
| p1.2 | Prove the leak guard refuses a private name | now pickable; nothing else is safe until this is proven |
| p2.2 | Translate the fourteen skills into the pack | the largest single piece of work |

## Shipped

| id | title | date |
|---|---|---|
| p1.1 | Create the public repo and push the scaffold | 2026-11-01 |
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
