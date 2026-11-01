# Stack: Next.js App Router

Selected by `stack: [nextjs-app-router]`. In the examples, `northwind-web`.

**Server/client boundary.** `"use client"` at the top of a file makes it and everything it
imports client code. Check: a secret or server-only module reachable from a client component; a
whole page turned client because one leaf needed a hook; `async` data fetching inside a client
component where a server component would do.

**Secrets in `NEXT_PUBLIC_*`.** Anything with that prefix is in the browser bundle. A service
key, an API secret or a private URL there is a Must fix, always.

**Auth on every protected page, not just the layout.** A layout gate is not a page gate:
layouts can be skipped by route-group changes and do not run for every segment. Each protected
page or route handler asserts access itself. Member or admin data reachable while logged out is
the single most expensive defect class here — check it explicitly.

**Caching is the default and it surprises people.** Fetches and route segments are cached
unless told otherwise. A page showing stale data after a mutation, or a dynamic page built
statically, is usually a missing `revalidate`/`no-store`/`revalidatePath`. Conversely,
`no-store` sprayed everywhere is a performance finding.

**Hydration mismatches.** `Date.now()`, `Math.random()`, `localStorage` or `window` read during
render. Any of these in a component that also renders on the server is a defect.

**The four forgotten states.** Empty, loading, error, and long text. Plus logged-out, and
keyboard focus. A new screen without them is a Should fix at minimum.

**Responsive and accessible.** Check the project's narrow breakpoint (360 or 390). `div` used
as a button; an icon button with no accessible label; a removed focus ring; a hard-coded string
where the project uses i18n (`next-intl`) — including `aria-label` and `placeholder`.

**Optimistic updates.** Fine for likes, saves, cart quantity. **Never** for money, stock, or
anything capped. If the project's practices doc lists what is allowed, that list is the rule.

**Design tokens.** Raw hex or arbitrary spacing where the project has tokens; a bespoke
component duplicating an existing primitive. Both are findings. Check the repo's `commands`
first — a project with a colour-check script has already made this enforceable, and a rule the
tooling enforces does not need your attention.

**State that outlives its trigger.** A confirm dialog whose text is computed from data its own
action changes shows the wrong text while it closes, and one rendered inside a branch that the
action removes never gets its close callback (a per-call `mutate(…, { onSuccess })` is dropped
once the caller unmounts), leaving `open` stuck on for whatever is shown next. Check: the dialog
captures what it shows when it opens, stays mounted until closed, and the parent is keyed per
item. Same family: an effect whose cleanup cancels its own timers when a prop it caused flips back.

**A lookup that is lenient for display and strict for mutation.** When a component matches
stored data loosely to decide what to render as selected or active — trimmed, case-insensitive,
normalised — every handler that *writes* that field must use the same comparison. Otherwise the
row the user sees chosen is not the row the write targets, and the value is dropped or left
stale while the UI shows it set. Check: one shared predicate or index used by both, not an
exact `===` in the handler beside a normalised match in the render.

**A nested `loading.tsx` can swallow `notFound()`.** A route segment with its own
`loading.tsx` under a parent that already has one: a `notFound()` thrown by the inner page can
leave the skeleton on screen with a 200 instead of the 404 page. Check: one loading boundary per
route branch, and the not-found path of every new dynamic route actually exercised in a browser.

**A loading state machine whose initial state renders as a definitive answer.** A hook that
starts at `idle` and only reaches `loading` inside its effect states "none" for the first frame,
before anything has been attempted; an effect that returns early — no ids yet, nothing to fetch
— without setting a state leaves that first state on screen forever. Check: every state the
component can be in, `idle` and every early return included, reads as "still loading" or as a
real answer, and never as a negative the data has not earned.

**A value derived for a dependency list, then read back as the data.** `ids.join(",")` is a
stable effect key; `key.split(",")` is not the array. Any separator inside one element splits it
in two, and two different arrays can share one key, so the effect will not re-run when the data
genuinely changed. Check: the key is used only for comparison, and the original array is what
the body reads.

**A locally streamed turn de-duplicated against stored data by content equality.** A screen that
shows both a turn it is streaming and the server's stored copy needs a predicate for which to
hide. Matching on the message text hides the new turn from its very first render as soon as the
same text exists anywhere in the conversation — ask a question twice and the second one shows
nothing at all. Check: the de-duplication keys on an id, a turn counter or a position, never on
equality of user-supplied text.

**A "cleared" or "dismissed" id latch that is set once and never cleared.** A screen that
remembers which id the user stepped away from, and subtracts it from the current selection, must
clear the latch when the selection changes. Otherwise that id can never be chosen again: the URL
says one thing and the view shows another, silently. Check: every latch of this shape has a reset
on the input it filters — or the state belongs in the URL instead.
