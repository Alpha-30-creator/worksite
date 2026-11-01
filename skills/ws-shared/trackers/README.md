# Tracker adapters

Each adapter answers the same four questions, so no skill needs to know the tracker kind:

1. **List** — what is open, what is in progress and by whom, what is pickable now.
2. **Claim** — mark it mine, atomically enough that two people cannot both take it.
3. **Mark** — move it to in-review and to done.
4. **Note** — where a resume note or a comment goes.

Selected by `tracker.kind` in the cartridge. **An unknown kind is not an error** (R3): ask the
user those four questions, do the work, and offer to write a new adapter here. Adding a tracker
is adding a file in this folder — never editing a skill (R4).
