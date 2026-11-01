# Review packs: how one is chosen, and how to write one

**A review reads a rulebook before it reads the diff.** This page is how that rulebook is
assembled for a given change, and how to add to it.

**What is not on this page.** The `stack:` key itself — where it sits in the cartridge, what an
absent value means — belongs to [the cartridge schema](../integration/cartridge-schema.md); this
page documents no key. What the packs actually *say* is in the packs, under
[`ws-shared/stacks/`](../../skills/ws-shared/stacks/) and
[`ws-shared/review/`](../../skills/ws-shared/review/). Which copy of the pack you are editing is
[sync-direction.md](./sync-direction.md). Why reviews run in a context that did not write the
code is argued on [the concepts page](../product/overview.md).

## The three tiers

| Tier | What it is | Where it lives | Who owns it |
|---|---|---|---|
| 1 | universal — applies to every change in every project | the pack's `review/` and its baseline stack file | the pack |
| 2 | by stack — the traps of a particular technology | the pack's `stacks/` | the pack |
| 3 | this project's own risks, grown by use | `<docs_home>/risks/` — here, [`agent/risks/common.md`](../agent/risks/common.md) | the project |

Tiers 1 and 2 are a library change. Tier 3 is a normal docs commit in the project.

## What is always on

Selected for every change, whatever the stack says:

- [`review/tier1-universal.md`](../../skills/ws-shared/review/tier1-universal.md) — the universal
  checks;
- [`stacks/security-baseline.md`](../../skills/ws-shared/stacks/security-baseline.md) — objective,
  mapped to OWASP Top 10:2025, and selected with no tag at all;
- [`review/documentation.md`](../../skills/ws-shared/review/documentation.md) — where writing
  belongs, and what a review should not report;
- [`review/ai-slop.md`](../../skills/ws-shared/review/ai-slop.md) — for any change an agent wrote.

## How a tier-2 pack is selected

1. **The selector is the cartridge's `repos[].stack`** — a list of tags, per repo.
2. **Selection is per changed repo.** A change touching two repos composes the union of what
   their tags select.
3. **The mapping is the tag table in
   [`ws-shared/reference.md`](../../skills/ws-shared/reference.md)**, not in any skill. A skill
   reads the table; adding a row is how a tag starts resolving.
4. **Deduplicate.** Several tags can map to one pack, so resolve tags to packs and read each pack
   **once per review**, not once per tag.
5. **A tag with no pack is fine.** Tiers 1 and 3 still apply, and nothing fails.

Then the composed set is not handed over whole: the selected items are narrowed to the ones this
change can plausibly trip and rewritten as specific questions about this diff, with objective
rules separated from house preferences.

**The worked case is this repo.** Its single repo declares `stack: []`, so **no tier-2 pack is
selected at all** — the always-on set plus this project's own risks file is the entire rulebook.
That is a legitimate configuration rather than an unfinished one, and it is the clearest
demonstration that an empty tag list degrades instead of failing.

## Who reads a pack, and when

| Skill | When it reads a pack |
|---|---|
| `ws-plan` | at plan time, for each `stack:` tag on the repos the plan touches — so the plan is built against the rulebook instead of meeting it at review |
| `ws-review` | composing the brief, which is the only place selection is actually performed; and again when it proposes a new line |
| `ws-fanout` | writes the selected risks into each track's **build** brief, and briefs a separate reviewer per track under `ws-review`'s rules — the same selection, run once per track |
| `ws-setup` | names the packs in a new project's generated rule skill and risks file |
| `ws-refine` | writes a pack, or a line in one, and adds the tag-table row — the only writer |

**A pack may point at another pack**, so a selected pack can pull one in by reference: the
AI-slop file sends supply-chain findings to the security baseline, and the documentation pack
defers to tier 1 on comments.

## Where an off-list tag leaves you

Not a failure, and worth noticing: a tag that keeps appearing with no pack behind it is the
evidence that a pack should exist. That is the normal trigger for writing one.

## How to write one

The shape the shipped packs have:

- a title naming the technology, and a line naming the selector — `Selected by stack: [<tag>]`;
- one line on what it applies to;
- then **independent bolded assertions**, each one thing to look for with the defect stated.

No narrative, no project names, no code listings beyond the fragment an assertion needs. Each
entry has to be checkable against a diff by someone who has never seen the codebase.

One line pair, as illustration of the shape rather than a rule to copy:

```markdown
**A secret in a client bundle is exposed.** Everything in this directory ships to the browser,
so a credential read here is public the moment it builds. A new variable read client-side that
is not safe to publish is a Must fix.
```

The generic class, with the consequence named — never "we had a bug where …".

## Objective, or house preference

Every entry is one or the other, and a new entry must say which:

- **objective** — breaking it causes a vulnerability or a defect. It can block.
- **preference** — a deliberate house choice. A review reports it *as* a preference, names the
  rule it comes from, and never blocks on taste.

An entry that does not say which gets reported as a law, and a review that reports taste as a bug
stops being trusted.

## How packs grow

By use, and only by use. When a review **confirms** a finding whose risk class is written down
nowhere, one line is proposed:

| The class would catch bugs in | Goes to |
|---|---|
| other projects on this stack | the stack pack in `ws-shared/stacks/` |
| this project only | the project's `risks/` file |

**One line, phrased as what to look for** — a description of the class, not of the bug that
revealed it. A whole new pack also earns its row in the tag table, or nothing will ever select it.

## Project risks are not a pack

Tier 3 lives in the project's own docs — [`agent/risks/common.md`](../agent/risks/common.md)
here — and changes in an ordinary docs commit. It is not a library change, it is not published,
and it is read only for the project that owns it.

## Adding a stack never edits a skill

Cited in the pack as **R4**. In this guide's terms:

> Adding a stack is **one new pack file** plus **one row** in the tag table. No skill learns the
> stack.

Checkable the same way: open the diff and count the files. A skill in it means the design was
broken, not extended.

**The failure mode, named.** If you find yourself about to branch on a stack tag inside a skill —
`if stack includes …`, a per-stack step, "for Terraform repos, also check …" — stop. That branch
is a pack entry, written in the wrong file. Write the pack.

## Where the file goes

A pack is written in the working copy of the pack, not in this repo; this repo's `skills/` is a
received copy and reaches that state by a publish.
[sync-direction.md](./sync-direction.md) says which copy is which and how a change travels.
