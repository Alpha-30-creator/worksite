# Stack: Flask + MongoDB (pymongo)

Selected by `stack: [flask, pymongo]`. In the examples, `atlas-api`.
Company repo — follow its conventions; do not propose changing them.

**Auth decorator on every new route.** This stack puts access control on the view function, so
a new route simply has none until someone adds it. Compare each new route against its nearest
sibling. A missing decorator is a Must fix.

**Trusting the client for identity or scope.** A `user_id`, `tenant` or `school` read from the
request body or query instead of the JWT. In a multi-tenant product this is a cross-tenant data
leak, not a style issue.

**Unindexed queries.** A new query path with no matching index does a collection scan that is
fast on seed data and fatal in production. Any new filter or sort field is a finding unless an
index exists.

**No schema means no guarantees.** Mongo accepts anything, so reads must tolerate documents
written by older code: missing fields, wrong types, a field that used to be a string and is now
an array. New code that assumes a field exists on every document is a defect.

**Env read at import time.** `os.environ["X"]` at module scope crashes on import if unset, and
pins the value. Where the repo sources env through a shell script rather than calling
`load_dotenv` — `atlas-api` in the examples does — a bare `.env` does **not** feed local runs,
so a bare `.env` does not feed local runs — a change that assumes dotenv works locally is wrong.

**Mutable default arguments and globals.** `def f(x=[])` and module-level mutable state are
shared across requests under a threaded server.

**Destructive scripts.** Where the repo has a reset-and-reseed flag — `--nuke_db` in the
examples — it wipes the database. Any change that calls a destructive
path from somewhere reachable in normal operation is a Must fix.

**Secrets.** Never commit `setup_env.sh` values, `.env`, or `.cursor/mcp.env`.

**Tests.** `pytest.ini` exists, so new behaviour gets a pytest test — not a one-off script.
