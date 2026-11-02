# worksite status

**Updated:** 2026-11-02

**Where it is:** the pack is in the repo and generic — thirteen `ws-*` workflow skills plus the
`ws-shared` reference pack they all read, no private names. Public at
[github.com/Alpha-30-creator/worksite](https://github.com/Alpha-30-creator/worksite).
**Publishing works**: `ws-refine` ends by running `scripts/publish.sh`, which copies the skills
out of the private library behind the leak guard, and the pack has reached this repo that way
since 2026-11-01. The reference documentation exists — the cartridge schema at
`docs/integration/cartridge-schema.md`, the concepts page at `docs/product/overview.md`, the three
extension guides under `docs/engineering/`, four ADRs under `docs/decisions/` — and `check.sh` is
green on every section. **CI runs it** on every pull request and every push to `main`, so a
contributor who never ran `git config core.hooksPath .githooks` is still caught; both the hook and
CI read the same `scripts/leak-patterns.txt`, which is the limit of what either can catch.

**Installable, and now run by strangers.** [`INSTALL.md`](../INSTALL.md) is the entry point an
agent is pointed at, and [`docs/README.md`](README.md) maps this tree — both shipped 2026-11-02,
p4.2 and p3.4. **Two agents with none of this project's history have now followed it end to end**
(p7.1), which cost 44 guess-points, five fixes and three defects, and the board one net row. What
that does not establish is that the install is *clear* — two agents are not a population, and their
`--store` was forced, which a real first install would not be. What is
known not to be covered is written down once, in
[records/known-limitations.md](records/known-limitations.md), rather than carried as open tasks.

**Decided:** ADR 0001 (`docs/decisions/0001-library-is-the-source-of-truth.md`) — the agent-sync
library stays the working copy, this repo is a published artifact, and publishing is a step inside
`ws-refine`. ADR 0002
(`docs/decisions/0002-publishing-is-a-guarded-copy-from-the-library.md`) — that publish is a
guarded plain copy, its commits land directly on `main`, with the residual risk recorded.
ADR 0003 (`docs/decisions/0003-shared-external-stores-are-declared-in-the-cartridge.md`) — a place
the work reaches that no worktree isolates is declared in the cartridge, so `ws-fanout`'s gate can
reason about it. ADR 0004
(`docs/decisions/0004-a-check-must-state-what-it-read.md`) — a self-checking check may certify only
what it stated it read, which is why the graph audit now names its own counts.

## In progress

| id | title | claimed | where it is |
|---|---|---|---|
| p8.31 | The leak surface has three uncovered edges | 2026-11-02 @Alpha-30-creator | [PR #17](https://github.com/Alpha-30-creator/worksite/pull/17), in review |

**p8.35 shipped 2026-11-02**: a `$1` in a skill body is replaced by the caller's
argument at delivery, which had `ws-env` and `ws-sync` reporting every project "not linked on this
device" while writing nothing. Fixed in the library and published as `cbcc499`; the audit now has a
gate so the next one is caught by a check rather than by a stranger.

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
| p8.13 | `for r in <repos>` survives in three skills | it prints success with the work still there, on a workspace whose path contains a space — this one |
| p8.25 | Shipping does not refresh the cartridge rows it invalidates | it defends the first file every agent reads, and this session hit it three times in one day |
| p8.32 | A retired track leaves its parent directory behind | 9.6M of orphaned worktree on a real project, invisible to both sweep passes |
| p8.34 | `ws-setup`'s profiles and the cartridge keys it writes | merged from p8.3 and p8.33 on 2026-11-02: the lite-profile contradiction cannot be resolved without the profile decision |
| p8.36 | The loop assumes a git remote and dies without one | four of five loop skills; the situation a stranger is actually in |
| p8.30 | One rule for who may push the library | resolved by hand in the last batch, written down nowhere |
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
| p7.1 | Dry-run the install as a stranger | 2026-11-02 |
| p8.35 | `ws-env` and `ws-sync` each gave a confidently wrong answer | 2026-11-02 |
| p1.2 | Prove the leak guard actually refuses a commit | 2026-11-02 |
| p3.4 | An index for the docs tree | 2026-11-02 |
| p8.24 | Gates that read an empty result as a pass | 2026-11-02 |

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
