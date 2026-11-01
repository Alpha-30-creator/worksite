# Stack: hexagonal (ports & adapters) architecture

Selected by `stack: [hexagonal]`. A house architecture rather than a framework convention, so
**the project's own practices doc is the rulebook** and this pack is only the review lens over
it:

- Find it from the cartridge: the backend and frontend practices docs under the project's
  `engineering/`. They own the layer rules, the API conventions and the auth rules; where they
  disagree with this pack, they win.
- Read the layer rules section **and the lint config that enforces them** before reviewing.
  A rule the linter already enforces does not need your attention; a rule it cannot enforce
  does.

**Layer violations — the first thing to check.** Domain importing infrastructure. A repository
or HTTP client reached from a component or controller. One feature importing another feature's
internals rather than its port. These are structural and they compound, so they are Must fix
even when the code works.

**Ports are owned by the inside.** The interface lives with the domain/application code; the
adapter implements it. An interface defined next to its adapter means the dependency points the
wrong way.

**Mappers are not optional.** Entity → domain model → response DTO, each explicit. A layer
that passes the previous layer's type straight through has erased the boundary.

**Composition roots.** New use cases, repositories and adapters are wired in the module that
owns composition, not constructed inline. An inline `new SomeRepository()` inside a use case is
a finding.

**The response envelope.** If the project defines one, every response uses it, and client-side
schemas are written against the **payload**, not the envelope. Zod schemas that include the
envelope wrapper are a recurring defect.

**Frontend mirror.** The same rules apply: `domain/` holds entities, schemas and the repository
*interface*; `infrastructure/` holds the axios implementation; `application/` holds queries and
mutations; `presentation/` holds components. A component importing axios is the frontend
equivalent of a layer violation.

**Where docs and code disagree, code wins — and the doc is fixed in the same change.** A
finding that the doc is stale is a real finding.
