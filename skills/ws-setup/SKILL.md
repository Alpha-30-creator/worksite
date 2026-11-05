---
name: ws-setup
description: Set up or upgrade one project's agentic workspace - interview for the repos, tracker, git flow, environments, house rules and the managed services the agent itself must drive, then generate the state directory, the cartridge, the workspace instruction files, any credential file those services need, the per-area rule skills and the agent-sync wiring. On a project that already has some of this it detects what exists, shows a table of what it would add or change, and waits for a yes. Ends with a project an agent can work in, and never with something overwritten that you did not approve. Use when starting a new project, onboarding an existing one, or bringing an older one up to the current workflow. Not for making this machine current, which is ws-sync.
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
question. **`services: []` and `agent_env: null` go in the same way**: question 13 is `standard`'s,
so this rung writes no credential file — say in one line that a service the agent must drive gets
declared by re-running `ws-setup` in upgrade mode, and that `ws-env init` is what creates a store
if there is none yet. It is not the only unasked value: the template also ships `artifacts`, `agents_file`,
`state_dir` and `worktrees`, and on this rung **say the four defaults out loud in one line** rather
than letting them arrive silently — `workspace-state`, `copy`, `.<project>`, `true`. The one that
must **not** be written unasked is `house_rules.owned_by`: question 12 exists because an unstated
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
13. **Credentials, and the services the agent will have to drive** — one question with two
    halves. First: does the project have env files worth syncing (`ws-env`)? Those are the
    *application's* credentials. Second, and new: **which managed services will the agent itself
    have to operate** — the host, the database platform, the queue, whatever the project actually
    runs on. **Offer nothing and name nothing**: the user lists them in their own words, and this
    skill holds no list of services to prompt with. Then run *Services, and how the agent reaches
    them* below, once per service, before you generate anything.
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

## Services, and how the agent reaches them

Question 13's second half, worked once per service the user named. It ends with a `services:` row
per service, possibly a credential file, a section in the generated `AGENTS.md`, and a pass/fail
line per service that was **run** rather than assumed.

**This skill knows no services, and that is deliberate.** A table of them here would do two
things, both bad: scope a project to whatever was in the table, and go stale at the rate those
services change their CLIs and their auth. What is generic is not *which* services exist but
**what shapes access takes**, and there are four.

### 1. Research each one, and establish rather than assume

For each service the user named, work out how an agent operates it **from the service's own
current documentation**, not from memory. You are looking for: is there a CLI; how does it
authenticate; what exactly does the agent need in its hands; and what read-only command proves
that access works.

**Never assume a CLI is signed in.** That is the failure this section exists to prevent: a CLI on
`PATH` looks like working access and is not, and the first thing to find out is a failed deploy
mid-task. Where a CLI is present, **run its check command** and read the result.

Where you cannot establish how access works — the documentation is unclear, the service is
internal, the answer depends on a plan tier you cannot see — that is `TODO:` in the cartridge and
a question to the user (R2). **Never invent a credential name**: a wrong variable name is worse
than an absent one, because the user will paste a real token into it.

**A service often offers more than one way in, and the row records the one *this project uses*.**
Measured while this section was written: of two widely used platforms researched from their own
current documentation, **both** supported a signed-in CLI session *and* an environment-variable
token. So the question is never "which kind is this service" — it is "which kind is this project
on", which depends on what the human already has. Someone who signed the CLI in last year is
`cli-session` and needs nothing; the same service on a machine that has never seen it may be
`token`. Record the one in use, say in a clause why, and leave the alternatives out: a row listing
two mechanisms is a row nothing can check.

**Two rules about *how* you research and test, and both are there because of what the agent can do
to itself:**

- **Never run the human's login step yourself.** An interactive login is a browser or
  device-code flow, and running one from an agent session either hangs it waiting for input it
  cannot give or opens a flow the human has to finish anyway. `human_step` is a line you
  **print**. This was measured as a real hazard during this section's own research: one platform's
  interactive login is documented by a third party as hanging an agent harness outright.
- **Never put a credential on a command line, in `check:` or anywhere else.** Arguments reach
  shell history and the process list, where a token outlives the command. Every CLI worth
  recording reads its credential from the environment; `check:` is a bare command, and the
  credential arrives via `set -a; source …; set +a`.
- **A service whose `check:` is `null` reports `UNPROVED`, never `ok`.** That is the honest output
  for a service with no read-only way to ask, and it is the same word 3b uses.
- **Record only a read-only `check:`, and refuse anything else.** `ws-sync` runs whatever is in
  that key, unprompted, on every machine catch-up — so a `check:` that deploys, writes, migrates,
  deletes or costs money is **refused here**, at the only point where a human is in the
  conversation. A service whose only proof of access is a write has **no** check: record `null`,
  and let the report say `UNPROVED` rather than recording something that will be run.

### 2. Conclude which of the four kinds it is

The kind is **your conclusion, which the user confirms** — not a question they answer, because it
is a fact about the service and they are entitled to not know it.

