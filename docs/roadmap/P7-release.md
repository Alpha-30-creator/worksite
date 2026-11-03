# P7 — Proven by a stranger, then tagged

**Goal:** the install is known to work for someone who is not the author.

## [x] p7.1 — Dry-run the install as a stranger · 2026-11-02 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/16

- **Repos:** worksite
- **Depends on:** p4.2
- **Re-scoped 2026-11-02:** the `p5.1` dependency is removed because P5 is closed and both its
  tasks are dropped — the loop runs with no secrets syncing at all, so a stranger's dry run does
  not need an init mode. The `p6.2` dependency is now carried by p4.2, which absorbed it. The two
  cheapest cases of **p8.4** are absorbed here, because this task already stands up a throwaway
  project and running them costs almost nothing once it exists; p8.4 itself is dropped.
- **Acceptance:**
  - [x] a fresh agent-sync library and a throwaway project, following `INSTALL.md` only, using
        nothing the author happens to know — **two agents with none of this project's history, in
        temp stores; the forced `--store` is recorded as a stated deviation**
  - [x] every point where the agent had to guess, ask or improvise is recorded in
        `docs/records/` with a dated report — **44 guess-points; the eighteen in `INSTALL.md`
        enumerated in [the record](../records/2026-11-02-stranger-install-dry-run.md), the other
        twenty-six classed, because the logs are uncommittable in a public repo**
  - [x] each one becomes a fix or a documented limitation — not a note to self — **5 `INSTALL.md`
        fixes, 3 limitations, 2 tasks (p8.35, p8.36), 1 criterion on p8.30. Net +1 to the board**
  - [x] the loop is then run on one real task in that throwaway project, end to end — **all five
        stages on a one-file task, 8 commits, worklog harvested, track retired, tracker marked
        done, follow-up filed**
  - [x] run with **no cartridge**: `ws-review` must ask its three questions and continue;
        `ws-env` and `ws-sync` must work from the device file alone *(absorbed from p8.4,
        2026-11-02)* — **3 asked, 3 observed, verdict reached; both work with no cartridge, and
        the word does not appear in `ws-env/SKILL.md` at all**
  - [x] run against a tracker kind with **no adapter** — the four questions must get asked and a
        new adapter written, with no skill edited *(absorbed from p8.4, 2026-11-02)* — **4 asked,
        4 observed; a working adapter written with zero skill edits, verified by `diff -rq`. But
        the pack never picked it up — now a criterion on p8.30**

## [x] p7.2 — Tag and announce · 2026-11-03 · @Alpha-30-creator · https://github.com/Alpha-30-creator/worksite/pull/22

- **`v0.1.0` is tagged and pushed; the GitHub release is NOT published.** Tagging is the
  mechanic this task's body called untracked, and the criterion is met. Announcing is the first
  public statement this repo makes, so the drafted text waits on the owner's wording rather than
  on this task. Draft harvested into the worklog.

- **Repos:** worksite
- **Depends on:** p7.1
- **Cut 2026-11-02** to one criterion. Tagging and the reciprocal links are a release mechanic
  that needs no tracking; the claim-by-claim verification is the part that can fail silently, so
  it is the whole task.
- **Acceptance:**
  - [x] the README's claims all verified against the tagged tree — **39 checks, 0 failures,
        against `git archive v0.1.0` extracted into an empty directory** (no `.git`, no branch,
        nothing uncommitted). One claim was false: the gap table still named p7.1, which had
        shipped the day before. The enumeration is now `scripts/check-readme-claims.sh`, whose
        first version could not see the claims it was checking — nine false READMEs passed it
        until a review mutated a copy. Mutation test now 17/17. p7.3 filed: nothing runs it
