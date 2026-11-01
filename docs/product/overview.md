# worksite — concepts

This page is the argument for worksite: what problem it solves, the loop that closes it, and why
each of its opinions is worth having rather than tolerating. It is deliberately not a reference.
The key-by-key account of the cartridge lives in [the cartridge schema
page](../integration/cartridge-schema.md), and the install path lives in the README.

It is written for someone deciding whether to adopt this — or whether to build something like
it — and for anyone working inside it later who wants to know why it refuses what it refuses.

## The problem

Coding agents are good at writing code and bad at nearly everything around it. They begin without
establishing what the task actually is. They skip the plan, or write one and then quietly do
something else. They declare success on a reading of their own diff. They review their own work
and find it good. And when a session ends — compaction, a crash, a closed laptop lid — whatever
they had worked out goes with it.

The tempting read is that this is a model defect, fixable by a better prompt or a better model.
It is not. The gap is **structural**: every one of those failures is a missing *stopping point*.
Nothing in a chat has a defined end state, so there is nothing for "done" to mean, nothing to
hand to a second reader, and no place a record gets written on the way past. A stronger model
with no stopping points fails the same way, faster.

The second half of the problem is that the gap is re-solved per repo. Each project grows its own
instruction file and its own half-remembered conventions; they are all slightly different, none
is complete, and an improvement made in one reaches none of the others. The effort is real and it
never compounds.

worksite closes the gap once: **thirteen skills plus a shared reference they all read**, each one
with a named terminal state, and all of a project's own facts in one declarative file per project
rather than inside the skills.

## The loop

Five skills carry one task from unclaimed to merged. Each ends with one specific thing and
refuses to end with anything else.

| Skill | Ends with |
|---|---|
| `ws-start` | a claimed task and a summary — never a plan, never code |
| `ws-plan` | an **approved** plan — never with code written |
| `ws-verify` | evidence against each acceptance criterion — never "looks right" |
| `ws-review` | a verdict from a context that **did not write the code** |
| `ws-ship` | the work merged, the record written, nothing ephemeral left behind |

The terminal states are the mechanism, not decoration. A stage with a named end is the only kind
whose **collapse is detectable**. Planning that slid into building is invisible if planning has
no defined output; against "ends with an approved plan" it is simply the gate not reached. The
same holds for verification that slid into assertion, and for debugging that slid into a
plausible patch. Each of those is the normal, comfortable failure, and each becomes visible the
moment its stage has a contract.

The rest of the pack sits off the loop: `ws-debug` establishes a confirmed cause before any fix
is designed; `ws-task` changes what the work *is* and never implements it; `ws-wrap` pauses a
track without closing it; `ws-fanout` runs several at once; `ws-setup`, `ws-sync` and `ws-env`
handle the project, the machine and the credentials. `ws-shared` is not invoked at all — it is
the reference the others read by path.

## The opinions, and why you should want them

### Gates that stop

The failure a gate prevents is design churn discovered *after* the build, when changing course is
expensive and an agent has already produced something that looks finished.

An agent that can produce a screen or a migration in ninety seconds has removed the last natural
pause from the process. There used to be one, and it was not discipline — it was the hour the work
would take. `ws-plan` puts it back where changing your mind is still free: it ends with an
*approved* plan, and for UI work it writes a mockup, presents it and stops. The skill says
outright that the design is **expected** to change there, because that is the gate working rather
than failing.

The objection is that a gate slows you down. It moves the slowdown earlier, which is the whole
trade: a decision reversed at the gate costs a paragraph, and the same one reversed after the
build costs the build. The gate worth being suspicious of is the one that never changes anything —
a gate that only ever gets a yes is a formality, and formalities get skipped.

### Evidence, not assertion

The failure here is "done" meaning *the code it wrote reads as though it would work*.

`ws-verify` produces evidence mapped one-by-one to each acceptance criterion, and records
explicitly what it could **not** prove. The second half does the work: an unprovable criterion
written down is a visible gap someone can decide about, while the same criterion with no evidence
and no note silently passes — and the acceptance criteria stop being a contract and become a wish.

The objection is that the tests are the evidence. Sometimes they are — and this repo is the
counterexample it has to answer honestly, because worksite has no typecheck, no lint, no test and
no build, deliberately. Its entire `verify` is one shell script plus a written argument per
criterion. The point was never a test runner; it is the **mapping**. A project with an excellent
suite still has criteria no suite covers — "a reader can write a working cartridge from this page
alone" is one — and those are exactly the ones that get waved through.

