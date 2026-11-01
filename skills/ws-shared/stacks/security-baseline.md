# Stack: security baseline (objective)

Applies to **every** web project — selected automatically, no tag needed. Mapped to
OWASP Top 10:**2025** (the current, eighth edition). Two things changed since 2021 and both
matter here: **SSRF is now inside A01**, and **Software Supply Chain is a new A03**.

Everything in this file is objective: violating it causes a vulnerability, not a style
disagreement. House preferences live in the project's own practices docs.

## A01 Broken access control (#1, and it includes SSRF now)

- **Identity from the server session, never the request.** A `userId`, `tenant` or `orgId` taken
  from a body, param or header instead of the authenticated context is an authorisation bypass.
- **Nested ownership.** Fetching a child row by id without checking it belongs to the caller's
  parent. `GET /orders/5/items/99` must verify item 99 is on order 5.
- **Prefix and path matching.** Compare on segment boundaries, case-insensitively, against the
  routed path — not `request.url`. `startsWith('/admin')` matches `/administrators`, and some
  routers will send `/ADMIN/x` to the `/admin/x` handler.
- **Mass assignment on input.** A DTO that accepts a field the caller must not set — `role`,
  `isAdmin`, `price`, `ownerId`, `status`. Rejecting *unknown* fields does not help if the field
  is declared. Check what each new input field lets a user change.
- **Not-found over forbidden.** For "exists but isn't yours", prefer 404 to 403 so the endpoint
  can't be used to enumerate ids.
- **SSRF.** Any server-side fetch of a URL the user influenced — an image import, an avatar from
  a link, a configurable webhook target, a "preview this page" feature. It can reach cloud
  metadata (`169.254.169.254`), `localhost`, and internal services from inside the trust
  boundary. Needs a host allowlist, private/link-local ranges blocked, and redirects not
  followed blindly.
- **Open redirect.** `?next=` / `returnTo` after login must be validated against internal paths.
  `startsWith('/')` is not enough — `//evil.com` is protocol-relative and leaves your origin.

## A02 Security misconfiguration (#2 — the biggest riser)

- **Security headers**, none of which frameworks set by default: CSP, HSTS,
  `X-Content-Type-Options: nosniff`, `Referrer-Policy`.
- **Internal detail in production errors** — stack traces, ORM or driver messages, SQL.
- **API docs or debug routes reachable in production** (Swagger, GraphQL playground, health
  endpoints that dump config).
- **CORS**: never `*` with credentials; it cannot work anyway, and it must not linger after a
  refactor. Check every entry point, not just the main one.
- **Cookies**: `httpOnly`, `secure`, an explicit `SameSite`, and — the one people miss — the
  clear must use the *same* domain, path and `SameSite` as the write, or logout silently fails.

## A03 Software supply chain (NEW, #3)

- **Every new runtime dependency is justified in the change.** New package = new attack surface
  and new maintenance.
- **A package with a `postinstall` script** runs arbitrary code at install time. Check it.
- **Lockfile respected**: CI uses `npm ci` (or `pnpm i --frozen-lockfile`), never `npm install`.
- **Package name verified against the registry.** A name that is nearly right is the attack —
  and agents hallucinate plausible names, so an agent-added import is the highest-risk case.
  See `../review/ai-slop.md`.
- **Pinned, not floating,** for anything security-relevant.

## A04 Cryptographic failures

- **Timing-safe comparison** for secrets, signatures, tokens and MACs. `===` leaks the value a
  byte at a time. Use `crypto.timingSafeEqual` / `hmac.compare_digest`.
- **JWTs: pin the algorithm** at verification. Never let the token's own `alg` header choose —
  that is the alg-confusion class, `alg: none` included. Verify issuer, audience and expiry.
- **Password hashing** with bcrypt/argon2 at a current cost. Never a bare hash, never
  home-made salting.
- **Tokens for reset, invite and magic links**: CSPRNG, high entropy, single-use, short-lived,
  invalidated on use, and stored hashed.
