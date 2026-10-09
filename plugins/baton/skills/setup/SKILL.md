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
| The request is for `## Repositories` alone, whether or not a backend file exists | Add or replace that one section in `~/.claude/baton.md`, creating the file if absent and leaving every other section as it is. Run only Step 3's two `## Repositories` checks and Step 4's `## Repositories` checks, then stop: the full Step 3 counts and the Step 4 check table test a backend's operations, which this request neither writes nor changes. It overrides no shipped operation, so it is not the duplicate the no-backend-file rows refuse. |
| The request is for `## Assets` alone, whether or not a backend file exists | The same, for that section: add or replace it in `~/.claude/baton.md`, creating the file if absent and leaving every other section as it is. Run only Step 3's two `## Assets` checks, then stop - the section defines no operation, so Step 4 has nothing of it to run. |
| The request is for `## Repositories` and `## Assets` together, whether or not a backend file exists | Both rows above, in one pass over `~/.claude/baton.md`: write each section and run each one's checks. They are the two optional per-machine sections and neither overrides a shipped operation, so a request for both is still not the duplicate the no-backend-file rows refuse. |
| No backend file; route 1 or 2 selected | Stop: a copy of the shipped defaults is a second file to keep in sync. |
| No backend file; route 3 | Step 2. |
| A backend file | Print it, name the sections it defines, and ask before continuing. Step 3 overwrites it. |

## Step 2 - Load the contract

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github-gh.md
```

Copy the structure from the file the "Example" section of `defining-backends.md` names for how
the tracker is reached. Ask which tracker and forge the project uses when the request names
neither.

## Step 3 - Write the file

Target `.claude/baton.md`. Write `~/.claude/baton.md` only on request: a cloud or CI session
clones the repo and never sees a home directory.

Restate all five sections - `## Tracker`, `## Categories`, `## Forge`, `## Review`,
`## Launcher` - and every operation each one owns.

```
grep -c '^## \(Tracker\|Categories\|Forge\|Review\|Launcher\)$' .claude/baton.md
```

- PASS: 5.
- FAIL: fewer. Add the missing sections before Step 4.

`## Forge` gets the same count of its own operations that `## Workflow` gets below, and for
the same reason: `stack-link` writes to the forge, so Step 4 never runs it.

```
grep -c '^- \*\*\(verify-checkout\|pr-create\|stack-link\|pr-view\|pr-update\|closes\|refs\):\*\*' .claude/baton.md
```

- PASS: 7.
- FAIL: fewer. Add the missing operations before Step 4.

A tracker that carries no labels gets `- **list-categories:** none` rather than an entry that
prints the `## Categories` labels back. A `create` that substitutes `<category>` carries the
empty-value note `defining-backends.md` requires under `list-categories: none`.

`## Workflow` is the sixth section and stays out of the file unless the user asks for a step
its defaults do not give - a ticket moved to in-progress when implementation starts, a
pre-push sequence of the project's own rather than its test command alone, a reviewer
requested on every pull request, a worklog after publishing, something logged when an
attended flow ends, handoffs kept somewhere other than the tracker. Written, the section
restates all eleven of its operations.

```
grep -c '^- \*\*\(post-handoff\|has-handoff\|started\|verify\|code-review\|request-reviewer\|review-wait\|published\|reviewed\|stopped\|wrap-up\):\*\*' .claude/baton.md
```

- PASS: 11, or 0 where the file has no `## Workflow`.
- FAIL: anything between. Add the missing operations, `wrap-up` included, before Step 4:
  Step 4 never runs the writing operations, so it cannot catch one left out.

`## Repositories` is the seventh section and the second optional one. It stays out of
`.claude/baton.md` altogether: it maps `owner/repo` to an absolute local path. Write it in
`~/.claude/baton.md`, and only on request - a change spanning repositories that depend on each
other is what needs it. No count above requires it.

```
grep -c '^## Repositories$' ~/.claude/baton.md 2>/dev/null
```

- PASS: `1` where the user asked for the section; `0`, or no output at all, where they did not.
  `grep` prints nothing and exits 2 when the file does not exist, which is the usual case.
