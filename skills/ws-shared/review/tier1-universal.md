# Tier 1 — universal review checks

Applies to every change in every project. Written once; never duplicated into a project.

Grounding, so the weighting is not arbitrary:
- **~75% of what code review catches is evolvability** — readability, structure, naming,
  organisation — not functional bugs. Tests catch functional defects; review catches what makes
  next month expensive. A review that only hunts bugs is doing a quarter of the job.
- **Static analysis covers only ~16%** of what humans find. Lint and typecheck passing is
  nearly no evidence. Never report "checks pass" as if it were a verdict.
- **Attention decays across a changeset.** Later files get reviewed worse. So: read in a
  declared order, and **state which parts you actually covered**.

## The checks

**1. Design — the most important one.**
Does the change fit the system it lands in? Does it belong here, or in a shared library, or
not yet at all? Do its pieces interact sensibly? A change that works but sits wrong is a
finding.

**2. Functionality.**
Does it do what the author intended, and is that good for the user *and* for the next
developer? Look for edge cases, and bugs visible from reading rather than running.

**3. Concurrency.**
Race conditions and deadlocks are nearly invisible at runtime and nearly always visible on the
page. Any read-then-write on shared state, any counter, any stock or quota, any
check-then-act. Treat every one as a finding until shown otherwise.

**4. Complexity and over-engineering.**
Could it be simpler, at the line, function and module level? Generality for a need that does
not exist yet gets flagged — solve today's problem.

**5. Tests that would actually fail.**
Tests belong in the same change as the code. Ask of each: *if the implementation were wrong,
would this test go red?* A test that asserts what the code does rather than what it should do
is worse than no test, because it looks like coverage. Flag it loudly.

Two tests are required rather than merely nice: **a negative authorisation test for every new
protected endpoint** (the wrong user gets 403/404), and a test for the failure path of anything
that talks to an external service. Reviews catch evolvability problems and tests catch
functional ones, so a test that cannot fail removes the only functional net there is.

A concurrency test that fires two fast requests at once may never overlap: the first finishes
before the second starts, and the test passes even when the race handling is broken. Hold the
first inside the critical section (a slow fake, a barrier) and assert the loser's exact outcome.

**6. Naming.** Descriptive without being unreadable. A name that lies is a defect.

**7. Comments — is it the right content, and is it in the right place?** Two different defects:

- *Wrong content.* A comment restating the code is noise. A stale one is a defect. A comment that
  **contradicts** the code is a lie about behaviour, and worse than no comment at all. Check TODOs
  the change touches.
- *Right content, wrong place.* A comment that is really a document — a rejected alternative, a
  dated measurement, how the system composes, a claim that will expire — hides knowledge from
  everyone not reading that exact file, and rots where nothing re-reads it. **Move it, do not
  delete it.** `../review/documentation.md` has the detectors, the destinations, and the list of
  things that must *not* be reported, including the structured API documentation that belongs in
  the code.

**8. Consistency.** Where the style guide is silent, match the surrounding code. A change that
invents a second way to do something already done nearby is a finding.

**9. Documentation.** If the change alters how anything is built, run, used or released, the
docs change with it — in the same commit.

**10. Every line, and say what you covered.**
Read all human-written code in the diff. Skim generated files and data. If something is too
hard to understand, that is itself the finding — say so rather than guessing. End every review
by naming which files you read fully and which you skimmed.

**11. Invariants do not survive a later transformation on their own.** Where a change guarantees
a shape — sorted, alternating, non-empty, de-duplicated, bounded — find every slice, filter, map
or truncation applied to the same data afterwards, often in another layer, and check the
guarantee still holds there. A comment claiming the guarantee is a defect if it does not.

**12. Code health.** A change that works but degrades the system is not ready. Say what it
would cost later.

**13. Say what is good.** Name the thing done well. It is cheap and it is how the next change
gets better.

**14. Security and exceptional conditions.**
`../stacks/security-baseline.md` applies to every change, always — it is objective, mapped to
OWASP Top 10:2025, and not optional. Pay particular attention where the change touches auth,
identity, an external call, a new dependency, or user-supplied content.

## Severity

| Level | Means |
|---|---|
| **Must fix** | wrong behaviour, data loss, a security or permission gap, a migration that can destroy, a test that cannot fail, **a comment that contradicts the code or whose time-relative claim is already false** |
| **Should fix** | works but will cost later: duplication, a leaked abstraction, a missing edge case with a known trigger, **a comment that is really a document, a claim that will expire, a missing docstring on an exported public symbol** |
| **Note** | naming, a comment that merely restates the code, a simpler alternative. Never blocks |

Anything that is only taste is prefixed `Nit:` and never blocks.
