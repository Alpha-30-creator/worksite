# Examples

Three invented projects, reused throughout the pack so you build one mental model instead of
meeting a new made-up name in every file. Between them they cover every tracker adapter and most
stack tags.

| Project | Shape | Tracker | Covers |
|---|---|---|---|
| **northwind** | two code repos plus a docs repo | `roadmap-files` | multi-repo, hexagonal NestJS, Next.js App Router, money, migrations, serverless |
| **kestrel** | one repo | `github-projects` | single-repo, FastAPI, an agent loop |
| **atlas** | two repos, a company's conventions | `trello` | `artifacts: in-repo`, Flask, Terraform, rules you follow rather than own |

None of them is real. Where a pack needs a concrete example — a path, a command, a file name — it
uses one of these rather than a real repository.

| File | What it shows |
|---|---|
| [device.yaml](device.yaml) | the agent-sync device file: where projects live **on one machine** |
| [cartridge.md](cartridge.md) | a filled-in cartridge for northwind, frontmatter and prose |
| [manifest.tsv](manifest.tsv) | the secrets store manifest |
| [tasks-file.md](tasks-file.md) | the `tasks-file` tracker, which `lite` projects default to |

## Reading the three

**northwind** is the shape most of the pack is written for: several repos that ship together, a
docs repo of their own, phases of work tracked in files, and money flowing through it — so it
needs plans, contracts, migrations discipline and a real review.

**kestrel** is the opposite end: one repo, issues on a board, non-deterministic behaviour that
cannot be proved by reading a diff. It exists in the examples to keep the pack honest about
projects that have no test suite and no second repo.

**atlas** belongs to a company. Its conventions are followed, not authored — `owned_by: company`
in the cartridge — which is why `ws-refine` must never propose changing its house rules, and why
its plans live in the repo rather than in workspace state.
