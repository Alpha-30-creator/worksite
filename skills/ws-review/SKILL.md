---
name: ws-review
description: Independently review unshipped work in a fresh context that did not write the code - compose a standalone brief from the acceptance criteria, the approved plan, the universal checks, the documentation rules, the stack packs for what changed and the project's own risk list, run it in a background subagent, then verify every finding against the code before reporting and record the ones overturned. Ends with a verdict you can act on and, where something was learned, a better risk list. Use before shipping, when asked for a code review, or when a change touches money, auth, migrations or concurrency. Not for proving the work functions, which is ws-verify.
---

# Review the current work

Ends with a verdict you can act on, and — where something was learned — a risk list that is
better than it was.

## Before anything

1. Read [../ws-shared/reference.md](../ws-shared/reference.md).
2. Find the project: resolve the workspace root from `device.yaml`, then read its cartridge at
   `<docs_home>/reference.md` if there is one.
   **Not in `device.yaml`, or no `device.yaml` at all?** Do not refuse and do not guess a path.
   Take the workspace root to be the directory you were pointed at — the repo's own root, or its
   parent where several repos sit side by side — say which you chose and that it was not resolved
   from `device.yaml`, and carry on. Review is read-only, so the cost of a wrong root is a gather
   that finds nothing, which the gather's own output now names. A project reviewed on a machine
   that has never been set up is the normal case for an outside reviewer, not an error.
3. **No cartridge?** Work without it. Ask three questions and carry on: which repos changed,
   what the change is supposed to do, and what the stack is. Never refuse for a missing
   cartridge.
4. Read the task and the approved plan if they exist (`<state_dir>/tracks/<id>/`, or the
   project's own location — a project whose cartridge sets `artifacts: in-repo` keeps plans in
   the repo, typically under `implementation_plans/<id>/`).
5. `git -C "<repo>" fetch -q` for each changed repo, **where one has a remote** — `fetch` exits 0
   and establishes nothing in a repo that has none, so it proves nothing on its own. Check
   `git -C "<repo>" remote` first and say which repos could not be refreshed. The gather in section 3
   prints the base ref it actually used, which is what makes a stale or local-only base visible.

## 1. Choose the rulebooks

| Always | Then, by what changed |
|---|---|
| `../ws-shared/review/tier1-universal.md` | one `../ws-shared/stacks/<name>.md` per `stack:` tag on each changed repo |
| `../ws-shared/stacks/security-baseline.md` — objective, OWASP Top 10:2025 | |
| `../ws-shared/review/documentation.md` — where writing belongs, and what not to report | |
| `../ws-shared/review/ai-slop.md` — any change an agent wrote | `<docs_home>/risks/common.md` and `risks/<repo>.md`, if they exist |
| | the repo's own practices docs, named by the stack pack |

Name them explicitly in the brief. A generic brief gets a generic review.

## 2. Pick the risks that actually apply to *this* change

Read the diff yourself first — enough to choose. From the packs and the project risks, select
**only the items this change can plausibly trip**, and write them into the brief as specific
questions. Six sharp risks beat forty generic ones.

Always include, when the diff touches them: auth and permission gaps, a read-then-write on
shared state, money, a migration, a new dependency, a new route, a webhook, a server-side fetch
of a user-supplied URL, user content rendered as HTML, and any prompt built from user input.

**Separate objective from preference in the brief.** An objective violation (security baseline,
tier 1) is a defect and can block. A house preference from the project's practices docs is
reported as a preference, with the rule it comes from named, and never blocks on its own. Tell
the reviewer which is which, or it will report taste as though it were a bug — and you will
stop trusting it.

## 3. Run it somewhere that did not write the code

**Never review in the session that wrote it.** That session reads its own intent into the code
and will defend it. Options, in order:

| Reviewer | When |
|---|---|
| **Background subagent** (Claude Code: the Agent tool; Codex/Cursor: their equivalent) | the default |
| **An external agent** — Codex reviewing Claude's work, or the reverse | a delicate change: money, auth, a migration, the cap. Two different models miss different things |
| In-session | only if no subagent exists, and only after saying so and getting a yes |

Carry on with something else while it runs.

### The brief must stand alone

The reviewer has none of this conversation. Include:

- **Layout**: workspace root path; that the root is *not* a git repo; use `git -C "<repo>"`; which
  repos changed and on which branch; the integration branch to diff against.
- **The task**: id, title, and the **acceptance criteria verbatim**, plus what is explicitly out
  of scope.
- **Approved decisions**, summarised in the brief itself — not a pointer to the plan.
  *Do not report these as deviations; do report them if implemented wrongly.*
