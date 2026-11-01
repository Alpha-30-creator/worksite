# The AI-slop axis

Agent-written code fails differently from human-written code. The research on AI-generated code
finds quality is driven by prompt design, task specification and the developer's own
expertise — which is why the plan gate, the acceptance criteria and the rule skills exist. This
file names the failure modes so the reviewer looks for them specifically.

Check every one of these on any change an agent wrote.

**1. Plausible but wrong.**
Idiomatic-looking code written against an API that does not exist in the *installed* version.
Check the version in the manifest, not the vibe. The more confident and conventional the code
looks, the more worth checking it is.

**2. Invented APIs and packages.**
A method that does not exist; an import that is not in `package.json` / `requirements.txt`. Any
newly imported package is a finding until confirmed present and intended.

**This is a security finding, not just a correctness one.** Attackers register the plausible
package names that models invent, so an agent-added import is the single highest-risk
dependency you can have. Verify the name against the registry, check for a `postinstall`
script, and treat it under OWASP A03 — see `../stacks/security-baseline.md`.

**3. Duplication instead of reuse.**
A new helper that already exists three folders away, because nothing grepped first. Search for
the function's purpose before accepting it as new.

**4. Tests written to pass.**
The most dangerous one, because it looks like coverage. Signals: assertions that mirror the
implementation line for line; a mock that returns exactly what the assertion checks; a test
with no failing path; snapshot tests of everything. Ask the tier-1 question — *would this go
red if the code were wrong?*

**5. Silent scope creep.**
Unrelated "improvements" riding along: reformatting, a renamed variable in an untouched file, a
dependency bump nobody asked for. Each one is either a separate change or removed.

**6. Dropped edge cases.**
The plan listed them; the code skipped them. Read the plan's edge cases as a checklist against
the diff. Agents routinely implement the happy path and summarise as if complete.

**7. Copied with its bug.**
A neighbouring module cloned as a template, including a stale pattern or an old workaround that
no longer applies. If the new code matches an old file suspiciously closely, check what that
old file got wrong.

**8. Permissive defaults.**
A new route without the guard its siblings have; a new config defaulting to open; a new query
without the tenant or user filter. Compare the new thing against its nearest existing sibling,
specifically on auth, scoping and validation.

**9. Confident summaries.**
The change description says "and added tests for X" when there are none, or "handles the empty
case" when it does not. Verify claims against the diff; do not take the summary as evidence.

**10. Lost nuance in refactors.**
A refactor that drops a guard clause, an early return, or an `if` that looked redundant and was
not. For any refactor, diff the *behaviour*, not the shape.

## How to report these

They are ordinary findings — use tier-1 severity. Do not label a finding "AI slop" in the
output; say what is wrong and how to see it. The point of this list is where to *look*, not a
category to put in the report.
