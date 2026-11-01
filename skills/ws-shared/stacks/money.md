# Stack: money

Selected by `stack: [money]`. Applies to anything that moves, holds or totals money.

**Never a float.** `0.1 + 0.2` is not `0.3`. Amounts are integer minor units (cents) or a
decimal type all the way through — database column, domain model, API contract, UI. A `number`
holding dollars is a Must fix.

**A formatted string is not a value.** `"HK$1,200.00"` is for display only. String
concatenation to build an amount (`"HK$" + total`), or parsing a formatted string back into a
number, are both defects. Format at the very edge, once.

**Currency travels with the amount.** An amount without a currency code is ambiguous the moment
a second currency appears. A new money field with no currency alongside it is a finding.

**Rounding is a decision, not a side effect.** Where it happens, which direction, and on
totals versus line items. Rounding each line then summing gives a different answer from summing
then rounding — the code should say which it means.

**No optimistic UI on money.** Ever. Showing a balance, a total or a successful payment before
the server confirms is a Must fix, regardless of how good it feels.

**Idempotency.** A payment or charge endpoint that can be called twice must do the same thing
once. Check for an idempotency key, or a uniqueness constraint that makes the second attempt
fail safely. Retries happen — in webhooks, in clients, in queues.

**Totals are derived, never stored and trusted.** If a total is stored for performance, there
must be something that recomputes and reconciles it.

**Webhooks decide, the client does not.** Payment state comes from the provider's verified
webhook, not from a browser redirect the user could have skipped or forged. See
`vercel-serverless.md` on raw-body signature verification.

**Idempotency keys name the request.** An idempotency key built from state the operation itself
changes (a running total, a status, a count) is not stable across a retry; the key must name the
request, supplied by the caller.

**A retry whose precondition the first attempt destroyed.** Once a provider call has succeeded, the
record it referred to may no longer satisfy the guard the retry re-enters — a refunded payment is
no longer refundable — so the retry throws for ever while the money has already moved. Every step
after the point of no return must be re-drivable from the recorded state, and a step that reads a
terminal state and returns silently is how a refund gets made and never told.

**Retry sweeps filter, then limit.** A retry or re-queue sweep that applies its batch limit before
excluding rows it has given up on lets those rows fill every batch and starve newer ones; filter
first, then limit.

**Test money with the ugly numbers.** Amounts that do not divide cleanly, a discount larger
than the total, zero, a refund of a partially refunded order.

**A completed checkout that is not yet paid is still money on its way.** With asynchronous
methods (Alipay, WeChat Pay, bank debits) a Stripe Checkout Session can be `complete` while
`payment_status` is still unpaid. Code that treats anything not `open` and not `paid` as
abandoned, and replaces it with a fresh payable session, lets the customer pay twice. Check:
only an `expired` session is replaced; `complete` is treated as in progress.

**Due dates and day counts are calendar arithmetic in the business's time zone.** `timestamptz +
interval 'n months'` run in a UTC session lands a day off near midnight and month ends, and "due in
N days" taken from a fixed schedule constant drifts when the sweep that sends it runs hours after
the window opens. Check: the zone is explicit in the SQL and the count is computed at send time.

**A step that can take several payments breaks "another payment already settled it" checks.** A
confirmation that skips when another settled payment exists for the same step stops working once a
short payment can be followed by the rest; deduplicate on the payment's own id instead.

**A status the provider's webhook updates is not a guard against a second charge.** Between the payment
settling and the record it updates moving, a "can this be paid?" check that reads only that record passes
while the pending-payment lookup finds nothing — both gates are open at once. Check for a settled payment,
not for the state a settled payment will eventually produce.

**Reusing an open checkout session must check it still matches what is owed now** — purpose and
amount. Otherwise a session opened before a refund or a plan change charges the old amount.

**A record of what you asked the provider for, and the provider's own settled total, double-count the
moment it acts.** If request rows are never closed, a paid-out request sits in both numbers, and
subtracting both makes the remainder unrefundable for ever after the first partial one. Check the amount
still available is computed against what the provider has **not** yet acted on.

**An idempotency key minted per dialog-open turns "close and try again" into a second charge.** After a
failure the natural retry must reuse the failed attempt's key; only a request the provider accepted earns
a new one.
