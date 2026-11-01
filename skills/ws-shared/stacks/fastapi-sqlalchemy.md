# Stack: FastAPI + SQLAlchemy + Pydantic

Selected by `stack: [fastapi, sqlalchemy]`. In the examples, `kestrel-ai`.

**Sync work in an async route blocks the whole event loop.** A `def` route doing I/O is fine
(FastAPI threadpools it); an `async def` route calling a blocking client — `requests`, a sync
DB driver, `time.sleep`, a CPU-bound loop — stalls every other request. One of the most common
and most invisible defects in this stack.

**Session lifetime.** A session must be request-scoped via `Depends`. A module-level session, a
session shared between requests, or one not closed on an exception path leaks connections and
eventually exhausts the pool. Check the exception path specifically.

**Response models.** A route returning an ORM object without a `response_model` serialises
whatever columns exist, including hashes and internal flags. Pydantic response models are
explicit, field by field.

**Lazy loading outside the session.** Accessing a relation after the session closes raises
`DetachedInstanceError` — or worse, after a commit, silently re-queries. Eager-load what the
response needs (`selectinload`), and never return an ORM object straight out.

**N+1.** A loop over rows that touches a relation. Same test as any ORM.

**Pydantic v1 vs v2.** `.dict()`/`.parse_obj()` are v1; `.model_dump()`/`.model_validate()` are
v2. `orm_mode` became `from_attributes`. Mixed idioms in one change means one of them is wrong
for the installed version — check the manifest.

**Validators that do I/O.** A Pydantic validator hitting the database or network runs in
unexpected places and is near-impossible to test. Validation is pure.

**Dependency overrides in tests.** Tests that patch globals instead of using
`dependency_overrides` leak state between tests.

**Background work.** `BackgroundTasks` dies with the process; it is not a queue. Anything that
must survive a restart needs real infrastructure. Flag long-running work started in a request.

**Migrations.** See `migrations-sql.md`. For Alembic specifically: autogenerate misses
server defaults, enum changes, and index renames — read the generated script, never trust it.
