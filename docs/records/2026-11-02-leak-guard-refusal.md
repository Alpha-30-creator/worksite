# p1.2 leak guard refusal · 2026-11-02

Measured against commit `81311dc` on branch `test/p1.2-leak-guard-refusal`, with
[`scripts/check.sh`](../../scripts/check.sh), [`scripts/leak-patterns.txt`](../../scripts/leak-patterns.txt),
[`.githooks/pre-commit`](../../.githooks/pre-commit) and [`LICENSE`](../../LICENSE) at the sha256
values in the table below. Nothing in the repo was changed to produce any result here; this is a
measurement of the guard as it stands, plus the two files it produced.

Until today nothing had watched this guard refuse anything. It is the one mechanism in this repo
whose failure cannot be undone after the fact, so "it looks right" was the whole of the evidence.

**This record names no pattern from `scripts/leak-patterns.txt`.** Every probe used the pattern on
**line 8** of that file — a single contiguous private project name — and it is referred to by that
line reference throughout. Where a transcript below would have printed it, it reads
`<PRIVATE-NAME>`. The reason this is more than a promise is in the last section.

## How the probes were made safe

Two properties had to hold at once: a **real** commit had to be refused, and no private name could
reach history, a branch or a committed file.

**The circularity, and the order that removes it.** Attempting a commit that carries a private
name is only safe *if the guard works* — which is the thing under test. So `scripts/check.sh` was
run **directly** in staged mode first, and the commit was attempted **only after** that run had
been observed to exit 1. The hook's entire body is `exec scripts/check.sh --staged`, so a direct
exit 1 means the hook cannot exit 0 and the commit cannot land. Had the direct run exited 0, the
probe would have been torn down with nothing committed: a guard that passes a staged private name
is a far larger finding than this task.

**Two probes, in two places.** Probe A ran in the real worktree on the real branch with the real
hook, and attempted a real commit — highest fidelity, and the thing the criterion actually asks
for. Probe B ran in a throwaway `git init` repo outside every real repo, to which **no remote was
ever added**, confirmed before and after. Probe B earns its place twice over: it proves the install
command [`CONTRIBUTING.md`](../../CONTRIBUTING.md) opens with yields a working guard **from zero**,
on a repo where `core.hooksPath` had never been set; and it is the only safe place for case B4
below, which the guard **passes** — in the real worktree a commit attempt for B4 would have
succeeded and put a private name on a branch.

### The copies Probe B ran against were the worktree's bytes

| File | sha256 | Copy matched |
|---|---|---|
| `scripts/check.sh` | `9b5863207d70f019077669cc452f08fd2c5a6aff19a7bdc7dd9593b7cf6a2b35` | yes |
| `scripts/leak-patterns.txt` | `47bd8c67a472f472efadbd2670e72cc5be5ea4c889ef756c0954e893c6315d93` | yes |
| `.githooks/pre-commit` | `cbb11f0edd5ffe1b497551857c4f375dbf5a68f49bbc71ce148b69502211a616` | yes |
| `LICENSE` | `f03fb4fd22e50592a206484784b2d29bffe0d685c399b09881820c9ae3c5ea0d` | yes |

Each was compared before any probe ran, with an abort on mismatch. A result in the throwaway repo
is therefore a result about these bytes, not about a lookalike.

## Which run sites were exercised, and which were not

Section 1 is reached from six places in this tree — five automated invocations and one documented
manual run — in two modes. Two of the six were exercised directly.

| Site | Mode | Exercised |
|---|---|---|
| `scripts/publish.sh`:181 — preflight, refuse to publish onto an already-red target | working tree | no |
| `scripts/publish.sh`:277 — the guard inside the throwaway candidate clone | working tree | no |
| `scripts/publish.sh`:321 — the guard on the target's staged tree | `--staged` | no |
| `.githooks/pre-commit`:6 | `--staged` | **yes** — A2, A3, B1 |
| `.github/workflows/check.yml`:24 — CI, every PR into `main` and every push to `main` | working tree | no |
| documented manual run — `CONTRIBUTING.md`:62, and the cartridge's `verify` | working tree | **yes** — A1, B2, B3, B4 |