- FAIL: more than 1.

Written, it carries one row per repository, each naming an absolute path:

```
grep -c '^| `[^/`]*/[^`]*` | `/' ~/.claude/baton.md 2>/dev/null
```

- PASS: one per repository the user named.
- FAIL: fewer. A relative path resolves against whatever directory a launcher happens to start
  in, so a row that is not absolute is a row to rewrite.

`## Assets` is the eighth section and the third optional one. It stays out of
`.claude/baton.md`: write it in `~/.claude/baton.md`, and only on request. Its one entry is
`root`, in the form the "Sections" part of `defining-backends.md` gives for `## Assets`.

```
grep -c '^## Assets$' ~/.claude/baton.md 2>/dev/null
```

- PASS: `1` where the user asked for the section; `0`, or no output at all, where they did not.
  `grep` prints nothing and exits 2 when the file does not exist, which is the usual case.
- FAIL: more than 1. Keep one heading.

This next check runs only where the check above found the section. Skip it where the user did
not ask for `## Assets`: the file carries no `root`, and running it there prints a failure
about an entry nobody meant to write.

Written, its `root` must be an absolute path to a directory that exists. A relative path
resolves against whatever directory the run happens to start in:

```
root=$(sed -n 's/^- \*\*root:\*\* *//p' ~/.claude/baton.md 2>/dev/null | tr -d '`' | tail -1)
case "$root" in /*) test -d "$root" && echo "ok $root" || echo "FAIL not a directory: $root";;
  *) echo "FAIL not absolute: $root";; esac
```

- PASS: `ok` and the path.
- FAIL: either message. `FAIL not absolute:` with nothing after the colon is the section
  carrying no `root` entry at all. Fix the entry before stopping.

## Step 4 - Verify by running

Run the check table under `## Checks` in `reference/defining-backends.md` against the file.
Run the read-only operations and report each by name:

```
reachable
list-mine
list-categories
verify-checkout
```

Where the file's notes say `list-categories` answers one `<category>` at a time, run it with
the label from the first row of the file's `## Categories` table. Where `list-categories` is
`none`, the tracker carries no labels: run nothing for it and report it as skipped. A
`list-categories` the file does not define is not skipped - it fails the step as an
undefined operation.

- PASS: every row passes and all four operations return - or, where `list-categories` is
  `none`, the other three return.
- FAIL: any row fails or any operation errors. Fix the entry and restart Step 4.

Where the file carries `## Repositories`, check every row of it too. A wrong path sends a run
into the wrong tree rather than failing, so the check is the repository each path answers as,
not merely that something is there:

```
test -d <path> && git -C <path> rev-parse --show-toplevel
```

Then run `verify-checkout` in each row's path and compare its answer with that row's
`owner/repo`.

- PASS: every row's path is a git checkout whose `verify-checkout` answer equals its
  `owner/repo`.
- FAIL: any row whose path is missing, is not a checkout, or answers with a different
  repository. Fix the row and restart Step 4.

`verify-checkout` reads and writes nothing, so running it once per row adds nothing to the
list below.

Never verify by running `create`, `comment`, `pr-create`, `stack-link`, `review-post`,
`post-handoff`, `started`, `published`, `reviewed`, `stopped`, `wrap-up` or
`request-reviewer`. Each one writes to the tracker or the forge - `stack-link` to a pull
request belonging to somebody else's handoff. Never run `verify` either: a project's sequence may rewrite files in the
user's checkout.

## Step 5 - Offer document types and an owner map

Offer each once, as optional. For document types, name
`${CLAUDE_PLUGIN_ROOT}/skills/write-deliverables/reference/defining-doc-types.md`, and write a
contract only for a type the user names. For an owner map, name
`${CLAUDE_PLUGIN_ROOT}/skills/write-deliverables/reference/defining-owners.md`, and write a row
only for a fact the user names.

## Stop

Stop when Step 4 passes and Step 5 has been offered. An operation still failing at Step 4 stops
the run: report that operation by name and the file as incomplete, never as configured.