| `access:` | What it means | What it needs from the human | What gets written |
|---|---|---|---|
| `cli-session` | a CLI the human signs in once, which then holds its own session | one `… login`, once per machine, **in their own terminal** | the CLI, its check, the login step. **No credential and no file** |
| `token` | the service issues a credential the agent carries | create it, paste it, once | a block in `<state_dir>/env/agents.env` with the value **empty** |
| `runtime-var` | the credential the control plane needs is already in a runtime env file | nothing | `credential:` for the variable's **name** and `env_file:` for the file that already holds it. Nothing new is created |
| `none` | no programmatic access — a dashboard, a console, a human-only flow | the operation itself, every time | that the agent **stops and asks**, which is the correct behaviour rather than a gap |

`none` is an answer. A service recorded that way makes an agent ask for a deploy instead of
hunting for a way to do it itself, which is the behaviour you want and the opposite of what an
absent row produces.

### 3. Record it in the cartridge

One row per service under `services:`, per the schema page. The two keys worth saying out loud
when you fill them:

- **`scope:`** — what that credential can reach, in a clause. The user is about to paste it; what
  it can touch is the fact they need and the one nobody writes down.
- **`source_of_truth:`** — where the live values actually are. For a hosted service it is the
  dashboard, and the file in the workspace is *a copy, so nobody is ever locked out of knowing
  what is configured*. A credential file that does not say this gets half-believed.

Also propose the **`stack:` tags** those services imply, since those are what select the review
packs — a managed Postgres with row-level security and a serverless host both have rules already
written, and a tag is how a review finds them.

### 4. Write a credential file only if something needs one

**A project whose services are all `cli-session`, `runtime-var` or `none` gets no file and no
folder**, and `agent_env: null` is the complete answer. Say so rather than creating an empty file:
an empty credential file is a promise, which is the same rule that keeps `risks/` unseeded.

Where at least one service came out `token`:

| Write | What it is |
|---|---|
| `<state_dir>/env/agents.env` | **only** the agent's own credentials, one block per `token` service, **every value empty** |
| `<state_dir>/env/README.md` | generated: a file / where-it-goes / is-it-secret table, the loading line, and the source-of-truth sentence |

**`env/` rather than the state dir root**, and the reason is not cosmetic: reading
`<state_dir>/*.md` is a routine agent habit — the journal, `task.md`, `plan.md` — and a secret must
never be in the path of a habit. One subdirectory keeps the two apart.

**No new ignore rule is needed and none is added.** The state dir is already uncommittable, and
`ws-start` asserts that on every single run rather than trusting it. On a single-repo project the
`.gitignore` line this skill already writes is what provides it — say that out loud here, because
on that layout the line is the only thing between a pasted token and a public commit.

The file is **written once and appended to**. It holds values the human typed, so a later service
adds a block and nothing already in the file is rewritten, re-ordered or diffed into. **The agent
writes no value, ever** — not a placeholder that looks like a value, not a token it found in
another file, not one it generated.

The loading line goes in the generated README and is the one an agent will need later:

```bash
set -a; source "<state_dir>/env/agents.env"; set +a   # export everything defined from here on, then stop
```

The `is-it-secret` column is honest rather than uniformly alarming. A publishable or anon key that
is compiled into a browser bundle is **not** a secret — anyone who opens the site has it, and what
protects the data is the service's own row-level rules. Marking it secret teaches the user to
ignore the column.

### 5. Then prove it, and say what the human must do

Close the services step with two short blocks, in this order:

```
services, checked just now:
  <service>   cli-session   `<check>`   ok — signed in as <account the command printed>
  <service>   cli-session   `<check>`   NOT SIGNED IN — run <human_step>
  <service>   token         `<check>`   NOT YET — <VAR> is empty in <path>
  <service>   token         `<check>`   CLI MISSING — <install>
  <service>   <any>         `<check>`   CHECK FAILED (exit <n>): <the command's own last line>
  <service>   <any>         `<check>`   TIMED OUT after <n>s — it wanted input or kept polling
  <service>   <any>         —           no check recorded, so access is UNPROVED, not ok
  <service>   none          —           no programmatic access; the agent will ask you

what you need to do, once:
  1. run `<cli> login` in your own terminal                      (<service>)
  2. install the CLI: <install>                                  (<service>)
  3. create a token at <url> and paste it into <path> as <VAR>   (<service>)
```

Eight shapes, of which **seven** are `ws-sync` step 3b's too, because the two reports answer the
same question on different days. Exactly one is this report's alone: `NOT YET`, the only moment
where a value has not been pasted *yet* — on any later day that is simply a check that fails. (3b
has an eighth of its own, for a row with no `access:` at all, which cannot happen here because this
step is what writes the row.)
Run each check the way 3b does — **run each check the way 3b does**, with stdin at `/dev/null` and
bounded in time. Measured there: a real platform CLI, installed and unauthenticated, blocks
indefinitely on its own login prompt. A check that times out is not a pass and is not a machine
problem; it means the `check:` can prompt, so record one that cannot, or `null`. **`CLI MISSING` is the common first run**, not an edge case: a project
is usually set up before its tooling is installed, and a report with no shape for it either says
nothing or says `ok`. Where the check exits non-zero for a reason none of these covers, print the
exit status and the command's own last line rather than a guess at what it meant.

