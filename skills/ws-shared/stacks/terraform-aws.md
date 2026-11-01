# Stack: Terraform + AWS (multi-tenant)

Selected by `stack: [terraform, aws]`. In the examples, `atlas-infra`.
Flow is **recon → plan → approve → apply**; see that repo's `docs/INFRA_AGENT_HANDOFF.md`.

**Read the plan output, every line.** The review *is* the plan. The words to search for are
`destroy`, `replace`, and `forces replacement`. A resource being replaced rather than updated
means downtime or data loss — a database, a volume, an EIP, anything stateful.

**Never apply without a plan the human approved.** Not `-auto-approve`, not "it's a small
change". This is the one non-negotiable in this pack.

**State.** `terraform.tfstate` is gitignored here — keep it that way; state holds secrets in
plaintext. A change that commits state, or that would run without the configured remote
backend, is a Must fix. Concurrent applies without locking corrupt state.

**IAM breadth.** `"*"` in an action or resource. A policy attached to a role that more than one
tenant assumes. Widening an existing policy as a shortcut rather than adding a scoped one.

**Multi-tenant isolation — the point of this repo.** A resource that should be per-tenant
created once and shared; a tenant identifier interpolated from something not guaranteed unique;
a `for_each` over tenants whose key can change, which destroys and recreates on rename.
`for_each` keyed by a stable id, never by list index.

**Hardcoded identifiers.** Account ids, region strings, ARNs and AMI ids inline instead of
variables or data sources. They silently bind the config to one environment.

**`tfvars` holds secrets** and is gitignored. Values belong in the secrets store, not in the
repo, and not in a `.example` that gets filled in and forgotten.

**Drift.** If `plan` shows changes nobody made, someone edited in the console. Report it rather
than quietly reconciling.