- **The rulebooks by path**, to read in **two or three calls, never one** — a single batched read of a dozen
  files truncates, and a reviewer that lost them says nothing and falls back to the brief. Tell it to confirm
  it has each file's text before relying on it, and to re-read individually anything a truncated call dropped.
- **The selected risks** from step 2, as questions.
- **Constraints**: read-only. No edits, commits, staging, pushes, network writes, paid API
  calls. Leave the working trees exactly as found.
- **One-pass gather** — this single call shows branch, status, committed diff, uncommitted
  changes and every untracked file:

```bash
( cd "<workspace>" || exit 1        # a subshell: a bare exit would close a persistent terminal
while IFS= read -r r; do
  [ -n "$r" ] || continue
  _pfx=$(git -C "$r" rev-parse --show-prefix 2>/dev/null) && [ -z "$_pfx" ] \
    || { echo "NOT A REPO ROOT: $r — run that rev-parse by hand to see why"; continue; }
  echo "=== $r ($(git -C "$r" branch --show-current))"; git -C "$r" status --short
  _base=""                          # two quoted literals, not a path list: `for` is right here
  for cand in "origin/<integration>" "<integration>"; do
    git -C "$r" rev-parse --verify -q "$cand" >/dev/null && { _base="$cand"; break; }
  done
  if ! git -C "$r" rev-parse --verify -q HEAD >/dev/null; then
    echo "--- NO COMMITS YET — nothing is committed in this repo, so there is nothing to diff"
  elif [ -z "$_base" ]; then
    echo "--- NO BASE REF: neither origin/<integration> nor <integration> exists."
    echo "    Showing the whole branch history instead — this is NOT a diff of the change."
    git -C "$r" log --oneline --stat HEAD
  elif [ "$(git -C "$r" rev-parse "$_base")" = "$(git -C "$r" rev-parse HEAD)" ]; then
    echo "--- HEAD IS $_base — the work was committed ON the base, not on a branch off it,"
    echo "    so there is no committed diff to show. Everything to review is either uncommitted"
    echo "    below or already in $_base. ASK which commits are the change before reviewing."
  else
    echo "--- committed, vs $_base"; git -C "$r" diff "$_base...HEAD"
  fi
  echo "--- uncommitted"
  if git -C "$r" rev-parse --verify -q HEAD >/dev/null; then
    git -C "$r" diff HEAD
  else                         # no HEAD to diff against, so take the two halves separately
    git -C "$r" diff --cached  # the empty tree vs the index: this is where staged files show
    git -C "$r" diff           # the index vs the working tree
  fi
  git -C "$r" ls-files --others --exclude-standard | while IFS= read -r f; do
    echo "--- NEW: $r/$f"; cat "$r/$f"
  done
done <<'REPOS'
<repo paths, one per line>
REPOS
)
```

**The base ref is resolved and printed, never assumed.** `origin/<integration>` does not exist in
a repo with no remote, and the old line `diff origin/<integration>...HEAD; diff HEAD` lost exactly
the committed half: the `;` meant the uncommitted diff, the status and the untracked files still
printed, so the gather looked like it had worked while the one thing a reviewer most needs — what
the branch actually changed — was replaced by a `fatal:` higher up the output. It now falls back to the local `<integration>` and says which it used, because the two are not the
same thing: the local ref is this machine's last-fetched view, so a diff against it can hide
commits someone else has pushed. With neither ref present it prints `NO BASE REF` and shows the
branch history instead, labelled as **not** a diff of the change — a reviewer told that is a
reviewer who knows to ask for the base, which is the whole point of naming it.

Two more states are named rather than shown as emptiness, because an empty committed diff is
exactly what "I have nothing to review" looks like. **`HEAD IS <base>`**: on a local-only project
the work is often committed straight onto the integration branch, so `<base>...HEAD` is empty
while the change is right there in the history — ask which commits are the change. **`NO COMMITS
YET`**: an unborn repo, where `log HEAD` and `diff HEAD` both exit 128. There the uncommitted half
is taken in two pieces, because `git diff` alone is the **index against the working tree** and
would hide everything already staged — `git diff --cached` is the empty tree against the index, and
on a first-commit repo that is most of the change.

Read line by line, and quote every `$r`: a workspace path containing a space word-splits under
bash, every `git -C` fails on a fragment, and this block still prints a `===` heading and an
empty diff per fragment — which reads exactly like a branch with no changes. A review that saw
nothing is the worst available failure here, so the gather is the one block that must not have
this shape. Two more guards for the same reason. The `cd` is now `|| exit 1` **inside a
subshell**, because a failed `cd` used to leave the loop running against relative paths and
printing empty diffs — and the parentheses matter: a bare `exit` in a block pasted into a
persistent terminal closes the session. The `rev-parse` line makes a wrong *fill* print a named
`NOT A REPO ROOT` rather than one more empty diff. **Neither that line nor a missing repo is a
review result** — fix it and gather again, and read the output rather than the exit status, which
stays 0 even when every path was refused.

