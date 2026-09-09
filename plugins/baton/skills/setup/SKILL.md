---
name: setup
description: Use when baton has to be pointed at a tracker other than GitHub, or an existing backend file has to be completed or repaired - "/baton:setup", "configure the baton backend", "point baton at Linear". Writes the backend file with every operation its sections own and verifies it by running them. Does not apply to filing, investigating, implementing or reviewing work.
---

# Setup

Write one backend file for this project and prove it runs. Invoked only: no other baton skill
calls this one.

The output is configuration, not prose. `baton:write-deliverables` does not apply to it, and
`reference/defining-backends.md` fixes the sections, the operation names and the placeholder
spellings.

## Step 1 - Route on what exists

```
ls .claude/baton.md ~/.claude/baton.md 2>/dev/null
command -v gh
```

| Found | Action |
|---|---|
| No backend file, `gh` present | Stop. The shipped defaults run as they are, and a copy of them is a second file to keep in sync. |
| No backend file, no `gh` | Step 2. |
| A backend file | Print it, name the sections it defines, and ask before continuing. Step 3 overwrites it. |

## Step 2 - Load the contract

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
```

The first fixes the operation table and the placeholder spellings; the second is the structure
to copy. Ask which tracker and forge the project uses when the request names neither.

## Step 3 - Write the file

Target `.claude/baton.md`. Write `~/.claude/baton.md` only on request: a cloud or CI session
clones the repo and never sees a home directory.

Restate all five sections - `## Tracker`, `## Categories`, `## Forge`, `## Review`,
`## Launcher` - and every operation each one owns. A section left out is not overridden at all,
so its shipped GitHub heading stays loaded and those operations keep running `gh`.

```
grep -c '^## \(Tracker\|Categories\|Forge\|Review\|Launcher\)$' .claude/baton.md
```

- PASS: 5.
- FAIL: fewer. Add the missing sections before Step 4.

## Step 4 - Verify by running

Run the check table at the end of `reference/defining-backends.md` against the file. Run the
read-only operations and report each by name:

```
reachable
list-mine
list-categories
verify-checkout
```

- PASS: every row passes and all four operations return.
- FAIL: any row fails or any operation errors. Fix the entry and restart Step 4.

Never verify by running `create`, `comment`, `pr-create` or `review-post`. Each one writes to
the tracker.

## Step 5 - Offer document types

Offer this once, as optional: `baton:write-deliverables` ships three contracts and derives any
type not listed, so a project needs none. Name
`${CLAUDE_PLUGIN_ROOT}/skills/write-deliverables/reference/defining-doc-types.md`, and write a
contract only for a type the user names.

## Stop

Stop when Step 4 passes and Step 5 has been offered. An operation still failing at Step 4 stops
the run: report that operation by name and the file as incomplete, never as configured.