Why the four were not:

- **The three `publish.sh` sites** are reachable only by running [`scripts/publish.sh`](../../scripts/publish.sh),
  which commits onto `main` and is the publish path for the shared skills library. It was not run
  on this track at any point, for any reason. That is a prohibition, not a coverage gap to close
  later by running it.
- **CI** would have meant pushing a branch carrying a private name to a pull request, which is the
  exact outcome the guard exists to prevent. Refused flatly. CI's section 1 is byte-identical code
  reached in working-tree mode, which the manual site exercises.

**The claim this record makes, and no wider:** both of section 1's modes were exercised against the
real script and the real pattern file; two of six invocation sites were exercised directly; the
three publish-path sites and CI were not. Nothing here proves "the guard is proven everywhere".

## Probe A — the real worktree, nothing committed

Baseline before anything: `HEAD` `81311dc8a8e0973600c84d8aaa49cc8cad074e17`,
`git rev-list --all --count` 122, `git status --porcelain` empty, `git stash list` empty,
`core.hooksPath` `.githooks`, `bash scripts/check.sh` exit 0.

The probe file was `leak-probe-p1.2.tmp` at the worktree root, one line long, carrying the line-8
pattern. `git check-ignore` exits 1 on it, so it is not ignored and working-tree mode enumerates
it as an `--others` entry.

### A1 — working-tree mode. Expected exit 1 with the file and line. Observed exit 1.

```
$ bash scripts/check.sh
== 1. private names ==
  leak-probe-p1.2.tmp:1:Leak-guard probe for track p1.2. This line names the <PRIVATE-NAME> project deliberately.
  FAIL — 1 file(s) hold a private name. The pack must be generic.
exit=1
```

### A2 — staged mode, run directly. The gate. Expected exit 1. Observed exit 1.

```
$ git add -- leak-probe-p1.2.tmp
$ git diff --cached --name-only --diff-filter=ACM
leak-probe-p1.2.tmp
$ bash scripts/check.sh --staged
== 1. private names ==
  leak-probe-p1.2.tmp:1:Leak-guard probe for track p1.2. This line names the <PRIVATE-NAME> project deliberately.
  FAIL — 1 file(s) hold a private name. The pack must be generic.
exit=1
```

This is the run that authorised the next one. Staged mode reads the staged blob through
`git show ":<path>"`, not the file on disk, so A2 is evidence about the bytes a commit would
actually carry.

### A3 — a real commit, no `--no-verify`. Expected refused. Observed refused.

```
$ git commit -m "test(guard): deliberate leak probe — must be refused"
== 1. private names ==
  leak-probe-p1.2.tmp:1:Leak-guard probe for track p1.2. This line names the <PRIVATE-NAME> project deliberately.
  FAIL — 1 file(s) hold a private name. The pack must be generic.
checks FAILED
exit=1
$ git rev-parse HEAD
81311dc8a8e0973600c84d8aaa49cc8cad074e17
$ git rev-list --all --count
122
```

The `file:line` prefix was printed in all three runs, read from each run's own output rather than
inferred from one.

### Teardown, and five assertions that history is untouched

After `git restore --staged` and `rm -f`, all five passed: `HEAD` equal to the baseline sha,
`rev-list --all --count` still 122, `git status --porcelain` empty, `git stash list` empty,
`bash scripts/check.sh` exit 0.

**One thing survived teardown that the plan had not predicted, and it is worth the paragraph.** A
failed pre-commit hook creates no commit object — but `git add` writes the file's **content** into
the object store *before* the hook ever runs, and `git restore --staged` only rewrites the index.
The probe's blob therefore outlived the probe: unreachable from any ref, absent from the index, and
sitting in the object store as a loose file. It was removed by its exact hash. Not with `git gc`,
because this object store is shared with other live worktrees and a sweep would have collected
their unreachable objects too; `git fsck` reported no corruption afterwards. An unreachable blob
cannot be pushed and cannot enter history, so this was residue rather than exposure — but a probe
that reports "history is untouched" while leaving the private name in `.git/objects` is reporting
on the wrong half of the repository. This is recorded as a boundary in
[known-limitations.md](known-limitations.md).