The first block is **run, not asserted** — an agent reporting access it did not test is the exact
shape this pack exists to refuse. A check that fails is not a setup failure: it is the correct
output of a setup where the human has a step left, which is why the two blocks are adjacent.

**Then say how the credential reaches the second machine, because nothing else will.** A pasted
token lives in one file on one laptop until it is encrypted into the store: `ws-env push` adds the
`manifest.tsv` row for `agent_env`, and `ws-env init` offers that row when it is the step that
created the store. Name the command in the same breath as asking for the paste — the definition is
`ws-env`'s *init* section and this is a pointer at it, not a second copy — and say it only **after**
a value exists, because a row whose file is still empty decrypts to blanks and overwrites a
filled-in copy on the next `pull`.

The operations a service must **never** be driven through from a local machine — a deploy that
belongs to CI, a migration against production — go in `forbidden:` on the row, and from there into
the generated `AGENTS.md`, where every later session meets them without being asked.


## Generate

Show the full file list first and wait for a yes. Then, from `templates/`:

**One generated block is shown in full rather than by filename: the `AGENTS.md` template's *How to
work with me* section.** Every other thing here is a fact about the project that the interview
already settled, so naming the file is enough. That section is the only one written for the
**person** — how they want to be talked to — and it is the one whose words they will want to
change. So say them, and ask:

> I'm going to put this at the top of `AGENTS.md`, above *Start here*. These six are defaults, not
> house style — tell me what to change:
>
> *(the six bullets, verbatim)*
>
> Anything you want different, or anything to add? Rules that are about **you** rather than the
> project belong here: how to address you, a writing convention for anything you will send, a
> format you want answers in.

**It is shown, not asked as an open question.** "How do you want to be talked to?" gets an empty
answer or a vague one from most people, and a vague section is worse than none: an agent reads it
and acts on it. Six concrete defaults get edited; a blank prompt gets skipped. The same reason
every other question here carries its recommendation.

**Write them even if the user says nothing.** The defaults are true for anyone — they are the
pack's own rules about reporting, stated to the agent in plain words rather than left implicit in
thirteen skills — so silence means the defaults stand, not that the section is omitted.

**On `upgrade`, a project without the section gets it offered as an `add` row** like anything else:
that is how an existing project acquires it, and the words are shown there too.

| Write | From | Profile | Notes |
|---|---|---|---|
| `<docs_home>/reference.md` | `templates/cartridge.md` | all three | the cartridge: frontmatter + prose |
| `<docs_home>/workspace/AGENTS.md` | `templates/workspace-agents.md` | all three | **the source** of the workspace instructions, including *How to work with me* — the one block whose words are shown before they are written |
| `<root>/AGENTS.md` | copy of the above | all three | with the generated-by header |
| `<root>/CLAUDE.md` | `@AGENTS.md` | all three | one line |
| `<state_dir>/`, `<state_dir>/tracks/` | — | all three | and `me` if there are collaborators |
| the tracker's own file | the adapter | standard, full | `TASKS.md` for `tasks-file`; nothing to write for a hosted kind |
| the docs repo's `README.md` | — | **full, and only where question 17 created a docs repo** | what the repos are and where each page lives — content that exists the moment the project does. **Not `STATUS.md`**: that path is the tracker's `status_file` on a `roadmap-files` project, and "where the work stands" on a minutes-old project is the same promise-not-fact that keeps `risks/` unseeded |
| `<state_dir>/env/agents.env` | — | standard, full — **and only where a service came out `token`** | one block per such service, **every value empty**. No `token` service means no file and no `env/` folder: see *Services, and how the agent reaches them* |
| `<state_dir>/env/README.md` | — | same as above | the where-it-goes and is-it-secret table, the loading line, and where the live values actually live |
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
| AGENTS.md *How to work with me* | absent | six default lines, shown before writing | add |
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
- **Never run a service's `login`, and never open its browser flow.** It needs a terminal the agent
  is not, and an interactive login can hang the session outright. `human_step` is printed.
- **The agent writes no credential value, ever** — not into the generated file, not a placeholder
  that looks like a value, not one copied out of another file.
- **Record only a read-only `check:`.** `ws-sync` runs it unprompted on every machine; a service
  whose only proof is a write gets `check: null`.
- **No service is named in this skill, and none is proposed from a list.** The user names them;
  you research them.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- `ws-sync` — confirm the machine is current and the generated copies match their sources
- `ws-env` — bring this project's credentials into the store
- `ws-start` — claim the first task
- `ws-refine` — change a generic skill or this project's cartridge
