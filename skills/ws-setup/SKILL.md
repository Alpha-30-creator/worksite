---
name: ws-setup
description: Set up or upgrade one project's agentic workspace - interview for the repos, tracker, git flow, environments and house rules, then generate the state directory, the cartridge, the workspace instruction files, the per-area rule skills and the agent-sync wiring. On a project that already has some of this it detects what exists, shows a table of what it would add or change, and waits for a yes. Ends with a project an agent can work in, and never with something overwritten that you did not approve. Use when starting a new project, onboarding an existing one, or bringing an older one up to the current workflow. Not for making this machine current, which is ws-sync.
---

# Set up a workspace

Ends with a project an agent can work in, and **never** with something overwritten that you
did not approve.

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md).
2. Work out where you are and what already exists:

```bash
ROOT=$(pwd)
echo "root: $ROOT"
[ -f .agent-sync.yaml ] && echo "agent-sync marker: $(sed -n 's/^project: *//p' .agent-sync.yaml)" || echo "no agent-sync marker"
git rev-parse --is-inside-work-tree 2>/dev/null && echo "root IS a git repo" || echo "root is not a git repo (good for multi-repo)"
for d in */; do [ -d "$d/.git" ] && printf '  repo: %-28s %s\n' "${d%/}" "$(git -C "$d" remote get-url origin 2>/dev/null)"; done
ls -d .*/ 2>/dev/null | grep -vE '^\.(git|claude|codex|cursor|agents|vscode|idea)/$'
# find distinguishes "searched it all, found nothing" from "could not descend" by its own exit
# code; throwing that away turns an unsearchable tree into the mode "new", and new on a
# configured project is the damaging answer. Checked on BSD/macOS find; GNU find documents the
# same non-zero-on-error contract, but that was not run here.
hits=$(find . -maxdepth 3 -name 'reference.md' -path '*agent*' 2>/dev/null); rc=$?
if [ -n "$hits" ]; then printf 'cartridge candidate: %s\n' "$hits"
  [ "$rc" -eq 0 ] || echo "(and the search was incomplete — there may be more)"
elif [ "$rc" -ne 0 ]; then echo "UNSEARCHABLE: could not descend under $ROOT — the mode is UNKNOWN"
else echo "searched $ROOT to depth 3, and found no cartridge"
fi
ls AGENTS.md CLAUDE.md 2>/dev/null
```

3. Pick the mode from what you found — and say which you picked and why:

| Found | Mode |
|---|---|
| A cartridge (`<docs_home>/reference.md` with frontmatter) | **upgrade** |
| Repos, maybe an `AGENTS.md`, but no cartridge | **adopt** — interview, but seed every answer from what is there |
| An empty or near-empty folder | **new** |
| `UNSEARCHABLE: …` | **none — stop.** You have not established there is no cartridge, and **new** on a configured project is the damaging answer. Say which path you tried, ask, re-run |

**The mode is inferred; the profile is not.** Those are two different questions and this table
answers only the first. Mode is *what is already here*, which the filesystem genuinely knows.
Profile is *how much writing this project will earn*, which it cannot — a folder with one repo in
it may be a weekend experiment or a product with five years ahead of it, and the shapes are
identical. Until p8.34 this table carried a row reading "one repo, throwaway or experimental →
lite", which guessed at intent from structure and never asked.

## The profile — one question, asked

Ask it before the interview, because it decides which interview you run and what gets written:

> **How much of the pack does this project want?** My recommendation is **standard**.
>
> - **lite** — the cartridge, the instruction files that point an agent at it, and a track
>   directory. **Six questions.** No tracker, no rule skills, no `risks/`. The loop runs; what it
>   cannot do is *claim* work or mark it done, because there is nothing to claim it on. For a
>   throwaway: the system must never cost more than the work is worth.
> - **standard** — all of lite, plus a tracker, and the git-flow and house-rule answers the loop
>   needs. **Fourteen questions.** The loop works end to end. No rule-skill family and no reference
>   docs tree until something earns one. For anything that will outlive the week.
> - **full** — all of standard, plus the per-area rule skills (`<rule_prefix>-<area>`) and
>   `rules/<area>.md`, a docs repo where there are several repos, and reference pages as they are
>   earned. **Twenty-one questions.** For several areas of work, or writing other people read.