## Probe B — a throwaway repo, no remote, ever

Fresh empty directory in a scratchpad, `git init`, the four sha256-verified copies above, and the
documented install command run on a repo where `core.hooksPath` was unset — confirmed unset before,
`.githooks` after. The harness commit itself passed the guard, since all four files are excluded by
name. `git remote` printed nothing at the start, after the harness commit, and immediately before
the directory was deleted. The directory was removed with `rm -rf` and its absence asserted.

The working tree was reset between cases so that each case is isolated.

### B1 — the documented install yields a working guard from zero. Expected refused. Observed refused.

```
$ git config --get core.hooksPath        (before)
(unset — exit 1: no guard at all on this clone)
$ git config core.hooksPath .githooks
$ git commit -m "test(guard): B1 must be refused"
== 1. private names ==
  probe-b1.txt:1:Probe B1. This line names the <PRIVATE-NAME> project deliberately.
  FAIL — 1 file(s) hold a private name. The pack must be generic.
exit=1
$ git rev-list --all --count
1
```

One commit, the harness. The refusal is the whole history of that repo's second commit attempt.

### B2 — `LICENSE` does not trip the guard. Expected exit 0. Observed exit 0.

A line carrying the line-8 pattern was **appended** to the copied `LICENSE`, staged, and checked.
No commit was attempted.

```
$ tail -1 LICENSE
Probe B2 appended line, naming the <PRIVATE-NAME> project.
$ git diff --cached --name-only --diff-filter=ACM
LICENSE
$ bash scripts/check.sh --staged
== 1. private names ==
  ok
exit=0
$ bash scripts/check.sh            (working-tree mode, same file)
== 1. private names ==
  ok
exit=0
```

**The bound this measures.** The exclusion at `scripts/check.sh`:18 is **whole-file** and applies
before the file's content is read, in both modes. It is not scoped to the copyright line that
needed it, so anything later added to `LICENSE` is unscanned too. A line that would fail section 1
anywhere else in the repo passes there.

### B3 — the public npm scope does not trip the guard. Expected exit 0. Observed exit 0.

```
$ cat probe-b3.txt
npm i -g @abdur-codes/agent-sync
$ bash scripts/check.sh            (working-tree mode, file not yet staged)
== 1. private names ==
  ok
exit=0
$ bash scripts/check.sh --staged
== 1. private names ==
  ok
exit=0
```

Confirmed in both modes, and standing in the tree independently: `skills/ws-shared/new-device.md`
carries that install command in a tracked, non-excluded file, and section 1 reports `ok` on the
whole tree. No commit was attempted for B3.

### B4 — both on one line. Expected exit 0. Observed exit 0. This case passes the guard today.

```
$ cat probe-b4.txt
npm i -g @abdur-codes/agent-sync   # for the private project <PRIVATE-NAME>
$ grep -c . probe-b4.txt
1
$ bash scripts/check.sh --staged
== 1. private names ==
  ok
exit=0
$ bash scripts/check.sh            (working-tree mode)
== 1. private names ==
  ok
exit=0
```

Isolating which filter passed it: the pattern alternation matches that line — one matching line —
and after the inline allowlist, **zero** lines survive. Section 1 saw the match and then discarded
the whole output line, at `scripts/check.sh`:46.

**`check.sh` only. No commit was attempted for B4, here or anywhere**, because in a repo with a
remote this one would have succeeded.

