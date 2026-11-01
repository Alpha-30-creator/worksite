# Stack: Vercel serverless

Selected by `stack: [vercel-serverless]`. In the examples, both northwind repos.

**The function timeout is a hard ceiling.** Work that grows with data will pass in dev and fail
in production. Flag: a loop over rows with no batch limit; fan-out without concurrency control;
an external call with no timeout of its own; an LLM call on a route that is not the dedicated
AI function. Ask "what happens at 100× today's rows?"

**CPU work driven by user-typed input.** Work that grows with a value a user controls (words in
a name, list length, nesting depth) and is repeated per item or per what-if copy can reach the
timeout from a single record. Flag it and ask for an input cap and a timing test. A cache keyed
on objects built fresh for each call (a `WeakMap` over per-item copies) caches nothing; key it by
value.

**Cold starts and per-invocation state.** Module-level caches, in-memory rate limiters and
`setInterval` do not survive between invocations and are not shared between concurrent ones.
Anything that must persist or be shared needs real infrastructure.

**Database connections.** Each concurrent invocation opens its own. Without a pooler, traffic
exhausts Postgres connections. A new long-lived connection or a raised pool size is a finding.

**CommonJS/ESM bundling.** Where the repo declares a bundle check in `commands:` — the examples
give `northwind-api` a `check:cjs` — it exists precisely because a new
dependency can break the serverless bundle in a way nothing else catches. **Any new runtime
dependency must be reported with whether `check:cjs` was run.**

**Signed webhooks need the raw body.** QStash, Stripe and similar verify a signature over the
exact bytes. A route that lets a JSON body parser run first will fail verification — and
usually only in production. Check raw-body handling on every new webhook.

**Route config must exist for the function to be reachable.** A new AI or long-running route
missing from `vercel.json` rewrites lands on the default function with the default timeout.

**Branches deploy.** Pushing an integration or release branch is a deployment. In review, say
plainly whether merging this change deploys it and to where.

**Env vars are per-environment and set in Vercel.** A change that needs a new variable is
incomplete until the variable exists in every environment it will run in. Say which are missing.