**Say the cost of the answer, not just the name**, and the numbers above are the enumerated
questions below rather than an impression — six, fourteen, twenty-one. A project can move up the
ladder later: `ws-setup` in upgrade mode asks only the questions the next rung adds, which is why
the rungs are numbered continuously. Moving up is cheap; having started at `full` on a weekend
experiment is twenty-one questions where six would have done.

**One rung is not a repo count.** This pack's own project is a **single repo** and is `full`,
correctly: it earns `decisions/`, `records/` and `engineering/`. Repo count is in `repos:`; the
profile is about writing.

## The interview

Ask in order. **Every question carries your recommendation**, so "yes, next" is a valid answer
all the way through. Where the folder already tells you the answer, state it and ask only for
confirmation — never ask what you can read.

### Lite profile — six questions

1. Project id and what it is, in a sentence.
2. The repo (or repos), and its GitHub owner.
3. **Where the cartridge goes** — `docs_home`, ending `/agent`; for one repo that is
   `<repo>/docs/agent`. Asked on **every** rung, because every rung writes a cartridge and there is
   nowhere to put it otherwise. Propose the answer from the repo you found; it is a confirmation,
   not a decision. **If the folder holds several repos**, say which repo you are putting it in and
   why that one — on `lite` and `standard` that is the whole answer, since neither rung creates a
   docs repo. Only on `full` is it provisional, because question 17 may move the cartridge into a
   `<project>-docs` repo; say so there rather than here, where two rungs of three can never keep
   the promise.
4. Stack, and the commands for typecheck / lint / test / build. Read `package.json`,
   `pyproject.toml` or `requirements.txt` first and propose what you found.
5. Branch and PR flow, or "just commit to main".
6. AI attribution on or off.

Then generate and stop, writing **`tracker.kind: none`**, which the rung decides rather than a
question. It is not the only unasked value: the template also ships `artifacts`, `agents_file`,
`state_dir` and `worktrees`, and on this rung **say the four defaults out loud in one line** rather
than letting them arrive silently — `workspace-state`, `copy`, `.<project>`, `true`. The one that
must **not** be written unasked is `house_rules.owned_by`: question 11 exists because an unstated
`me` and a chosen `me` are the same value with different provenance, and writing it here would
collapse exactly that. On `lite`, leave it absent. `ws-start` has a stated path for it: no board
to read, so the task is written into `task.md` from the answer to "what is the work" rather than
copied from one. A `lite` project gets the cartridge, the instruction files that point an agent at
it, and a track directory — and **no tracker, no rule skills, no `risks/`**. It *does* get a
journal and a mirror, because the mirror depends on `docs_home`, which question 3 asks on every
rung; only a project with no `docs_home` has a local journal alone. The track loop still runs
locally; what it has nowhere to do is *claim* work, because there is no tracker to claim it on.
(So `lite` has no tracker **at all**: the pack's `tasks-file` adapter is **`standard`'s** default,
not this one.)

### Standard profile — fourteen questions

**Everything in lite, and then** — the numbering continues, so a rung is literally the rung below
plus its own questions:

7. **Tracker** — which kind, and where; this is the question that moves `tracker.kind` off `none`.
   Default `tasks-file` at `TASKS.md` in the docs home, which is the right answer for one person
   and one area of work; offer `roadmap-files` if the work
   already has phases, and a hosted kind if the project already has a board.
8. **The track directory** — `state_dir`, default `.<project>`. Say that the workspace root being
   a non-repo is what normally keeps it uncommittable, and that on a single-repo project it needs
   a `.gitignore` line instead.
9. **Worktrees** — `worktrees: true` unless each worktree would mean repeating a slow dependency
   install. Name that cost; it is the only real one.
