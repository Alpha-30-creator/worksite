---
schema_version: 1
project: atlas
profile: full
state_dir: .atlas
docs_home: atlas-api/docs/agent
artifacts: in-repo
agents_file: copy
worktrees: true

tracker:
  kind: trello
  board_id: 6f2a91c4d8e30b17
  lists:
    open: "Backlog"
    in_progress: "Doing"

repos:
  - dir: atlas-api
    owner: atlas-education
    role: backend
    integration_branch: develop
    deploy_branches:
      main: production
    stack: [flask, pymongo, migrations]
    commands:
      typecheck: null
      lint: ruff check .
      test: pytest -q
      build: null
      verify: null
  - dir: atlas-infra
    owner: atlas-education
    role: infra
    integration_branch: main
    deploy_branches: {}
    stack: [terraform, aws]
    commands:
      typecheck: null
      lint: terraform fmt -check -recursive
      test: null
      build: terraform plan
      verify: null

git_flow:
  branch_pattern: "feature/<id>-<slug>"
  pr_into: integration_branch
  merge_style: squash
  release: "a release branch cut from develop, merged to main by the team lead"
  forbidden:
    - force-push to develop or main
    - running terraform apply from a laptop
    - committing a tenant id into a fixture

environments:
  staging:
    url: https://staging.atlas-education.example
    deploy: "merge to develop; the pipeline deploys"
  production:
    url: https://atlas-education.example
    deploy: "the team lead merges the release branch; never you"

house_rules:
  ai_attribution: false
  owned_by: company
  commit_convention: conventional
  hooks: none

machine:
  windows-laptop:
    note: "the venv lives in Scripts/ not bin/, and chmod 600 on an env file is a no-op here"
---

# atlas reference

A company's project, not yours. Two repos and a Trello board someone else owns. The conventions
here are **followed, not authored** — that is what `owned_by: company` means, and it is the most
load-bearing line in this file.

## The shapes this example exists to show

The [northwind cartridge](cartridge.md) covers the common case: several repos you own, a tracker in
files, plans in workspace state. This one covers what a stranger is likelier to walk into.

| Key | Here | Why it is different |
|---|---|---|
| `tracker.kind` | `trello` | a hosted board. **Its claim is not a lock** — a comment can be posted by two people at once, so re-read the card after claiming and stop if someone got there first |
| `artifacts` | `in-repo` | plans live at `atlas-api/implementation_plans/<id>/plan.md`, on the task branch, because the company wants them in the repo. `ws-ship` keeps the plan and deletes only the journal and scratch |
| `house_rules.owned_by` | `company` | `ws-refine` must never propose changing these house rules. It may say a rule costs something; it may not rewrite it |
| `docs_home` | inside a code repo | there is no docs repo to own, so the cartridge lives in the backend repo. The journal mirror lives there too, which means **the repo is private and the mirror is safe**; on a public repo it would not be |
| `merge_style` | `squash` | stated, rather than left for `ws-ship` to ask about every time |
| `environments` | two, with a deploy sentence each | production says `never you`. That sentence is the whole point of the key |

## `machine:` is inert today

The `machine:` block above is **a note to a human, not configuration**. No skill reads it: the
cartridge schema records that it has no merge semantics and no reader, and resolving that is an
open task on the pack's own roadmap. It is shown here because the shape is what a cartridge author
will reach for when one device differs — and because an example that quietly omitted it would leave
them inventing their own. Write the note; do not expect behaviour from it.

## Workspace layout

```
atlas/                      the workspace root — a plain folder, not a repo
  atlas-api/                Flask, Mongo, the docs and the cartridge
  atlas-infra/              Terraform
  .atlas/                   track state. Never committed
```

## Rules that override defaults

- **Multi-tenant.** A school is the tenant. Never trust a `school` read from the request body;
  take it from the token. The `flask-mongo` pack says this too, and here it is the first thing a
  review looks for.
- **`terraform apply` is never run from a laptop.** The pipeline does it. A plan is fine locally.
- **No typecheck, no build in the API, and no `verify`.** Recorded as `null` rather than invented.
  `ws-verify` runs lint and tests and says plainly that the other two do not exist.
- **The team lead merges to production.** A PR into `main` that you merge yourself is a mistake
  even when it is green.

## Open questions

- The board has a third list, **Done**, and `tracker.lists` has no key for it — it holds `open` and
  `in_progress` and only those. So a finished card's destination is asked rather than configured,
  once per task, forever. Recorded on the pack's roadmap as a cartridge gap; until it is fixed,
  expect the question and answer it the same way each time.
- A trello claim is **not atomic**: moving the card to `Doing` and adding yourself is the claim, and
  two people can do it at once. Re-read the card after claiming and stop if someone else got there
  first. There is no cartridge key for this — it is how the adapter works.
