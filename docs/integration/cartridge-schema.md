# The cartridge schema

A **cartridge** is one project's own facts, written where every `ws-*` skill can find them. The
skills are generic; the cartridge is what makes them act like they were written for your project.

This page is the format. It documents the schema **as the pack actually implements it**, which
means it also names the places where the schema and the pack disagree — see
[Known gaps](#known-gaps). Nothing here describes a key the pack does not read.

Every "read by" cell is backed by the grep ledger described in
[section 4](#4-how-to-read-the-key-tables), which traced each key through `skills/` one at a
time. A cell that makes a **specific** claim — a stated default, a stated degrade behaviour, a
quoted rule — carries the `file:line` citation for it; a cell that only names the consuming
skills does not repeat the line numbers behind it.

The three cartridges in this repo — the blank template, a filled multi-repo example, and this
repo's own — are linked from [See also](#see-also) at the foot of the page, together with the
shared files this page cites.

---

## 1. What it is and where it lives

| | |
|---|---|
| **File** | `<docs_home>/reference.md` — one per project |
| **Shape** | a YAML frontmatter block, then Markdown prose |
| **Written by** | `ws-setup`, from an interview |
| **Read by** | every `ws-*` skill, as step 1 or 2 of its "before anything" |
| **Committed** | yes — it lives in the docs repo or the docs folder, and it is permanent |

The frontmatter holds the machine-readable facts: repos, tracker, git flow, environments, house
rules and per-device overrides (`ws-shared/reference.md`:187-188). The prose below it holds the
things a table cannot carry — the workspace layout, where to find what, the rules that override
an agent's defaults, and the open questions.

**The division of labour matters.** Facts about *how to work on the project* belong here. Facts
about *the product* belong in the docs tree, and facts about the *system* belong in
`engineering/` or `decisions/` (`ws-refine`:33 for the cartridge half, `ws-refine`:65 for the product half, and
`ws-shared/review/documentation.md`). A
cartridge that starts explaining the product has absorbed something that will go stale in it.

Three things are **not** in the cartridge, and looking for them here wastes time:

| Fact | Where it lives |
|---|---|
| Where this project's workspace is *on this machine* | `~/.agent-sync/device.yaml` (`ws-shared/reference.md`:74-86) |
| Your handle, and your collaborators' | `<state_dir>/me` (`ws-setup`:99, `ws-shared/tracks.md`:12) |
| Track state — the plan, the journal, the evidence | `<state_dir>/tracks/<id>/` ([`ws-shared/tracks.md`](../../skills/ws-shared/tracks.md)) |

---

## 2. The smallest cartridge that works

```yaml
---
project: meridian
repos:
  - dir: meridian-service
    owner: example-org
---

# meridian reference

Read this before any work on meridian.
```

That is a complete, valid cartridge. `ws-setup`:181 is explicit: *"A cartridge with only
`project` and `repos` must work. Ship a partial cartridge rather than blocking on an unanswered
question."*

Everything in the rest of this page is **additive**. Each key you add buys one more thing a
skill can do without asking you; each key you leave out costs capability and nothing else.

---

## 3. The three rules that govern every key

Read these before the tables, because every cell below depends on them.

**R1 — Degrade, never fail.** A missing key means less capability, never an error
(`ws-refine`:66-67). No skill refuses to run over an absent key, and `ws-env` and `ws-sync` must
work with **no cartridge at all** (`ws-shared/reference.md`:190). The four skills that say
out loud what they do with no cartridge do different things, and the difference is deliberate:

| Skill | With no cartridge | Cited |
|---|---|---|
| `ws-review` | works without it; asks three questions — which repos changed, what the change should do, what the stack is — and never refuses | `ws-review`:16-18 |
| `ws-start` | offers `ws-setup` in adopt mode, then continues as best it can | `ws-start`:16 |
| `ws-sync` | skips the generated-instructions step and says nothing | `ws-sync`:101 |
| `ws-fanout` | offers to set the key it needs via `ws-refine`, and refuses to invent a third option | `ws-fanout`:40-48 |

**R2 — `TODO:` is a valid value; an invented fact is not.** *"Never invent a fact to fill a
field — a wrong fact in the cartridge is worse than a missing one, because every skill reads
it"* (`ws-setup`:101-103, 183). See [section 11](#11-absent-vs-null-vs-empty-vs-todo).

**R3 — Unknown keys are ignored.** A key the pack does not know is not an error
(`ws-refine`:66-67). You may add project-specific keys; nothing will read them, and nothing will
break.

### Key order does not matter, but follow the template's

YAML is a mapping, so no reader depends on the order. Use the order of
[section 13](#13-a-complete-cartridge-annotated) anyway — identity and layout, `tracker`,
`repos`, `git_flow`, `environments`, `house_rules`, `machine` — because it is the order
`ws-setup`'s template writes and the order its interview asks in, so a human diffing two
cartridges sees a change rather than a reshuffle.

### Required means "load-bearing", not "enforced"

**No skill validates a cartridge, and no skill fails on a missing key** — R1 forbids it. So the
`required` column below is a statement about *capability*, not about enforcement:

| Value | Meaning |
|---|---|
| **yes** | the cartridge is not usable without it. Only `project` and `repos` (`ws-setup`:181) |
| **conditional** | required once you want the feature it drives, or once its parent key is present |
| no | purely additive |

---

## 4. How to read the key tables

Every key table — sections 5 to 10, and section 12 — has the same six columns.

| Column | What it says |
|---|---|
| **key** | the key, qualified by its parent |
| **type** | the YAML type, and the value set where one is defined |
| **required** | **yes** / **conditional** / no, per the table above |
| **default** | what a reader behaves as if the key said, when the key is absent |
| **read by** | the skills that consume it (see the four classes below) |
| **missing →** | what happens when it is absent |

**"Default" and "what the template ships" are not the same thing, and the tables keep them
apart.** `ws-setup` writes a value into most keys, so in practice you will rarely see one absent —
but a value in the template is not a default a reader applies. Where the only source for a value
is `ws-setup`'s template, the cell says *template ships `X`*, and the "missing →" cell then says
what a reader actually does with nothing. `worktrees` is the worked example: the template ships
`true`, and an absent key reads as **not** `true`.

**The `default` column carries the same provenance marks as "missing →"**: a default quoted from
the pack is plain text with its citation, and one derived from a reading skill's behaviour is
marked ***inferred***. That column is where this page's first self-contradiction lived, so it
gets the same discipline.

### The four "read by" classes

| Class | How the cell reads | Why it matters |
|---|---|---|
| Read by name | the skill list | a skill names the key, so the mapping is exact |
| Read by concept | the skill list, plus *(by concept, not by name)* | the skill acts on the fact but never names the key, so renaming the key would not break anything — and would not be noticed either |
| Written, never read | "nothing reads this" | `ws-setup` writes it and no skill consumes it |
| Read, never specified | not in a table — in [Known gaps](#known-gaps) | a skill reads something the schema does not define |

The mapping was built as an exhaustive grep ledger over `skills/`, in three passes per key —
the backticked literal and `key:` form, then the dotted or possessive form
(`tracker.kind`, "the cartridge's `commands`"), then the English concept for any key the first
two passes missed. **`skills/ws-shared/examples/` and `skills/ws-setup/templates/` are excluded
from the ledger**: they are cartridge *data*, not readers, so a hit in them proves nothing about
who consumes a key.

### The provenance convention in "missing →"

Degrade behaviour is written down globally (R1) but **not per key anywhere in the pack**, so
most of these cells are derived rather than quoted. The two forms are:

- **plain text with a citation** — stated in the pack at that line
- ***inferred*** — derived from the reading skill's own instructions, and written down nowhere

Every *inferred* cell is a place the pack does not state its own behaviour. That is a punch-list,
not a per-row complaint; it is picked up once in [Known gaps](#known-gaps).

---

## 5. Identity and layout

```yaml
schema_version: 1
project: meridian
profile: full
state_dir: .meridian
docs_home: meridian-docs/agent
artifacts: workspace-state
agents_file: copy
worktrees: true
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `schema_version` | integer | no | none — *template ships* `1` | **nothing reads this** | no effect — *inferred*, since nothing consumes it |
| `project` | string, lowercase-kebab | **yes** | none | `ws-setup` | the cartridge cannot be matched to its `agent-sync` project id or workspace — *inferred* |
| `profile` | `full` \| `lite` | no | none — *template ships* `full` | `ws-setup`; `lite` is read by concept by `ws-shared/tracks.md` and `ws-shared/reference.md` *(by concept, not by name)* | treated as `full`, so the full interview and the full artefact set apply — *inferred* |
| `state_dir` | path, relative to the workspace root | **conditional** — the track loop needs it | none — *template ships* `.<project>` | `ws-start`, `ws-plan`, `ws-verify`, `ws-ship`, `ws-wrap`, `ws-task`, `ws-fanout` | no track directory, so no `tracks/current`, plan, journal or evidence — *inferred* |
| `docs_home` | path to the agent docs directory — **it ends `/agent`** | no | none | `ws-start`, `ws-plan`, `ws-verify`, `ws-wrap`, `ws-review`, `ws-ship`, `ws-setup`, `ws-refine`, `ws-fanout` | on a `lite` project, a local journal only, with no mirror and nothing on the other machine, said once when the track is created (`ws-shared/tracks.md`:77). What a **`full`** project without it does is *inferred*: the journal cannot be mirrored and `risks/`, `rules/` and `worklog/` have no location |
| `artifacts` | `workspace-state` \| `in-repo` | no | `workspace-state` — stated (`ws-shared/tracks.md`:37) | `ws-plan`, `ws-review`, `ws-ship` | `workspace-state` — plans and journals in `<state_dir>`, never in a repo (`ws-plan`:52) |
| `agents_file` | `copy` \| `include` \| `symlink` | no | none — *template ships* `copy` | `ws-sync` | the deployed `AGENTS.md` is not refreshed or drift-checked — *inferred* |
| `worktrees` | boolean | no | none — *template ships* `true`, and an absent key is **not** `true` | `ws-start`, `ws-plan`, `ws-fanout` | `ws-fanout` greps `^worktrees:` (`ws-fanout`:32) and an absent key reads as not-`true`, so it takes the `false` branch and will not fan out without hard per-repo ownership — *inferred* |

**`artifacts: in-repo` relocates the plan, and only the plan.** There is no key that puts the
journal or the verify evidence in a repo: those stay ephemeral workspace state under
`<state_dir>/tracks/<id>/` on every project, and `ws-ship` deletes them at ship whatever
`artifacts` says (`ws-shared/tracks.md`:100-106, 185; `ws-ship`:146). If what you want is "the
plan is a reviewable artefact in the repo", that is what this key gives you. If what you want is
"the journal is in the repo too", the pack cannot express it.

The plan goes to `<repo>/implementation_plans/<id>/plan.md`,
committed on the task branch, and the branch itself is how it crosses machines — so no journal
mirror is needed (`ws-shared/tracks.md`:37-38, 76; `ws-plan`:50-51). `ws-ship` keeps that plan and
deletes only the journal and the verify scratch (`ws-ship`:146, `ws-shared/tracks.md`:104-106, 185).
`ws-review` looks for the plan there rather than in `<state_dir>` (`ws-review`:20). It is a
company convention on some projects: *"respect it; do not argue with it"*
(`ws-shared/tracks.md`:40-41). **On a multi-repo project, nothing specifies which repo holds the
plan** — see [gap 10](#known-gaps); say so in the cartridge prose and keep it in one place.

**`lite` is a smaller interview, not a smaller schema.** It costs five questions instead of
thirty, and `ws-setup` generates no journal, no rule skills and no risks file (`ws-setup`:36,
45-54). It does not forbid any key: a `lite` project may carry a `tasks-file` tracker, which is
what the adapter index recommends for one (`ws-shared/reference.md`:210,
`ws-shared/trackers/tasks-file.md`:3). The pack says both *"no tracker"* and *"the `lite`
default"*; that contradiction is [gap 9](#known-gaps), and a tracker key on a `lite` cartridge is
read exactly like any other.

**`docs_home` ends `/agent`, and the path is the agent directory itself** — not the docs root.
`<docs_home>/reference.md` is the cartridge (`ws-shared/reference.md`:187), `<docs_home>/risks/`
the project's own review risks (`ws-plan`:44, `ws-review`:32, `ws-refine`:32, `ws-debug`:13),
`<docs_home>/worklog/<id>.md` the harvest (`ws-ship`:100, `ws-task`:67),
`<docs_home>/workspace/AGENTS.md` the instruction source (`ws-sync`:90) and
`<docs_home>/journal/<id>.md` the mirror (`ws-shared/tracks.md`:72). On a single-repo project
that is `<repo>/docs/agent`; on a multi-repo project, `<docs repo>/agent`. **Four sites in the
pack assume otherwise** and append a second `/agent` — see [gap 13](#known-gaps), which matters
on any project that writes the dominant form.

**`state_dir` is never committed.** On a multi-repo project the workspace root is not a git repo,
which is what keeps it uncommittable. On a single-repo project the root *is* a repo, so
`ws-setup` adds `<state_dir>/` to its `.gitignore` and says so (`ws-setup`:129-131). Removing
that line commits your track state.

### `merge_style`

`ws-ship` reads it; nothing in the pack defines it. It gets a row because a skill reads it, and
every cell that cannot be sourced says so.

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `merge_style` | `merge` \| `squash` \| `rebase` — ***inferred***, the pack states no value set | no | none | `ws-ship`:85 — *"use the project's merge style (`merge_style` in the cartridge)"* | `ws-ship` has no merge style to apply and falls back to asking or to the repo's own default. **That fallback is the only behaviour this key has**, because `ws-setup`'s template never writes it — so in practice every project is in the missing case — *inferred* |

**Its placement is inferred too.** `ws-ship`:85 says only "`merge_style` in the cartridge" and
names no parent key, so top-level is this page's reading, not the pack's statement. It would sit
as plausibly under `git_flow`. Setting it is therefore a guess either way until the pack says —
[gap 1](#known-gaps).

**`agents_file: symlink` is a documented value you should not choose.** *"Do not use a symlink
even on macOS. Windows git checks a symlink out as a text file containing the path, silently, and
the agent then has no rules"* (`ws-setup`:126-127).

---

## 6. Tracker

`tracker:` is a map. One key selects the adapter; the rest are **conditional on that key** —
each kind has its own disjoint set, and a key from the wrong kind is simply ignored (R3).

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `tracker` | map | no | none | `ws-start`, `ws-task` | no board: nothing to list, claim or mark. The loop still runs — `ws-start` can be given a task by hand — *inferred* |
| `tracker.kind` | `github-projects` \| `roadmap-files` \| `trello` \| `tasks-file` \| `none` | **conditional** — required when `tracker` is present | none | `ws-start`, `ws-task`, and the adapter index in `ws-shared/reference.md` | an unknown or absent kind is not an error: ask the four questions in [`skills/ws-shared/trackers/`](../../skills/ws-shared/trackers/)`README.md` and carry on (`ws-shared/trackers/README.md`:10, `ws-start`:18) |

`kind` selects one file, and that file is the whole contract:

| `tracker.kind` | Adapter | Suits | Real claim lock? |
|---|---|---|---|
| `roadmap-files` | `ws-shared/trackers/roadmap-files.md` | a solo build with phases | yes — a pushed commit |
| `github-projects` | `ws-shared/trackers/github-projects.md` | a team, or anything already on issues | no |
| `trello` | `ws-shared/trackers/trello.md` | a board someone else owns | no |
| `tasks-file` | `ws-shared/trackers/tasks-file.md` | `lite` projects, anything small | yes — a pushed commit |
| anything else | ask the four questions, then write a new adapter | — | ask |

*(`ws-shared/reference.md`:205-211. "No real lock" means assigning is not atomic: re-read the
item after claiming and stop if someone else got there.)*

### `kind: roadmap-files`

```yaml
tracker:
  kind: roadmap-files
  path: roadmap
  status_file: STATUS.md
  markers: default
  claim: push
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `tracker.path` | path to the folder of `P*.md` phase files | **conditional** | none | the `roadmap-files` adapter | the adapter cannot find the board — *inferred* |
| `tracker.status_file` | path to the one-screen status file | **conditional** | none | the `roadmap-files` adapter | no status view to update on claim or on done — *inferred* |
| `tracker.markers` | enum; `default` is the only defined value | no | `default` — *inferred* | the `roadmap-files` adapter | the `default` marker set — *inferred* |
| `tracker.claim` | enum; `push` is the only defined value | no | `push` — *inferred* | the `roadmap-files` adapter | a pushed commit as the lock — *inferred* |

`markers` and `claim` each have exactly one defined value. The keys exist so a project can
diverge; what else they would accept is not written down, and [Known gaps](#known-gaps) says so.
The `default` marker set is `[ ]` open, `[~]` claimed, `[r]` PR open, `[x]` done, `[-]` dropped,
`[?]` blocked on a decision (`ws-shared/trackers/roadmap-files.md`:6-18).

### `kind: github-projects`

```yaml
tracker:
  kind: github-projects
  org: example-org
  project_number: 4
  statuses:
    todo: "To do"
    in_progress: "In progress"
    review: "In review"
    done: "Done"
  assignee_default: example-user
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `tracker.org` | string — the GitHub org or user that owns the project board | **conditional** | none | the `github-projects` adapter | every `gh project` call lacks `--owner` — *inferred* |
| `tracker.project_number` | integer — the `<n>` in `gh project item-list <n>` | **conditional** | none | the `github-projects` adapter | the board cannot be addressed — *inferred* |
| `tracker.statuses` | map of this project's Status column names | **conditional** | none | the `github-projects` adapter | the adapter falls back to *"the project's 'to do' equivalent"* and asks which Status to list (`ws-shared/trackers/github-projects.md`:15-17) |
| `tracker.assignee_default` | string — a GitHub login | no | none | the `github-projects` adapter — marked optional at `github-projects.md`:4 | scope is asked for instead: mine, someone else's, or everyone (`github-projects.md`:15) |

`statuses` and `assignee_default` are the adapter's own two optional keys. **The adapter gives
`statuses` no schema**, so the map above is one legible way to write it and not a format the pack
will recognise; what the adapter is documented to need is the Status column *names* and, once
derived, the field ids (`ws-shared/trackers/github-projects.md`:23-27). Keep the column names
exactly as the board spells them — the adapter resolves them by name.

### `kind: trello`

```yaml
tracker:
  kind: trello
  board_id: 5f3a91c2e4b07d1a8c6f2d40
  lists:
    open: "To Do"
    in_progress: "Doing"
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `tracker.board_id` | string — the Trello board id | **conditional** | none | the `trello` adapter | no board to query — *inferred* |
| `tracker.lists` | map — the names of the lists that mean open and in progress | **conditional** | none | the `trello` adapter | list ids cannot be resolved by name — *inferred* |

List ids are resolved from names **case-insensitively** (note the space in "To Do"). **`lists`
holds two lists and only two** — open and in progress. There is **no key for the done list or the
review list**, and that is not an omission you can work around by adding one: the adapter asks
where a finished card goes, every time, and nothing you write in the cartridge answers it
(`ws-shared/trackers/trello.md`:3-4, 48-53). See [gap 14](#known-gaps), which is the sharpest of
them for anyone authoring a Trello cartridge. Credentials never go in the cartridge — they come from
the shell env or `ws-env` (`trello.md`:9-20).

### `kind: tasks-file`

```yaml
tracker:
  kind: tasks-file
  path: TASKS.md
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `tracker.path` | path to the single tasks file | no | `TASKS.md` in the docs home or the repo root (`ws-shared/trackers/tasks-file.md`:3) | the `tasks-file` adapter | `TASKS.md` in the docs home or the repo root (`tasks-file.md`:3) |

### `kind: none`

No further keys. `none` is a listed value of `kind` (`ws-setup`:87); no adapter file exists for
it, and nothing in the pack describes behaviour specific to it beyond the unknown-kind path
above.

---

## 7. Repos

`repos:` is a **list of maps**, one per repository in the workspace. It and `project` are the
two keys a cartridge cannot omit.

```yaml
repos:
  - dir: meridian-service
    owner: example-org
    role: backend
    integration_branch: dev
    deploy_branches:
      main: production
      dev: staging
    stack: [fastapi, sqlalchemy, migrations]
    commands:
      typecheck: mypy .
      lint: ruff check .
      test: pytest
      build: null              # no build step in this repo
      migration: alembic upgrade head
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `repos` | list of maps | **yes** | none | `ws-setup`; every skill that loops over repos | nothing to sync, diff, branch or check — *inferred* |
| `repos[].dir` | string — the folder name under the workspace root | **conditional** — a list item needs it | none | `ws-start`, `ws-sync`, `ws-ship`, `ws-review`, `ws-setup` *(by concept, not by name)* | `git -C <repo>` has no target — *inferred* |
| `repos[].owner` | string — the GitHub owner | no | none | `ws-ship`, for `gh pr create -R <owner>/<repo>` *(by concept, not by name)* | the PR command cannot be formed; `gh` falls back to the remote — *inferred* |
| `repos[].role` | `backend` \| `frontend` \| `docs` \| `infra` \| `lab` \| `legacy` | no | none | **nothing reads this** — the vocabulary appears only in `ws-setup`'s interview (`ws-setup`:60-61) | no effect — *inferred* |
| `repos[].integration_branch` | string — the branch work merges into | no | none | `ws-start`, `ws-plan`, `ws-ship`, `ws-review`, `ws-sync` *(by concept, not by name)* | `ws-review` has no branch to diff against and `ws-start` cannot report "not on its integration branch" — *inferred* |
| `repos[].deploy_branches` | map, `branch: environment`. `{}` means nothing deploys | no | `{}` — *inferred*, and **unsafe to rely on** | `ws-ship` | **see the callout below** |
| `repos[].stack` | list of tags | no | `[]` — *inferred* | `ws-plan`, `ws-review`, and the twelve packs under `ws-shared/stacks/` | tiers 1 and 3 of the review still apply, so no stack pack is selected: *"a tag with no pack is fine… degrade, never fail"* (`ws-shared/reference.md`:231) |
| `repos[].commands` | map, name → shell command or `null` | no | `{}` — *inferred* | `ws-verify`, `ws-review`, `ws-fanout` | nothing to run as that repo's own checks, so verification rests on the evidence per criterion alone — *inferred* |

**A dedicated docs repo is one of the `repos:` entries**, with `role: docs` and usually an empty
`deploy_branches` and `commands` — see the multi-repo
[example](../../skills/ws-shared/examples/cartridge.md), whose third repo is its docs. It is a
checkout in the workspace like any other, and `ws-start` syncs it because the tracker often lives
in it. `docs_home` then points **inside** it: `<docs repo>/agent`.

> **An absent `deploy_branches` is the one unsafe omission.** `ws-setup`:92 calls which branches
> deploy *"a safety fact, not trivia; get it exactly right"*, and `ws-ship`:85 checks it before
> merging and says out loud whether the merge deploys and where. An absent key is
> indistinguishable from `{}` — "nothing deploys" — so a merge that does deploy goes through
> announced as safe. Write `{}` when nothing deploys, and write the map when something does.
>
> Map **only** the branches that deploy; a branch that exists and deploys nothing is simply not a
> key. Where the answer is unknown, R2 applies: `deploy_branches: "TODO: ask who owns the deploy"`
> is a question a skill must raise, where `{}` is an assertion it will act on.

### `commands` in detail

`ws-verify` runs these as the repo's own checks and **prefers `verify` where the repo has one**;
otherwise it runs them individually, batched into one call (`ws-verify`:18-22). `ws-review` is
told to run the same set and report pass/fail, never fix (`ws-review`:93-94).

| key | read by | note |
|---|---|---|
| `commands.verify` | `ws-verify`, `ws-review` | one command that stands for the lot. Preferred when present |
| `commands.typecheck`, `.lint`, `.test`, `.build` | `ws-verify`, `ws-review` | the standard four |
| any other name | `ws-verify`, `ws-review` (as *"plus `extra`"*), and the stack packs | **either** signal selects the `migrations-sql` pack: a `migrations` stack tag, **or** the repo having `commands.migration` at all (`ws-shared/stacks/migrations-sql.md`:3). Neither is needed when the other is there |

**`null` is the right value for a check the repo does not have.** *"A `null` command means the
repo genuinely does not have that check — say so rather than inventing one"* (`ws-verify`:25).
A repo with no test runner is normal and is verified by the other checks plus driving it.

### `stack` in detail

Tags select the tier-2 review packs, and `ws-plan` reads the same packs while planning so the
work is designed against the rules it will be judged by (`ws-plan`:45-47). The tag → pack table
lives in `ws-shared/reference.md`:235-248. **A reader cannot invent a tag that works**, so it is
reproduced here in full — these are the tags that select a pack, as of `683a6ed`:

| Tag | Pack it selects |
|---|---|
| *(none — always on)* | `security-baseline.md` |
| `nestjs`, `typeorm` | `nestjs-typeorm.md` |
| `hexagonal` | `hexagonal-nest.md` |
| `nextjs-app-router` | `nextjs-app-router.md` |
| `vite`, `react-router-spa` | `vite-react-spa.md` |
| `fastapi`, `sqlalchemy` | `fastapi-sqlalchemy.md` |
| `flask`, `pymongo` | `flask-mongo.md` |
| `terraform`, `aws` | `terraform-aws.md` |
| `vercel-serverless` | `vercel-serverless.md` |
| `migrations` | `migrations-sql.md` |
| `money` | `money.md` |
| `llm-agent` | `llm-agent.md` |

Twelve packs, nineteen tags. Several tags can map to one pack — `nestjs` and `typeorm` both
select `nestjs-typeorm.md` — and a pack is read once per review, not once per tag.

**A tag outside this list is still legal and still worth writing.** It selects no pack, which
costs nothing (tiers 1 and 3 still apply), and it is the signal that a pack should exist: packs
grow when a review confirms a finding whose class is not written down
(`ws-shared/reference.md`:255-258). So tag the repo with what it actually is — `python`,
`postgres`, `django` — and accept that today only the nineteen above change the review.
The list is dated because it grows; `ws-shared/reference.md` is the live copy.

**Tags are the only machine-readable place a technology is named.** There is no key for a
language or runtime version, so a version that matters goes in the cartridge prose under "Rules
that override defaults", where the agent reading the cartridge will see it.

---

## 8. Git flow

`git_flow` is **project-wide** — there is one block, not one per repo. Per-repo branching lives
in `repos[].integration_branch`, and `pr_into: integration_branch` is the literal string that
means "each repo's own". `release:` is one free-prose string for the whole project, so a project
whose repos release differently describes both in it.

```yaml
git_flow:
  branch_pattern: "<type>/<id>-<slug>"
  pr_into: integration_branch
  release: "PR from dev into main; merging main deploys production"
  forbidden:
    - force-push to dev or main
    - "--no-verify"
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `git_flow` | map | no | none | `ws-setup` collects it; the generated workspace `AGENTS.md` renders it wholesale *(by concept, not by name)* | the workspace instructions lose their git-flow section — *inferred* |
| `git_flow.branch_pattern` | string; the placeholders are `<type>`, `<id>`, `<slug>` | no | none | `ws-plan`, which names the branches per repo from it (`ws-plan`:65) | `ws-plan` has no pattern to form branch names from and must ask or invent — *inferred* |
| `git_flow.pr_into` | string — a branch name, or the literal `integration_branch` to mean each repo's own. **Prefer the literal** — see below | no | `integration_branch` — *inferred* | `ws-ship`, which opens the PR `--base <integration>` *(by concept, not by name)* | each repo's `integration_branch` — *inferred* from `ws-ship`:68-72, which speaks only of "the integration branch" |
| `git_flow.release` | string, free prose — how a release happens | no | none | `ws-ship`, whose Releases section treats a release as a separate explicit act *(by concept, not by name)* | `ws-ship` has no release procedure to follow and must ask — *inferred* |
| `git_flow.forbidden` | list of strings — actions never to take in this project | no | `[]` — *inferred* | `ws-fanout`, which carries the project's overriding rules into every build brief *(by concept, not by name)* | the pack's own universal bans still apply — never `--no-verify`, never `git add -A`, no force-push (`ws-ship`:64-65, `ws-fanout`:193) — but nothing project-specific is passed on — *inferred* |

**Prefer `pr_into: integration_branch` over naming a branch, even when every repo uses the same
one.** `repos[].integration_branch` is read for more than the PR base: `ws-review`:71 diffs
against it, `ws-start`:31 reports a repo that is not on it, and `ws-plan`:28 reads the code as it
stands on it. Writing `pr_into: develop` does not wire those up — it only hard-codes the PR base,
and it does so in a second place that can drift from the first. Nothing errors if the two
disagree; the review simply diffs against the wrong branch. The literal keeps one source of
truth per repo.

No skill names `pr_into`, `release` or `forbidden`. They are read as the English facts they
encode, which means renaming them would break nothing and would also be noticed by nothing.

---

## 9. Environments

```yaml
environments:
  local:      "http://localhost:3000, api on 3001"
  staging:    "https://staging.example.com — deploys from dev"
  production: "https://example.com — deploys from main"
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `environments` | map, name → one-line description | no | `{}` — *inferred* | `ws-debug`, which establishes which environment a failure is in before theorising (`ws-debug`:23) | `ws-debug` asks which environment instead — *inferred*; `ws-debug` reads the key and does not state the fallback |

**Record the environments you know do not exist, rather than leaving them out** — with a note
saying so — *"so a plan can say 'this needs staging, which doesn't exist'"* (`ws-setup`:93-94):

```yaml
environments:
  local:      "http://localhost:3000"
  staging:    "does not exist — nothing between local and production"
  production: "https://example.com — deploys from main"
```

**That applies to an environment you have established does not exist, not to one nobody has
mentioned.** The two are different states and they take different values: a stage you have asked
about and confirmed is absent gets a key with a "does not exist" note; one you simply have no
information about gets a quoted `TODO:` naming the question, or no key at all if it never came up.
Writing "does not exist" for an environment you merely were not told about asserts a fact you do
not have, which is R2's whole point. And `environments: {}` on a project where nothing is
deployed is accurate, not unfinished.

---

## 10. House rules

```yaml
house_rules:
  ai_attribution: false
  owned_by: me
  commit_convention: conventional
  hooks: "husky — lint and typecheck on commit; never bypass"
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `house_rules` | map | no | none | `ws-ship`, `ws-refine`, `ws-setup`, `ws-fanout` | the pack's own universal house rules still apply (`ws-shared/reference.md`:272-283) — *inferred* |
| `house_rules.ai_attribution` | boolean. **Writing `false` is equivalent to omitting the key** — see below | no | none — *template ships* `false` | `ws-ship`:65 | the pack bans AI attribution in every commit and PR unconditionally (`ws-shared/reference.md`:278), so an absent key behaves as `false`. `ws-ship` acts on it only in the `false` direction; **nothing in the pack describes what `true` would do** — *inferred* |
| `house_rules.owned_by` | `me` \| `company` | no | none — *template ships* `me` | `ws-setup`:97, 186; `ws-refine`:71 | treated as `me`, so `ws-refine` may propose changing the house rules. `company` means *"the rules are followed, not authored"* and `ws-refine` must never propose changing them — *inferred* |
| `house_rules.commit_convention` | string, e.g. `conventional` | no | none | `ws-fanout`, into every build brief; `ws-setup`, in the interview *(by concept, not by name)* | no convention is passed to a builder — *inferred* |
| `house_rules.hooks` | string, free prose — what the repo's hooks do and how to enable them | no | none | `ws-ship` and `ws-wrap`, which both state that hooks always run and are never bypassed *(by concept, not by name)* | an agent does not know a hook exists, or how to enable it — *inferred* |

**`ai_attribution: false` changes nothing, and is worth writing anyway.** The pack already bans
AI attribution in every commit and PR unconditionally (`ws-shared/reference.md`:278), so the
absent key and the explicit `false` produce identical behaviour. The template writes it because a
house rule stated in the project's own file is one an agent meets while reading the cartridge
rather than two files away — and because the *absence* of the line would otherwise be the only
evidence either way. It is the one key on this page where writing the default is purely
documentary.

> **`owned_by` fails in the permissive direction, and that is the second unsafe omission on this
> page.** `company` is the switch that stops `ws-refine` proposing a change to rules you do not
> own (`ws-refine`:71, `ws-setup`:97, 186). Absent — or holding a `TODO:` — it is read as `me`,
> the permissive branch, so `ws-refine` will propose rule changes it may not be entitled to
> propose, with no error and no prompt. The enum has only the two values, so a team that
> *collectively authors* its own rules has no lexical home; `me` is the semantically right answer
> there, and **writing it is safer than leaving it to the default, because they are the same
> value with different provenance** — one is a decision, the other is a gap nobody notices.
> Compare `deploy_branches`: both keys are cases where absent and a real value are
> indistinguishable to the reader, and the reader picks the dangerous reading.

---

## 11. Absent vs `null` vs empty vs `TODO:`

Four ways to write "there is nothing here", and they do not mean the same thing. The examples in
the pack use all four deliberately.

| You write | It means | A reader should |
|---|---|---|
| the key is **absent** | the question was never answered | degrade per the key's "missing →" row |
| `null` | the thing genuinely does not exist | say so, and **not invent a substitute** (`ws-verify`:25) |
| `{}` or `[]` | an empty collection, as a positive statement | treat it as the answer. `deploy_branches: {}` means *nothing deploys* |
| `TODO: <what is unknown>` | the answer exists but nobody knows it yet | ask, and never fill it with a guess |

### `TODO:` in full

```yaml
tracker:
  kind: github-projects
  org: example-org
  project_number: "TODO: ask which board this team actually uses"
```

**Quote it.** A bare `TODO: ask …` holds a second colon and is not valid YAML, so the value
goes in quotes. The pack does not state this; it follows from the file being YAML.

`ws-setup` writes `TODO:` wherever an interview answer is genuinely unknown, because *"a wrong
fact in the cartridge is worse than a missing one, because every skill reads it"*
(`ws-setup`:101-103). Two consequences:

- **A `TODO:` is a question, not a value.** A skill that meets one asks rather than proceeding on
  it. No skill in the pack is documented as detecting the `TODO:` prefix, so in practice it is
  read by the agent reading the cartridge — which is also how it should be treated.
- **A cartridge with `TODO:` values ships.** It is not a draft to be held back: R1 says ship the
  partial cartridge rather than blocking on the unanswered question (`ws-setup`:181-183).

Say *what* is unknown and *who* could answer it. `TODO:` alone is a shrug; `TODO: ask the
platform team which branch deploys staging` is a task.

---

## 12. `machine:` overrides

```yaml
machine:
  windows-desktop:
    note: "python venv scripts live in Scripts/ not bin/; chmod is a no-op here"
```

`machine:` is a map keyed by **device id** — the `device:` field in `~/.agent-sync/device.yaml`
on that machine. `ws-shared/reference.md`:77 is the authority: *"`device:` … this device's id;
`machine:` overrides in a cartridge key off it"*. The device id is per machine and does not
travel: a workspace root is not a repo, so `.agent-sync.yaml` is not committed anywhere and
*"the id has to be typed correctly on each machine"* (`ws-shared/new-device.md`:120-121).

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `machine` | map, device id → map | no | `{}` — *inferred* | `ws-shared/reference.md`:77, 188 — which every `ws-*` skill reads first *(by concept, not by name)* | no per-device facts; everything resolves from the top-level keys — *inferred* |

**What may be overridden is not specified, and no skill is documented as merging a `machine:`
block over the top-level keys.** This page will not invent a merge rule it cannot cite. What the
pack actually does with `machine:` is:

- it names the key as the place per-device facts belong (`ws-shared/reference.md`:188);
- it keys them off the device id from `device.yaml` (`ws-shared/reference.md`:77);
- and its one worked example carries a free-text `note:` — a platform difference an agent needs
  to know and no top-level key expresses (`ws-shared/examples/cartridge.md`:78-80).

So the dependable use is **a per-device `note:`, read by whoever reads the cartridge**. Treat a
device block that redefines a top-level key as a statement to a human reader, not as a merge the
pack performs — and see [Known gaps](#known-gaps). What belongs in a device block in any case is
only what is true of the *machine*: platform differences, a tool that is absent there, a path
convention. Workspace paths themselves never belong here — those come from `device.yaml`, and
*"always resolve a workspace path from there. Never hardcode one"* (`ws-shared/reference.md`:86).

---

## 13. A complete cartridge, annotated

Every key on this page, on a single-repo project with a `roadmap-files` board. The two in-repo
examples — [this repo's own cartridge](../agent/reference.md) and the multi-repo
[northwind example](../../skills/ws-shared/examples/cartridge.md) — are the other two shapes
worth reading.

```yaml
---
schema_version: 1               # nothing reads it; a version marker for a future reader
project: meridian               # REQUIRED. Matches the agent-sync project id
profile: full                   # full | lite. lite = a five-question interview, not a smaller schema
state_dir: .meridian            # local, ephemeral, gitignored. Holds tracks/<id>/
docs_home: docs/agent           # single repo, so the docs live in it. Always ends /agent
artifacts: workspace-state      # workspace-state (default) | in-repo
agents_file: copy               # copy | include | symlink. copy — never symlink
worktrees: true                 # each track its own checkout; required for ws-fanout

tracker:
  kind: roadmap-files           # selects ws-shared/trackers/roadmap-files.md
  path: docs/roadmap            # the folder of P*.md phase files
  status_file: docs/STATUS.md   # the one-screen status view
  markers: default              # the only defined value
  claim: push                   # the only defined value; a pushed commit is the lock

repos:                          # REQUIRED. A list, one map per repo
  - dir: .                      # folder under the workspace root; "." for a single repo
    owner: example-org          # GitHub owner, for gh pr create -R <owner>/<repo>
    role: docs                  # documentation only — nothing reads this key
    integration_branch: main    # what work merges into
    deploy_branches: {}         # branch: environment. {} is a POSITIVE "nothing deploys"
    stack: []                   # tags select the tier-2 review packs
    commands:
      typecheck: null           # null = the repo genuinely has none. Never invent one
      lint: null
      test: null
      build: null
      verify: bash scripts/check.sh   # preferred by ws-verify when present

git_flow:
  branch_pattern: "<type>/<id>-<slug>"   # ws-plan forms branch names from this
  pr_into: integration_branch            # or a literal branch name
  release: "tag v<x.y.z> on main; nothing is published"
  forbidden:                             # project-specific bans, into every build brief
    - force-push to main
    - "--no-verify"

environments: {}                # record the ones that DON'T exist too, with a note

house_rules:
  ai_attribution: false
  owned_by: me                  # company = ws-refine must never propose changing these
  commit_convention: conventional
  hooks: "run: git config core.hooksPath .githooks"

machine: {}                     # per-device notes, keyed by the device.yaml device id
---

# meridian reference

Read this before any work on meridian. Facts about the *product* live in the docs; facts about
**how to work on it** live here.

## Workspace layout
## Where things are
## Rules that override defaults
## Open questions
```

The four prose headings come from the template (`ws-setup/templates/cartridge.md`:44-60).
**Nothing in the pack enforces them** — the frontmatter is what skills parse, and the prose is
read by an agent, so a heading missing is a gap in what the agent is told rather than a format
error. They are not decoration, though. "Rules that override defaults" is where an agent's own habits get
overridden, and "Open questions" is where a known unknown goes instead of being assumed away.

---

## Known gaps

Everything above is checkable against `skills/`. These are the places where the pack and the
schema do not line up. Each is a candidate for `ws-task`, and none should be closed by writing
documentation for a key that does not exist.

Recorded 2026-11-01 against `skills/` at commit `683a6ed`.

| # | Gap | Evidence | Follow-up |
|---|---|---|---|
| 1 | **`merge_style` is read but never defined.** `ws-ship` uses *"the project's merge style (`merge_style` in the cartridge)"*, and no template, example or adapter defines the key — so `ws-ship` always falls back to asking or to the repo's default. That fallback is its only degrade behaviour | `ws-ship`:85 | `ws-refine` should add the key to `ws-setup`'s template with its value set, or `ws-ship` should stop naming a key the schema does not have |
| 2 | **`schema_version` has no reader.** A version marker nothing consumes. Fine for a first schema, but it is a promise nothing keeps | zero hits across `skills/` | decide what would read it, or drop it from the template |
| 3 | **`repos[].role` has no reader.** The six-value vocabulary is enumerated in the interview and never consumed | `ws-setup`:60-61 | plausible selector for rule skills or review packs; otherwise drop it |
| 4 | **Nine keys are read only as English**, of which four are structural. `git_flow`, `git_flow.pr_into`, `git_flow.release`, `git_flow.forbidden`, `house_rules.commit_convention`, `house_rules.hooks`, and — the structural ones — `repos[].dir`, `repos[].owner`, `repos[].integration_branch`. Each is acted on and never named, so the schema and its readers are coupled by prose alone | ledger passes 1 and 2 return nothing for each of the nine | low priority on the first six; worth knowing before any rename, and worth knowing that renaming `dir` or `owner` would break nothing and be noticed by nothing |
| 5 | **Three interview answers have no key to land in.** `ws-setup` collects a one-line project description and a two-or-three-letter rule-skill prefix, and neither has a cartridge key; collaborators and handles land in `<state_dir>/me`, which is local and uncommitted | `ws-setup`:58-59, 99 | the prefix is the sharp one: `ws-fanout` briefs builders to load the `<prefix>-<area>` skills, and nothing in the cartridge says what the prefix is |
| 6 | **`github-projects` says to record ids in the cartridge without naming a key.** *"Get the ids once … and record them in the cartridge so this is not re-derived every session"* | `ws-shared/trackers/github-projects.md`:26-27 | the adapter should name the key, or the schema should define one |
| 7 | **`machine:` has no merge semantics.** The key is named and keyed off the device id, but no skill is documented as applying a device block over the top-level keys | `ws-shared/reference.md`:77, 188 vs. zero reader | decide whether `machine:` overrides keys or only carries notes, and write it down |
| 8 | **`tracker.markers` and `tracker.claim` have one defined value each.** `default` and `push`. The keys exist so a project can diverge; what else they accept is unspecified | `ws-shared/trackers/roadmap-files.md`:4 | either define a second value or document them as reserved |
| 9 | **`profile: lite` contradicts the tracker index.** `ws-setup` says a `lite` project gets *"no tracker"*, while `tasks-file` is documented as *"the `lite` default"* and the adapter index recommends it for `lite` projects | `ws-setup`:54 vs. `ws-shared/trackers/tasks-file.md`:3, `ws-shared/reference.md`:210 | one of the two should give. A `lite` project with a `TASKS.md` is the common case, so the `ws-setup` line is the likelier error |
| 10 | **`artifacts: in-repo` does not say which repo.** The path is `<repo>/implementation_plans/<id>/`, and on a multi-repo project nothing names the repo | `ws-shared/tracks.md`:38, `ws-plan`:50-51 | either a key, or a stated rule such as "the repo the task's first step touches" |
| 11 | **`tracker.statuses` has no schema.** The adapter names the key and never says what shape it takes, so two projects will write it differently and neither is wrong | `ws-shared/trackers/github-projects.md`:4 | the adapter should show the shape it expects |
| 12 | **Degrade behaviour is stated globally and almost never per key.** R1 and four per-skill no-cartridge behaviours are written down; individual keys are not, which is why most "missing →" cells on this page are marked *inferred* | `ws-shared/reference.md`:190, `ws-refine`:66-67 vs. the tables above | each *inferred* cell is one line a skill could state about itself |
| 13 | **Four sites append a second `/agent` to `docs_home`.** 27 sites across 13 skills treat `docs_home` as the agent directory itself; four treat it as the docs root and append `/agent`. `ws-shared/tracks.md` contradicts **itself** between :72 and :108. This is live, not theoretical: on a cartridge saying `docs_home: docs/agent`, `ws-fanout`:32 greps `docs/agent/agent/reference.md`, which does not exist — so its isolation check reads as `worktrees` absent and it takes the `false` branch | the dominant form: `ws-shared/reference.md`:187, `ws-start`:15, `ws-review`:15, `ws-setup`:111, `ws-ship`:100, `ws-plan`:44, `ws-verify`:52, `ws-debug`:13, `ws-task`:67, `ws-refine`:32, `ws-shared/tracks.md`:72. The four exceptions: `ws-fanout`:32, :136, :192 and `ws-shared/tracks.md`:108 | a pack defect, filed as its own task. The four sites should drop the extra `/agent` |
| 14 | **`tracker.lists` cannot name the done list.** The adapter defines `tracker.lists` as *"the names of the lists that mean open and in progress"* — two lists. It then instructs the agent to move a finished card *"where the team puts done cards"* and, for review, to **ask** where a finished card should go. So on every Trello project the two most common operations end in a question the cartridge is structurally unable to answer, once per card, forever. **This is the sharpest authoring gap on the page**: unlike `merge_style` it is not a missing key with an obvious shape — the key exists and its documented contract excludes the values a writer most wants to set | `ws-shared/trackers/trello.md`:3-4 vs. :48-53 | `tracker.lists` should take `done` and `review` alongside `open` and `in_progress`, or the adapter should say the asking is intended |

---

## See also

| Need | Read |
|---|---|
| The blank template `ws-setup` fills | [`skills/ws-setup/templates/cartridge.md`](../../skills/ws-setup/templates/cartridge.md) |
| A filled multi-repo cartridge | [`skills/ws-shared/examples/cartridge.md`](../../skills/ws-shared/examples/cartridge.md) |
| This repo's own cartridge | [`docs/agent/reference.md`](../agent/reference.md) |
| What a tracker adapter must answer | [`skills/ws-shared/trackers/`](../../skills/ws-shared/trackers/) |
| Tracks, the journal, the artifact lifecycle | [`skills/ws-shared/tracks.md`](../../skills/ws-shared/tracks.md) |
| Devices, stores, review packs, house rules | [`skills/ws-shared/reference.md`](../../skills/ws-shared/reference.md) |
| What is still to be written in this docs tree | [`docs/roadmap/P3-reference.md`](../roadmap/P3-reference.md) |