10. **Where plans and journals live, and how the workspace instructions are deployed** — two keys
   the template ships and nothing asked until p8.34, which is the third time this task found that
   shape (`docs_home`, `git_flow.release`, these). Recommend both defaults and move on unless the
   answer is no: `artifacts: workspace-state` keeps plans and journals in `<state_dir>`, and
   `in-repo` instead puts the plan on the task branch — **a company convention on some projects**,
   and it also exempts the journal from being mirrored. `agents_file: copy` writes the workspace
   `AGENTS.md` as a copy refreshed by `ws-sync`; **never `symlink`**, for the reason in Generate.
11. **Merge style** — `squash`, `merge` or `rebase`, as the repo is actually set up. This is written
   rather than left absent, because `ws-ship` otherwise asks every time.
12. **House rules** — attribution, commit convention, hooks, and **`owned_by`**: `me` if these
    rules are yours to change, `company` if they are followed rather than authored. **Write the
    value even when it is `me`**: absent, it is *read* as `me`, so the guard that stops `ws-refine`
    proposing changes to rules you do not own never fires, and a decision and a gap nobody noticed
    become the same value with different provenance.
13. **Credentials**, if any — whether the project has env files worth syncing (`ws-env`).
14. **Environments** that exist *now*, and which do not exist yet — record the absent ones with
    a note rather than leaving them out, so a plan can say "this needs staging, which doesn't
    exist".

**What standard does not write**, and the reason is the pack's own living-docs rule: no
`rules/<area>.md`, no rule skills, no `risks/`, no `decisions/` or `records/` directory. Each of
those is created when it has a first thing to hold — `ws-review` writes `risks/` when it finds a
first risk, `ws-plan` names where a decision record goes when a decision is made. A seeded empty
folder is a promise, and the pack's rule is to write what is true now.

### Full profile — twenty-one questions

**Everything in standard, and then** — the numbering continues again. Until p8.34 this section was
a *parallel* list rather than an additive one, and three of standard's questions were missing from
it: `state_dir`, `worktrees` and `merge_style`. A ladder whose top rung silently drops questions
from the middle one is not a ladder, and the project this pack ships from had `merge_style`
unwritten for exactly that reason.

15. **`rule_prefix`** — two or three letters naming the rule skills, e.g. `nw` for northwind,
    giving `nw-backend`. **Required on this rung**, and it goes **into the cartridge**, not only
    into the directory names: `ws-fanout` briefs every builder to read `<rule_prefix>-<area>`
    skills and has nowhere else to look the value up. Until p8.34 it was asked here, used to name
    four things, and recorded nowhere.
16. **Repos, in detail** — this **expands question 2** rather than re-asking it: for each repo
    already named, add role (`backend` / `frontend` / `docs` / `infra` / `lab` / `legacy`) and
    integration branch. Propose both from what is on disk.

    Then: **is there anywhere else this project's work edits, that is not one of these repos?** A
    library a tool owns, a shared fixture store, somewhere a generated artifact is published from.
    Recommend **none** — most projects have none, and a wrong entry is worse than an absent one
    (R2). Each one the answer names becomes a `shared_stores:` entry: an `id`, a `$HOME`-relative
    `path` (**never an absolute home path** — the cartridge is committed and read on every
    machine), the single global command that publishes the **whole** store as `publish:` or `null`
    if there is none, and a `note`. It is read by `ws-fanout`, which runs one track per declared
    store per batch because a worktree isolates the repos above and nothing outside them.
    Declaring nothing is a real answer with a real cost: that gate can then see no further than
    `repos:`.
