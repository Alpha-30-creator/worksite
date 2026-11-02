# Security

## What this repo is

Markdown and two shell scripts. No runtime, no dependencies, no build, and nothing published to a
registry — so there is no service to attack and no package to poison. The only code that ever runs
is [`scripts/check.sh`](scripts/check.sh), [`scripts/publish.sh`](scripts/publish.sh) and
[`.githooks/pre-commit`](.githooks/pre-commit), all of them run locally by someone who cloned the
repo and read them first.

What this repo does have is a privacy boundary. It is assembled by copying skills out of a private
working copy ([ADR 0001](docs/decisions/0001-library-is-the-source-of-truth.md)), and the history
here is public from the first commit, so a private name that lands in it cannot be taken back.
The guard below is about that boundary and nothing else.

## What the guard protects

Section 1 of [`scripts/check.sh`](scripts/check.sh) matches the files it enumerates
case-insensitively against the extended regexes in
[`scripts/leak-patterns.txt`](scripts/leak-patterns.txt), and exits non-zero with the file and line
of every hit. **Which files it enumerates depends on the mode:** run with no arguments it reads the
whole working tree, tracked and untracked alike; run with `--staged` it reads
`git diff --cached --diff-filter=ACM`, so only staged additions and modifications — a file that is
untracked, or tracked and unmodified, is not read at all in that mode. It runs automatically in
**five** places — three of them on the publish path, two of them in `--staged` mode:

- as a **preflight on this repo before the publish starts** (`scripts/publish.sh`:181, working-tree
  mode), which refuses to publish into a tree whose guard is already failing — so a pre-existing
  leak is never buried under a publish commit;
- in a throwaway clone of the candidate, before a byte is written here (`publish.sh`:277,
  working-tree mode);
- again on this repo's staged tree, which is what is actually about to be committed
  (`publish.sh`:321, `--staged`);
- once more in the pre-commit hook, on exactly those staged bytes
  ([`.githooks/pre-commit`](.githooks/pre-commit), `--staged`) — which fires on the publish commit
  too, since `publish.sh` never passes `--no-verify`;
- and in CI — [`.github/workflows/check.yml`](.github/workflows/check.yml):24 runs the whole suite
  on every pull request into `main` and on every push to `main`, the second of which exists because
  publish commits land on `main` directly
  ([ADR 0002](docs/decisions/0002-publishing-is-a-guarded-copy-from-the-library.md)).

Plus one documented manual run, at [`CONTRIBUTING.md`](CONTRIBUTING.md):62.

**Five sites, six invocation lines.** `publish.sh`:181 and :184 are the same preflight: when it
fails, the second line re-runs it without `>/dev/null` so the output is visible. Someone counting
`bash scripts/check.sh` finds six and should not "correct" the five.

This count was **four** until 2026-11-02, omitting the preflight (p8.31).

The one thing that is guaranteed, stated no wider than it holds: in a file that is neither
excluded nor blanked by one of the pattern file's own `!` allowlist entries, a string matching a
pattern in
`scripts/leak-patterns.txt` cannot reach `main` through a pull request without CI going red, and
cannot be committed on a clone where the hook is installed.

**The push-to-`main` run reports after the fact.** The commit has already landed by the time it
starts, so it cannot block anything — not even with branch protection, which gates merges rather
than pushes. It is a signal, not a gate. The publish path that uses that route is not therefore
unguarded: it keeps its own three runs of the guard — a preflight on this repo, then a throwaway
clone before a byte is written here, then this repo's staged tree — the hook fires on the publish
commit as a fourth, and the CI run is a fifth look at bytes those four have already passed.

## What it does not protect

1. **It is a regex scan over a fixed list.** A private name nobody has added to
   `scripts/leak-patterns.txt` is invisible to every run, because all five read the same file.
   Coverage is the patterns listed there **minus its own `!` allowlist entries, minus the files
   excluded in [docs/engineering/layout.md](docs/engineering/layout.md)'s table** — so the pattern
   file plus that one table is the whole of it. Until 2026-11-02 one allowlisted string was inline
   in `check.sh`, and auditing coverage meant reading the script too (p8.31). Green means "no known
   pattern". It has never meant "no private data".
2. **It is not a secret scanner.** A key, a token, a password or a credential file is not a name
   and passes every run. The hook's own comment says this; this is the file it points at. What
   does cover credentials on this repo is GitHub's secret scanning and push protection, which are
   **repo settings and not part of the pack** — a fork inherits whatever the fork sets.
3. **It is not installed by default.** `core.hooksPath` is a per-clone git setting, so "the guard
   runs again at commit time" is **false on any checkout where nobody ran
   `git config core.hooksPath .githooks`**. CI is the backstop for this repo only; a fork gets CI
   only if the fork enables Actions. And **a check that runs is not a check that blocks** —
   requiring the `check` job before a merge is a branch-protection setting on `main`, not a file
   in this tree, and it is not yet set.
4. **Not a sandbox.** The pack constrains an agent's *workflow*, not its capabilities. It does not
   limit what commands run, what gets network access, or what a bad instruction could reach.

## Out of scope

- **Your agent's own permissions.** What a coding agent is allowed to do on your machine is your
  agent's configuration. Nothing here changes it.
- **agent-sync**, and the private library the skills are copied out of. Both are other projects.
- **`sops` and `age`**, used by `ws-env`. The encrypted store is not in this repo and no key is.
- **Vulnerabilities in GitHub Actions itself**, or in `actions/checkout`. Report those upstream.

## If a private name reaches history

Fixing the tip does not help: git keeps every version. The procedure, including the four
preconditions to check before rewriting anything, is
[docs/runbooks/purge-a-leak-from-history.md](docs/runbooks/purge-a-leak-from-history.md). It is
destructive and it rewrites published history, so read it before you start rather than while you
are running it.

## Reporting a vulnerability

- Anything that should not be public — a leaked name still in history, a hole in the guard, a way
  to make `publish.sh` write something it should not — through GitHub's private reporting route:
  https://github.com/Alpha-30-creator/worksite/security/advisories/new. It is visible only to the
  maintainer.
- Anything non-sensitive: an issue at https://github.com/Alpha-30-creator/worksite/issues.

There is no service to take down and no release to patch, so expect a reply and a commit rather
than an advisory process. This is one person's published working setup, maintained in the open on
no schedule; nothing here promises a response time.