- **Secrets never in the client bundle, logs, URLs or error messages.** A secret in a query
  string lands in access logs and `Referer` headers.

## A05 Injection

- **Raw SQL with interpolation** — `query(\`… ${x}\`)`, or a query builder taking a user string
  as an identifier or an `ORDER BY`. An ORM protects you right up until someone writes raw SQL.
- **NoSQL operator injection**: a user-supplied object reaching a query can smuggle `$ne`,
  `$gt`, `$where`. Validate to primitives.
- **XSS**: `dangerouslySetInnerHTML` / `innerHTML` / `v-html` with anything not sanitised. A
  markdown renderer allows raw HTML unless configured not to. **An uploaded SVG is a script
  document** — never serve user SVGs from your own origin.
- **Prompt injection** — the LLM-era case. Untrusted content reaching a prompt whose output
  drives an action or a tool call. Untrusted text is data, never instructions; the model's
  output is not an authorisation decision.
- **Command and path injection**: user input in a shell command, or in a filesystem path
  (`../`), or as an archive entry name.

## A06 Insecure design

- **Rate limits on anything expensive or abusable**: login, register, reset, search, export,
  file upload, and every LLM endpoint — that last one is a *cost* attack as much as a security
  one.
- **Server-side enforcement of every limit** a user can see. A quota, a cap or a maximum checked
  only in the UI is not enforced.
- **Caps and counters cannot be read-then-written** under concurrency. Conditional update, row
  lock, or a database constraint.

## A07 Authentication failures

- **No account enumeration.** Login, register and reset all give the same answer whether or not
  the account exists, and take roughly the same time.
- **Refresh token rotation with reuse detection** — a replayed refresh token invalidates the
  whole session family.
- **Session invalidation** on password change, on role change, and on logout-everywhere.
- **MFA and OAuth state**: the `state` parameter checked on return, PKCE for public clients.

## A08 Software and data integrity

- **Verify webhook signatures** before trusting a payload, over the **raw body** (see
  `vercel-serverless.md`), with a timing-safe compare.
- **Idempotency** on anything that charges, sends or mutates on retry. Retries are normal.
- **Never trust client-side state for a decision** — prices, totals, entitlements and payment
  outcomes come from the server or the provider's verified webhook, not a browser redirect.

## A09 Logging and alerting failures

The half that is usually missing is the *presence* of logs, not their hygiene:

- **Log the security events**: failed logins, authorisation denials, permission and role
  changes, admin actions, payment state transitions. Without these you cannot answer "was this
  exploited?"
- **Never log** tokens, cookies, passwords, reset links, signatures, full payment payloads, or
  prompts containing user data.
- Enough context to trace one request end to end, and alerting on the events that matter.

## A10 Mishandling of exceptional conditions (NEW)

- **Swallowed exceptions**: `catch {}`, or a catch that logs and then continues as if the
  operation succeeded.
- **Partial failure in a multi-step operation.** Step 2 of 4 fails — what state is the data in,
  and who reconciles it? Every multi-step flow needs a defined answer.
- **Every external call has a defined failure path**: timeout, retry policy, and what the user
  sees. The dangerous case is a call that succeeds remotely and fails locally — charged but not
  recorded.
- **Fail closed.** When an authorisation or validation check errors, deny. A `try/catch` around
  a permission check that returns `true` on error is a critical bug.
- **No floating promises / fire-and-forget** work that must not be lost.

## Accessibility (objective — WCAG)

- Every input has an associated `<label>`. A placeholder is not a label.
- Interactive elements are real elements: no `div`/`span` with `onClick`. Keyboard reachable.
- A visible focus indicator. `outline-none` without a `:focus-visible` replacement is a defect.
- Heading order not skipped. Icon-only controls have accessible names.
- Body text contrast at least 4.5:1. `prefers-reduced-motion` respected.
- `lang` set correctly, and updated per locale in a multilingual app.