17. **A docs repo, if there are several repos.** Lite asked where the cartridge goes; this asks
    whether the project has earned a repo for its documentation:

    | Project shape | Docs home |
    |---|---|
    | one repo | `<repo>/docs/` — already answered on the lite rung |
    | several repos | a dedicated `<project>-docs` repo, cloned into the workspace |

    The docs repo may be in your own account even when the code repos are in a company
    organisation — that is the usual case, since the docs carry your way of working. **The
    cartridge is always `<docs>/agent/`.**

    No docs repo yet on a multi-repo project? Offer to create one (`gh repo create
    <project>-docs --private`), clone it into the workspace root, and `agent-sync link` stays
    pointed at the workspace.

    **Create the directories the project has something to put in, and no others** — the same rule
    that stops `risks/` being seeded. On a multi-repo `full` project that is `agent/` for the
    cartridge, plus the docs repo's own `README.md`, which has content the moment the project
    exists: what the repos are, and where each page lives. **`STATUS.md` is the tracker's**, on a
    `roadmap-files` project — it is `tracker.status_file`, and the adapter owns its shape. `decisions/`, `records/`,
    `runbooks/`, `engineering/`, `product/` and `integration/` are created by the step that writes
    their first page. See `../ws-shared/reference.md` for what each is for and whether it is living
    or immutable.

    **Never put docs in the brain.** `~/brain` keeps business decisions, people, meetings and
    contracts; anything describing the system goes in the docs.
18. **Stack per repo**, which **expands question 4** from one answer to one per repo. Read the
    manifests; propose; let them correct. A repo with no typecheck or no test runner is normal —
    record `null`, do not invent one.
19. **How a release happens, and which branches deploy.** Two facts, one question, and the second
    is a safety fact rather than trivia: `ws-ship` checks `deploy_branches` before every merge and
    says out loud whether that merge deploys, and its Releases section treats a release as a
    separate explicit act it needs `git_flow.release` to describe. Get both exactly right — the
    template ships `release:` with a placeholder, so an unanswered question leaves a placeholder in
    the cartridge rather than an absent key.
20. **Rule skills** — one per repo that has code, plus one for migrations if there is a schema.
    These are what `rule_prefix` names.
21. **Collaborators and handles**, if more than one person. Sets up `<state_dir>/me`.

An unfamiliar tracker is fine on any rung (R3): ask how to list, claim and close work, and offer
to write a new adapter into `ws-shared/trackers/`.

Where an answer is genuinely unknown, write `TODO:` into the cartridge. **Never invent a fact
to fill a field** — a wrong fact in the cartridge is worse than a missing one, because every
skill reads it.

## Generate

Show the full file list first and wait for a yes. Then, from `templates/`:

| Write | From | Profile | Notes |
|---|---|---|---|
| `<docs_home>/reference.md` | `templates/cartridge.md` | all three | the cartridge: frontmatter + prose |
| `<docs_home>/workspace/AGENTS.md` | `templates/workspace-agents.md` | all three | **the source** of the workspace instructions |
| `<root>/AGENTS.md` | copy of the above | all three | with the generated-by header |
| `<root>/CLAUDE.md` | `@AGENTS.md` | all three | one line |
| `<state_dir>/`, `<state_dir>/tracks/` | — | all three | and `me` if there are collaborators |
| the tracker's own file | the adapter | standard, full | `TASKS.md` for `tasks-file`; nothing to write for a hosted kind |
| the docs repo's `README.md` | — | **full, and only where question 17 created a docs repo** | what the repos are and where each page lives — content that exists the moment the project does. **Not `STATUS.md`**: that path is the tracker's `status_file` on a `roadmap-files` project, and "where the work stands" on a minutes-old project is the same promise-not-fact that keeps `risks/` unseeded |
| `<docs_home>/rules/<area>.md` | — | **full only** | one per rule skill; start from what the repo already does |
| `~/.agent-sync/store/skills/<rule_prefix>-<area>/SKILL.md` | `templates/rule-skill.md` | **full only** | thin: points at `rules/<area>.md` |

**Beyond this table, only what a question created** — the docs repo itself (question 17) and the `.gitignore` line below — **and that is a rule rather than an omission.** `risks/`, `decisions/`,
`records/`, `engineering/` and `worklog/` are written by the step that first has something to put
in them — `ws-review` on its first risk, `ws-plan` when it names where a decision record goes,
`ws-ship` at its first harvest. Until p8.34 this table wrote `<docs_home>/risks/common.md` from a
template and described it as *"seeded empty; grows via `ws-review`"*, which is a promise in a file
rather than a fact, and it is the pack's own living-docs rule broken by the generator that ships
it. A reader who opens an empty `risks/common.md` learns nothing except that someone intended
something.

