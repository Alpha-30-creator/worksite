# P5 — Credentials sync that starts from nothing

**Goal:** `ws-env` works for someone who has no secrets store, no age key and no `.sops.yaml`.

## [ ] p5.1 — Add an init mode to ws-env

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

## [ ] p5.2 — Write the secrets guide

- **Repos:** worksite
- **Depends on:** p5.1
- **Acceptance:**
  - [ ] `docs/engineering/secrets.md` covers the store layout, the manifest's four columns, the
        two keys, and why the manifest is TSV rather than YAML
  - [ ] it is honest about the boundary: the agent key is a plaintext file, so key separation is
        a guard rail against accidents and a leaked key, not a sandbox
  - [ ] the sops `.sops.yaml`-relative-to-input trap is documented, with the staging workaround
  - [ ] it states that `chmod 600` is a no-op on Windows
