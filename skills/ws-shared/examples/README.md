# Examples

Three invented projects, reused throughout the pack so you build one mental model instead of
meeting a new made-up name in every file. Between them they cover every tracker adapter and most
stack tags.

| Project | Shape | Tracker | Covers |
|---|---|---|---|
| **northwind** | two code repos plus a docs repo | `roadmap-files` | multi-repo, hexagonal NestJS, Next.js App Router, money, migrations, serverless |
| **kestrel** | one repo | `github-projects` | single-repo, FastAPI, a LangGraph agent loop |
| **atlas** | two repos, a company's conventions | `trello` | `artifacts: in-repo`, Flask + Mongo, Terraform, rules you follow rather than own |

None of them is real. Where a pack needs a concrete example — a path, a command, a file name — it
uses one of these rather than a real repository.

**Two of the three have a cartridge written out**, and they were chosen to be opposites: northwind
is several repos you own with a file tracker and plans in workspace state; atlas is a company's
project with a hosted board, plans in the repo, and house rules you follow rather than author.
Between them they cover the two halves of almost every key. kestrel is described here and in the
stack packs but has no cartridge of its own — a third would repeat what these two already show.

| File | What it shows |
|---|---|
| [device.yaml](device.yaml) | the agent-sync device file: where projects live **on one machine** |
| [cartridge.md](cartridge.md) | a filled-in cartridge for northwind, frontmatter and prose |
| [cartridge-atlas.md](cartridge-atlas.md) | a second filled-in cartridge, for atlas: a hosted tracker, `artifacts: in-repo`, `owned_by: company`, and a `machine:` block with its inertness stated |
| [manifest.tsv](manifest.tsv) | the secrets store manifest |
| [tasks-file.md](tasks-file.md) | the `tasks-file` tracker, which `lite` projects default to |

## Reading the three

**northwind** is the shape most of the pack is written for: several repos that ship together, a
docs repo of their own, phases of work tracked in files, and money flowing through it — prices in
**HKD**, minor units as integers — so it needs plans, contracts, migrations discipline and a real
review.

**kestrel** is the opposite end: one repo, issues on a board, non-deterministic behaviour that
cannot be proved by reading a diff. It exists in the examples to keep the pack honest about
projects that have no test suite and no second repo.

**atlas** belongs to a company. It serves **schools**, so a school is its tenant — which is why
the Flask pack warns about trusting a `school` read from the request body instead of the token.
Its conventions are followed, not authored — `owned_by: company` in the cartridge — which is why
`ws-refine` must never propose changing its house rules, and why its plans live in the repo
rather than in workspace state.

**kestrel** runs its agent on LangGraph. Where a pack carries a rule that only holds for one
framework, it says so — see `stacks/llm-agent.md`.