The generated copy always starts with:

```
<!-- Generated by ws-sync from <docs_home>/workspace/AGENTS.md. Edit the source, not this. -->
```

**Do not use a symlink** even on macOS. Windows git checks a symlink out as a text file
containing the path, silently, and the agent then has no rules. See ws-shared.

**If the workspace root is itself a git repo** (single-repo projects), add `<state_dir>/` to its
`.gitignore` — the root being a non-repo is what normally keeps state uncommittable, and that
protection is absent here. Say so.

**Say where the worktree root lands, too, and say it for the single-repo case explicitly.** The
default is the workspace root's sibling — `<workspace>/../<project>-tracks` — so on a single-repo
project it is necessarily **outside** the workspace, because the workspace *is* the repo and the
only alternative puts every track worktree inside it. That is the right answer and it surprises
people, so it is stated at setup rather than discovered when a folder appears one level up. A
project that wants it elsewhere sets `worktree_root:`; see *The worktree root* in
`../ws-shared/tracks.md` for how a value is resolved.

Then wire it up:

```bash
agent-sync link <id>                      # registers this directory on this device
agent-sync include skill/<rule_prefix>-<area> --project <id>
agent-sync save                           # validate, deploy, commit, push
agent-sync status                          # expect no drift
```

If the workspace root is not a git repo, `agent-sync link` will say the marker cannot travel.
**Record that**: the other device needs `agent-sync link <id>` run there by hand.

## Upgrade / adopt mode

Never write first. Read, compare, show, wait.

1. **Read** what exists: the cartridge if any, `AGENTS.md`, the state dir, the skills already
   in the library for this project, `agent-sync status`.
2. **Compare** against what the current design would generate.
3. **Show one table** and stop:

```markdown
| Thing | Now | Would become | Action |
|---|---|---|---|
| cartridge | absent | <docs_home>/reference.md | add |
| AGENTS.md | symlink into docs repo | generated copy + source | change (Windows-safe) |
| tracker | roadmap files | unchanged | leave |
| state dir | .<project>/active-task.md | .<project>/tracks/<id>/ | migrate |
| `<rule_prefix>`-plan … `<rule_prefix>`-ship | project workflow skills | generic `ws-*` | retire after the loop lands |
| risks | inline in a project review skill's prompt | `<docs_home>/risks/common.md` | extract |
```

4. **Apply only what was approved**, one line at a time where the user wants that.

**Expect disagreements.** An older project's facts will have drifted from reality — a branch
that was renamed, an environment that now exists, a command that changed. When the cartridge and
the repo disagree, **the repo wins and the cartridge is corrected**; when you cannot tell, ask.
Do not quietly copy a stale fact forward.

**Migrating a singleton active task**: `<state_dir>/active-task.md` becomes
`<state_dir>/tracks/<id>/task.md` and `tracks/current` gets its id. Keep the old file until the
user confirms, then delete.

**Retiring project workflow skills** is the last step and needs its own yes, after the generic
loop has been used on a real task in that project. Never in the same change as the upgrade.

## Rules

- Degrade, never fail. A cartridge with only `project` and `repos` must work. Ship a partial
  cartridge rather than blocking on an unanswered question (R1).
- Never invent a fact. `TODO:` is a valid value; a wrong fact is not.
- Never overwrite a file the user has edited without showing the diff and waiting.
- Never create a symlink for an instruction file.
- Never propose changing `house_rules` when `owned_by: company` — and **say which branch you took**
  when the key is absent, because absent reads as `me` and that is the permissive one.
- Never touch a repo's own `AGENTS.md` / `CLAUDE.md` or its practices docs — those are repo
  changes and ship through a task, not through setup.
- No AI attribution in anything generated, including the library commit.
- Adding a tracker or a stack means adding a file in `ws-shared/`, never editing a skill (R4).

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-sync` — confirm the machine is current and the generated copies match their sources
- `ws-env` — bring this project's credentials into the store
- `ws-start` — claim the first task
- `ws-refine` — change a generic skill or this project's cartridge
