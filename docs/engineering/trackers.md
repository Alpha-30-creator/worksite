# How to add a tracker

**Adding a tracker kind is adding one file that answers four questions.** This page is the
procedure: what the four answers must contain, how the file is shaped, and one example worked
end to end.

**What is not on this page.** Which cartridge keys a kind reads, what each one defaults to and
what happens when one is missing belong to
[the cartridge schema](../integration/cartridge-schema.md) — this page documents no key. Which
copy of the pack you are editing, and how a change reaches this repo, belong to
[sync-direction.md](./sync-direction.md) — this page does not restate the direction. The case
for having adapters at all, with the objections, is in
[the concepts page](../product/overview.md).

## Why there is an adapter at all

The loop needs four things from a tracker and nothing else: what is open, a way to take one,
a way to move it, somewhere to leave a note. Everything else a tracker offers exists for people
to look at. A skill taught one tracker's vocabulary gains nothing and loses the ability to run
anywhere else, so the vocabulary lives in an adapter and the skills read whichever one the
cartridge selects.

## The four questions

An adapter is usable by the loop when all four answers are concrete enough to run without asking
you anything the cartridge already says.

| Question | What the answer must contain |
|---|---|
| **List** | what is open; what is in progress **and whose**; what is pickable **now**, including how a dependency or a blocker is read if the tracker has one. Enough to avoid proposing a task someone else holds. |
| **Claim** | how an item becomes mine — **and whether that is a lock.** If it is not, say so in those words and carry the re-read step below. |
| **Mark** | how an item moves to in-review, and how it moves to done. Both, separately: they are different states and often different mechanisms. |
| **Note** | where a resume note or a comment goes, and whether people read it. |

## What an adapter file is

One Markdown file in the pack's [`ws-shared/trackers/`](../../skills/ws-shared/trackers/), named
for the kind, selected by the cartridge's `tracker.kind`. A row in
[the adapter index](../../skills/ws-shared/trackers/README.md) makes it findable. Nothing else.

The skeleton the shipped adapters use:

```markdown
# Tracker: <kind>

Cartridge keys: <the keys this adapter reads, named in its own text>

## List
## Claim
## Mark
## Note
```

Read the shipped ones before writing a new one — they are the reference for how much detail an
answer needs:

- [`roadmap-files.md`](../../skills/ws-shared/trackers/roadmap-files.md) — phases and tasks in
  Markdown in a repo
- [`tasks-file.md`](../../skills/ws-shared/trackers/tasks-file.md) — one flat file
- [`github-projects.md`](../../skills/ws-shared/trackers/github-projects.md) — a hosted board
  over issues
- [`trello.md`](../../skills/ws-shared/trackers/trello.md) — a hosted board someone else owns

**Credentials are never written into an adapter or a cartridge.** An adapter points at the shell
environment or at `ws-env` and refers to variables by name.

## The claim question is the honest one

The shipped adapters are **not** uniform here, and a new one must not imply that they are.

| Shape | What claim actually gives you |
|---|---|
| A task file inside a repo | a real lock. The claim is a pushed commit; a rejected push **is** the mutual exclusion, and the retry — `pull --rebase`, re-check the item is still open, then retry or pick another — is the whole concurrency story. |
| A task file outside a repo | **no lock.** The adapter says so in those words: single-player. |
| A hosted board | **no atomic claim.** Assigning an item or moving a card is not a lock. |

So, for any kind without a lock, both of these are part of the adapter and not optional:

1. it **states** that there is no lock, rather than leaving a reader to infer it from silence;
2. its claim step **re-reads the item immediately after claiming**, and stops and says so if
   someone else is now on it.

An adapter that skips either one reads exactly like an adapter with a lock, which is the one
failure a reader cannot detect.

## Worked example — adding `driftwood`

`driftwood` is a **fictional** hosted kanban service, invented for this page in the pack's own
example style. It does not exist, and neither do the endpoints below.

**Why a hosted board for the example.** The four questions are trivially answerable for a file
in a repo, and the shipped adapters already cover that twice. The question that bites is
**claim**, and it only bites where there is no lock — so writing this adapter forces the three
decisions that separate a usable adapter from a plausible one: say plainly there is no lock,
carry the re-read step, and decide what to do about the states the board has no key for instead
of inventing one.

### The ask

The board belongs to a client, it is not GitHub, and the work has to be tracked where they can
see it. So: a new kind, `driftwood`, selected by `tracker.kind` and reading the board id and the
lane names the client's board actually uses.

