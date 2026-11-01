# P5 — Credentials sync that starts from nothing

**This phase is closed (2026-11-02).** Both tasks are dropped: the README states plainly that the
loop works with no secrets syncing at all, and nothing in the pack hard-stops without a store, so
an init mode and its guide are work for a user who does not exist yet. Revisit when one does.

**Goal:** `ws-env` works for someone who has no secrets store, no age key and no `.sops.yaml`.

## [-] p5.1 — Add an init mode to ws-env — the README states the loop works with no secrets syncing at all; nothing hard-stops without it — revisit when a user has a store

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. P7's p7.1 no longer depends on it.

## [-] p5.2 — Write the secrets guide — the README states the loop works with no secrets syncing at all; nothing hard-stops without it — revisit when a user has a store

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. It documents p5.1, which is dropped.