- **Checks to run and report** pass/fail, never fix: each changed repo's `commands` from the
  cartridge (`verify` if it has one, else typecheck/lint/test/build plus `extra`). Batch
  independent commands into one call.
- **Budget: 10–15 tool calls.** Each call re-sends the whole brief, so cost is round trips, not
  bytes. Read more per call; never re-read what the diff already showed.
- **Quote the exact source line** for every finding, never a line number — reviewers invent
  line numbers.
- **Declare coverage**: which files were read fully, which were skimmed.

**Do not tell it what you already checked, or that anything passed.** Both bias it.

## 4. Verify everything before you report it

This step is what separates a review from review theatre.

- **Check every finding against the code.** Grep the quoted line, read around it.
- **Drop the wrong ones and say why**, in an *Overturned* section. A reviewer that invents
  findings is worse than none, and you only find out by checking.
- Do not defend code because this session wrote it. That is the whole reason for step 3.
- **A clean review of a delicate change is a reason to look yourself** — money, a cap, auth, a
  migration. Clean there usually means not looked at.
- **A clean review that followed the brief is a result, not a failure.** A reviewer that read the
  diff, selected its risks, ran the checks and reports no `Must` and no `Should` has done the job:
  say so in the verdict and ship. The line above is about a *delicate* change reviewed by someone
  who may not have looked — it is not an instruction to produce findings. Never pad a thin review.
  A finding invented to fill a section costs the next reader their trust in the ones that are real,
  which is the whole reason *Overturned* exists.

## 5. Close the learning loop

For each **confirmed** finding, ask: is this risk class already written down?

| If it is | Then |
|---|---|
| In a pack or the project risks | nothing to do — the system worked |
| Not written down, and it would catch bugs in **other** projects on this stack | propose one line for `../ws-shared/stacks/<name>.md` |
| Not written down, and it is specific to this project | propose one line for `<docs_home>/risks/common.md` or `risks/<repo>.md` |
| **It is this change's own residue** — a citation that drifted, a count that changed, a description now narrower than the behaviour | one line in the **harvest entry**, with the change that caused it. It earns a risk line or a task only when the *mechanism* recurs across three changes |

Show the exact wording, wait for a yes, then write it. Stack-pack edits go through
`agent-sync save`; project risks are a normal docs commit.

**You run that save, not the reviewer, and it is not the whole job.** A stack pack is a library
file, so editing one is a `ws-refine` change: after the save it still owes that skill's **graph
audit** and its **publish** step, or the pack is edited in a state nobody audited and the public
artifact never receives it. Either make the edit through `ws-refine`, or run those two steps here
and say you did. The save itself is the lead's for the same reason a `ws-fanout` builder's is —
it acts on the whole library — and this skill's reviewer is a background subagent by default.
`ws-refine`'s *Who may run what* states the rule, including that a plain deploy (`agent-sync
apply`) is local while `save` also commits and pushes; the "wait for a yes" above already implies
a session that can ask, which a subagent is not.

**Writing a finding down is not the same as filing a task.** A risk line records a class so the
next review catches it; a task is work someone will do. `ws-task`'s *Where a finding belongs*
decides which, and most confirmed findings are the first.

**One line, phrased as what to look for.** Not a description of this bug — a description of
the class. This is how the packs get good instead of staying a guess.

## Output

```markdown
# Review: <task> <title>

## Verdict
<Ready to ship | Needs fixes | Blocked — one line why>

## Acceptance
- [x] / [ ] <criterion verbatim> — <evidence or gap>

## Checks
<repo: command — pass/fail, per changed repo>

## Must fix
## Should fix
## Notes

## Coverage
<files read fully | skimmed | not reached>

## Scope
<in scope | drifted — what>

## Overturned
<reviewer findings that were wrong, and why>

## Learned
<risk classes proposed, and where they would go — or "nothing new">

## Next step
```

## Rules

- Never review in the session that wrote the code without saying so and getting a yes.
- Never report a finding you have not verified against the code.
- Never let "lint and typecheck pass" stand in for a verdict — that covers ~16% of what matters.
- Read-only. The reviewer changes nothing; you change nothing in this skill either.
- No AI attribution in anything this produces.

## What next?

Invoke with `/skill-name` in Claude Code or Cursor, `$skill-name` in Codex.

- Fix the Must findings, then `ws-review` again
- `ws-ship` — the verdict is ready to ship
- `ws-debug` — a finding is a real defect with an unknown cause
- `ws-task` — a finding is real but out of this task's scope
- `ws-fanout` — this review is one of a batch; reconcile across the tracks there