This is **not** recorded as a standing limitation, because it is being fixed: it is an acceptance
criterion on **p8.31** in [P8-pack.md](../roadmap/P8-pack.md), the merged leak-surface task, added
on 2026-11-02. Narrowing the allowlisted string would not close it — the fix is to strip the
allowlisted substring from the line before matching, rather than dropping the line. p8.31 also
carries the correction to `SECURITY.md`'s run-site count, which says four and lists four, omitting
the `publish.sh`:181 preflight. Both were measured here; neither is this track's to fix.

## What this does not prove

- The three `scripts/publish.sh` sites and the CI site, for the reasons in the table above.
- That the guard catches a private name **not** in `scripts/leak-patterns.txt`. It does not, and
  no probe here pretends otherwise. See [SECURITY.md](../../SECURITY.md).
- That the guard is a secret scanner. It is not — a key, a token or a credential file is not a
  name and passes every run.
- Anything about a clone where nobody ran the install command. B1 measures the opposite case: that
  the command works where it is run, which is why the first line of `CONTRIBUTING.md` is the first
  line of `CONTRIBUTING.md`.

## How to re-run this

The procedure is frozen beside the measurement it produced deliberately, so the two cannot drift
apart. Re-run it when `scripts/check.sh` or `scripts/leak-patterns.txt` changes.

1. **Baseline, and stop on anything dirty.** Record `git rev-parse HEAD`,
   `git rev-list --all --count`, `git status --porcelain` (must be empty),
   `git config --get core.hooksPath` (must be `.githooks`), `git stash list` (must be empty),
   `shasum -a 256` of the four files, and `bash scripts/check.sh` (must exit 0).
2. **Write the probe file** at the repo root with a `.tmp` name, one line, containing the pattern
   on line 8 of `scripts/leak-patterns.txt`. Read it out of that file rather than typing it, and
   confirm `git check-ignore` exits non-zero on the probe path.
3. **A1.** `bash scripts/check.sh`. Expect exit 1 and the probe's `file:line` prefix.
4. **A2, the gate.** `git add --` the probe path, then `bash scripts/check.sh --staged`. **Expect
   exit 1. If it exits 0, stop.** Do not attempt a commit; tear down, and treat it as a broken
   guard — that is a debug and a tracker row, not something to work around.
5. **A3.** Only after A2 exited 1: `git commit` with **no** `--no-verify`. Expect non-zero, the
   same `file:line`, and `HEAD` unchanged.
6. **Tear down and assert.** `git restore --staged --` the path, `rm -f` it, then re-assert all
   five baseline values. Then compute the staged blob's hash with `git hash-object` and remove that
   one loose object by its exact hash — not with `git gc`, which would sweep other worktrees'
   unreachable objects. Confirm `git cat-file -t` on that hash now fails and `git fsck` reports no
   corruption.
7. **Probe B.** A fresh empty directory outside every real repo, `git init`, **no remote, ever**.
   Copy the four files and verify each sha256 against step 1, aborting on mismatch. Run
   `git config core.hooksPath .githooks`, commit the harness, then run B1 (commit refused), B2
   (pattern appended to `LICENSE`, staged, exit 0), B3 (the npm scope alone, exit 0) and B4 (both
   on one line, exit 0). Reset the working tree between cases. **`check.sh` only for B2 to B4 — no
   commit, because they pass.** Then `rm -rf` the directory and assert it is gone.
8. **Keep raw transcripts out of the repo.** They carry the unredacted pattern. The track's
   `verify/` directory is inside the gitignored state directory, which is where they belong;
   anything that reaches `docs/records/` is redacted first, including absolute paths, since the
   author's home path is itself a pattern.

## Why the redaction in this file is not a promise

`docs/records/` is **not** in `scripts/check.sh`'s `excluded()`. Section 1 reads this file whole,
in both modes, and it is not fence-aware — a pattern pasted into a fenced transcript block above
would be a hit exactly like one in prose. So a private name anywhere in this record makes
`bash scripts/check.sh` exit 1 and makes the record **uncommittable**. The redaction is enforced by
the very mechanism this record documents, and the green check on the commit that added this file is
the proof that it holds. It is the neatest thing on this track: the guard guarded its own
certificate.
