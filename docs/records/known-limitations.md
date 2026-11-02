# Known limitations

**Recorded 2026-11-02.** Seventeen mechanisms in this repo and in the pack that work, and the
boundary each one stops at. Each entry names the mechanism in one clause and its boundary in the
next. This is a record, not a task list: an entry changes only when the mechanism does, and then
it changes in the same commit.

These were filed as roadmap tasks and triaged out on 2026-11-02 by the owner, after an
independent audit. A limitation that is written down costs a reader one sentence; the same
limitation as an open task costs every reader a decision about whether to take it.

## `scripts/check.sh`

**Section 3 is not fence-aware.** Its extraction greps the whole file for bracket-paren pairs, so
a link written inside prose or inside a fenced code block is resolved as a real target and fails
the build; a page that documents the link checker cannot show a broken link.

**Section 3 resolves relative links only.** It never resolves an anchor, never a line number, and
never its own coverage. Section 1's allowlist used to be part of that gap — one string was inline
in the script rather than in `scripts/leak-patterns.txt`, so the pattern file did not describe the
whole scan. It does now (p8.31); what remains outside it is the excluded-files table in
[../engineering/layout.md](../engineering/layout.md).

**`LICENSE`'s exclusion from section 1 is whole-file.** It is applied before the file's content is
read, in both modes, rather than being scoped to the copyright line that needed it, so a line that
would fail section 1 anywhere else in the repo passes there — measured on 2026-11-02 by staging a
pattern-carrying line appended to a copy of it
([2026-11-02-leak-guard-refusal.md](2026-11-02-leak-guard-refusal.md)).

**A refused commit leaves the rejected content in the object store.** `git add` writes the blob
before the pre-commit hook runs and `git restore --staged` only rewrites the index, so the guard
keeps the name out of history and out of every commit while the bytes remain as an unreachable
loose object until something prunes them; the hook cannot reach back past its own invocation.

## Trackers

**Claim locks are not uniform.** Only the file-based adapters — `roadmap-files` and `tasks-file` —
give a real lock, where a pushed commit either wins or is rejected; the hosted adapters re-read
after claiming and trust what they see.

**No adapter answers "what is the status of id X?"** The stale sweep in `ws-start` therefore
decides by set difference against the open, claimed and blocked lists, and asks about what is
left rather than removing it.

**`tracker.lists` names the open and in-progress lists only.** On a three-list board the agent
has nowhere to record where a finished card goes, so it asks, every task, for the life of the
project.

**Three of the pack's documented steps cannot be run in a sandbox.** `ws-sync` step 1
(`agent-sync sync` — pull, apply, push against the real library, with no read-only form),
`ws-env pull` (decrypts to disk), and `agent-sync save` (deploys to every agent and pushes) all
write outside a working directory, and none has a `--store` or dry-run escape. A cautious
first-time user therefore cannot trial the pack without writing to their own machine. Measured
2026-11-02 when two agents following `INSTALL.md` refused all three.

**`ws-env status` cannot be fully answered without the age key.** Its table promises whether each
file matches the store "by variable names, never values", which requires decrypting. So the mode
the skill calls "read-only and always safe" is complete only on a machine that already holds the
key; elsewhere the match column is unverified rather than clean.

**A retirement block that must run whole can be refused for being exactly that.**
`ws-shared/tracks.md` requires its removal block to run in one shell, because an in-script `$id`
guard is what bounds its `rm -rf`. An agent harness that screens commands may refuse the block for
containing that construct — met 2026-11-02 — leaving the operator to run the removal with the path
written out literally. Nothing in the pack can resolve this; a documented safety mechanism and a
platform one are in direct opposition.

**`tracker.statuses` is declared schema-less.** An adapter needing a board's column names has no
shape to read, so it states that need in its own text rather than relying on one the pack does not
define. Recorded here on 2026-11-02 after p8.33's merge note said it had been — it had not, and
`engineering/trackers.md` was the only file mentioning it, pointing at a task id that no longer
exists.

## The cartridge

**There is no way to say "this command exists, do not run it".** A `null` command means the repo
does not have one, which is a different claim; the do-not-run case is enforced by briefing the
agent, not by the cartridge.

**`schema_version` has no reader.** It is present in `ws-setup`'s cartridge template and in
`ws-shared/examples/cartridge.md`, and a grep over `skills/` finds no skill that reads it — it is
a marker for a human, not a compatibility mechanism.

## Tracks

**The no-upstream refusal when retiring a track is deliberately conservative.** It refuses a
worktree whose branch has no upstream of its own, so it also refuses a branch that was merged and
pushed by another route, and the operator's escape is to override it knowingly.

**An `artifacts: in-repo` project's journal does not travel between machines.** `in-repo`
relocates the plan and only the plan, and the journal mirror is exempt on that layout, so a track
resumed on a second machine resumes from the plan and the tracker.

## The leak guard

**Section 6 reads unreachable objects only; no section reads reachable history.** Section 1 scans
the current tree, so a private name in an old commit is invisible to the whole suite. That case is
the [purge runbook](../runbooks/purge-a-leak-from-history.md)'s, and it is the operator's to
notice.

**A reflog cuts both ways against section 6, and the second direction cost a publish.** It hides
residue from the source (below) — and a local `git clone` copies the whole object store while not
copying reflogs, so everything the source's reflog was holding becomes *unreachable in the clone*.
`publish.sh` assembles its candidate in exactly such a clone, so section 6 refused every publish
until the candidate scan was given `--no-object-store` (p8.38). The mechanism was already written
down here before it bit; what was missing was reading it from the other end.