### Fresh eyes, and the discipline that keeps them useful

The failure is the session that wrote the code reviewing the code. It reads its own intent into
what is on the page, and where the intent and the text disagree it defends the text.

`ws-review` composes a **standalone brief** — the acceptance criteria verbatim, the approved
decisions summarised into it rather than linked, the rulebooks named by path, the selected risks
written as questions — and runs it where none of the writing conversation exists. Both halves
matter: a reviewer that still has the conversation is not independent, and a reviewer with no
brief is generic, returning the same six observations it would return about any codebase.

The counter-discipline belongs in the same breath. Every finding is verified against the code
before it is reported, and overturned findings are *recorded*. Without that, fresh eyes become a
confident-noise generator, and the cost is worse than skipping review: you stop reading the
reviews, and the habit is gone.

The objection is that a second agent is just more tokens. It is, and the pack is explicit about
the cost rather than burying it — `ws-fanout` runs only on an explicit request, because the money
is the user's, and it caps work at five in flight counting builders and reviewers together.

### The lead that never builds

The failure is the coordinator quietly becoming the busiest builder. Once it has a half-finished
edit of its own, the two jobs only it can do are the first two it stops doing.

When several tracks run at once, the lead claims them, assigns **file ownership before any work
starts**, briefs one builder per track in its own worktree and a *separate* reviewer per track,
then verifies every finding and reconciles across tracks. Those jobs all require not being inside
any one track: an agent holding a cross-track invariant cannot also be the agent with an
uncommitted change in one of them, because the invariant is then something it would have to
report against itself.

This is enforced by a refusal rather than a preference: two tracks that would touch the same file
do not run in the same batch, and the overlapping one is dropped and run afterwards. An opinion
with a refusal behind it is the kind worth having; one merely recommended is a comment.

The objection is that a lead who writes no code is pure overhead on a solo project. It buys the
one property parallelism destroys by default — that no agent reviews its own work — and it is
opt-in: the single-track loop has no lead at all.

## Four design moves

### Generic skills, per-project cartridge

**No skill knows anything about any project.** Repos, tracker, branch flow, environments and house
rules live in one declarative file per project, which the skills read.

The alternative is not "no configuration". It is configuration smeared across forks of the loop:
put a project's facts inside the skills and you own N slightly different loops, where an
improvement to one reaches none of the others — the original problem wearing a tidier hat. Put
them in one file per project and refinement **compounds**: a trap learned the hard way on one
project is defended on the next without touching the next project at all. That compounding, not
tidiness, is the whole return on the indirection.

The objection is that this is indirection for its own sake, because an agent can read the repo and
work out the branch pattern. It can, usually — and that is the problem. Inference is
non-deterministic and unauditable: it is right most of the time and wrong **without telling you**,
so you find out downstream, where the mistake is expensive and its origin is no longer visible. A
declared key is wrong *visibly and once*.

The honest limit: the cartridge is **not fully specified today**. `ws-ship` reads a `merge_style`
that nothing in the pack defines, several keys are never read by name — some only by concept, and
at least one by nothing at all — and `ws-setup`'s interview collects answers that have no key to
land in. [The cartridge schema page](../integration/cartridge-schema.md) accounts for that key by
key, and names the holes it cannot close from the outside. None of it argues against the
mechanism — it argues for writing the schema down — and the reason the loop works anyway is the
**degrade-never-fail** rule: a missing cartridge, or a missing key, means less enrichment, never a
hard stop.

### Tracker adapters

**Every tracker answers the same four questions, so no skill knows which one you use.**

The surface a loop actually needs from a tracker is only four questions wide: list what is open
and pickable, claim one, mark it in-review and done, and note something against it. Everything
else a tracker offers — views, swimlanes, estimates, automations — exists for humans. Once that
is visible, teaching a skill one tracker's vocabulary is obviously a bad trade: the skill gains
nothing and loses the ability to run anywhere else. The test the pack sets itself is checkable
rather than aspirational: adding a tracker adds a file, never edits a skill. An unknown kind is
not even an error — ask the four questions, do the work, offer to write the adapter afterwards.

The objection is that four trackers is a premature abstraction and everyone should just use
issues. The reply is that you frequently do not get to choose: the board belongs to a client, or
to a team that was there first, or a solo build wants its tasks in a file in the repo, where the
agent reads them in the same breath as the code.

