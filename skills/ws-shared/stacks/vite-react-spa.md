# Stack: Vite + React Router SPA

Selected by `stack: [vite, react-router-spa]`.

**Everything ships to the browser.** There is no server component and no server runtime. Any
secret in the bundle is exposed — and in Vite, **only `VITE_*` vars are injected**, so a
missing prefix means `undefined` at runtime rather than an error. Check both directions: a
secret that *is* prefixed, and a needed var that is not.

**Auth is client-side, so it is not a security boundary.** Route guards hide UI; they do not
protect data. Every protected read must be enforced by the API (or RLS, for Supabase). A
finding is: a guard added client-side with no corresponding server-side check.

**Supabase from the browser.** The anon key is public by design, so **row-level security is the
actual access control**. A new table or query without RLS considered is a Must fix. A
`service_role` key anywhere in this repo is a Must fix.

**Routing.** Loader/action errors need an error element or they blank the screen. A protected
route without a redirect for the unauthenticated case. Lazy routes without a suspense boundary.

**No SSR means no SEO and a visible first paint.** Fine for an authenticated studio app; a
finding if the change adds a public marketing page here.

**Bundle growth.** A heavy dependency added for one small use (a date library, an icon set, a
chart library) is a Should fix in an SPA, where it lands in the initial download.

**State.** Server data in React state instead of a query cache leads to stale views and
refetch storms. Check whether the project has a query layer and whether this change bypassed it.
