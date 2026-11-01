# Documentation and comments

Always on, every change. Objective where it can be: the detectors below are things you can point
at and quote, not matters of taste.

This pack answers **where a piece of writing belongs**, not how much of it there should be.
Over-detailed comments are usually *well written* — that is exactly why they survive review. Being
in the wrong place is a different defect from being badly written, and it has a different fix:
**move it, do not delete it.** A reviewer who reports "delete this comment" will be ignored, and
should be.

## The discriminator

A comment is read by someone standing at that line. So:

> **Would a reader at this line need this in order to change the line correctly?**

| What the writing is true of | Where it belongs |
|---|---|
| the line | the comment, as briefly as it can be put |
| the system | `engineering/` |
| a choice, and the alternatives rejected | `decisions/` — an ADR |
| a measurement on a date | `records/`, with the comment pointing at it |

## Detectors

**1. A time-relative claim.** "until today", "no longer", "currently", "for now", "at the moment",
"was never set", "has never been hit", "recently", "the new X". These are assertions with an
expiry date, and nothing re-reads them when they lapse. In a comment they rot silently; in a
**dated** ADR or record they stay correct forever, because the date is part of the claim.

A claim that is **already false** is `Must fix` — see Severity. One still true is `Should fix`:
rewrite it so it cannot rot, or move it somewhere dated.

**2. A dated measurement offered as evidence.** A number, a date, and a conclusion drawn from
them. This is the evidence for a decision, and evidence belongs with the decision — `decisions/`
if it justified a choice, `records/` if it recorded a moment. The comment keeps the conclusion and
points at the record.

**3. A rejected alternative.** "X rather than Y, because…", "we tried Z and it…", "this was 50
before and that failed". **This is the ADR signature** and the single most valuable thing to
relocate rather than lose: a PR never keeps it, and the next person to touch the line will
otherwise re-litigate the same choice. Report it as "this is an ADR", naming the decision.

**4. A fact about the system, not about the line.** How components compose, what a framework does
internally, how a pipeline is staged, what a type means across modules. True of the system, so it
goes stale when any *other* file changes — which no reviewer of that other file will ever notice.
`engineering/`.

**5. The comment repeats itself.** The same argument twice in one block. A sign it grew by
accretion over several sessions rather than being written once, and a reliable indicator that
there is a document trying to get out.

## What must NOT be reported

A pack that only knows how to delete is worse than no pack. **None of these is a finding:**

- **Structured API documentation belongs in the code.** Python docstrings, TSDoc or JSDoc on
  exported symbols, Go doc comments on exported identifiers, Rust `///`. Tooling reads them and
  the reader is at the call site. A **missing** one on an exported public symbol is a finding in
  the *other* direction — `Should fix`.
- **Usage and invocation blocks.** The commands to run a script, what it writes, its contract. A
  reader at the top of that file needs them.
- **A durable one-line "why".** Brevity is not the goal; **durability** is. A short reason that
  cannot rot is exactly right and should be praised, not trimmed.
- **A non-obvious workaround with its reason**, ideally a link to the issue or upstream bug. The
  code cannot say this and nothing else will.
- **A comment on a deliberate surprise** — a cast that looks wrong, an order that matters, a
  seemingly redundant guard. Removing it costs the next reader an hour.

## By language

The *form* changes; the discriminator does not.

| Language | In the code | Still misplaced |
|---|---|---|
| Python | docstrings on public modules, classes, functions (PEP 257); the first line a summary | narrative above a constant or an import |
| TS / JS | TSDoc on exported symbols; `@param` only where the name does not carry it | file headers that explain the architecture |
| Go | doc comments on exported identifiers, starting with the identifier's name | design rationale in a package comment |
| SQL / migrations | intent of *this* migration, in the migration | schema-wide explanation — that is `engineering/` |
| Shell | usage block at the top, and why a flag is needed | anything about the system around it |
| Config / IaC | why a value is what it is, in one line | the measurement that produced it — that is a record |

A repo whose practices doc says otherwise wins: that is a house rule, and this pack is not a law
about taste.

## Severity

Set in `tier1-universal.md`. In short: restating the code is a `Note`; a comment that is really a
document is `Should fix`; a comment that **contradicts** the code, or whose time-relative claim is
already false, is `Must fix` — it is a lie about behaviour, which is worse than silence.

## How to report one

Three things, or it will not be acted on:

1. **Quote the opening line** of the comment, so it can be found.
2. **Name the destination** — `engineering/`, an ADR in `decisions/`, a record in `records/`. Not
   "move this to the docs".
3. **Say what stays behind.** Usually one line plus a pointer. A finding that leaves the line with
   no explanation at all will be rejected, correctly.

If a change *adds* writing of this kind, the plan should already have named its home — `ws-plan`
step 11 requires it. A review finding here on new code is also a sign the plan skipped that step.
