# P5 — Credentials sync that starts from nothing

**Reopened 2026-11-04.** It closed on 2026-11-02 because an init mode was "work for a user who
does not exist yet. Revisit when one does." That condition is met: the owner asked for an init
path for new users, and for the setup interview to ask which managed services the agent will have
to operate and then write the credentials file it needs. p5.1 and p5.2 stay dropped — ids are
never reused — and the work is one row, p5.3, because the two halves share the file they hand
each other.

**Goal:** `ws-env` works for someone who has no secrets store, no age key and no `.sops.yaml`.

## [-] p5.1 — Add an init mode to ws-env — the README states the loop works with no secrets syncing at all; nothing hard-stops without it — revisit when a user has a store

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. P7's p7.1 no longer depends on it.

## [-] p5.2 — Write the secrets guide — the README states the loop works with no secrets syncing at all; nothing hard-stops without it — revisit when a user has a store

**Dropped 2026-11-02.** The reasoning is in this file's git history at `9c973ee`. It documents p5.1, which is dropped.

## [~] p5.3 — `ws-env` cannot start a new user, and nothing asks which services the agent must operate · claimed 2026-11-04 · @Alpha-30-creator

- **Repos:** worksite (pack)
- **Depends on:** —
- **Why now:** two halves of one gap, and they meet at one file. `ws-env` has four modes and all
  four assume the store already exists — its first check prints `store MISSING -> git clone it`,
  and its *New machine* section carries an existing setup to a second machine rather than creating
  a first one. Separately, `ws-setup` asks whether the project has "env files worth syncing"
  (question 13) and never asks **which services the agent itself must drive**, so the credential
  an agent needs to run `supabase`, `vercel` or `aws` on the user's behalf is never named, never
  obtained and never synced. The answer to the second is a generated file; the first is what
  encrypts it.
- **Acceptance:**
  - [ ] `ws-env init` exists as a fifth mode and creates a store from nothing: the repo, the age
        key at mode 600, `.sops.yaml`, a commented empty `manifest.tsv`, and the pre-commit hook
        that refuses plaintext. It refuses to proceed when `sops` or `age` is missing, **naming the
        install command**; it never touches an existing key; and re-running it repairs rather than
        overwrites
  - [ ] `init` takes an explicit store path, defaulting to `~/.agent-secrets`, and **says which
        store it acted on** — so it can be run and proved without writing to the real one. One of
        the three sandbox-impossible steps in `records/known-limitations.md` stops being one for
        this mode, and that entry is corrected rather than left standing
  - [ ] `ws-setup` asks which managed services or cloud platforms the project uses, and for each
        one **establishes rather than invents** four facts: the CLI, the credential the agent needs,
        where the user obtains it, and a command that proves it works. A service it cannot
        establish is written `TODO:` and asked about. It also proposes the `stack:` tags those
        services imply, since those select the review packs
  - [ ] those answers are **declared in the cartridge** rather than remembered, and the schema page
        documents the new key(s) with the type, the default, which skills read them, and what
        happens when they are missing
  - [ ] `ws-setup` generates a gitignored agent credential file at the declared path — one block
        per service: the variable, what it is for, where to obtain it, the CLI that consumes it,
        and the verify command, with **values left empty** — and then tells the user in chat
        exactly which values to paste. Nothing is written into the file by the agent
  - [ ] the two halves meet: that generated file is what `ws-env` adds a `manifest.tsv` row for, so
        the pasted credentials become syncable to the second machine. Stated once and pointed at
        from both skills, never two copies
  - [ ] `lite` says in one line that no credential file is written and what to run when a service
        needs one. The rungs stay six / fourteen / twenty-one with continuous numbering — or every
        site that states those numbers changes in the same commit
  - [ ] **Evidence:** `init` run against a throwaway store, one file added and pulled into a
        throwaway workspace; `ws-setup`'s services step run on a throwaway project naming two real
        services, with the generated file shown; `bash scripts/check.sh` green; `ws-refine`'s graph
        audit finding count not risen
- **Notes:** the pack installs nothing and authenticates nothing — it names what the user must
  paste and proves it works afterwards. That boundary is the point of the row, not a limitation of
  it: `ws-setup` writing a credential into a file it generated is the one thing this must not do.
