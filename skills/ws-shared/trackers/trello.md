# Tracker: Trello

Cartridge keys: `tracker.board_id` and `tracker.lists` — the board id and the names of the
lists that mean open and in progress. In the examples, atlas.

**Do not rely on a Trello MCP server** — it is frequently disconnected in Cursor. Use the REST
API over `curl`.

## Credentials

Prefer the shell env, then `ws-env`. Never print a value, never paste one into chat:

```bash
# once the secrets store holds them:
( set -a; eval "$(tr -d '\r' < <workspace>/.cursor/mcp.env)"; set +a; ... )
# or inject for one command without touching disk:
ws-env run <project>/cursor-mcp.json '<command>'
```

Auth is a query string on every call: `key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}`.

## List

Base `https://api.trello.com/1`.

| Step | Call |
|---|---|
| board lists | `GET /boards/<boardId>/lists?fields=id,name` |
| cards in a list | `GET /lists/<listId>/cards?fields=id,name,shortUrl,labels,desc,idMembers` |
| full card | `GET /cards/<cardId>?fields=name,desc,url,shortUrl,labels,idList&checklists=all` |
| comments | `GET /cards/<cardId>/actions?filter=commentCard` |

Resolve list ids by name, **case-insensitively** (note the space in "To Do"). **Skip placeholder
cards whose title is exactly the list name** — some boards carry header stubs like that.
Checklist items that read like acceptance criteria **are** the acceptance criteria; there is no
other structured field for them.

## Claim

```bash
curl -s -X PUT "https://api.trello.com/1/cards/<cardId>?idList=<doingListId>&key=$K&token=$T"
curl -s -X POST "https://api.trello.com/1/cards/<cardId>/idMembers?value=<memberId>&key=$K&token=$T"
```

Moving to `Doing` plus adding yourself is the claim. **It is not atomic** — re-read the card
afterwards, and if someone else is on it, stop and say so.

## Mark

In review: comment the PR url on the card and move it to the board's review list if one exists
(where the board has no review list — the examples give atlas only `To Do` and `Doing` — **ask**
where a finished card should go rather than
inventing a list). Done: move it where the team puts done cards; never create a new list.

## Note

A comment on the card:
`POST /cards/<cardId>/actions/comments?text=<urlencoded>`.
