# P5 — Credentials sync that starts from nothing

**This phase is closed (2026-11-02).** Both tasks are dropped: the README states plainly that the
loop works with no secrets syncing at all, and nothing in the pack hard-stops without a store, so
an init mode and its guide are work for a user who does not exist yet. Revisit when one does.

**Goal:** `ws-env` works for someone who has no secrets store, no age key and no `.sops.yaml`.

## [-] p5.1 — Add an init mode to ws-env — the README states the loop works with no secrets syncing at all; nothing hard-stops without it — revisit when a user has a store

**Dropped 2026-11-02**, body kept. P7's p7.1 no longer depends on it.

- **Repos:** worksite
- **Depends on:** p2.2
- **Acceptance:**
  - [ ] a fifth mode, `init`, creating the store repo, generating the agent key at mode 600,
        writing `.sops.yaml`, an empty `manifest.tsv` and the pre-commit hook that refuses
        plaintext
  - [ ] it refuses to proceed if `sops` or `age` is missing, naming the install command
  - [ ] it explains the two-key model and leaves the passphrase-protected personal key as an
        explicit opt-in step
  - [ ] re-running it repairs rather than overwriting, and never touches an existing key
  - [ ] verified on a machine with no store: init, add one file, pull it into a workspace

## [-] p5.2 — Write the secrets guide — the README states the loop works with no secrets syncing at all; nothing hard-stops without it — revisit when a user has a store

**Dropped 2026-11-02**, body kept. It documents p5.1, which is dropped.

- **Repos:** worksite
- **Depends on:** p5.1
- **Acceptance:**
  - [ ] `docs/engineering/secrets.md` covers the store layout, the manifest's four columns, the
        two keys, and why the manifest is TSV rather than YAML
  - [ ] it is honest about the boundary: the agent key is a plaintext file, so key separation is
        a guard rail against accidents and a leaked key, not a sandbox
  - [ ] the sops `.sops.yaml`-relative-to-input trap is documented, with the staging workaround
  - [ ] it states that `chmod 600` is a no-op on Windows
