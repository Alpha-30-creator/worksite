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

**The retirement guard asks whether its own removal would lose commits — it took three drafts to
ask that.** The first asked whether an *upstream was configured*, which refused a branch
`worktree add -b` had created and never committed to, stranding every library-only track behind a
guard protecting commits that did not exist. p8.32 replaced it with a count of commits on no
remote-tracking ref, which fixed that and still asked about the wrong place: **a remote is where a
copy lives, and `git worktree remove` removes a checkout, not a branch.** Measured — after
removing a worktree whose branch held an unpushed commit, `refs/heads/<branch>` still points at
it. So p8.40 made the count ask which commits would be left reachable from **no branch, tag or
remote-tracking ref**, which refuses the one shape that really loses work (a detached `HEAD` that
committed) and stops refusing the three that do not. Being on no remote is now a printed note:
true, worth knowing, and not a reason to refuse. The decision is
[ADR 0006](../decisions/0006-retirement-refuses-what-removal-would-lose.md).

**A non-empty `<id>/` directory after retirement is reported, never deleted.** `git worktree
remove` takes gitignored build output with it (measured), so a successful removal leaves the
directory empty and one `rmdir` finishes the job. A directory that is *not* empty means an earlier
removal did not finish, and since `rm -rf` is the one unrecoverable act in this path the block
prints the size and contents and stops. The cost is real: `ws-ship` holds the tracker transition
until the verification line is clean, so leftover build output blocks marking the task done until
somebody looks at it. That is the intended trade — the directory is named for the track being
retired, so the residue belongs to it.

**Two readings of `../<project>-tracks` exist in the wild, and only new roots are governed.**
p8.32 made the worktree root a cartridge key resolved absolutely against the workspace root, with
the workspace's sibling as the default. `ws-start` reports an existing root found under the other
reading rather than creating a second beside it — but it reports it to a human, and adopting it is
a cartridge edit somebody has to make. Nothing migrates a root automatically, and a project whose
two roots each hold half the tracks stays that way until someone acts on the report.

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

**What still assumes a remote, after p8.36 and p8.40.** `ws-ship`'s push and PR steps are
unchanged: a local-only project genuinely cannot push or open a PR, and stopping is right, but
neither *says* so — both run `git push -u origin <branch>` unguarded, so what a stranger sees is a
raw git fatal rather than an explanation. `ws-wrap`'s push was the same until p8.40, which guarded
it, because `ws-start`'s stale sweep names `ws-wrap` as the exit for a track that holds work and a
remoteless project would be sent to a command that cannot run.

**Retirement no longer assumes a remote at all** (p8.40,
[ADR 0006](../decisions/0006-retirement-refuses-what-removal-would-lose.md)), and the paragraph
that used to live here was wrong in both directions across three drafts — worth keeping as a
record of how. The first two named an escape that worked only against the old test (set a local
upstream); p8.32 removed the test that made it work. The third, written by p8.32, called the
result "an absolute bar", which was equally false, and replaced it with the **local bare
mirror**: measured, 2 commits on no remote, `git push` to a `--bare` repo on the same disk, count
0. That measurement still holds, and it is still the honest answer to *"is this work anywhere but
this machine"* — but it was being offered as the answer to *"may I remove this worktree"*, and
p8.40 measured that the second question never depended on a remote. The bare mirror is a backup,
not a precondition. Four drafts, and what finally settled it was measuring the operation rather
than arguing about the test.

A track configured `worktrees: false` is still never checked by the guard at all, since it only
loops over the track's worktrees.

**The retirement block's fenced shell is never executed by `verify`, on any platform.** `check.sh`
reads the pack as text — frontmatter, links, parity — and CI runs `check.sh`, so a GNU-vs-BSD
difference inside a fenced block reaches CI only if `check.sh` itself trips over it. p8.32's block
was exercised against BSD `find` on macOS across nine fixtures; the one case left untested is GNU
`find -delete` on a path carrying a literal `..`, which GNU refuses and which the resolver can
still produce when the root's parent does not exist. No GNU `find` exists on the authoring machine.
This is the general shape of the p7.3 lesson and it has not been closed: the pack's executable
content is proved by whoever runs it, not by the gate.

**Mid-rebase and mid-bisect state in a worktree is invisible to every check retirement makes.**
The tree is clean and the commits are pushed, so retirement proceeds and `worktree remove` discards
an in-progress rebase. Lost work rather than lost commits, and not something a commit count can be
made to catch — recorded here because the guard's stated promise is about work, and this is work.

