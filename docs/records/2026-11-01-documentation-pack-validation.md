# p8.2 documentation pack validation · 2026-11-01


Applied `review/documentation.md` and the rewritten `tier1-universal.md` check 7 to three
specimens found by surveying all `.ts`/`.tsx`/`.py` across the four projects. A pack that flags
all three is as broken as one that flags none.

## Specimen A — 39-line comment above one constant (Python, config.py)

**Expected: flagged, with destinations named. Result: flagged on all five detectors.**

| Detector | Evidence quoted from the comment | Destination |
|---|---|---|
| 1 — time-relative | "This was never set", "It has never actually been hit", "which this ran on **until today**", "It is **no longer** a guess" | rewrite time-independent |
| 2 — dated measurement | "A campaign build measured on 2026-10-06 used twelve tool batches"; "Measured on the first build that completed (2026-10-06): 125 super-steps" | `records/` |
| 3 — rejected alternative | "50 rather than more, because this is also the bound on a looping agent"; the 25 → 50 → 250 history and why two failed | ADR in `decisions/` |
| 4 — system fact | the five-node middleware list defining what a "step" is | `engineering/` |
| 5 — self-duplication | the twelve-tool-batches argument appears in paragraph 1 and again in paragraph 4 | shorten |

**Severity: Must fix.** Not merely because it is a document in the wrong place (`Should fix`), but
because detector 1 lands on a claim that is **already false** — the comment says the limit "ran on
LangGraph's default of 25 **until today**", written against 2026-10-06. Read now, "today" is
meaningless and the sentence asserts something untrue about the present.

**What stays behind:** the first line, plus a pointer. Something like — *how many graph steps one
turn may take; 250 from measured usage, see ADR NNNN.* Reporting "delete this comment" would be
wrong and would be rejected.

## Specimen B — 35-line file header (TypeScript, build-fit-cohort.ts)

**Expected: flag only the narrative, leave the usage block alone. Result: correct.**

| Section | Verdict | Why |
|---|---|---|
| `npx tsx scripts/build-fit-cohort.ts …` invocation lines | **not flagged** | counter-rule: usage blocks stay. A reader at this line needs the commands |
| "Makes real API calls. Writes `…/fit-cohort.ts` and commits it — the generated cohort is the artefact, not this script." | **not flagged** | the script's contract, true of this line |
| "── Why through the pipeline rather than by hand ──" and its three paragraphs | **flagged** — detector 3 | a rejected alternative with reasoning. ADR |
| corpus properties: "deliberately varied: bullet-heavy and prose, dated and undated…" | **flagged** — detector 4 | true of the corpus, not of this script. `engineering/` |
| "These members carry **enrichment-produced** significance… The two are not comparable on magnitude" | **flagged** — detector 4 | a data-model fact spanning modules |
| "── What it does not do ──" | **partially flagged** | the one-line fact stays — which of the two scores these records carry, and that the other reads zero; the rationale behind it, that synthesising the missing input would attribute a score nobody chose, is a rejected alternative, so it moves |

This is the specimen that proves the rule works: **one comment, two different right answers**, and
the pack separates them rather than treating length as the defect.

## Specimen C — two docstrings (Python, supabase_subscriptions.py)

**Expected: not flagged at all. Result: not flagged.**

- `"""One subscription by its Stripe id."""` — a PEP 257 summary line on a public function.
  Counter-rule: structured API documentation belongs in the code.
- `"""The subscription to show this person, newest first.` … *"A customer can accumulate rows — a
  lapsed Start purchase, then a plan — so 'current' is the most recently updated one rather than
  the only one."* — structured API documentation **plus** a durable one-line *why* explaining a
  non-obvious choice, read exactly where it is needed. Two counter-rules.

No detector fires: no time-relative language, no dated measurement, no rejected alternative, and
the fact is true of this function rather than of the system. A length- or density-based rule would
have flagged this one, which is why the plan rejected that rule.

## Result

| Specimen | Expected | Actual | Pass |
|---|---|---|---|
| A — constant comment | flag, Must fix, destinations named | flagged on 5/5 detectors, Must fix | yes |
| B — mixed file header | flag narrative only, keep usage | usage and contract untouched; narrative flagged | yes |
| C — docstrings | no finding | no finding | yes |

**The pack discriminates.** The same two repos that hold the two worst offenders also hold
exemplary docstrings, and the rules separate them.

## Not proved here

- Behaviour on Go and Rust: the language table asserts their conventions but no specimen existed
  in these projects to test against. Marked as asserted, not verified.
- Whether `ws-plan` step 11 actually changes planning behaviour. That needs a real task planned
  after this change, not an inspection — it will be observable on the next planned track.
