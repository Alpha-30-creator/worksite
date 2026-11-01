# 0002 — Publishing is a guarded file copy, checked in a throwaway clone

**Date:** 2026-11-01
**Status:** accepted
**Supersedes:** —
**Builds on:** [ADR 0001](0001-library-is-the-source-of-truth.md)

## Context

ADR 0001 settled the *direction*: the agent-sync library is the working copy, this repo is a
published artifact, and `ws-refine` ends by publishing. It did not settle the *mechanism*, and
until now there was none — parity was maintained by an agent copying files by hand and
remembering to. The most recent skill commit before this one is titled "sync the pack copy",
which is what hand-maintained parity looks like in a log.

Four facts constrain the mechanism, all of them established by reading the tree rather than
assumed:

- **The library holds far more than this pack.** Only fourteen of its skill directories are
  `ws-*`; the rest are the author's private project packs, whose *names* are themselves entries
  in [`scripts/leak-patterns.txt`](../../scripts/leak-patterns.txt). Anything that shares the
  library's history or directory shares those.
- **The publish target's own path is a private name.** The patterns include the author's home
  directory and workspace folder, so a target path hardcoded in a published skill would be caught
  by the very guard it runs. The target must come from configuration that is never published.
- **[`scripts/check.sh`](../../scripts/check.sh) is git-aware.** It enumerates files with
  `git ls-files` or `git diff --cached`, so it cannot be pointed at a loose directory. A candidate
  that wants to be scanned before it lands has to sit inside *a* git repo.
- **The friction budget is zero.** The task that produced this ADR says so: if refining a skill
  becomes more steps than it was, ADR 0001's design has failed rather than been endured.

## Decision

**A script in this repo — [`scripts/publish.sh`](../../scripts/publish.sh) — invoked by a short,
configuration-driven step at the end of `ws-refine`.**

1. `ws-refine` resolves zero or more targets from `~/.agent-sync/publish.targets`, one absolute
   workspace path per line. No file means no targets, which means today's behaviour exactly: a
   one-line note and carry on. For each target it runs `bash <target>/scripts/publish.sh` and
   respects the exit code. That is the whole of the generic side — **+1 command, 0 decisions**.
2. The source is the glob `ws-*` inside the library's `skills/`. **Never a hand-maintained list
   of fourteen**: a list is bookkeeping, and bookkeeping rots. The glob keeps the private packs
   out **by the library's naming convention, which review must keep true** — not by any property
   of the filesystem. A future private pack named `ws-anything` would be copied, and a directory
   named exactly `ws-` is matched too. `ws-shared` is included — it is already published, and the
   other thirteen skills link into it.
3. The script refuses, before copying anything anywhere, on: a missing source; a source with no
   `ws-*` directories; a target that is not a git repo; a target not on `main`; a dirty target
   tree; a target whose `check.sh` is **already** failing; and a skill published here that the
   source no longer has, unless `--prune` is passed.
4. The candidate is assembled in a throwaway `git clone` of this repo, staged there, and the
   guard runs **there** — staged first because the guard enumerates with `git ls-files`, which
   would otherwise still list a file that `--prune` had removed. Two classes of content are
   refused in preflight instead, because the clone scan cannot see them: a **symlink** anywhere
   inside a skill (the guard's working-tree mode reads content with `cat`, which follows the
   link, so it never sees the link's own path string — while git commits a blob whose content
   *is* that absolute path), and any file inside a skill directory that is neither pack Markdown
   nor the pack's own reference data — a dotfile such as an `.env`, an editor backup, a stray
   agent artifact. Everything in a skill directory is published, and the guard is a list of
   private *names*, not a secret scanner. `--allow-extra` lifts the second refusal and then names
   every file it let through; reference data files are listed on every run, since a secret can
   wear any extension. On a leak the script prints the guard's own `file:line` output, says the fix belongs
   to the library copy, and exits non-zero — and this repo has not been written to at any point.
   No commit, no staged change, no new file.
5. Before trusting a green guard, the script asserts the copy is plain: `diff -rq` of each source
   skill against the candidate must be silent. ADR 0001's load-bearing property is therefore an
   executable assertion, not a hope. If it ever fires, the de-personalisation in P2 is incomplete
   and the fix belongs there.
6. Only then is the real tree written and staged — and **the guard and the plain-copy assertion
   both run again, here, against that staged tree**. The candidate and the real copy are two
   independent copies from a source that can change in between, so until this run nothing has
   checked the bytes that are actually about to be committed. `--staged` mode reads blobs with
   `git show`, which also sees a symlink's own path rather than following it. The pre-commit hook
   then runs `check.sh --staged` once more, independently of this script; a publish refuses up
   front if that hook is not installed, because a missing hook is silent. Never `--no-verify`.
   Nothing to copy means "nothing to publish" and exit 0, because a step at the end of every
   refinement must not produce empty commits.