The honest limit is the interesting part, and the pack refuses to pretend otherwise: **the
adapters are not uniform where it matters most.** Only the two file-based trackers give a real
lock, and only when the file is in a repo: a pushed commit can be rejected, and that rejection is
the mutual exclusion. A tasks file outside a repo has no lock at all, and its adapter says so in
those words — single-player. The hosted boards have no equivalent either, because assigning an
issue or moving a card is not atomic, so their claim step re-reads the item and stops if someone
else got there first: a smaller guarantee, named as a smaller guarantee. An abstraction that
surfaces the difference it cannot hide is a real one; one that hides it is a lie you find out
about twice, once when it breaks and again when you discover the docs said it could not.

### Tracks and an append-only journal

**Work gets its own state, and every skill writes a journal entry at each stage boundary.**

The argument starts with where the loss actually happens. A plan is written at the start and a
resume note at the end, so a session that compacts or dies **in the middle** — at step 4 of 9 —
loses precisely the part nobody wrote down: which step it reached, what it already tried, what
turned out to be wrong. So skills append at every stage boundary, **not when asked**. Anything
that depends on remembering is missing exactly when it matters, because the moment you most need
the note is the moment you have least context left to write it.

Tracks are the other half: one active task per workspace breaks the instant a second chat opens,
so state is per track and the pointer to the current one is per session. The objection to tracks
specifically is that a directory per task is ceremony for one worker working on one thing. It is,
right until the second chat — and a second chat is not an exotic case, it is the ordinary way an
agent gets used, one window per thing you are waiting on. A single active task is an assumption
that holds until it silently does not, and the failure is two sessions writing over each other's
state with nothing reporting it.

The objection is bureaucracy: git and the pull request are already the record. Git records what
you **kept**. It has nothing to say about what you abandoned or why, and the abandoned approach is
the expensive knowledge — without it the next session re-tries it, confidently, and spends the
same hours again. One entry per boundary rather than one per thought makes the journal the
cheapest artifact in the loop, and the only one that pays out when a session dies.

### Harvest, then delete

**Plans, mockups and journals are deleted when a task ships. One distilled entry survives, and it
keeps the rejected alternatives.**

A docs tree is either trusted or ignored, and there is no halfway state. Plans and journals are
true for about a week; left in the tree afterwards they are indistinguishable from reference
documentation, and one stale plan read as current is enough for a reader to stop believing the
whole folder. So lifespan is a property of the **class** — ephemeral, harvested, permanent —
decided once, rather than a judgement call per file at the end of every task. Nobody makes that
call, understandably: the end of a task is the worst available moment to ask someone to assess
the durability of their own notes.

The objection is that deleting the plan destroys history. What is worth keeping was never the
plan: it is the decision and the rejected alternatives, and the remainder is instructions to a
builder who has already built the thing. So `ws-ship` **harvests first** — one worklog entry
holding what was chosen, what was rejected and why, the evidence summary and the risks learned —
and only then deletes. That rejected-alternatives line is what a pull request description never
carries, and why the harvest is mandatory rather than encouraged.

The strongest version of this move is that the pack argued with itself and lost. An earlier draft
carved `ws-ship` out of the house rule that a delete is shown and waits for a yes, on the happy
path: the user had already said ship, the harvest was committed, and one more prompt at the very
end is a real place for a session to die with the track still on disk. The reasoning was correct
and it pointed the wrong way. A track left on disk is **visible and recoverable**, and the stale
sweep finds it later; session state deleted without an answer is neither. Prefer the cheap
failure. The carve-out was reversed and removed from all three places it had been written down —
which is worth more than any assertion about discipline, because it is the rule surviving a case
where it was inconvenient.

## The state model

This section is written so that a session with no memory of the previous one can pick up a track
from these rules alone.

A **track** is one unit of work with its own state. Its id is the tracker's own id, lowercased and
made filesystem-safe — `p3.2`, `issue-116`, `card-6f2a91` — and a parallel numbering scheme is
never invented for it.

Where a track's files live is set by the cartridge's `artifacts` key: `workspace-state` (the
default) or `in-repo`. `workspace-state` keeps them in the workspace state directory, under
`tracks/<track-id>/`, where they cannot be committed. `in-repo` keeps them in the repo, under
`implementation_plans/<track-id>/`, committed on the task branch — a convention on projects that
want the plan beside the code, respected rather than argued with.

A track directory holds five things:

