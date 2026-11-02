# 0003 — A shared external store is declared in the cartridge, as a top-level `shared_stores:` list

**Date:** 2026-11-02
**Status:** accepted
**Supersedes:** —
**Builds on:** [ADR 0001](0001-library-is-the-source-of-truth.md)

## Context

`ws-fanout`'s safety gate asks whether worktrees isolate the tracks in a batch. That question is
only answerable about files inside the cartridge's `repos:`, because a worktree *is* a checkout of
a repo in that list. Work that lives outside it is invisible to the gate, so the gate answers
"safe" for a batch that is not.

This is not hypothetical here, and it was found by running the pack on itself. Most of this
project's open work edits the agent-sync library, which [ADR 0001](0001-library-is-the-source-of-truth.md)
establishes as the working copy of the skills and which is **not** one of this project's repos.
`worktrees: true` isolates checkouts of this repo and does nothing at all for the files actually
being changed.

The sharper half is not a file collision, which is why no amount of worktree would catch it. The
library's publish is a **single global operation**: it validates, deploys to every agent, then
commits and pushes the whole store. Two tracks editing it cannot publish independently — whichever
publishes first carries the other's half-finished edits out to every agent and pushes them, and
the second track's own publish then carries a state nobody reviewed. Both tracks' reports read as
successes.

Three constraints shaped the answer:

- **The gate runs before any work exists.** No gate can observe what a track *will* edit, so the
  only implementable shape is declare-then-detect.
- **A skill must not hold one project's facts.** `ws-fanout` is generic and published; a store
  path written into it would be one person's setup baked into every project's rulebook — and in
  this project's case it would be caught by the leak guard it would have to pass.
- **A key with no reader is a defect the pack already has twice.** `merge_style` is read by a skill
  and written by no template; `schema_version` is written by the template and read by nothing. A
  third of those was not worth adding.

## Decision

**The cartridge declares such a place, in a new top-level `shared_stores:` key: a list of
`{id, path, publish, note}`.**

```yaml
shared_stores:
  - id: agent-library
    path: ~/.agent-sync/store
    publish: agent-sync save
    note: "one global save — validates, deploys to every agent, then commits and pushes the whole store"
```

1. **Top level, not nested inside `repos:`.** The field reference is in
   [the cartridge schema](../integration/cartridge-schema.md#shared_stores).
2. **`ws-fanout`'s gate gains a second question** — *does any candidate track touch a declared
   store?* — established readable-first, exactly as the isolation check already is. Each candidate
   is classified **touches / does not touch / unknown** per store, from the inputs that exist
   before the task is claimed — its tracker entry, its acceptance criteria, and its plan where it
   has one. `- Stores:` is written into `task.md` at claim time by this same gate, so it is what a
   **resumed or taken-over** track is read from, not an input the gate has on a fresh candidate. A
   candidate whose use of a store cannot be determined from what exists is `unknown`, and `unknown`
   is a drop.
3. **One track per store per batch.** Of the tracks that touch a store, one stays and the rest are
   dropped from the batch — the same decision as a file overlap, in the same vocabulary. `unknown`
   is a drop too, never a quiet "does not touch".
4. **Two scopes of stop, kept distinct.** An unreadable cartridge stops the **whole batch**, which
   is existing behaviour and unchanged. A track whose store usage cannot be determined drops
   **that track**.
5. **`publish:` is forbidden by name in every other brief in the batch**, including the briefs of
   tracks that touch no store at all. The failure arrives from a track nobody thought was involved:
   one that never edits the store but runs its publish command for an unrelated reason.
6. **`ws-setup` asks for it**, with **none** as its recommendation, and its template ships
   `shared_stores: []`. The key has one reader, one writer and one definition site
   (`ws-shared/reference.md` and `ws-shared/tracks.md`).

## Rejected

**Nesting the store inside `repos:`.** The taxonomic argument is tempting — it is a place with
files, like a repo. The decisive argument is mechanical: several skills loop over `repos:` and run
git and the project's `verify` in each entry. `ws-plan` and `ws-start` both iterate it — as
`for r in <repos>; do` when this was decided, as a `while IFS= read -r r` loop over the repo paths
since p8.13 — and `ws-verify`'s first section is "The repos' own checks". A store
placed in that list would be fetched, branched, worktree'd and verified as if it were the
project's code. The key's only meaning is "this is **not** one of the repos", so nesting it inside
the list of them inverts it.

**A boolean `shared_library:`.** Cheapest possible change, and enough for this project, which has
exactly one such place. Rejected because it carries no path and no command, so the gate could
refuse a batch but could not tell any builder *what* to avoid — and the forbidden-by-name line in
every other brief is where the sharper failure is actually prevented. A boolean also cannot
express two stores, and a project with a shared design store and a shared fixture bucket is not
exotic.

**`ws-fanout` knowing the library itself.** Zero schema change, and the skill already has to know
about agent-sync for other reasons. Rejected on the rule `ws-refine` exists to enforce: a generic
skill names no project, path or store belonging to anyone real. It would also solve the problem
exactly once — for one store, on every project, whether or not that project has it — which is the
same shape of defect the task was filed against.

**Carrying it in `machine:`.** Superficially apt, since a store's path is a property of a machine.
Rejected because `machine:` has **no merge semantics and no reader**: the key is named and keyed
off the device id, and no skill is documented as applying a device block over the top-level keys.
That is an open gap on the schema page, and putting the first real consumer inside it would be
inventing the rule that gap exists to decide. The shape this does cost is a store that genuinely
moves per device; `path` is `$HOME`-relative, which is identical on every machine for a store a
tool owns, and anything else is a `TODO:` and a line of prose.

**An `isolated_by_worktrees:` field on each entry.** Explicit, and it would let the gate read the
answer rather than derive it. Rejected because it could only ever hold `false` — a worktree is a
checkout of a repo in `repos:`, and this key describes somewhere that is not one. A field with one
legal value is schema noise, and worse: it invites the gate to trust the author on the single fact
it can derive itself. The invariant is stated in prose on the schema page instead.

## Consequences

- **A project that declares nothing has a gate that still cannot see outside `repos:`.** That is
  the residual, and it is why `ws-setup` *asks* rather than only documenting. An absent key and an
  empty list give the same answer, and that answer proceeds — degrade, never fail.
- **`ws-refine` deliberately does not read the key.** Its store *is* the library by definition: it
  is the skill for editing it, it already names the path and already runs the publish. Making it
  look that up in a cartridge that may not exist improves nothing. This is written down so the
  next reader does not "finish the job".
- **One new branch that must not read an empty result as a negative answer.** Three gates in the
  pack already do, and that is an open follow-up; the new branch is written against the pattern
  rather than into it — `unknown` is a drop, and an unreadable cartridge is a batch stop.
- **The forbidding is by brief, not by a schema value.** There is no general way in the cartridge
  to say "this command exists, do not run it". If one lands, `publish:` should be revisited to use
  it.
- **That the gate fires on the next real batch is not proved by this ADR.** It is a claim about an
  agent's behaviour, provable only by a subsequent real `ws-fanout` run — the same honesty
  [ADR 0002](0002-publishing-is-a-guarded-copy-from-the-library.md) applies to its own publish step.
