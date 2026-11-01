# Stack: NestJS + TypeORM

Selected by `stack: [nestjs, typeorm]`. In the examples, `northwind-api`.

**Transactions and the manager.** A repository call inside a transaction that does not receive
the transactional `manager` silently runs on a different connection, so it is not in the
transaction and will not roll back. Check every repository method called inside a
`transaction()` / `queryRunner` block takes and forwards `manager`.

**Read-then-write on shared state.** Stock, quotas, counters, caps, "last one wins" fields. A
`find` followed by a `save` is a lost-update race under concurrency. Needs a locking read
(`SELECT … FOR UPDATE` / `pessimistic_write`), an atomic UPDATE with a WHERE guard, or a DB
constraint. Optimistic UI over it is a separate finding.

**Entities leaking outward.** A DTO that spreads an entity (`...user`) ships whatever columns
exist today plus whatever is added tomorrow — including `passwordHash`. Response shapes are
built field by field, explicitly.

**Guards: order and identity.** A new route outside the public prefix with no guard. A role
check (`role === 'admin'`) where a permission check belongs. A `userId` taken from the request
body or params instead of the authenticated context — that is an authorisation bypass, always
Must fix.

**Lazy relations and N+1.** A loop that touches `entity.relation` without a `relations:` or a
join issues a query per row. Flag any `for`/`map` over entities that dereferences a relation.

**Module wiring.** A provider registered in two modules gets two instances. Circular imports
"fixed" with `forwardRef` usually mean the boundary is wrong. A new use case not registered in
its composition root fails only at runtime.

**Validation at the edge.** Every inbound DTO validated (`class-validator` / Zod) with
`whitelist` and `forbidNonWhitelisted`, or unknown fields ride through. Numbers and booleans
from query strings need explicit transforms.

**A `timestamptz` round-tripped through a JS `Date` loses the column's microseconds**, so any
later comparison against the stored value silently stops matching. As a keyset cursor,
`(timestamp, id) > (cursor)` then matches the cursor row itself and the same page repeats for ever;
as a claim token, `WHERE claimed_at = $n` matches nothing and every write after the claim is lost
while the code reports success. Carry the value as the text Postgres printed and cast it back, or
stamp it with `date_trunc('milliseconds', now())` so the stored precision is one a `Date` can hold.
Mocked tests never see it — only a spec against real Postgres does. Also check that the ordering a
cursor follows has an index, which a mocked test will not tell you either.

**Raw `query()` results.** A raw `query()` on an `UPDATE`/`DELETE … RETURNING` returns
`[rows, count]` in TypeORM's Postgres driver, so a `rows.length > 0` check is always true; use the
query builder's `affected` or destructure.

**Migrations.** See `migrations-sql.md`.

**Layered architecture.** If the project tags `hexagonal`, read that pack too and treat the
repo's own practices doc as the rulebook.
