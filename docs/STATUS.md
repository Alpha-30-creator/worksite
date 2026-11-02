# worksite status

**Updated:** 2026-11-02

**Where it is:** the pack is in the repo and generic — thirteen `ws-*` workflow skills plus the
`ws-shared` reference pack they all read, no private names. Public at
[github.com/Alpha-30-creator/worksite](https://github.com/Alpha-30-creator/worksite).
**Publishing works**: `ws-refine` ends by running `scripts/publish.sh`, which copies the skills
out of the private library behind the leak guard, and the pack has reached this repo that way
since 2026-11-01. The reference documentation exists — the cartridge schema at
`docs/integration/cartridge-schema.md`, the concepts page at `docs/product/overview.md`, the three
extension guides under `docs/engineering/`, two ADRs under `docs/decisions/` — and `check.sh` is
green on every section. **CI runs it** on every pull request and every push to `main`, so a
contributor who never ran `git config core.hooksPath .githooks` is still caught; both the hook and
CI read the same `scripts/leak-patterns.txt`, which is the limit of what either can catch.

**Still not installable, and no stranger has run it.** There is no `INSTALL.md` (p4.2), so there
is nothing to point an agent at, and `docs/` has no index (p3.4). What is known not to be covered
is written down once, in [records/known-limitations.md](records/known-limitations.md), rather than
carried as open tasks.

**Decided:** ADR 0001 (`docs/decisions/0001-library-is-the-source-of-truth.md`) — the agent-sync
library stays the working copy, this repo is a published artifact, and publishing is a step inside
`ws-refine`. ADR 0002
(`docs/decisions/0002-publishing-is-a-guarded-copy-from-the-library.md`) — that publish is a
guarded plain copy, its commits land directly on `main`, with the residual risk recorded.

## In progress

| id | what it is doing | where |
|---|---|---|
| p8.24 | the graph audit's silent-pass gates — built and reviewed twice, not shipped | library: `ws-refine`, `ws-setup`, `ws-shared/review/`, `ws-shared/trackers/` |

p8.24 is held back from this batch's ship. Its second review found a Must — the fix reproduced the
defect it exists to kill, one part over — and closing it surfaced a **third** instance. The library
is ahead of the published `skills/` until it ships, which is why §4 reports three differences.

## Blocked

Nothing.

## The 2026-11-02 triage

**32 open tasks became 12, plus one deliberate thirteenth.** Done on the owner's instruction,
after an independent audit of the board, and implemented rather than re-triaged. **P2, P5 and P6
are closed as phases** — each says so at the top of its file. P8 is renamed from *Pack
improvements* to *Pack defects* and now holds only the defects where something reports success
while doing the wrong thing; its 23 open tasks became eight, three of them merges of several.
Everything else was dropped with its reason on the heading line and **its body kept**, because the
reasoning is what the sessions paid for, or replaced by one of eleven sentences in
[records/known-limitations.md](records/known-limitations.md) — a mechanism named in one clause and
its boundary in the next.

## Next up

Highest value first. **P8 is independent of publishing** — those tasks improve every project
today, so they do not have to wait for P1–P7.

| id | title | why now |
|---|---|---|
| p8.31 | The leak surface has three uncovered edges | the repo is public and permanent, and the one guarantee that holds it rests on a bold reminder |
| p8.13 | `for r in <repos>` survives in three skills | it prints success with the work still there, on a workspace whose path contains a space — this one |
| p8.3 | Close the `ws-setup` profile gap | the first thing `INSTALL.md` will point a stranger's agent at |
| p8.25 | Shipping does not refresh the cartridge rows it invalidates | it defends the first file every agent reads, and this session hit it three times in one day |
| p8.32 | A retired track leaves its parent directory behind | 9.6M of orphaned worktree on a real project, invisible to both sweep passes |
| p8.33 | The cartridge promises five things it does not deliver | an author writes something reasonable and is never told it was ignored |
| p8.30 | One rule for who may push the library | resolved by hand in the last batch, written down nowhere |
| p7.1 | Dry-run the install as a stranger | the install is unproven by anyone who is not the author; needs p4.2 |
| p7.2 | Tag and announce | cut to one criterion — the README's claims verified against the tagged tree, the part that can fail silently |

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
| p8.5 | Shared external stores are declared in the cartridge | 2026-11-02 |
| p4.2 | `INSTALL.md`, written for the agent that will run it | 2026-11-02 |
| p1.2 | Prove the leak guard actually refuses a commit | 2026-11-02 |
| p3.4 | An index for the docs tree | 2026-11-02 |

## Phases

| Phase | Goal | Independent of publishing? |
|---|---|---|
| [P1](roadmap/P1-scaffold.md) | A public repo with guard rails | no |
| [P2](roadmap/P2-depersonalise.md) | The pack in the repo, generic — **closed** | no |
| [P3](roadmap/P3-reference.md) | The docs a stranger needs | no |
| [P4](roadmap/P4-install.md) | README and an agent-readable install — **complete** | no |
| [P5](roadmap/P5-secrets.md) | Credentials sync that starts from nothing — **closed, both tasks dropped** | no |
| [P6](roadmap/P6-updates.md) | Publishing, and how users take updates — **closed** | no |
| [P7](roadmap/P7-release.md) | Proven by a stranger, then tagged | no |
| [P8](roadmap/P8-pack.md) | Pack defects | **yes** |
