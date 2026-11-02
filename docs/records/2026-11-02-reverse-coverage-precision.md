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

## The anchored form, before the change: three candidates, two real

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

## Recall — measured, because a precision figure beside an unmeasured recall is half a result

Precision says how many of the findings are real. It says nothing about how many real gaps the
check never raises, and that number is the larger one:

| | Count |
|---|---|
| distinct prose mentions of a sibling skill, across the 13 skills with a `What next?` | **33** |
| surviving the offer-verb filter | **9** |
| unlisted **and** reported | **3** |
| unlisted **and never reported** | **12** |

Twelve. The check raises a quarter of the unlisted pairs that exist. Several of the misses read
like real exits rather than like references — one skill's prose reaches for the verify step and the
wrap step, another for the ship step, another for the start step — and the verb filter does not see
any of them because they are phrased in idioms outside its anchor list.

**This is the honest shape of the result: high-ish precision bought with low recall.** The check
narrows the pack to a line or two that are worth reading, and it is not a coverage guarantee in
either direction. The blind spot was disclosed in kind from the start — "the anchor list is a sample
of the pack's current idiom, not a grammar" — and this is its magnitude. An independent review
measured 35 and 10 for the first two rows, scanning fenced code as well as prose; the 33 and 9 here
exclude fenced code, which is what the shipped check does.

## A false positive the change introduced into its own text, and what was done about it

Worth recording because it is the sharpest thing the review found about this check, and because
the first instinct — reword the sentence — would have been the wrong one.

A comment added to the audit block explained the precision hazard by quoting a comparison in
backticks: ``("as `ws-review` does") looks exactly like an offer``. The reverse check then fired on
that comment, because `ws-refine`'s own `What next?` does not list the review step. **The sentence
explaining the false-positive hazard was itself a false positive**, and live precision on the
shipped library became **4 candidates, 2 real, 2 false**.

The fix taken is **not** rewording the comment. It is excluding **fenced code blocks** from the
scan, on the principle that the check's own definition is "an exit the *prose* offers", and a
comment inside a shell block is not prose. Measured: the exclusion drops exactly that one finding
and keeps both true positives, which sit in ordinary prose. Precision returns to **3 candidates, 2
real, 1 false**.

> **2026-11-03 (p8.13).** Both true positives were `What next?` gaps in `ws-plan` and `ws-start`,
> and p8.13 listed them. A pack-wide run now reports **1 candidate, 0 real**. That one candidate
> is **not** the false positive this section is about — that one was `ws-refine`'s own comment, and
> the fenced-code exclusion removed it. It is the other one, from the table above: `ws-ship` →
> `ws-review`, "offer any new risk class … as `ws-review` does". Same idiom, different site, and
> the fenced-code exclusion cannot reach it because it sits in prose.
> The recall figures above are unchanged — **33 / 9 / 12**, re-measured. The reason is not merely
> that p8.13's new prose names no sibling in backticks (it does not): it is that both pairs it
> listed were already **inside the 9**, verb-anchored and reported. Listing them moved the
> unlisted-and-reported count from 3 to 1 and the listed count from 6 to 8; the 12, which are the
> pairs the verb filter never sees at all, were untouched.

**The exclusion has a one-directional cost and it is not hypothetical:** an exit genuinely offered
inside a fenced example is now invisible to the check. That trade was taken because a worked example
is not an offer, and a check that cannot tell them apart would make every future explanation of its
own behaviour a finding.

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