7. **From the first write to this repo until the commit lands, every failure path restores it** —
   `reset --hard` to the HEAD it was found with, `clean` of the untracked files it added — and
   says what it restored, or says loudly that it could not. Without that, a commit refused by the
   hook (or by a missing `user.email`, a signing failure, an index lock) would leave this repo
   staged and modified while the message claimed nothing had changed, and the leftovers would
   then trip the next run's dirty-tree refusal with no hint of what to reset.
7. `git push origin main`. A plain fast-forward push; never `--force`, never `--force-with-lease`.

### Carve-out: publish commits land on `main` directly

The project's git flow says changes reach the trunk by pull request. A publish commits straight to
`main`. This is deliberate, and it is a carve-out rather than an oversight:

- The branch the flow names as the PR target **is `main` here**. The rule was written for projects
  with a staging branch between feature work and the trunk; this repo has no such branch, so the
  rule has nothing to protect.
- A publish is a plain copy of content that was already proposed, approved and reviewed **in the
  library**, through `ws-refine`'s own propose-and-wait step. A PR would review the same bytes a
  second time, with no new information available to the reviewer.
- The guard runs three times on the publish path — in the throwaway clone, again on this repo's
  staged tree, and once more in the pre-commit hook on exactly those staged bytes — which is more
  checking than a PR would add.
- The task's own notes set the friction budget at zero, and this repo
  [declines pull requests](../engineering/sync-direction.md) anyway: a merge here would be
  overwritten by the next publish.

**Residual risk, stated plainly:** `main` is public and permanent, so a bad publish cannot be
taken back by reverting — the objects remain. And the scan bounds the **patterns listed** in
`leak-patterns.txt`, not privacy: a private name nobody has added to that file passes every run
of the guard, and a secret is not a name at all — which is why the content filter above refuses
unexpected files outright rather than trusting the scan to catch what is in them. A green publish means "no known pattern". It has never meant "no private data", and the
publish step says so in those words so that nobody reads it as a clean bill of health.

## Rejected

**Instructions inline in `ws-refine`'s own Markdown.** Cheapest, needs no file anywhere, and
consistent with the inline audit block the skill already carries. Rejected because the one
operation here that must be unmodifiable is the *refusal*. Prose is read and re-typed by an agent
that may reasonably "adapt" it — drop a `set -e`, reorder a step, skip a check that looked
redundant — and the failure mode is a private name in a public commit, which cannot be taken back.
An exit code in a file is not adaptable. The inline block is a fair precedent for reporting and
the wrong one for a gate.

**A script shipped inside the library, travelling with the skill.** Tempting: a stranger who
installs the pack would get the publisher too. Rejected on three counts. It would have to guess
each target's guard — its pattern file, its allowlist, its two modes — baking one artifact's
conventions into a generic skill, which is the thing `ws-refine` exists to prevent. It would add
an executable to a pack of Markdown, whose mode bit's survival through `agent-sync save` and three
deploys cannot be verified without running the deploy. And it would be published *into the repo it
publishes to*, so a bug in it ships to readers as part of the pack.

**Folding the publish into `agent-sync save`.** The most friction-free answer of all: zero extra
commands. Rejected because `agent-sync` is a different product, and `save` runs for every project
on every edit — one artifact's publish rule has no business in it. If this step proves reliable,
promoting it there is a task for that project, not a shortcut here.

**Any git-level mirror — subtree, a filtered ref push, a mirror remote.** Mechanically attractive,
and it would give this repo real history. **Hard no, and the most important rejection here:** the
library's history carries the private packs. Any ref pushed out of that repo risks carrying
objects that cannot be unpublished. The publish must be a **file copy into a repo whose history
has always been public**.

**Symlinking `skills/` at the library.** Then this repo holds no content for a reader, which
defeats the point of publishing it.

**A CI job that pulls from the library.** The library is private, CI does not exist here yet, and
a credential with read access to a private library, configured in a public repo, is a worse hazard
than the one being solved.

## Consequences

- **The hard gate now exists where `check.sh` said it should.** Section 4 of `check.sh` is a drift
  *detector* and says in its own comment that the gate belongs to the publish step. It now does.
- **Deleting a published skill stays a human decision.** The orphan refusal means a mechanical
  copy never performs a deletion; `--prune` is how someone means it, and a `--prune` that would
  remove more than a third of what is published needs `--prune-many` as a second, separate yes.
  A mistyped `--from` pointing at a thin but otherwise valid source looks exactly like a
  legitimate large deletion, and nothing else in the script would tell them apart.
- **The target owns its publish rules**, which is why this script lives here and not in the pack.
  Another artifact published from the same library would write its own.
- **The step's behaviour is earned on the next refinement.** That the publish actually fires at
  the end of a real `ws-refine` run is a claim about an agent's behaviour, provable only by a
  subsequent real refinement — not by this ADR and not by the script's tests.
