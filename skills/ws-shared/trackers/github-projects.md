# Tracker: GitHub Projects + issues

Cartridge keys: `tracker.org`, `tracker.project_number`,
`tracker.statuses`, optionally `tracker.assignee_default`.

## List

```bash
gh project item-list <n> --owner <org> --limit 50 --format json
gh project item-list <n> --owner <org> --limit 50 --format json --query 'assignee:<login> status:"TO DO"'
gh api "orgs/<org>/members?per_page=100" --jq '.[].login'      # who else there is
gh issue view <num> -R <org>/<repo> --json title,body,labels,assignees,comments
```

Ask the scope first — **mine** (the default), someone else's, or everyone — and which Status to
list (default the project's "to do" equivalent). Combine filters in `--query` where supported,
otherwise filter client-side.

## Claim

```bash
gh issue edit <num> -R <org>/<repo> --add-assignee <login>
gh project item-edit --id <item-id> --project-id <pid> --field-id <status-field> --single-select-option-id <in-progress>
```

Get the ids once with `gh project field-list <n> --owner <org> --format json` and record them in
the cartridge so this is not re-derived every session.

**There is no atomic claim here.** Assigning is not a lock. So: re-read the item immediately
after claiming, and if someone else is now assigned, say so and go back to the list. Where the
project has an explicit in-progress Status, set it — a human can see that.

## Mark

In review: Status → the review column, and comment the PR url on the issue. Done: let the PR's
`Closes #<num>` close it, then confirm the Status moved (automation sometimes does not fire).

## Note

A comment on the issue. Keep it short and factual — it is read by people, not just agents.
Handoffs are a comment plus a Status change; the assignee may stay unchanged.
