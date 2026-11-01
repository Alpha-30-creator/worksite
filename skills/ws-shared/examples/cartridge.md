---
schema_version: 1
project: northwind
profile: full
state_dir: .northwind
docs_home: northwind-docs/agent
artifacts: workspace-state
agents_file: copy
worktrees: true

tracker:
  kind: roadmap-files
  path: roadmap
  status_file: STATUS.md
  markers: default
  claim: push

repos:
  - dir: northwind-api
    owner: example-org
    role: backend
    integration_branch: dev
    deploy_branches:
      main: production
      dev: staging
    stack: [nestjs, typeorm, hexagonal, migrations, money, vercel-serverless]
    commands:
      typecheck: npm run typecheck
      lint: npm run lint
      test: npm test
      build: npm run build
      migration: npm run migration:run
      check:cjs: npm run check:cjs   # the serverless bundle check the vercel pack asks about
      verify: npm run verify

  - dir: northwind-web
    owner: example-org
    role: frontend
    integration_branch: dev
    deploy_branches:
      main: production
      dev: staging
    stack: [nextjs-app-router, vercel-serverless, money]
    commands:
      typecheck: npm run typecheck
      lint: npm run lint
      test: null          # no test runner yet — say so, do not invent one
      build: npm run build

  - dir: northwind-docs
    owner: example-user
    role: docs
    integration_branch: main
    deploy_branches: {}
    stack: []
    commands: {}

git_flow:
  branch_pattern: "<type>/<id>-<slug>"
  pr_into: integration_branch
  release: "PR from dev into main; merging main deploys production"
  forbidden:
    - force-push to dev or main
    - "--no-verify"
    - a migration merged without its down() tested

environments:
  local:      "http://localhost:3000, api on 3001"
  staging:    "https://staging.northwind.example — deploys from dev"
  production: "https://northwind.example — deploys from main"

house_rules:
  ai_attribution: false
  owned_by: me
  commit_convention: conventional
  hooks: "husky — lint and typecheck on commit; never bypass"

machine:
  windows-desktop:
    note: "python venv scripts live in Scripts/ not bin/; chmod is a no-op here"
---

# northwind reference

An **example** cartridge, for one of the three invented projects in
[README.md](README.md). Nothing here is real; it exists so you can see a filled-in cartridge
before writing your own.

Read this before any work on northwind. Facts about the *product* live in the docs; facts about
**how to work on it** live here.

## Workspace layout

The workspace root is **not** a git repo — it holds three repos side by side. That is what keeps
the state directory uncommittable, and it is why every git command is `git -C <repo>`:

| Path | GitHub | Role |
|---|---|---|
| `northwind-api/` | `example-org/northwind-api` | the backend, hexagonal NestJS |
| `northwind-web/` | `example-org/northwind-web` | the storefront, Next.js App Router |
| `northwind-docs/` | `example-user/northwind-docs` | docs, the roadmap tracker, and this cartridge |
| `.northwind/` | — | track state. Never committed |

Note that the docs repo is owned by the **individual** while the code repos belong to the
organisation. That is the normal case, not a mistake: the docs carry a way of working that
outlives any one engagement.

## Where things are

| Need | Read |
|---|---|
| What is open, and whose | `northwind-docs/STATUS.md`, then `northwind-docs/roadmap/` |
| The API contract for a feature | `northwind-docs/integration/<feature>.md` |
| Layer rules, API conventions | `northwind-docs/engineering/backend-practices.md` |
| The same, for the web layers that mirror them | `northwind-docs/engineering/frontend-practices.md` |
| Why something is the way it is | `northwind-docs/decisions/` |
| Known traps in this project | `northwind-docs/agent/risks/` |

## Rules that override defaults

- **Money is involved.** Prices are in HKD. Totals are derived, never stored and trusted; every
  amount is minor units as an integer, and a formatted string is never a value. The `money` stack
  pack applies to both code repos.
- **The API ships before the web work that consumes it.** A task touching both orders the repos
  accordingly, and the contract in `integration/` may be committed right after plan approval so
  frontend work marked "(contract)" can start in parallel.
- **Merging `main` deploys production.** There is no separate release gate, so the PR *is* the
  gate.
- **`northwind-web` has no test runner.** Recorded as `null` rather than invented. It is verified
  by the other checks plus driving it.

## Open questions

- No load testing exists for the checkout path. Named here rather than assumed away.
