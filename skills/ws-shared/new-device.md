# Setting up a new device

The full procedure for getting a machine from nothing to working. Read by `ws-sync` in
`--new-device` mode; also followable by hand.

**Windows is the expected case**, so every step below is written for it, with macOS noted where
it differs. **Use Git Bash as the shell for everything** — the skills are bash, and porting them
to PowerShell is not worth it.

---

## Part 1 — what the human does first

These need a person. Nothing else works until they are done.

### 1. Install

| Tool | Windows | macOS |
|---|---|---|
| Git (brings Git Bash) | `winget install Git.Git` | preinstalled |
| Node LTS | `winget install OpenJS.NodeJS.LTS` | `brew install node` |
| Python 3 | `winget install Python.Python.3.12` | `brew install python` |
| GitHub CLI | `winget install GitHub.cli` | `brew install gh` |
| sops | `winget install SecretsOPerationS.SOPS` | `brew install sops` |
| age | `winget install FiloSottile.age` | `brew install age` |
| agent-sync | `npm i -g @abdur-codes/agent-sync` | same |

Then `gh auth login`.

### 2. The skills

```bash
agent-sync setup --clone <your library repo url>
```

Registers the device and deploys every skill into Claude Code, Codex and Cursor.

### 3. The age key — the one irreducibly manual step

The private key cannot live in a repo. Copy it from the Mac by hand:

- **From:** `~/.config/sops/age/keys.txt`
- **To (Windows):** `%USERPROFILE%\.config\sops\age\keys.txt`

Any out-of-band channel. Then:

```bash
mkdir -p ~/.config/sops/age          # Git Bash understands this path on Windows
git clone <your secrets repo url> ~/.agent-secrets   # or `ws-env init` on a first machine
git -C ~/.agent-secrets config core.hooksPath .githooks
```

`chmod 600` is a **no-op on Windows** — say so rather than implying the file is protected there.
The protection is NTFS permissions on the user profile.

### 4. A personal knowledge base, if you keep one

```bash
git clone <your notes repo url> ~/<folder>
```

Optional. Nothing in the pack requires it.

---

## Part 2 — what the agent does, and must ask about

### 5. Inventory before changing anything

**Print this table and stop.** On a machine that has not been used in a while there may be
months-old uncommitted work, and losing it is the worst available outcome.

```bash
# the projects the library knows about
sed -n '/^projects:/,$p' ~/.agent-sync/device.yaml
```

| Project | Folder expected | Exists? | Repos cloned | Behind by | Uncommitted |
|---|---|---|---|---|---|

### 6. Ask where each missing workspace goes — do not guess

A workspace folder that is absent, or somewhere different from the Mac, is **normal**. The paths
are per device by design; `device.yaml` holds them.

**Ask the user, once, for each project that is missing or not where the library expects:**

> "`<project>` isn't registered on this machine. Where should its workspace live? I can see you
> have `<the Development folder found below>`. Shall I create `<that>/<Project>`, or somewhere
> else?"

Find the candidates first so the question is concrete, not open-ended:

```bash
for d in ~/Development ~/Dev ~/dev ~/code ~/Projects ~/source/repos ~/Documents/Development; do
  [ -d "$d" ] && echo "  found: $d" && ls -1 "$d" | head -10 | sed 's/^/      /'
done
```

**Never invent a path, and never reuse the Mac's path.** On Windows a Mac path is wrong by
definition.

### 7. Create each workspace, in this exact shape

The structure is not optional — it is what the whole system assumes. For each project:

```bash
mkdir -p "<chosen path>"
cd "<chosen path>"
# the root is NOT a git repo, and must not become one.
# that is what makes it safe to keep credentials, plans and track state here.
```

Then clone the repos from the project's cartridge `repos:` list, and register the project:

```bash
agent-sync link <project-id>        # with the EXACT id below
```

**The id matters.** A workspace root is not a repo, so `.agent-sync.yaml` is not committed
anywhere and cannot travel — the id has to be typed correctly on each machine.

**Where the list comes from.** There is no inventory of projects in this pack, on purpose — one
would be wrong the moment a project is added, renamed or retired. The authority is the library
itself: `agent-sync status` names every project the library knows, and a project's own docs repo
names the repos to clone beside it. Write the list down in **your** docs, not here.

| Project id | Repos to clone (owner/name → folder) | Docs home |
|---|---|---|
| `northwind` | `example-org/northwind-api`, `/northwind-web`, plus `example-user/northwind-docs` | `northwind-docs/agent/` |
| `kestrel` | `example-org/kestrel-ai` (single repo) | `docs/agent/` |

Note the docs repo under a different owner from the code repos. That is the normal case, not a
mistake — see [reference.md](reference.md).

Then per project:

```bash
mkdir -p .<project>/tracks            # .northwind, .kestrel — one per project id
```

and write the workspace instruction files as **copies**, never symlinks:

```bash
{ echo '<!-- Generated by ws-sync from <docs>/agent/workspace/AGENTS.md. Edit the source, not this. -->'
  cat <docs>/agent/workspace/AGENTS.md; } > AGENTS.md
echo '@AGENTS.md' > CLAUDE.md
```

**Never a symlink.** Windows git checks a symlink out as a text file containing the path,
silently, and the agent then reads a one-line file instead of the rules. It looks like the agent
ignoring you.

### 8. Credentials

```
ws-env pull
```

Writes each env file to the path `manifest.tsv` records, resolved against this device's
`device.yaml`. Report what landed and what was skipped because a project is not linked.

### 9. Catch up what already existed

Only now, and **one repo at a time**, per `ws-sync` step 2. Ask before every pull on a repo that
is both behind and dirty — that is where work gets lost.

Ask once, before starting: **"is there uncommitted work on this machine you care about?"** If
yes, go repo by repo. If the user says treat it as disposable, re-cloning is far faster — but
that is their call.

### 10. Verify

```bash
agent-sync status      # expect no drift
ws-sync                # expect a clean drift table
```

---

## Windows differences worth knowing

| Thing | Note |
|---|---|
| `agent-sync setup --clone` | **wrong if the store already exists.** Check for `~/.agent-sync/store` with the right remote first; if it is there, `agent-sync sync` instead |
| Shell | **Git Bash** for everything. Not PowerShell, not cmd |
| Paths | always from `device.yaml`; a Mac path is never right here |
| `chmod 600` | a no-op. Env files are less protected than on macOS — say so |
| Line endings | `tr -d '\r'` when sourcing an env file; the secrets store pins LF |
| Symlinks | do not create them. See step 7 |
| Python venv | `Scripts/` here, `bin/` on macOS |
| A multi-repo project | its marker cannot travel, because the workspace root is not a repo — `agent-sync link <id>` must be run here by hand |
| A project needing Docker or nginx | **nginx on Windows is genuinely unpleasant**; such a project may stay macOS-only in practice. Record that in its own docs, not here |
| Long paths | enable them, or a deep `node_modules` will fail: `git config --global core.longpaths true` |
