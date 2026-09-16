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
```

Run the route check that opens `${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md`. Its
routes 1 and 2 are the two ways the shipped defaults run; route 3 is neither.

| Found | Action |
|---|---|
| No backend file; route 1 or 2 selected | Stop. The shipped defaults run as they are - through the GitHub MCP tools, or through `reference/backend-github-gh.md` - and a copy of them is a second file to keep in sync. |
| No backend file; route 3 | Step 2. |
| A backend file | Print it, name the sections it defines, and ask before continuing. Step 3 overwrites it. |

## Step 2 - Load the contract

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github-gh.md
```

The first fixes the operation table and the placeholder spellings; the other two are the
structure to copy - `backend-github.md` for a tracker reached through an MCP connector,
`backend-github-gh.md` for one reached through a CLI, whose shell entries a retarget to
another CLI tracker starts from. Ask which tracker and forge the project uses when the
request names neither.

## Step 3 - Write the file

Target `.claude/baton.md`. Write `~/.claude/baton.md` only on request: a cloud or CI session
clones the repo and never sees a home directory.

Restate all five sections - `## Tracker`, `## Categories`, `## Forge`, `## Review`,
`## Launcher` - and every operation each one owns. A section left out is not overridden at all,
so its shipped GitHub heading stays loaded and those operations keep running against GitHub.

```
grep -c '^## \(Tracker\|Categories\|Forge\|Review\|Launcher\)$' .claude/baton.md
```

- PASS: 5.
- FAIL: fewer. Add the missing sections before Step 4.

`## Workflow` is the sixth section and stays out of the file unless the user asks for a step
its defaults do not give - a ticket moved to in-progress when implementation starts, a
reviewer requested on every pull request, a worklog after publishing, something logged when
an attended flow ends, handoffs kept somewhere other than the tracker. Its defaults resolve
through whatever `## Tracker` this file defines, so a Jira backend posts handoffs to Jira
without restating them. Written, the section restates all nine of its operations, because a
`##` heading replaces its section whole.

```
grep -c '^- \*\*\(post-handoff\|has-handoff\|started\|code-review\|request-reviewer\|review-wait\|published\|stopped\|wrap-up\):\*\*' .claude/baton.md
```

- PASS: 9, or 0 where the file has no `## Workflow`.
- FAIL: anything between. Add the missing operations before Step 4. An operation left out is
  undefined rather than defaulted, and the skill that calls it stops - `implement-handoff` at
  Step 2 in an unattended run. Step 4 cannot catch it, because it never runs the writing
  operations. `wrap-up` alone is the exception: the four attended skills skip it when it is
  undefined, but the file restates it all the same.

## Step 4 - Verify by running

Run the check table at the end of `reference/defining-backends.md` against the file. Run the
read-only operations and report each by name:

```
reachable
list-mine
list-categories
verify-checkout
```

Where the file's notes say `list-categories` answers one `<category>` at a time, run it with
the label from the first row of the file's `## Categories` table.

- PASS: every row passes and all four operations return.
- FAIL: any row fails or any operation errors. Fix the entry and restart Step 4.

Never verify by running `create`, `comment`, `pr-create`, `review-post`, `post-handoff`,
`started`, `published`, `stopped`, `wrap-up` or `request-reviewer`. Each one writes to the
tracker or the forge.

## Step 5 - Offer document types

Offer this once, as optional: `baton:write-deliverables` ships three contracts and derives any
type not listed, so a project needs none. Name
`${CLAUDE_PLUGIN_ROOT}/skills/write-deliverables/reference/defining-doc-types.md`, and write a
contract only for a type the user names.

## Stop

Stop when Step 4 passes and Step 5 has been offered. An operation still failing at Step 4 stops
the run: report that operation by name and the file as incomplete, never as configured.
