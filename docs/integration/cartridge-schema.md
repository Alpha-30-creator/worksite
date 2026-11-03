# The cartridge schema

A **cartridge** is one project's own facts, written where every `ws-*` skill can find them. The
skills are generic; the cartridge is what makes them act like they were written for your project.

This page is the format. It documents the schema **as the pack actually implements it**, which
means it also names the places where the schema and the pack disagree — see
[Known gaps](#known-gaps). Nothing here describes a key the pack does not read.

A cell that makes a **specific** claim — a stated default, a stated degrade behaviour, a quoted
rule — carries the quote and the file it came from, and a reader greps the quote, because line
numbers in this pack drift on every publish.

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
rules and per-device overrides (`ws-shared/reference.md`). The prose below it holds the
things a table cannot carry — the workspace layout, where to find what, the rules that override
an agent's defaults, and the open questions. Those four are what `ws-setup` writes; a project may
add sections of its own, and one worth knowing about is a home for items that have **stopped**
being open questions. Leaving a settled answer under *Open questions* is the commonest instance of
the tense defect the docs step looks for, and deleting it loses reasoning that is often
load-bearing.

**The division of labour matters.** Facts about *how to work on the project* belong here. Facts
about *the product* belong in the docs tree, and facts about the *system* belong in
`engineering/` or `decisions/` (`ws-refine` states both halves, and
`ws-shared/review/documentation.md`). A cartridge that starts explaining the product has absorbed something that will go stale in it.

**The prose half rots, and it rots from edits made elsewhere.** It is the only document in a
project whose staleness is caused by work that never touched it, so `ws-ship`'s **docs step**
(section 4, before the merge — not the harvest) re-reads four classes of row: anything naming a
task id, a phase, a path that does not exist yet, or a count. It asks whether each still *reads*
correctly rather than whether it is still true, and its closing line reports whether it ran. Two
rules for writing it so there is less to re-read:

- **Prefer a link to a decision record over a task id.** `(p8.30)` tells a reader which task
  changed a paragraph; it does not tell them why, and it stops resolving the moment the roadmap
  entry is archived or the file is renamed. A decision record is a document with a name, and
  linking it also puts the rejected alternatives one click away. Where there is no record behind
  the id, keep the id — an unresolvable citation is better than none, and it is a signal the
  reasoning was never written down.
- **Write what is true now, not what is planned.** A path named before it exists never fails: a
  bare path in a table cell is not a link, so no relative-link check sees it, and the row can
  outlive every commit without ever being right. If a path is aspirational, say so in the row.

Three things are **not** in the cartridge, and looking for them here wastes time:

| Fact | Where it lives |
|---|---|
| Where this project's workspace is *on this machine* | `~/.agent-sync/device.yaml` (`ws-shared/reference.md`) |
| Your handle, and your collaborators' | `<state_dir>/me` (`ws-setup`, `ws-shared/tracks.md`) |
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

That is a complete, valid cartridge. `ws-setup` is explicit: *"A cartridge with only
`project` and `repos` must work. Ship a partial cartridge rather than blocking on an unanswered
question."*

Everything in the rest of this page is **additive**. Each key you add buys one more thing a
skill can do without asking you; each key you leave out costs capability and nothing else.

---

## 3. The three rules that govern every key

Read these before the tables, because every cell below depends on them.

**R1 — Degrade, never fail.** A missing key means less capability, never an error
(`ws-refine`). No skill refuses to run over an absent key, and `ws-env` and `ws-sync` must
work with **no cartridge at all** (`ws-shared/reference.md`). **One stated exception, and it
is about the cartridge rather than a key:** `ws-fanout` stops when the cartridge cannot be *read*,
because it cannot otherwise tell isolation-off from cannot-tell, and the branch it would fall to
puts parallel builders in one working tree (`ws-fanout`). The four skills that say
out loud what they do with no cartridge do different things, and the difference is deliberate:

| Skill | With no cartridge | Cited |
|---|---|---|
| `ws-review` | works without it; asks three questions — which repos changed, what the change should do, what the stack is — and never refuses | `ws-review` |
| `ws-start` | offers `ws-setup` in adopt mode, then continues as best it can | `ws-start` |
| `ws-sync` | skips the generated-instructions step and says nothing | `ws-sync` |
| `ws-fanout` | **stops.** With no readable cartridge it cannot establish whether worktrees isolate the tracks, so it spawns nothing and asks for the right `docs_home` or offers `ws-setup`. With a cartridge that is merely *missing the key*, it offers to set it via `ws-refine` and refuses to invent a third option. The same gate reads [`shared_stores`](#shared_stores) the same way: unreadable stops the whole batch, while an absent key proceeds and costs the gate its view outside `repos:` | `ws-fanout` |

**R2 — `TODO:` is a valid value; an invented fact is not.** *"Never invent a fact to fill a
field — a wrong fact in the cartridge is worse than a missing one, because every skill reads
it"* (`ws-setup`). See [section 11](#11-absent-vs-null-vs-empty-vs-todo).

**R3 — Unknown keys are ignored.** A key the pack does not know is not an error
(`ws-refine`). You may add project-specific keys; nothing will read them, and nothing will
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
| **yes** | the cartridge is not usable without it. Only `project` and `repos` (`ws-setup`) |
| **conditional** | required once you want the feature it drives, or once its parent key is present |
| no | purely additive |

---

## 4. How to read the key tables

Every key table — sections 5 to 10, and section 12 — has the same six columns: **key**, qualified
by its parent; **type**, with the value set where one is defined; **required**, per the table
above; **default**, what a reader behaves as if the key said when the key is absent; **read by**,
the skills that consume it, marked *(by concept, not by name)* where a skill acts on the fact
without ever naming the key; and **missing →**, what happens when it is absent.

***inferred*** marks a cell derived from a reading skill's own instructions rather than stated by
the pack. A value the template writes is not a default either, and the tables say *template
ships `X`* instead: `worktrees` is the worked example, where the template ships `true` and an
absent key reads as **not** `true`.

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
| `profile` | `lite` \| `standard` \| `full` | no | none — *template ships* `standard` | `ws-setup`, which **asks** for it and never infers it from folder shape (p8.34); the rungs are read by concept by `ws-shared/trackers/tasks-file.md`, which names `standard` as the rung it is the default for. **No skill reads this key to decide what to do** — the rungs decide what `ws-setup` *writes*, and every skill downstream tests for the artefact rather than the value: `ws-review` creates `risks/` when it has a first risk whatever the profile says, and `ws-verify`, `ws-plan`, `ws-debug` and `ws-fanout` test whether that directory exists. Several of them **name** a rung in prose, to tell an agent an absence is expected rather than a gap — explanation, not a branch, and nothing parses the key | treated as `full`, so the full interview and the full artefact set apply — *inferred*. **`standard` is the rung added by p8.34**: cartridge, tracker, `state_dir` and the workspace `AGENTS.md`, without the rule-skill family or a reference docs tree. It is not a repo count — this pack's own project is a single repo and is `full` |
| `rule_prefix` | string, two or three letters | **conditional** — `full` requires it; `lite` and `standard` have no rule skills, so for them `null` is the correct value | none — *the template ships the key with no value, which is* `null`, and per [section 11](#11-absent-vs-null-vs-empty-vs-todo) that reads as "the thing genuinely does not exist" — true on the two lower rungs, and on `full` it means the interview did not finish | `ws-setup`, which names `<rule_prefix>-<area>` skill directories and the `agent-sync include` call from it; `ws-fanout` and `ws-plan`, which send builders to read those skills | **`ws-fanout` has nothing to brief with, and degrades by saying so** — it tells the builder there are no rule skills rather than naming files that do not exist, which is right on `lite` and `standard` and **wrong** on `full`. `ws-setup` on a `full` project with no value must ask before generating, since the skill directories are named from it and there is nothing to fall back to. Added by p8.34, when the value was asked in the interview, used to name seven things, and recorded nowhere — *stated* |
| `state_dir` | path, relative to the workspace root | **conditional** — the track loop needs it | none — *template ships* `.<project>` | `ws-start`, `ws-plan`, `ws-verify`, `ws-ship`, `ws-wrap`, `ws-task`, `ws-fanout` | no track directory, so no `tracks/current`, plan, journal or evidence — *inferred* |
| `docs_home` | path to the agent docs directory — **it ends `/agent`** | no | none | `ws-start`, `ws-plan`, `ws-verify`, `ws-wrap`, `ws-review`, `ws-ship`, `ws-setup`, `ws-refine`, `ws-fanout` | a project with a `state_dir` and **no `docs_home`** gets a local journal only, with no mirror and nothing on the other machine, said once when the track is created (`ws-shared/tracks.md`) — the rule keys off this key, not off the profile, which is what p8.34 corrected. What a **`full`** project without it does is *inferred*: the journal cannot be mirrored and `risks/`, `rules/` and `worklog/` have no location |
| `artifacts` | `workspace-state` \| `in-repo` | no | `workspace-state` — stated (`ws-shared/tracks.md`) | `ws-plan`, `ws-review`, `ws-ship` | `workspace-state` — plans and journals in `<state_dir>`, never in a repo (`ws-plan`) |
| `agents_file` | `copy` \| `include` \| `symlink`. **Never `symlink`**: *"Do not use a symlink even on macOS. Windows git checks a symlink out as a text file containing the path, silently, and the agent then has no rules"* (`ws-setup`) | no | none — *template ships* `copy` | `ws-sync` | the deployed `AGENTS.md` is not refreshed or drift-checked — *inferred* |
| `worktrees` | boolean | no | none — *template ships* `true`, and an absent key is **not** `true` | `ws-start`, `ws-plan`, `ws-fanout` | `ws-fanout` tests that the cartridge is **readable**, then greps `^worktrees:` (`ws-fanout`). Three outcomes, all stated rather than inferred: `true` proceeds; an **absent key reads as not-`true`**, so it takes the `false` branch and will not fan out without hard per-repo ownership; an **unreadable cartridge is a stop**, not that branch — spawn nothing, and the "different repos" option is disqualified by name because its own precondition is the unread `repos:` list (`ws-fanout`). **A worktree isolates the repos in `repos:` and nothing else** — a place outside them is declared in [`shared_stores`](#shared_stores) |
| `worktree_root` | path — absolute, `~`-relative, or relative **to the workspace root** | no | `<workspace root>/../<project>-tracks`, the workspace root's **sibling** — stated (`ws-shared/tracks.md`) | `ws-start`, `ws-shared/tracks.md` (retirement), `ws-setup` | the default is used, which is stated behaviour rather than a degrade. The value is **resolved to an absolute path once per session** and echoed; a relative value read against cwd instead of the workspace root is the defect this key exists to remove, since `../<project>-tracks` has two readings and **both exist in the wild**. The sibling is the default because on a **single-repo** project the workspace *is* the repo, so the other reading puts every track worktree inside it (`ws-setup`). Retirement substitutes it to find the `<id>/` directory git leaves behind, and to refuse to call a retirement `clean` while that directory is still there; with the key absent **and** `worktrees: false` there is no root and that step does nothing |

**`artifacts: in-repo` relocates the plan, and only the plan.** It goes to
`<repo>/implementation_plans/<id>/plan.md`, committed on the task branch, which is also how it
crosses machines — so no journal mirror is needed, `ws-review` looks for it there, and `ws-ship`
keeps it. The journal and the verify evidence stay ephemeral under `<state_dir>/tracks/<id>/` on
every project and are deleted at ship whatever `artifacts` says; "the journal is in the repo too"
is not expressible. It is a company convention on some projects: *"respect it; do not argue with
it"* (`ws-shared/tracks.md`). On a multi-repo project **nothing specifies which repo holds the
plan** — say so in the cartridge prose and keep it in one place.

**A rung is a smaller interview, not a smaller schema.** Six questions on `lite`, about twelve on
`standard`, about thirty on `full`, and each rung is the one below it plus its own questions
(`ws-setup`). No rung forbids a key: the schema is one shape and every key is read the same way
wherever it appears. What differs is what `ws-setup` **writes** — `lite` gets no tracker, no
journal mirror, no rule skills and no `risks/`; `standard` adds the tracker; `full` adds the rule
skills and `rules/<area>.md`.

So a `tasks-file` tracker key on a `lite` cartridge is still read normally, and it is also a sign
the project has outgrown that rung — `ws-setup` in upgrade mode adds what `standard` needs. Until
p8.34 this paragraph said the adapter index recommended `tasks-file` *for* `lite` while `ws-setup`
said `lite` gets no tracker, and left the contradiction on the page as a fact about the schema.

**`docs_home` ends `/agent`, and the path is the agent directory itself** — not the docs root.
`<docs_home>/reference.md` is the cartridge, `<docs_home>/risks/` the project's own review risks,
`<docs_home>/worklog/<id>.md` the harvest, `<docs_home>/workspace/AGENTS.md` the instruction
source and `<docs_home>/journal/<id>.md` the mirror. On a single-repo project that is
`<repo>/docs/agent`; on a multi-repo project, `<docs repo>/agent`. The `/agent` suffix is part of
the value in both files that **define** the key — `ws-setup/templates/cartridge.md` writes
`docs_home: <project>-docs/agent` and `ws-shared/examples/cartridge.md` ships
`northwind-docs/agent`.

**`state_dir` is never committed.** On a multi-repo project the workspace root is not a git repo,
which is what keeps it uncommittable. On a single-repo project the root *is* a repo, so
`ws-setup` adds `<state_dir>/` to its `.gitignore` — removing that line commits your track state.

`merge_style` is **not** a top-level key: it is [`git_flow.merge_style`](#8-git-flow), documented
with the rest of the flow.

### `shared_stores`

A place the project's work edits that is **not** one of the repos in `repos:` — a library a tool
owns, a shared fixture store, somewhere a generated artifact is published from. It exists for one
reason: a worktree is a checkout of a repo in `repos:`, so it isolates nothing outside them, and
without a declaration `ws-fanout`'s gate has no way to know such a place is there. The choice of a
top-level list, and the alternatives rejected, are in
[ADR 0003](../decisions/0003-shared-external-stores-are-declared-in-the-cartridge.md).

```yaml
shared_stores:
  - id: agent-library
    path: ~/.agent-sync/store
    publish: agent-sync save
    note: "one global save — validates, deploys to every agent, then commits and pushes the whole store"
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `shared_stores` | list of maps — **top level**, never nested inside `repos:` | no | none — *template ships* `[]` | `ws-fanout` | its gate sees no further than `repos:`, so two tracks editing the same place outside them pass as safe. Stated rather than inferred: an absent key and an empty list give the gate the same *"read, and no store declared"* answer, and that answer **proceeds** |
| `shared_stores[].id` | string, lowercase-kebab | **conditional** — once an entry exists | none | `ws-fanout` | the entry has no name to carry — not in the gate's classification, not in a brief, not in the `- Stores:` line the gate writes at claim time — so no track can be classified against it — *inferred* |
| `shared_stores[].path` | string, `$HOME`-relative — `~/…` or `${HOME}/…`, **never an absolute home path**. A store that genuinely moves per device has nowhere to say so: write a quoted `TODO:` and explain it in the cartridge prose (R2) | **conditional** — once an entry exists | none | `ws-fanout` | the other builders' briefs have no path to forbid by name — *inferred* |
| `shared_stores[].publish` | string \| `null`. One global command that publishes the **whole** store, so the first track to run it publishes the second track's half-finished edits. `null` is the positive statement *"shared, but nothing here pushes it anywhere"* | no | none | `ws-fanout` | the one-track-per-store cap still applies, on the same working-tree grounds as a shared checkout; what is lost is the command every *other* brief forbids by name — *inferred* |
| `shared_stores[].note` | string | no | none | `ws-fanout` | the owning builder is told it owns the store and not why it is shared — *inferred* |

`ws-fanout` is the only reader; `ws-setup` asks the question and its template ships
`shared_stores: []`. There is deliberately no `isolated_by_worktrees:` field — it could only ever
hold `false` — and the reasoning for all of it is [ADR 0003](../decisions/0003-shared-external-stores-are-declared-in-the-cartridge.md).

---

## 6. Tracker

`tracker:` is a map. One key selects the adapter; the rest are **conditional on that key** —
each kind has its own disjoint set, and a key from the wrong kind is simply ignored (R3).

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `tracker` | map | no | none | `ws-start`, `ws-task` | no board: nothing to list, claim or mark. The loop still runs — `ws-start` can be given a task by hand — *inferred* |
| `tracker.kind` | `github-projects` \| `roadmap-files` \| `trello` \| `tasks-file` \| `none` | **conditional** — required when `tracker` is present | none | `ws-start`, `ws-task`, and the adapter index in `ws-shared/reference.md` | an unknown or absent kind is not an error: ask the four questions in [`skills/ws-shared/trackers/`](../../skills/ws-shared/trackers/)`README.md` and carry on (`ws-shared/trackers/README.md`, `ws-start`) |

`kind` selects one file, and that file is the whole contract:

| `tracker.kind` | Adapter | Suits | Real claim lock? |
|---|---|---|---|
| `roadmap-files` | `ws-shared/trackers/roadmap-files.md` | a solo build with phases | yes — a pushed commit |
| `github-projects` | `ws-shared/trackers/github-projects.md` | a team, or anything already on issues | no |
| `trello` | `ws-shared/trackers/trello.md` | a board someone else owns | no |
| `tasks-file` | `ws-shared/trackers/tasks-file.md` | `standard` projects — one person, one area, no phases, anything small | yes — a pushed commit |
| anything else | ask the four questions, then write a new adapter | — | ask |

*(`ws-shared/reference.md`. "No real lock" means assigning is not atomic: re-read the
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

`markers` and `claim` each have exactly one defined value; the keys exist so a project can
diverge, and what else they would accept is not written down. The `default` marker set is `[ ]`
open, `[~]` claimed, `[r]` PR open, `[x]` done, `[-]` dropped, `[?]` blocked on a decision
(`ws-shared/trackers/roadmap-files.md`).

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
| `tracker.statuses` | map of this project's Status column names | **conditional** | none | the `github-projects` adapter | the adapter falls back to *"the project's 'to do' equivalent"* and asks which Status to list (`ws-shared/trackers/github-projects.md`) |
| `tracker.assignee_default` | string — a GitHub login | no | none | the `github-projects` adapter — marked optional at `github-projects.md` | scope is asked for instead: mine, someone else's, or everyone (`github-projects.md`) |

`statuses` and `assignee_default` are the adapter's own two optional keys. **The adapter gives
`statuses` no schema**, so the map above is one legible way to write it rather than a format the
pack recognises. Keep the column names exactly as the board spells them — the adapter resolves
them by name.

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
holds two lists and only two** — open and in progress; there is no key for the done or review
list, which is the sharpest hazard on this page for a Trello project ([Known
gaps](#known-gaps)). Credentials never go in the cartridge — they come from the shell env or
`ws-env` (`trello.md`).

### `kind: tasks-file`

```yaml
tracker:
  kind: tasks-file
  path: TASKS.md
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `tracker.path` | path to the single tasks file | no | `TASKS.md` in the docs home or the repo root (`ws-shared/trackers/tasks-file.md`) | the `tasks-file` adapter | `TASKS.md` in the docs home or the repo root (`tasks-file.md`) |

### `kind: none`

No further keys. `none` is a listed value of `kind` — it is in `ws-setup`'s template, and it is
what a **`lite`** project is generated with, since that rung asks no tracker question. **No adapter
file exists for it, by design, and that is not the unknown-kind path**: `ws-start` states what to
do instead — say there is no tracker, ask what the work is, and write it into `task.md` rather than
copying it from a board. What such a project has given up is the claim lock, which matters only
where someone else might take the same work (p8.34; before that, a `lite` project fell into the
unknown-kind path, whose remedy is to write an adapter for a tracker that does not exist).

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
| `repos[].role` | `backend` \| `frontend` \| `docs` \| `infra` \| `lab` \| `legacy` | no | none | **nothing reads this** — the vocabulary appears only in `ws-setup`'s interview (`ws-setup`) | no effect — *inferred* |
| `repos[].integration_branch` | string — the branch work merges into | no | none | `ws-start`, `ws-plan`, `ws-ship`, `ws-review`, `ws-sync` *(by concept, not by name)* | `ws-review` has no branch to diff against and `ws-start` cannot report "not on its integration branch" — *inferred* |
| `repos[].deploy_branches` | map, `branch: environment`. `{}` means nothing deploys | no | `{}` — *inferred*, and **unsafe to rely on** | `ws-ship` | **see the callout below** |
| `repos[].stack` | list of tags | no | `[]` — *inferred* | `ws-plan`, `ws-review`, and the twelve packs under `ws-shared/stacks/` | tiers 1 and 3 of the review still apply, so no stack pack is selected: *"a tag with no pack is fine… degrade, never fail"* (`ws-shared/reference.md`) |
| `repos[].commands` | map, name → shell command or `null` | no | `{}` — *inferred* | `ws-verify`, `ws-review`, `ws-fanout` | nothing to run as that repo's own checks, so verification rests on the evidence per criterion alone — *inferred* |

**A dedicated docs repo is one of the `repos:` entries**, with `role: docs` and usually an empty
`deploy_branches` and `commands` — see the multi-repo
[example](../../skills/ws-shared/examples/cartridge.md). `docs_home` then points **inside** it:
`<docs repo>/agent`.

> **An absent `deploy_branches` is the one unsafe omission.** `ws-setup` calls which branches
> deploy *"a safety fact, not trivia; get it exactly right"*, and `ws-ship` checks it before
> merging and says out loud whether the merge deploys and where. An absent key is
> indistinguishable from `{}` — "nothing deploys" — so a merge that does deploy goes through
> announced as safe. Write `{}` when nothing deploys, and write the map when something does.
>
> Map **only** the branches that deploy; a branch that exists and deploys nothing is simply not a
> key. Where the answer is unknown, R2 applies: `deploy_branches: "TODO: ask who owns the deploy"`
> is a question a skill must raise, where `{}` is an assertion it will act on.

### `commands` in detail

`ws-verify` runs these as the repo's own checks and **prefers `verify` where the repo has one**;
otherwise it runs them individually, batched into one call. `ws-review` runs the same set and
reports pass/fail, never fixes. **`null` is the right value for a check the repo does not have**:
*"a `null` command means the repo genuinely does not have that check — say so rather than
inventing one"* (`ws-verify`).

| key | read by | note |
|---|---|---|
| `commands.verify` | `ws-verify`, `ws-review` | one command that stands for the lot. Preferred when present |
| `commands.typecheck`, `.lint`, `.test`, `.build` | `ws-verify`, `ws-review` | the standard four |
| any other name | `ws-verify`, `ws-review` (as *"plus `extra`"*), and the stack packs | **either** signal selects the `migrations-sql` pack: a `migrations` stack tag, **or** the repo having `commands.migration` at all (`ws-shared/stacks/migrations-sql.md`). Neither is needed when the other is there |

### `stack` in detail

Tags select the tier-2 review packs, and `ws-plan` reads the same packs while planning so the
work is designed against the rules it will be judged by. **A reader cannot invent a tag that
works**, so the table is reproduced here in full; `ws-shared/reference.md` is the live copy and
the list grows:

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

Twelve packs, nineteen tags; a pack is read once per review, not once per tag. **A tag outside
the list is still legal and still worth writing** — it selects no pack, which costs nothing, and
it is the signal that a pack should exist. So tag the repo with what it actually is. Tags are
also the only machine-readable place a technology is named: a language or runtime version that
matters goes in the cartridge prose under "Rules that override defaults".

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
  merge_style: squash
  release: "PR from dev into main; merging main deploys production"
  forbidden:
    - force-push to dev or main
    - "--no-verify"
```

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `git_flow` | map | no | none | `ws-setup` collects it; the generated workspace `AGENTS.md` renders it wholesale *(by concept, not by name)* | the workspace instructions lose their git-flow section — *inferred* |
| `git_flow.branch_pattern` | string; the placeholders are `<type>`, `<id>`, `<slug>` | no | none | `ws-plan`, which names the branches per repo from it (`ws-plan`) | `ws-plan` has no pattern to form branch names from and must ask or invent — *inferred* |
| `git_flow.pr_into` | string — a branch name, or the literal `integration_branch` to mean each repo's own. **Prefer the literal** — see below | no | `integration_branch` — *inferred* | `ws-ship`, which opens the PR `--base <integration>` *(by concept, not by name)* | each repo's `integration_branch` — *inferred* from `ws-ship`, which speaks only of "the integration branch" |
| `git_flow.merge_style` | `squash` \| `merge` \| `rebase` | no | none — *template ships* `squash` | `ws-ship`, at the merge step | `ws-ship` asks, or takes the repo's own default, **once per ship forever**. Added to the template by p8.34: the key was read with nothing writing it, so every project sat permanently in the missing case, and its parent was unstated — it is `git_flow`, because the merge is part of the flow rather than a property of one repo — *stated* |
| `git_flow.release` | string, free prose — how a release happens | no | none | `ws-ship`, whose Releases section treats a release as a separate explicit act *(by concept, not by name)* | `ws-ship` has no release procedure to follow and must ask — *inferred* |
| `git_flow.forbidden` | list of strings — actions never to take in this project | no | `[]` — *inferred* | `ws-fanout`, which carries the project's overriding rules into every build brief *(by concept, not by name)* | the pack's own universal bans still apply — never `--no-verify`, never `git add -A`, no force-push (`ws-ship`, `ws-fanout`) — but nothing project-specific is passed on — *inferred* |

**Prefer `pr_into: integration_branch` over naming a branch, even when every repo uses the same
one.** `repos[].integration_branch` is read for more than the PR base — `ws-review` diffs against
it, `ws-start` reports a repo that is not on it, `ws-plan` reads the code as it stands on it — and
`pr_into: develop` wires none of that up. Nothing errors if the two disagree; the review simply
diffs against the wrong branch.

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
| `environments` | map, name → one-line description | no | `{}` — *inferred* | `ws-debug`, which establishes which environment a failure is in before theorising (`ws-debug`) | `ws-debug` asks which environment instead — *inferred*; `ws-debug` reads the key and does not state the fallback |

**Record the environments you know do not exist, rather than leaving them out** — with a note
saying so — *"so a plan can say 'this needs staging, which doesn't exist'"* (`ws-setup`):

```yaml
environments:
  local:      "http://localhost:3000"
  staging:    "does not exist — nothing between local and production"
  production: "https://example.com — deploys from main"
```

That applies to an environment you have **established** does not exist. One nobody has mentioned
gets a quoted `TODO:` naming the question, or no key at all — writing "does not exist" for an
environment you merely were not told about asserts a fact you do not have (R2). And
`environments: {}` where nothing is deployed is accurate, not unfinished.

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
| `house_rules` | map | no | none | `ws-ship`, `ws-refine`, `ws-setup`, `ws-fanout` | the pack's own universal house rules still apply (`ws-shared/reference.md`) — *inferred* |
| `house_rules.ai_attribution` | boolean. **Writing `false` is equivalent to omitting the key** — see below | no | none — *template ships* `false` | `ws-ship` | the pack bans AI attribution in every commit and PR unconditionally (`ws-shared/reference.md`), so an absent key behaves as `false`. `ws-ship` acts on it only in the `false` direction; **nothing in the pack describes what `true` would do** — *inferred* |
| `house_rules.owned_by` | `me` \| `company` | no | none — *template ships* `me` | `ws-setup`; `ws-refine` | treated as `me`, so `ws-refine` may propose changing the house rules. `company` means *"the rules are followed, not authored"* and `ws-refine` must never propose changing them — *inferred* |
| `house_rules.commit_convention` | string, e.g. `conventional` | no | none | `ws-fanout`, into every build brief; `ws-setup`, in the interview *(by concept, not by name)* | no convention is passed to a builder — *inferred* |
| `house_rules.hooks` | string, free prose — what the repo's hooks do and how to enable them | no | none | `ws-ship` and `ws-wrap`, which both state that hooks always run and are never bypassed *(by concept, not by name)* | an agent does not know a hook exists, or how to enable it — *inferred* |

**`ai_attribution: false` changes nothing, and is worth writing anyway.** The ban is already
unconditional, so the absent key and the explicit `false` behave identically; the template writes
it so an agent meets the house rule in the project's own file rather than two files away. It is
the one key on this page where writing the default is purely documentary.

> **`owned_by` fails in the permissive direction, and that is the second unsafe omission on this
> page.** `company` is the switch that stops `ws-refine` proposing a change to rules you do not
> own (`ws-refine`, `ws-setup`). Absent — or holding a `TODO:` — it is read as `me`,
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
| `null` | the thing genuinely does not exist | say so, and **not invent a substitute** (`ws-verify`) |
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
(`ws-setup`). Two consequences:

- **A `TODO:` is a question, not a value.** A skill that meets one asks rather than proceeding on
  it. No skill in the pack is documented as detecting the `TODO:` prefix, so in practice it is
  read by the agent reading the cartridge — which is also how it should be treated.
- **A cartridge with `TODO:` values ships.** It is not a draft to be held back: R1 says ship the
  partial cartridge rather than blocking on the unanswered question (`ws-setup`).

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
on that machine. `ws-shared/reference.md` is the authority: *"`device:` … this device's id;
`machine:` overrides in a cartridge key off it"*. The device id is per machine and does not
travel: a workspace root is not a repo, so `.agent-sync.yaml` is not committed anywhere and
*"the id has to be typed correctly on each machine"* (`ws-shared/new-device.md`).

| key | type | required | default | read by | missing → |
|---|---|---|---|---|---|
| `machine` | map, device id → map | no | `{}` — *inferred* | `ws-shared/reference.md` — which every `ws-*` skill reads first *(by concept, not by name)* | no per-device facts; everything resolves from the top-level keys — *inferred* |

**What may be overridden is not specified, and no skill is documented as merging a `machine:`
block over the top-level keys** — so the dependable use is **a per-device `note:`, read by whoever
reads the cartridge**, which is what the pack's one worked example carries. Treat a device block
that redefines a top-level key as a statement to a human reader, not as a merge the pack
performs. **Concretely: writing `machine.<device>.repos[].dir` does nothing** — no skill merges it,
nothing warns, and the top-level `repos[].dir` is what every skill reads. That is the shape to
avoid, and it is named here because a map keyed by device looks like an override mechanism and is
not one. What belongs here is only what is true of the *machine*: a platform difference, a tool
that is absent there, a path convention. Workspace paths never do — those come from
`device.yaml`, and *"always resolve a workspace path from there. Never hardcode one"*
(`ws-shared/reference.md`).

---

## 13. A complete cartridge, annotated

Every key on this page, on a single-repo project with a `roadmap-files` board — `full`, so it
carries `rule_prefix`, which that rung requires. The two in-repo
examples — [this repo's own cartridge](../agent/reference.md) and the multi-repo
[northwind example](../../skills/ws-shared/examples/cartridge.md) — are the other two shapes
worth reading.

```yaml
---
schema_version: 1               # nothing reads it; a version marker for a future reader
project: meridian               # REQUIRED. Matches the agent-sync project id
profile: full                   # lite | standard | full. Asked, never inferred from folder shape.
                                # A rung is a smaller interview, not a smaller schema
rule_prefix: md                 # full only, and REQUIRED there: names md-api, md-web, md-migration.
                                # ws-fanout briefs builders to read them and looks the value up here
state_dir: .meridian            # local, ephemeral, gitignored. Holds tracks/<id>/
docs_home: docs/agent           # single repo, so the docs live in it. Always ends /agent
artifacts: workspace-state      # workspace-state (default) | in-repo
agents_file: copy               # copy | include | symlink. copy — never symlink
worktrees: true                 # each track its own checkout; required for ws-fanout
worktree_root:                  # optional. Default: <workspace>/../<project>-tracks — the
                                # workspace root's sibling, resolved absolutely once per session

shared_stores:                  # places the work edits that are NOT repos below. [] = none, the
  - id: agent-library           # usual answer. ws-fanout runs one track per declared store per batch
    path: ~/.agent-sync/store   # $HOME-relative, never an absolute home path
    publish: agent-sync save    # the ONE global command that publishes the whole store; or null
    note: "deploys to every agent, then commits and pushes the whole store"

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
  merge_style: squash                    # ws-ship's merge; written so it stops asking per ship
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

The four prose headings come from the template (`ws-setup/templates/cartridge.md`).
**Nothing in the pack enforces them** — the frontmatter is what skills parse, and the prose is
read by an agent, so a heading missing is a gap in what the agent is told rather than a format
error. They are not decoration, though. "Rules that override defaults" is where an agent's own habits get
overridden, and "Open questions" is where a known unknown goes instead of being assumed away.

---

## Known gaps

**One** place where the pack and the schema do not line up in a way a cartridge author has to know
before writing a value. It is a candidate for `ws-task`, and it should not be closed by writing
documentation for a key that does not exist.

- **`house_rules.owned_by` still degrades to the permissive branch**, and p8.34 narrowed this
  rather than closing it. Absent — or holding a `TODO:` — it reads as `me`, so `ws-refine` may
  propose changes to rules you do not own. What changed is that **both sites that read it now say
  which branch they took**: `ws-refine` states "`owned_by` is not set, so I am treating these as
  yours to change" before it proposes anything, and `ws-setup`'s house-rules question
  says to write the value even when it is `me`, and says why. *Reversing* the default was considered and rejected — it would turn a silent
  permission into a silent refusal, which is not obviously better and is harder to notice. Write
  the value: a decision and a gap nobody noticed are otherwise the same value with different
  provenance.

Two rows left this section on 2026-11-03 and neither is a gap any more, so neither is listed:
`merge_style` is written by the template and documented under `git_flow`, and `rule_prefix` is a
key. **A project generated before that date still has neither**, so `ws-ship` asks for a merge
style and `ws-fanout` reports no rule skills to brief — both correct degrades, and `ws-setup` in
upgrade mode writes the keys.

`tracker.lists`' inability to name the done list is a **boundary rather than a mismatch** and lives
in [`records/known-limitations.md`](../records/known-limitations.md). This page carried a parallel
copy of it; two copies of one finding is how they come to disagree.

## See also

| Need | Read |
|---|---|
| The blank template `ws-setup` fills | [`skills/ws-setup/templates/cartridge.md`](../../skills/ws-setup/templates/cartridge.md) |
| A filled multi-repo cartridge | [`skills/ws-shared/examples/cartridge.md`](../../skills/ws-shared/examples/cartridge.md) |
| This repo's own cartridge | [`docs/agent/reference.md`](../agent/reference.md) |
| What a tracker adapter must answer | [`skills/ws-shared/trackers/`](../../skills/ws-shared/trackers/) |
| Tracks, the journal, the artifact lifecycle | [`skills/ws-shared/tracks.md`](../../skills/ws-shared/tracks.md) |
| Devices, stores, review packs, house rules | [`skills/ws-shared/reference.md`](../../skills/ws-shared/reference.md) |
| Why a shared external store is declared here | [ADR 0003](../decisions/0003-shared-external-stores-are-declared-in-the-cartridge.md) |
| What is still to be written in this docs tree | [`docs/roadmap/P3-reference.md`](../roadmap/P3-reference.md) |
