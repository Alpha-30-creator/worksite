# Contributing

## Step one, before any commit

```bash
git config core.hooksPath .githooks
```

Run that in your clone before you commit anything. This repo is assembled by copying out of a
private setup, and [`.githooks/pre-commit`](.githooks/pre-commit) refuses any commit carrying a
private name. `core.hooksPath` is a per-clone setting, so until you run it there is no guard on
your machine at all — and the cost of skipping it is not a failed check, it is a public,
permanent commit that cannot be taken back. [SECURITY.md](SECURITY.md) says what that guard does
and does not cover.

## Before you edit `skills/`

`skills/` is a **received copy**. The skills an agent actually loads come from the author's
private agent-sync library, and this repo is a published artifact of it
([ADR 0001](docs/decisions/0001-library-is-the-source-of-truth.md),
[sync-direction.md](docs/engineering/sync-direction.md)). Editing a skill here changes nothing
any agent loads, and the next publish overwrites the edit — so the change appears to do nothing,
or the opposite of nothing. That failure mode is written down in
[docs/agent/risks/common.md](docs/agent/risks/common.md) because it has already happened.

Upstream, a change to a skill is made through `ws-refine`, which edits the library and deploys
it. A contributor has no library, so that route does not exist for you. In a fork, your fork
becomes its own source of truth; read [`scripts/publish.sh`](scripts/publish.sh)'s plain-copy
assertion before you touch `skills/` there, because a publish that would transform rather than
copy is designed to fail loudly.

## Pull requests are not accepted

This repo is a one-way mirror of one person's working setup: a merge here would be overwritten by
the next publish. That is not a judgement on the change — the mechanism simply has no place to
keep it.

The workflow is triggered by pull requests anyway, and that is not a contradiction: the
maintainer's own tracks merge into `main` through pull requests, which is what the trigger is for.
What has nowhere to be kept is a patch from outside.

So there are two things to do instead:

- **Fork it** if you want it different. That is the intended answer, and the licence allows it.
- **Open an issue** at https://github.com/Alpha-30-creator/worksite/issues. That is the one
  inbound channel that works. A workflow step that is wrong, a doc that is wrong, a gap in the
  guard — all of it is worth reporting even though the patch cannot be merged.

## What is authored here, and what is received

Everything outside `skills/` is authored here and can be edited in a fork like normal code:
`README.md`, `docs/`, `scripts/`, `.githooks/`, this file and the other root furniture. `AGENTS.md`
at the root is generated from `docs/agent/workspace/AGENTS.md` — edit the source, not the copy.

[docs/engineering/layout.md](docs/engineering/layout.md) is the authority on which path is which,
path by path, along with which check looks at it. It is not restated here, so that it cannot drift
from it.

## How a change is checked

```bash
bash scripts/check.sh
```

That is the **whole** suite, and the only thing any gate runs. There is no typecheck, no linter,
no test runner and no build, and those are absent on purpose rather than unfinished — a repo of
Markdown and five shell files
does not get an invented test runner. The script has **seven** sections: private names, skill
frontmatter, relative links, library parity, the state-dir ignore assertion, the object store, and
the README's own claims. Section 4 is informational and never fails; **every other section can
fail**, sections 5, 6 and 7 included. Each says only as much as it knows: section 1 prints the file
**and the line**, section 3 prints the file and the link that did not resolve, section 2 prints the
skill's name, section 5 prints the `state_dir` it read and where it read it from, section 6 prints
how many objects it read before saying anything about them, and section 7 prints how many claim
groups it read, how many claims hold and how many it did not check. It had four sections until
2026-11-02 (p8.31) and six until 2026-11-03 (p7.3).

**Section 7 is [`scripts/check-readme-claims.sh`](scripts/check-readme-claims.sh)**, called rather
than inlined — 250 lines of claim-reading inside the gate would make the gate unreadable. Every
quantity in it is read **out of `README.md`** and compared to the tree, so renaming "thirteen
skills" to "twelve" fails. You can run it alone against any tree, which is what a tag does:
`bash scripts/check-readme-claims.sh <dir>`. It is **not** a second `verify`; there is one command
and this is a section of it. Until 2026-11-03 nothing ran it at all, which is the gap p7.3 closed.

Three things worth knowing before you rely on it:

- **Section 3 resolves every relative link and fails on a missing target**, including links inside
  fenced code blocks. So a link may only be added in the same change that adds the file it points
  at. Anchors and line numbers are never verified.
- **`--staged` mode resolves link targets against the working tree**, not the staged tree, so a
  link to a file that is present locally and not staged passes the hook and breaks on a fresh
  clone. Run the script with no arguments too, not just via the hook. **Section 7 reads the working
  tree in that mode too**, and for a harder reason: its checks open files with `cat` and `grep`,
  which `--staged` cannot redirect at all. It says so, and names each file that differs from the
  index, so the hook cannot quietly certify a version it did not read.
- **Section 7 tells "this claim is false" apart from "I could not check it".** A claim needing a
  tool this machine lacks — the Node floor is read out of `agent-sync`'s own `engines` field, and
  `agent-sync` is not installed in CI or on a reader's machine — is reported `UNCHECKED` by name,
  counted, and repeated in the closing summary. It is not a failure, because a true README must not
  turn CI red; it is not an `ok` either. "No claim of that shape found in `README.md`" **is** a
  failure, always: it means the README moved out from under the check.

[`.github/workflows/check.yml`](.github/workflows/check.yml) runs the same command on every pull
request into `main` and on every push to `main`. What CI does **not** do is block anything: making
a red check unmergeable is a branch-protection setting on `main`, not a file in this tree, and it
is not yet set. A green run means the suite passed, nothing more.

## House rules

These override whatever your agent would otherwise do:

- **Nothing dirty enters history.** Strip anything private in the working tree *before* the commit
  that adds the file, never after. The history here is public and permanent.
- **Conventional commits**, and branches named `<type>/<id>-<slug>`.
- **Never `--no-verify`**, and never force-push `main`.
- **No AI attribution** in a commit message or a pull request body: no `Co-Authored-By`, no
  "Generated with".
- Add the paths you changed by name rather than with `git add -A`. `.gitignore` is the only thing
  keeping `.worksite/` and `docs/agent/journal/` out of a public history, so a blanket add is one
  removed line away from committing them.

## Reporting something

| What | Where |
|---|---|
| A bug, a wrong doc, a workflow step that felt wrong | an issue: https://github.com/Alpha-30-creator/worksite/issues |
| Anything security- or privacy-sensitive, including a private name you found in history | [SECURITY.md](SECURITY.md), which has the private route |
| Conduct | [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) |
