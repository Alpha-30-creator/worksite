# The docs tree

The map of this docs tree: which page answers which question, and whether what it says can be
trusted to be current.

This page is not a second pitch and not a second install. What worksite is and why anyone would
adopt it lives in the root `README.md`; the argument for each of its opinions lives in
[product/overview.md](product/overview.md); installing it is [INSTALL.md](../INSTALL.md). Every
`.md` file under `docs/` is reachable from here in at most two hops, where the first hop is either
the page itself or the folder that contains it.

## Start here

- [product/overview.md](product/overview.md) — what this is, and why it is shaped this way.
- [STATUS.md](STATUS.md) — where the work is right now.
- [agent/reference.md](agent/reference.md) — how to work on this repo, if you are about to.

## The pages

Each row gives the page, the question it answers, and the kind of the folder it sits in — living
means it is maintained and can drift; immutable means it is never edited once written. Folder links
are deliberate where, and only where, a collection grows by file: the ADRs, the eight roadmap
phase files, the dated records and the worklog entries, whose list here would go stale by the next
merge. A *fixed* reference page is always linked directly even when it sits inside such a folder —
`roadmap/README.md` and `records/known-limitations.md` are the two, and both are rows below.

**Where this classification comes from, and who owns it.** The living/immutable property is the
pack's, specified once in its shared reference; this index restates it because knowing whether a
page can be trusted to be current is half of finding the right page.
[engineering/layout.md](engineering/layout.md) carries a table over the same folders and is the
authority for everything this index leaves out of it — what belongs in each folder *here*, which
copy of a path is authoritative, and which `check.sh` section reads it. Where the two disagree
about a folder's contents or provenance, layout.md is right and this page is stale.

### Root of `docs/`

| Page | The question it answers | Kind |
|---|---|---|
| [STATUS.md](STATUS.md) | Where is the work right now — what is in flight, blocked, next, shipped? | living; the first thing anyone reads being wrong is the failure mode |

### `product/` — living, slow; stale means drift

| Page | The question it answers | Kind |
|---|---|---|
| [product/overview.md](product/overview.md) | What is worksite, what is the loop, and what is the argument for each of its four opinions — with the objection and the honest limit of each? | living, slow |

### `engineering/` — living, fast; stale means confidently wrong, so it changes in the same PR as the thing it describes

| Page | The question it answers | Kind |
|---|---|---|
| [engineering/layout.md](engineering/layout.md) | What lives where in this repo, which copy of a path is authoritative, and what each section of `check.sh` does **not** cover? | living, fast |
| [engineering/trackers.md](engineering/trackers.md) | How do I add a tracker kind — the four questions an adapter answers, worked end to end? | living, fast |
| [engineering/stacks.md](engineering/stacks.md) | How is a review's rulebook assembled before it reads the diff, and how do I add a pack to it? | living, fast |
| [engineering/sync-direction.md](engineering/sync-direction.md) | Which of the two copies of the skills is the real one? A pointer page, by design. | living, fast |

### `integration/` — living, contract; stale means it breaks the other repo

| Page | The question it answers | Kind |
|---|---|---|
| [integration/cartridge-schema.md](integration/cartridge-schema.md) | Every cartridge key: its type, its default, which skills read it, and what a missing one does. | living, contract |

### `runbooks/` — living; stale here is dangerous, because someone follows it

| Page | The question it answers | Kind |
|---|---|---|
| [runbooks/purge-a-leak-from-history.md](runbooks/purge-a-leak-from-history.md) | A private string reached public history — what is the procedure? | living; the only runbook here |

### `roadmap/` and `agent/` — living; stale means the plan is wrong, or the skills read nothing

| Page | The question it answers | Kind |
|---|---|---|
| [roadmap/](roadmap/) | What work is planned, and what state is each piece in? The tracker itself, one file per phase. | living |
| [roadmap/README.md](roadmap/README.md) | What does each task marker mean, how is a task claimed, and when is one pickable? The marker vocabulary and the claim protocol. | living |
| [agent/reference.md](agent/reference.md) | This project's own cartridge, and the two rules that make this repo unusual. | living |
| [agent/risks/common.md](agent/risks/common.md) | What has gone wrong here before, so a review looks for it again? This project's own risk list. | living |
| [agent/workspace/AGENTS.md](agent/workspace/AGENTS.md) | The source of the root `AGENTS.md` — edit this one, never the generated copy. | living |
| [agent/worklog/](agent/worklog/) | What was shipped, and what was rejected on the way? One entry per track, written at harvest. | living, append-mostly |

### `decisions/` — immutable; never edited, superseded by a newer ADR

| Page | The question it answers | Kind |
|---|---|---|
| [decisions/](decisions/) | Why is it this way rather than the obvious alternative? The ADRs, numbered. | immutable |

### `records/` — immutable, dated; cannot be stale, because it records a moment

An ADR and a record are both immutable, for different reasons: an ADR is superseded by a later ADR,
while a dated record simply cannot go stale — it says what was true on a day.

| Page | The question it answers | Kind |
|---|---|---|
| [records/](records/) | What did a point-in-time review or audit find, and when? Dated reports. | immutable, dated |
| [records/known-limitations.md](records/known-limitations.md) | What is known not to be covered, mechanism by mechanism? The one standing record — undated in its filename and reference-shaped, but still a record: an entry changes only when the mechanism does, and then in the same commit. | immutable in the same sense |

### Outside `docs/`

| Page | The question it answers | Kind |
|---|---|---|
| [../README.md](../README.md) | What is this pack, for a reader arriving cold? | living |
| [../INSTALL.md](../INSTALL.md) | How is it installed? Addressed to the agent that will run it. | living |
| [../AGENTS.md](../AGENTS.md) | What does an agent need to know before touching this repo? Generated — the source is `agent/workspace/AGENTS.md` above. | living, generated |

## Deliberately absent

Three things the pack's own docs structure allows are missing here, and the absence is the
decision rather than an oversight. `engineering/layout.md`, linked above, makes the same
declaration for the first two in the same terms; it is the authority if the reasons ever diverge,
and this paragraph is here so a reader of the index alone does not read absence as oversight.

`design/` — the pack lists it as a living, slow folder beside `product/`. This repo ships Markdown
and shell; it has no screen, no control and no design system, so there is nothing for the folder to
hold. `agent/rules/` — the per-area rule skills a product repo gets. The "code" here is the
workflow pack itself, and changing it goes through `ws-refine` rather than through a rules page.
`00-START-HERE.md` — the pack's docs-root listing names it alongside `README.md` without assigning
either a job. This file does that job, and `STATUS.md` holds the "where is this now" role a
separate start-here page would claim.

## Where a new page goes

Read [engineering/layout.md](engineering/layout.md), section *Where your writing goes*: it has the per-case rules and this
page does not restate them.

The one rule worth repeating, because breaking it is what makes a docs tree feel untrustworthy:
dated reports go in `records/`, never loose among the reference pages.