**A reflog hides residue from section 6 for as long as it holds it.** `git fsck` treats reflog
entries as roots, so the blobs and trees of a commit just dropped by `reset` or `amend` are still
*reachable* and the section cannot see them — it becomes able to only when the reflog expires,
typically 90 days later. The section is therefore at its weakest in the minutes after the mistake
it would catch. Measured 2026-11-02: an abandoned commit's tree appeared to section 6 only after
`git reflog expire --expire=now --all`.

**Section 6 does not scan unreachable commit objects.** A commit header always carries the
committer's name and email, so a pattern list that includes the author's name matches every commit
and nothing can distinguish that from a leak. The number of unscanned commits is printed, so the
gap is visible rather than implied.

**Section 6's baseline is a list of hashes, so it is machine-local by nature.** A fresh clone has
none of those objects and reads zero; the declaration protects the machine that measured it and
nothing else. It cannot distinguish residue from a worktree's work in progress either, which is
why the decision not to prune lives in the file rather than in the check.

**The journal's device alias is not a secret.** It is `dev-` plus six hex of the device name's
sha256, so anyone who guesses the name confirms it. The claim is narrower than privacy: a mirror
pushed to a public repo stops carrying a name nobody chose to publish. A hand-written override in
the state dir is the author's to keep non-identifying; nothing checks it.

## The docs and the pack

**`file:line` citations anywhere in these docs are advisory.** The published copy they anchor to
moves whenever a skill gains a line, so the quoted text is the durable half of a citation and the
number is a convenience.

**Nothing proves an agent runs `ws-refine/audit.sh` rather than reconstructing it.** The skill
says to run the path and says why, and there is no longer a positional parameter in its body to
paste — but an agent that runs a **stale deployed** copy of `audit.sh` is caught by part 1 only
when the library has moved. Part 7 tracks `.md` files, so it does not notice the script itself
being out of date.

**A CRLF `audit.sh` would fail quietly.** `set -uo pipefail` with a trailing carriage return
prints `set: pipefail: invalid option name` and the script *continues* without `set -u` or
`pipefail` — measured, exit 0. The library copy has no CRLF and nothing asserts that it stays that
way; `scripts/check.sh` does not scan `.sh` files for line endings.

**The repo-path loops are a shape, not an executed rule.** p8.13 replaced the three
`for r in <repos>` loops with the heredoc `while IFS= read -r r` form and proved all three by
execution under bash against a workspace path containing a space. What ships is still a
**template**: the heredoc body reads `<repo paths, one per line>` and an agent fills it. So the
rule is enforced by the shape being hard to fill wrongly, not by anything that runs. Nothing in
`scripts/check.sh` or in `ws-refine`'s audit looks for `for r in` in a skill body, and a future
block written fresh in the old shape would ship.

What holds is narrower than this paragraph first claimed. A `for` list can perfectly well be
quoted — `for r in "$root" "$root"/*/`, quoted in the `ws-sync` paragraph below, is one — so the
claim is not about `for`. It is about the **template**: `<repos>` is a single placeholder, giving
the filling agent no per-path slot, while each heredoc line is one path by construction and is read
whole. A second guard covers the rest: `git -C "$r" rev-parse --show-prefix` with an emptiness test
on each path, measured empty at a repo root, a linked worktree root, a bare repo and through a
symlink, and non-empty only in a **work-tree** subdirectory. A wrong *fill* — a stray leading or
trailing space, a tab, a CRLF, a glob character, an unexpanded `~`, every path on one line, a
subdirectory rather than a repo root, or the placeholder left in verbatim — now prints a named
`NOT A REPO ROOT` line instead of one more reassuring `0 changed`. Twelve fillings were run before
and after, with the raw output kept. The subdirectory case is the one worth knowing about:
`rev-parse --git-dir`, which the first version of the guard used, succeeds there by discovery, so
the path was accepted and git reported on the **parent** repo under the subdirectory's label, with
no error printed anywhere.

**The guard is loud but not fatal.** `continue` leaves the exit status at 0, so a fill in which
every path is wrong still exits 0 — the output is the signal, not the status. It also prints
`NOT A REPO ROOT` for a directory git cannot read, or refuses under its dubious-ownership check,
and `2>/dev/null` hides git's own reason; the message points at the command rather than asserting
the fill was wrong. `--show-prefix` is also empty **inside** the git directory, so `<repo>/.git`
passes the guard and `git status` then fails with `fatal: this operation must be run in a work
tree`. Left alone: unlike the subdirectory case, that one prints an error.

**The four skill loops quote the delimiter (`<<'REPOS'`); `ws-shared/tracks.md`'s do not, and
should not.** The first draft of this change left the delimiter unquoted and justified it by
claiming that quoting would break `tracks.md` — which was simply false, since those are separate
blocks in a different file. The skills' heredocs hold literal paths, so quoting them is right and
they are now quoted: a path containing `$` or a backtick reaches `read` unaltered. The retirement
block in `tracks.md` fills its loops with `$repos` from a variable and its `done <<REPOS` must stay
unquoted for that to expand, while the `repos=$(cat <<'REPOS' … )` that *builds* the variable is
quoted. Two different jobs, two correct answers — stated because they look inconsistent.

**`ws-sync`'s two loops were deliberately left as `for`.** `for p in $(projects)` is safe only
because the `sed` that produces the ids constrains them to `[a-z0-9-]`, and
`for r in "$root" "$root"/*/` is glob-based and quoted. Both are correct and neither is a finding
— stated here because they look like the bug p8.13 fixed and the next reader will want to "fix"
them.

**The pack's gates are desk-verified, not live-verified.** Every description, collision matrix and
refusal has been checked by reading and by composition against fixtures; nothing yet proves that
the loop's triggers fire in ordinary use, and the author of a description is the worst judge of
whether it fires.
