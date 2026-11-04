# ADR 0007 — the agent's access to a service is researched at setup and declared, never assumed

**Date:** 2026-11-04 · **Status:** accepted · **Task:** p5.3

## Context

A project runs on managed services — a host, a database platform, a queue — and an agent working
on it has to operate them: deploy, run a migration, read a log. Until now the pack said nothing
about any of that. `ws-setup`'s question 13 asked whether the project had "env files worth
syncing", which is about the *application's* credentials, and nothing asked what the **agent**
needs in its own hands.

So every session worked it out again, and the two failure shapes were both silent. An agent that
assumes a CLI is signed in finds out mid-task, through a failed deploy. An agent that does not
know a service exists invents a way to reach it, or asks the user to do something a CLI already
does.

The first design for this shipped a **table of named services** in the pack, each with its CLI and
its credential. The owner rejected it, and the measurement that settles it came from his own
machine: two of his projects reach their host through a CLI he signed in once, and **no credential
for it exists anywhere** — not in an env file, not in the encrypted store. A table whose every row
assumed a pasted credential would have been wrong about the most common case in the very setup it
was modelled on.

## Decision

**No skill asks about, proposes or knows a particular service. The user names them; the agent
researches each one; what the pack defines is the closed vocabulary of how access works.** The
claim is scoped deliberately: `ws-shared/stacks/` does carry packs named for particular platforms,
because a review rulebook is about a technology by nature, and `ws-setup`'s services step proposes
those tags. What no skill contains is a list of services to prompt with, or any fact about how one
of them authenticates. Four kinds:

| `access:` | What it means |
|---|---|
| `cli-session` | a CLI the human signs in once, which holds its own session. No credential exists |
| `token` | the service issues a credential the agent carries, and the human pastes it |
| `runtime-var` | the credential the control plane needs is already in a runtime env file |
| `none` | no programmatic access; the agent stops and asks the human |

The conclusion is **the agent's, confirmed by the user** — it is a fact about the service, and the
user is entitled not to know it. It is written into the cartridge as `services:`, reaches every
later session through the generated `AGENTS.md`, and is **proved by running** each service's own
read-only `check:` rather than asserted: `ws-setup` runs them at the end, and `ws-sync` re-runs
them, because access is per machine and a signed-in CLI is signed in on exactly one. Where no
read-only check exists, `check:` is `null` and both reports say `UNPROVED` — never `ok`.

A credential file is written **only where some service is `token`**, at
`<state_dir>/env/agents.env`, holding only the agent's own credentials with every value empty. The
agent writes no value, ever.

## Alternatives rejected

1. **A table of services shipped in the pack.** Two independent faults. It scopes a project to
   whatever is in the table — a user whose service is absent gets nothing — and it goes stale at
   the rate those services change their CLIs and their auth, in a repo that publishes by copy and
   has no way to notice. Measured against the author's own setup it was also simply wrong: it
   assumed a pasted credential where the real mechanism was a signed-in CLI.
2. **The agent obtaining credentials itself**, through each service's login or OAuth flow. This
   puts the pack inside an authentication boundary it has no business in, and an agent entering
   credentials on a human's behalf is prohibited outright rather than discouraged. The human runs
   `login`; the pack prints the command.
3. **Keeping the credentials only in the encrypted store, with nothing declaring what exists.**
   The store answers "what do I have"; it cannot answer "what does this project need, and do I
   have it on this machine". Without a declaration, a missing credential is indistinguishable from
   a service that needs none — which is the `cli-session` case, and the one that matters.
4. **Asking the user which access kind applies.** It is research, not preference. Asking moves the
   work to the person least likely to have the answer and makes a wrong answer look confirmed.

## Consequences

- A service's access can be **unverifiable**: where it offers no read-only check, `check:` is
  `null` and the report says `no check` rather than `ok`. That is recorded as a boundary in
  `records/known-limitations.md`.
- `ws-sync` grows a step that runs commands against third-party CLIs. They are read-only by
  construction — the skill that records a `check:` refuses one that is not — and the enforcement is
  a written rule rather than a mechanism, which is stated where it is relied on.
- The research happens at setup time, on the user's tokens, and the skill says so.
- Nothing in the pack has to be updated when a service changes its CLI. Nothing in the pack knows.