### The four answers

**List.** Resolve lanes to ids once, then read the cards in the open and in-progress lanes:

```
GET  /v2/boards/<board-id>/lanes?fields=id,name
GET  /v2/lanes/<lane-id>/cards?fields=id,title,body,labels,assignees,url
GET  /v2/cards/<card-id>?checklists=all
```

Match lane names **case-insensitively**, report in-progress first so you can see what someone
else holds, then pickable. `driftwood` has **no dependency or blocker field**, so everything in
the open lane is pickable and there is nothing to resolve before proposing one — state that
rather than leaving the reader to wonder which it is. Checklist items that read like acceptance
criteria are the acceptance criteria; this board has no other structured field for them.

**Claim.** Move the card and add yourself:

```
PATCH /v2/cards/<card-id>            {"lane": "<in-progress-lane-id>"}
POST  /v2/cards/<card-id>/assignees  {"member": "<member-id>"}
```

**There is no atomic claim, and moving a card is not a lock.** So re-read the card immediately:

```
GET /v2/cards/<card-id>?fields=lane,assignees
```

If someone else is now assigned, stop, say so, and go back to the list. Nothing else in the
adapter pretends otherwise.

**Mark.** In review: comment the PR url on the card and move it to the board's review lane
**if the board has one**. Done: move it where the team puts finished cards — and because the
cartridge has no key naming that lane (see the limits below), **ask**, every time, rather than
inventing one or creating a lane on someone else's board.

**Note.** A comment on the card, `POST /v2/cards/<card-id>/comments`. Short and factual: people
read it.

**Credentials.** A bearer token read from the shell environment, or injected for one command
through `ws-env`. Named, never printed, and not stored in the cartridge.

### The diff that was made

- one new file in the pack's `ws-shared/trackers/`, named for the kind;
- one row in the adapter index.

### What was not touched

No skill. Not `ws-start`, not `ws-plan`, not `ws-ship`. No branch on the tracker kind anywhere.
No change to the cartridge schema. The cartridge for that one project gains a `tracker.kind` and
the keys the new adapter says it reads — which is a project's own fact, not a pack change.

**Where a file-based kind would differ:** only in the claim answer, which becomes a pushed commit
plus the rejected-push retry, and in the note answer, which becomes a line in the file.

## Known limits you will meet while writing one

Both of these are open, filed as **p8.20**. An adapter must work around them rather than assume
they are solved:

- **A board's column names have no documented shape in the cartridge.** `tracker.statuses` is
  declared schema-less, so an adapter that needs column names states that need in its own text
  instead of relying on a shape the pack does not define.
- **The Trello-style `lists` key carries open and in-progress only.** There is no key for a
  finished-card list, which is why the example above — and the shipped Trello adapter — asks
  where a finished card goes every task rather than inventing a list. A reader who invents a
  key for it is not told it was ignored.

There is also an open contradiction about what a `lite` profile does with a tracker — one file
in the pack says a `lite` project gets no tracker, while the single-file adapter calls itself the
`lite` default. Filed as **p8.22**; it is not resolved here, and a new adapter should not lean on
either reading.

## An unknown kind is not an error

A `tracker.kind` with no adapter does not stop the loop. Ask the user the four questions, do the
work with the answers, and offer to write the adapter afterwards. That behaviour is stated in
[the adapter index](../../skills/ws-shared/trackers/README.md); the pack's general
degrade-never-fail posture is on [the cartridge schema page](../integration/cartridge-schema.md).

## Adding a tracker never edits a skill

Cited in the pack as **R4**. In this guide's terms:

> Adding a tracker kind is **one new file** in the adapter folder plus **one row** in the adapter
> index. No skill learns the kind.

The test is checkable rather than aspirational, which is the point of stating it: open the diff
and count the files. A skill in it means the design was broken, not extended.

**The failure mode, named.** If you find yourself about to branch on a tracker kind inside a
skill — `if kind == …`, a per-kind table in a step, "for GitHub Projects, instead do …" — stop.
That branch is the adapter, written in the wrong file. Write the adapter.

## Where the file goes

The adapter is written in the working copy of the pack, not in this repo; this repo's `skills/`
is a received copy and reaches that state by a publish.
[sync-direction.md](./sync-direction.md) says which copy is which and how a change travels.
Editing the copy here is the mistake that looks like it worked.
