# Tracker adapters

Each adapter answers the same four questions, so no skill needs to know the tracker kind:

1. **List** — what is open, what is in progress and by whom, what is pickable now.
2. **Claim** — mark it mine, atomically enough that two people cannot both take it.
3. **Mark** — move it to in-review and to done.
4. **Note** — where a resume note or a comment goes.

Selected by `tracker.kind` in the cartridge. **An unknown kind is not an error** (R3): ask the
user those four questions, do the work, and offer to write a new adapter. Adding a tracker is
adding a file to this folder — never editing a skill (R4).

## Which copy of this folder, and why it matters

**Write the adapter in the library, then deploy it.** This folder exists once in the library and
once per agent you have installed — `~/.claude/skills/`, `~/.codex/skills/`, `~/.cursor/skills/`,
as applicable. Read the library's own path out of `agent-sync doctor --json`'s `store` field
rather than assuming where it is. The copies are **independent files**, not links: measured, the
library copy and each deployed copy of the same adapter have different inodes and none is a
symlink (Windows checks a symlink out as a text file, which is why the pack deploys copies — see
*Cross-platform rules* in [../reference.md](../reference.md)).

**An agent reads the deployed copy.** So:

- **An adapter written only in the library is read by nothing** until a deploy copies it out.
  Measured: a file added to the library alone was invisible to all three agents.
- **An adapter written only into one agent's deployed copy** puts that copy into drift. The next
  deploy does **not** silently overwrite it — it stops and asks whether to *adopt* the edit into
  the library or *overwrite* it, and `ws-sync`'s rule is never to pick that for the user. So it
  either becomes a library change anyway, or it is destroyed on purpose. What it never does is
  quietly reach the other agents.

**Two commands bridge the two, and they are not interchangeable.** `agent-sync apply` deploys the
library to this machine's agents and **commits nothing and pushes nothing**; `agent-sync save`
does that *and* commits and pushes the whole library. An adapter is untestable until it has been
deployed by one of them — invoking a skill reads the deployed copy — so **trying a new adapter
costs a local deploy, which is reversible, and does not require publishing anything.** Because
either command moves the *whole* library, writing an adapter is a
**[`ws-refine`](../../ws-refine/SKILL.md) change**: follow its *Who may run what* for which of the
two to run, when, and who may run it. A subagent writes the file and stops.

**Why this had to be written down.** During the p7.1 validation run, an agent with none of this
project's history wrote a complete, correct adapter for an invented tracker kind with zero skill
edits — exactly as the sentence above told it to — and **the pack never picked it up**, because
nothing said the file had to be deployed. It is an easy gap for an author to miss: `ws-refine`
makes *them* deploy before they test, so the author's own walk down this path always works.