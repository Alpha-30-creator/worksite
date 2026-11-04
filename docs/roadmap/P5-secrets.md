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
  - [ ] **re-scoped 2026-11-04 by the owner:** this read "asks which managed services … and for
        each one establishes four facts: the CLI, the credential the agent needs, where the user
        obtains it, and a command that proves it works". It assumed every service needs a pasted
        credential, and the plan behind it shipped a table of named services. Both are wrong: a
        signed-in CLI needs no credential at all — which is how two of the owner's own projects
        reach Vercel — and a service list in the pack scopes a project to that list. Now: the user
        **names** the services, in their own words and with nothing offered; the agent
        **researches each one** and concludes **how** access works, from a closed vocabulary of
        access kinds rather than a list of services; and it **establishes rather than assumes**,
        in particular never assuming a CLI is signed in. A service it cannot establish is `TODO:`
        and a question. It also proposes the `stack:` tags those services imply, since those select
        the review packs
  - [ ] the access kinds cover the four real shapes, and the fourth is an answer rather than a
        gap: a CLI the human signs in once, a credential the human pastes, a control-plane
        credential that already exists in a runtime env file, and no programmatic access at all —
        where the agent's correct behaviour is to stop and ask the human
  - [ ] every service's access is **proved, not claimed**: `ws-setup` runs each one's read-only
        check command and reports pass/fail per service, and `ws-sync` re-runs them, because a
        signed-in CLI is per machine and "works here, not there" is a drift-table fact
  - [ ] those answers are **declared in the cartridge** rather than remembered, and the schema page
        documents the new key(s) with the type, the default, which skills read them, and what
        happens when they are missing
  - [ ] **re-scoped 2026-11-04 by the owner**, same cause: a credential file is written **only
        when some service actually needs one**, and a project whose services are all signed-in
        CLIs gets no file and no folder. Where one is written it is
        `<state_dir>/env/agents.env` — the owner's own convention, read from a live workspace on
        2026-11-04, including why it sits in `env/` rather than the state dir root: the routine
        habit of reading `<state_dir>/*.md` must never touch a secret. It holds **only** the
        agent's own credentials, never runtime values, with the variables named and **every value
        empty**; a generated `README.md` beside it carries the where-it-goes and is-it-secret
        table and the loading line; and the agent tells the user in chat what to paste. **The
        agent writes no value, ever**
  - [ ] the same facts reach the generated workspace `AGENTS.md`, from the same cartridge rows —
        how the agent reaches each service, what the human did once, and what it must never run
        from a local machine. The owner's workspaces hand-write exactly this today, which is the
        evidence it belongs in the generated file
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
