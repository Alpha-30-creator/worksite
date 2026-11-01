---
name: ws-shared
description: Reference that every ws-* skill reads before doing anything - where this device's projects live, the secrets store layout and key model, the cross-platform rules, and the house rules for reporting drift and handling secrets. Not invoked directly; read reference.md.
disable-model-invocation: true
---

# ws-shared

Facts the `ws-*` skills share. Read [reference.md](reference.md).

Fix a wrong fact here through `ws-refine`, never by editing a deployed copy under
`.claude/skills/` or `.codex/skills/` — those are overwritten by `agent-sync save`.