| File | What it is |
|---|---|
| `task.md` | the task verbatim, plus metadata — repos, branches, worktree paths |
| `plan.md` | the approved plan |
| `journal.md` | append-only, one entry per stage boundary |
| `mockup.html` | UI tasks only |
| `verify/` | evidence and scratch |

Beside the track directories sits `tracks/current`: **one line, the track id this session is on.
It is per session, not per machine.** Two chats on one machine each set their own, and every skill
reads it rather than assuming. If it is missing, or names a track that does not exist, the skill
**asks which track** — that case is a stop, never a guess. A lead session running several tracks
at once does not set it at all; each subagent is told its track explicitly, and shipping names the
track id in the invocation because there is no `tracks/current` to read.

A journal entry is headed with its stage, timestamp, device and handle, and carries four fields —
`did`, `next`, `rejected`, `open`. The stages are `claimed`, `planned`, `step <n>` (one per
completed plan step), `verified`, `reviewed`, `paused` and `shipped`. Entries are appended and
never rewritten.

**Resuming cold = read `task.md`, then `plan.md`, then the last two or three journal entries.**
That is the whole recovery path, and every skill that writes an entry owes a reader that property.

State crosses machines through the journal. Workspace-state files cannot be committed, so the
journal is mirrored to `<docs_home>/journal/<track-id>.md` and pushed — **one commit per stage,
not per thought**. `in-repo` projects need no mirror, because the task branch already carries the
files. A lightweight project with no docs home gets a local journal
only, and is told so once when the track is created, so nobody expects to find it on the other
machine.

Every artifact in the system belongs to one of three lifespan classes, and the class decides when
it dies:

| Class | What | Lifespan |
|---|---|---|
| Ephemeral | plan, mockup, journal, verify scratch | deleted at ship, always |
| Harvested | one distilled worklog entry per task | permanent, in the docs home |
| Permanent | the cartridge, the risk list, the rule skills | permanent, edited deliberately |

The one exception is `artifacts: in-repo`: there, ship keeps the plan and deletes only the journal
and the scratch, and says that the plan was kept.

Finally, the boundary that makes all of this safe to clean up. **Retiring** a track means removing
its session state — the track directory, the worktrees it was given, and `tracks/current` if it
names that track. **It never touches a branch, a commit, a pushed PR or the tracker item.** Four
callers need it and all four point at one definition rather than keeping a copy. Before removing
anything it refuses outright if a worktree holds uncommitted work, unpushed commits, or no
upstream at all — in that last case the commits exist nowhere else — then shows what will go and
waits for a yes. The operator mechanics live with the skill that owns them; the guarantee is the
part worth knowing from here.

## What this is not

An honest list, because a page that oversells this is worse than no page.

- **Not CI.** Nothing here runs on a push or blocks a merge by itself. The checks are the
  project's own, run by a skill in a session; a project that wants them enforced still needs CI.
- **Not a sandbox.** The pack constrains an agent's *workflow*, not its capabilities. It does not
  limit what commands run, what gets network access, or what a bad instruction could reach.
- **Not multi-user.** Tracks keep two sessions from colliding, and the file-based trackers give a
  real claim lock, but this is one person's working setup with a handle on it, not a team system
  with permissions.
- **Not installable yet, and not yet proven by anyone but its author.** The repo is public and the
  pack is generic, but the install path is still being written and no stranger has run the loop
  end to end from these instructions. [docs/STATUS.md](../STATUS.md) says where that stands.
- **Not accepting pull requests.** This is a one-way mirror of one person's setup; a merge here
  would be overwritten by the next publish. Fork it if you want it different.
- **Not finished being argued about.** The cartridge has unspecified keys, the tracker adapters do
  not offer the same locking guarantee, and the roadmap carries the open problems rather than
  hiding them.

## Where to go next

- [docs/STATUS.md](../STATUS.md) — what is being worked on now, and what is next
- [docs/roadmap/](../roadmap/README.md) — the phases, and the open problems named as tasks
- [ADR 0001](../decisions/0001-library-is-the-source-of-truth.md) — which copy of the skills is
  authoritative, and the two alternatives that were rejected
- [docs/engineering/sync-direction.md](../engineering/sync-direction.md) — how a change travels
  from the working copy to this repo to your agents
- [docs/integration/cartridge-schema.md](../integration/cartridge-schema.md) — every cartridge
  key: type, default, which skills read it, what happens when it is missing, and the gaps that
  are the pack's rather than the page's
- [docs/agent/reference.md](../agent/reference.md) — this project's own cartridge, if you want to
  read a real one