The tracker adapter `ws-shared/trackers/roadmap-files.md`
degrades with a named `COULD NOT REFRESH` message, but phrases it as "may be stale" even where
there is nothing to be stale against. What p8.36 changed is the seven places that
failed *before* reaching any such decision. The limitation that remains is in the degrade itself:
where `origin/<integration>` does not resolve, `ws-plan` and `ws-review` fall back to the **local**
`<integration>`, which is this machine's last-fetched view. A plan or a review built on it can
silently miss commits someone else has pushed. Both now print which ref they used, so the reader
can tell — but nothing checks whether that ref is current, because without a remote there is
nothing to check it against.

**The sync row reports the remote and the upstream as two separate facts, and that is deliberate.**
`ws-start` §1 now reads the fetch's exit status, so `NO REMOTE`, `FETCH FAILED`, `no upstream for
this branch`, `upstream [gone]` and `behind/ahead N/M` are named states rather than one confident
row — and the remote clause and the upstream clause both print, because they are independent: a
branch tracking a purely local branch in a repo with no remote reads `NO REMOTE — nothing was
fetched · behind/ahead 0/1`, which is exactly true. Six states measured, `[gone]` among them
(reproduced by deleting a non-default branch on the remote, since a bare repo refuses deletion of
its own HEAD branch). What the row still cannot say is *why* a fetch failed — git's own reason
prints above the table rather than in it. It also cannot tell one `rev-list` failure from
another: `2>/dev/null` means an unborn or orphan HEAD whose upstream ref *does* exist reads as
`upstream [gone]`. Narrow, and loud in every other respect, but it is a mislabel rather than a
silence.

**The pack's gates are desk-verified, not live-verified.** Every description, collision matrix and
refusal has been checked by reading and by composition against fixtures; nothing yet proves that
the loop's triggers fire in ordinary use, and the author of a description is the worst judge of
whether it fires.

**What section 7 of `check.sh` does not cover, after p7.3.** The gate now refuses a false README
claim, and the limits of that are worth stating in the same breath. It reads the **working tree**
in every mode, `--staged` included, because its checks open files with `cat` and `grep` and
`--staged` cannot redirect them. It asks which paths the index and the working
tree hold different content for, and prints them, so the mismatch is named rather than glossed —
but naming it does not remove it, and it cuts **both ways**. The hook can certify a README nobody is committing: with `README.md` staged
for deletion and still on disk, section 7 reads the on-disk copy and reports that every claim
holds. And symmetrically, **it refuses a commit over a working-tree claim nobody is staging** — an
unstaged README edit, or an untracked extra roadmap file or skill directory, changes what the
counts measure and blocks every commit in the repo until it is dealt with. Asking that question precisely took three attempts, and the two
wrong ones fail in opposite directions. `git diff --name-only` alone names none of the three cases
above and prints a conflicted path twice — a reviewer found all four by reproducing them.
`git status --porcelain` then named *too much*: it reports a staged, worktree-clean file as
uncommitted, which is the one case where the index and the working tree agree exactly, so this
task's own commit announced that all seven of its staged files differed from the commit they were
in. A label that is wrong on the ordinary case is a label nobody still reads by the time it is
right, which is why the noisy version is recorded here as a defect and not as a cautious choice.
It reads **the quantities it enumerates**, not every number in the README: the thirteen is stated
four times and only two of those are claims it reads, so a stale figure at `README.md`:48 or :49
passes. Widening that is cheap and deliberately not done here — it is claim coverage, which is
p7.2's subject, and this task is the wiring. It reads no prose judgement at all: whether
`docs/product/overview.md`'s argument persuades is not checkable, and a skill-table cell that paraphrases its skill's own `Ends with`
sentence fairly is reported as a `note` — three of the thirteen are, today — with only a cell
sharing no content word at all failing. And it covers `README.md` alone. `CONTRIBUTING.md`,
`SECURITY.md` and `docs/engineering/layout.md` state counts too, including the count of this
script's own sections, and **nothing reads a claim out of those files**; the arithmetic in them has
now been wrong twice (the "three shell scripts" that were five, p7.2; the six sections that are
seven, this task). That is the same shape one document further out, and it is recorded here rather
than filed, because a second claim checker aimed at three more files earns less than it costs.

**An `UNCHECKED` claim is not a claim that holds.** Section 7 distinguishes "this claim is false"
from "a tool this machine lacks means I did not look", and the second is deliberately not a
failure: the Node floor is read out of `agent-sync`'s own `engines` field, so a hard failure there
would turn CI — which has no `agent-sync` — red on a README that is perfectly true. The cost is
that a green gate on a reader's machine or in CI certifies **one claim fewer** than a green gate
here. That is why the count is printed in the section, each one named, and repeated in the closing
summary: the narrowing is visible rather than inferred. It is a wider hole than one claim, and the
widest case is worth naming: without `python3` the whole skill-table paraphrase check goes unread,
so **a README cell that genuinely contradicts its skill passes the gate there** — reported as
thirteen unchecked claims, counted, and named, but passed. The first draft reported those thirteen
as one, understating what went unread by twelve. The line this draws is that only a missing
*tool* is `UNCHECKED` — "no claim of that shape found in `README.md`" stays a failure, because it
means the README moved out from under the check rather than the machine being short of something.

**Two of the claim checker's ten groups were only ever correct on an idle board**, and nothing
could have found that until something ran it. Groups 8 and 9 read the roadmap's status markers and
counted only `[ ]` as open, so *claiming any task* — marking it `[~]` — dropped the open count by
one and failed the gate; measured both ways on 2026-11-03 before fixing it, with `[~]` on p7.3 for
group 9 and on p8.30, a gap-table row, for group 8. `[ ]`, `[~]` and `[r]` now all count as open,
which is what a reader means by an open gap — **and the first fix of that was itself wrong.** It
listed five markers and asserted "only `[x]` done and `[-]` dropped are closed"; the project
defines **six**, in `skills/ws-shared/trackers/roadmap-files.md`, `docs/roadmap/README.md` and
`docs/integration/cartridge-schema.md`, and the one it omitted was `[?]` blocked on a decision —
so marking any task blocked refused every commit. A reviewer found it from the definition. The set
was enumerated from memory in a repo that writes it down three times, and it is now defined once
in the script and shared by both groups — **and that sentence was false the first time it was
written too.** The "one definition" was read by group 9 alone; group 8 enumerated the same four
markers in its own arms, so narrowing the definition moved one group and not the other, which a
second review demonstrated by doing exactly that. Group 8 now tests membership against the shared
definition and uses its own arms only for the wording, which cannot disagree because a marker
outside the set never reaches them. An unrecognised marker is reported as unrecognised rather than
as closed, because reading an unknown marker as done is how `[?]` broke. The general form is
worth keeping: a check written as
evidence for one task is written against the tree as it stood that day, and the states it never
saw are the ones it gets wrong the moment it starts running on every commit.

**A tool that is present and does not work is the hole this task kept falling into.** Section 7's
contract is that a missing tool makes a claim `UNCHECKED` rather than failing the gate, and twice
the code tested the wrong thing. `command -v python3` succeeds for a python3 that cannot run —
the ordinary macOS state with no Command Line Tools, where it prints `xcrun: error: invalid active
developer path` and exits 1 — so the check took its python3-present branch, produced nothing, and
reported "a README claim does not hold": a tool failure diagnosed as a false README, the contract
exactly inverted. Worse, the `package.json` walk it then entered **never terminated**: the
realpath came back empty, `dirname ""` is `.`, `dirname "."` is `.`, and nothing bounded the loop.
That loop predates this task and was harmless while nothing ran the script; section 7 runs it in
`verify`, in the pre-commit hook and at all three publish sites, so p7.3 is what would have hung
every one of them, with no output and no timeout. `python3` is now probed by running it, `mktemp`
is probed too because the same block needs it, and each message names the tool that is actually
absent rather than the first one in the list. A **real** bug in that block still fails, which is
the line that matters: a tool this machine lacks is `UNCHECKED`, a program that is here and wrong
is a failure.

**Every measurement in this repo was taken under a `grep` that CI does not have.** On the author's
machine the first `grep` on `PATH` is `ugrep 7.8.4`, not the `/usr/bin/grep` that is BSD grep
2.6.0-FreeBSD, and CI runs GNU grep on `ubuntu-latest`. The checks here use a small common subset
— `-c`, `-h`, `-o`, `-E`, `-q`, `-x`, `-l`, `-v` — and section 7 is green in CI as well as locally,
so nothing is known to differ. What cannot be claimed is that the three implementations agree on
anything not exercised, and the figures recorded in this repo's `records/` and `verify/` artefacts
were produced under the first of the three. Noted by a reviewer, which is the only reason it is
written down at all.

**A placeholder is a template, and a template is filled by someone who is not reading carefully.**
p8.13 fixed the loops that iterate repo paths; p8.39 fixed the *placeholders* those loops and
every other block substitute into, which had carried no quotes anywhere in the pack — about thirty
sites across most skills. The two are the same defect reached from different directions, and the
second is the one an author writes without noticing, because a fenced block reads as correct until
somebody fills it with a path that has a space in it. What makes it worth a limitations entry
rather than only a fix is that **it was filed as a loud failure and is not one.** The loud shape is
`git -C <repo> status --short` → `fatal: cannot change to '…/My'`. Three are silent: the same idiom
inside `$( )` still prints its row, `0 changed`, at exit 0; and a `2>/dev/null` placed there for
"the file is absent" suppresses "you split my path" identically, so
`cat <state_dir>/tracks/current` reads as *no current track* and `ls <state_dir>/tracks/` as *no
tracks on this machine*. A fourth is neither — an unquoted **assignment** does not split at all:
bash takes `state_dir=/x/My Projects/.p` as a prefix assignment for the command `Projects/.p`,
which fails **audibly** and does not persist, so the variable is **empty** and
`rm -rf "$state_dir/tracks/$id"` becomes one argument, `/tracks/$id`. That exits 0, the
verification beside it checks the same wrong path, and the retirement prints
`clean: track removed` over a track it never touched. So that one is loud and *then* falsely
reassuring, which is harder to catch than silence, because the error has already scrolled past by
the time the success line arrives. **Both halves of this paragraph were wrong first.** The task
body claimed a plain loud failure; the correction then claimed four silent shapes and attributed a
destroyed file to the assignment, which cannot produce it — that was a different shape, an unquoted
*use*, and no `rm` in the pack has that form. A severity claim is a claim, and it took two reviews
to get this one right.

**What p8.39 deliberately did not quote, and why that list has to be written down.** An agent told
"quote the path placeholders" will quote these too, and each one breaks: `<paths…>` in
`git add <paths…>` is several words on purpose; `-R <owner>/<repo>` is a GitHub slug rather than a
path; a **bare id** cannot hold a space, so quoting it is noise that makes the real quotes harder to
see — `<project>` is constrained to `[a-z0-9-]` by `device.yaml`'s own parser, while a track id is
constrained by the pack's convention and not by any parser, and the first draft of this sentence
credited the parser with both. An id composed *into* a path is a path and does take the quotes. Two forms also look
wrong and are right: `~/"<folder>"` rather than `"~/<folder>"`, because the tilde does not expand
inside quotes, and `"<path>"/P*.md`, because the glob has to stay outside them. Fenced blocks that
are **not commands** — output samples, tables, generated-by headers, file templates — were left
alone, and they are named in [the p8.39 worklog](../agent/worklog/p8.39.md) rather than left as
silence a later reader would have to re-derive. An earlier draft of this sentence cited the track's
`verify/01-inventory.txt`, which is gitignored and is deleted when the track is retired: a
permanent record must not point at an ephemeral one, and that is the second time this task pointed
a reader at something they could never open.

**Deploying a shared store is not publishing it, and conflating the two produced a rule nothing
could follow.** `agent-sync apply` writes each agent's copy of the library and commits and pushes
nothing; `agent-sync save` does that *and* commits and pushes the whole store. p8.30's first draft
treated them as one step and concluded that only the lead may run it, once, after review — which
is unsatisfiable for exactly the changes `ws-refine` exists to make, because its own *Verify in
two runs, and the first one must fail* requires deploying a skill-body change before it can be
verified at all, and verification precedes review. The change proved this against itself: it was
deployed to all three agents before its own review, because it had to be. The rule now separates
the two, and the general form is worth keeping — **when a command does two things with different
costs, a rule about "the command" will be wrong about one of them.**

**What a shared store still costs, after p8.30.** The rule is stated once and pointed at from six
places, but the mechanism underneath it has not changed and cannot be fixed from the pack: both
halves act on the **whole** store, so there is no way to deploy or publish one track's library
change. A lead that deploys mid-batch to verify track A necessarily deploys track B's unfinished
edits to every agent on the machine — local and reversible, but real — and `save` would push them
to every machine. The pack's answer is procedural (one track per store per batch, the command
forbidden by name in every brief, the lead runs it) because a procedural answer is the only kind
available to a document. A tool that could publish one artifact would make the rule unnecessary,
and that is agent-sync's problem rather than the pack's.

**The highest-read-priority file was the last one to be corrected.** Four of p8.30's six
contradicting sites were skills; the other two were `docs/agent/reference.md` — which `AGENTS.md`
orders every agent to read *before anything else* — and ADR 0003 item 5, with status `accepted`.
The first draft fixed the skills and left both, so the file every agent reads first still stated
the retired rule. The lesson generalises past this task: **a sweep for a contradiction has to
include the records that stated the old rule, not only the files that execute it**, and an
accepted ADR gets amended in its own text rather than quietly outvoted by a newer skill. ADR 0003
now carries `item 5 amended 2026-11-03 (p8.30)` in its header, which is the first use of that
field in this repo.
