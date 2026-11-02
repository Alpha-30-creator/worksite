# Reverse coverage check — measured precision on the pack as it stands · 2026-11-02

The graph audit's coverage was **forward only**: it verified that every skill *named* in a
`What next?` exists, with no check that every exit the **prose** offers is listed. p8.17 added a
`ws-setup` exit to one skill and the audit stayed clean, because nothing looked that way.

This records what the reverse direction actually costs, measured on the fourteen-skill pack before
any of it was changed, because the design question was never *whether* to add the check but
**whether its false positives make it a check nobody runs twice**. Criterion in `d34ab8c`.

## The naive form is unusable, and this is by how much

Taking every `ws-[a-z]+` token in a skill's body and demanding it appear in that skill's
`What next?`:

| | Result |
|---|---|
| findings | **22** |
| skills implicated | **13** of 14 |
| true positives among them | 2 |

Nearly all of them are references that are not exits at all — one skill saying what it is *not*
for, another saying what a sibling does afterwards. It also **invents a skill**: one body contains
the words "Windows-safe", from which an unanchored `ws-[a-z]+` extracts `ws-safe`, and the forward
check then dutifully reports it missing.

## The anchored form: three candidates, two real

Anchored twice — on a **backticked** skill name *and* on an **offer verb** (`offer`, `ask for`,
`go through`, `hand off`, `switch to`, `instead`, `→`):

| Candidate | What the prose says | Verdict |
|---|---|---|
| `ws-plan` → `ws-start` | "No current track → ask for `ws-start`." | **true positive** |
| `ws-start` → `ws-setup` | "No cartridge → offer `ws-setup` in adopt mode" | **true positive** |
| `ws-ship` → `ws-review` | "offer any new risk class … as `ws-review` does" | **false positive** — a comparison, not an exit |

**Precision 2/3 on fourteen files. One skill was skipped** for having no `What next?` — a reference
pack is read by path rather than invoked, and correctly must not grow one. The skip is **counted
and printed**, not silent, so "1 skipped" is visible rather than assumed.

## What was accepted, and why

Roughly **one false positive per pack-wide run**, against 22 for the naive form and **zero
detections** for what shipped before. The check prints `UNLISTED EXIT` and **does not fail the
audit**: at this precision a hard failure would block a legitimate change about once per run, and a
gate people learn to step over is worse than one that reports. Each finding is read and judged.

The prose-only alternative was rejected by the owner on the strength of these numbers: it would
have found **neither** of the two real gaps. The rejected alternatives are
[ADR 0004](../decisions/0004-a-check-must-state-what-it-read.md).

## What it cannot catch

Recorded so the measurement is not read as coverage:

- an exit offered in prose that names no skill in backticks — "hand this back to whoever planned it";
- an exit offered through a verb outside the anchor list. The anchor list is a sample of the pack's
  current idiom, **not a grammar**;
- an exit offered in a file that is not a `SKILL.md`. Shared reference material sends readers to
  skills by name and has no `What next?` at all;
- the distinction between an offer and a comparison, which is the false positive above and is a
  question only a reader can answer.

## How it was measured

Both forms were run over the pack as a shell loop, under `bash` explicitly, before any file was
edited. The anchor behaviour was then confirmed against a purpose-built five-skill fixture pack: an
offered-and-unlisted exit (fires), a comparison in the shape of the known false positive (fires, and
is labelled), a body containing "Windows-safe" (**no** `ws-safe` under the anchored form, `ws-safe`
under the naive one — so the backtick anchor is demonstrably what kills it), an offered exit that
*is* listed (silent), and a skill with no `What next?` (counted as skipped, and the count printed).

**Two of the three live candidates are in files that the change measuring them did not own.** They
were reported rather than fixed, and routed to their owning task in `d34ab8c`. A check finding real
gaps on its first run, in files its author may not touch, is the intended behaviour and not a
problem to be tidied away.
