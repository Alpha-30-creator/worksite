# worksite status

**Updated:** 2026-11-02

**Where it is:** the pack is in the repo and generic — the thirteen `ws-*` workflow skills plus
the `ws-shared` reference pack, no private names. Public at
[github.com/Alpha-30-creator/worksite](https://github.com/Alpha-30-creator/worksite).
**Publishing works**: `ws-refine` ends by running [scripts/publish.sh](../scripts/publish.sh),
which copies the skills out of the library behind the leak guard, and the pack reached this repo
through that mechanism for the first time on 2026-11-01. The cartridge schema
([integration/cartridge-schema.md](integration/cartridge-schema.md)) and the concepts page
([product/overview.md](product/overview.md)) are written.

**Still not installable, and no stranger has run it.** There is no `INSTALL.md` (p4.2), so there
is nothing to point an agent at. **CI exists** since p4.3: `.github/workflows/check.yml` runs
`bash scripts/check.sh` on every pull request and on pushes to `main`, so the pre-commit hook is no
longer the only thing between a private name and a public commit — a contributor who never ran
`git config core.hooksPath .githooks` is caught at the PR. Both read the same
`scripts/leak-patterns.txt`, so the pattern list is still the limit of what either can catch, and
a check that runs is not a check that blocks: requiring it before a merge is branch protection,
which is p1.2. `CONTRIBUTING.md`, `SECURITY.md` and `CODE_OF_CONDUCT.md` are written and linked
from the README; `INSTALL.md` stays unlinked prose until p4.2, because `check.sh` §3 fails on a
missing target.

**Decided:** [ADR 0001](decisions/0001-library-is-the-source-of-truth.md) — the agent-sync
library stays the working copy, this repo is a published artifact, and publishing is a step
inside `ws-refine` rather than something anyone remembers to do.
[ADR 0002](decisions/0002-publishing-is-a-guarded-copy-from-the-library.md) — that publish is a
guarded plain copy, and its commits land directly on `main`, with the reasoning and the residual
risk recorded.

## In progress

A two-track fanout batch, claimed 2026-11-02.

| id | title | holder | where it is |
|---|---|---|---|
| p8.5 | `ws-fanout` cannot isolate work outside the project's repos | @Alpha-30-creator | PR open: [#9](https://github.com/Alpha-30-creator/worksite/pull/9); library saved and deployed |

**Two tracks, not more, and the reason is p8.5 itself.** Every other open task on this board
edits the agent-sync library, `agent-sync save` is a single global deploy-and-push, and worktrees
isolate checkouts rather than the library — so at most one library track may run per batch until
p8.5 lands. p3.4 was dropped from the batch because it owns `README.md`, which p4.3 owns; p1.2 was
dropped because two of its criteria are p4.3's deliverables. Both run straight after.

The previous four-track batch is closed: p4.1, p3.3, p3.5 and p8.17 all shipped, each harvested,
each track retired and verified. **P3 is complete** apart from p3.4.

## Blocked

Nothing. p2.1 was unblocked by ADR 0001.

## Next up

Highest value first. **P8 is independent of publishing** — those tasks improve every project
today, so they do not have to wait for P1–P7.

| id | title | why now |
|---|---|---|
| p8.3 | Close the `ws-setup` profile gap | found by using the pack on itself |
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
| p8.23 | Rule numbers cited everywhere, defined nowhere | `R3` already means two different things in two published files |
| p8.24 | Three gates read silence as a pass | the graph audit has two of them, so every pack change is certified by a check that may not have run |
| p8.25 | Shipping does not refresh the cartridge it invalidates | nine stale statements in the file every agent reads first |
| p8.26 | Three things the guard does not cover | one of them makes three documents wrong at once if it ever breaks |
| p3.4 | The docs tree has no index | three reference pages landed and two are unreachable except from the root README |
| p8.27 | `ws-start` never writes the `- Stores:` line the gate reads | p8.5's own lesson, inherited |
| p8.28 | The schema page's sixteen `ws-setup` citations moved | fifth citation drift in a day |
| p8.29 | `ws-fanout`'s description no longer says what it refuses | flagged twice and deliberately not taken |
| p8.30 | Two skills give opposite instructions about pushing the library | resolved by hand in this batch, written down nowhere |

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
| p3.3 | Write the extension guides | 2026-11-02 |
| p3.5 | Stale pointers and the skill count in the cartridge | 2026-11-02 |
| p4.1 | Write the README | 2026-11-02 |
| p8.17 | `docs_home` doubles in four sites | 2026-11-02 |
| p4.3 | Repo furniture: contributing, security, conduct and CI | 2026-11-02 |

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
