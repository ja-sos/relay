---
name: file-issue
description: Use when review findings need to become tracker issues - after a code review, audit, or repo read that produced defects, gaps, or improvement ideas. Files one categorized issue per finding through the configured tracker, anchored to a commit so line references stay resolvable.
---

# File issue

Turn review findings into tracker issues. Applies when the findings already exist in this
session. Does not apply to filing from a description alone, or to commenting on an issue
that exists.

Every operation named below comes from the backend. Load it, later files overriding
earlier by `##` heading:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
```

That file's `## Tracker`, `## Forge` and `## Review` run through the GitHub MCP tools, and it
opens with the check that picks the route. Run the check before reading on. Where it selects
the `gh` fallback - those tools absent, `gh` authenticated - load that route's file next, so
it replaces those three sections:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github-gh.md
```

Where neither route is available, `backend-github.md` says what that means. Either way, the
project's own files load last:

```
cat .claude/baton.md 2>/dev/null
cat ~/.claude/baton.md 2>/dev/null
```

Two failures are stops, not fallbacks: an operation this skill names that no loaded file
defines, and an operation that fails because its tool is missing or unauthenticated - a
command exiting non-zero, or a named tool the session lacks or cannot authorize. Report
the operation name, the entry that failed, and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`. Never run a command this backend does
not define - an improvised equivalent writes to a tracker the project did not choose.

## Step 1 - Anchor

In the target repo:

```
git rev-parse --short HEAD
git branch --show-current
```

Record the SHA. Line numbers rot; the SHA is what keeps `src/hub.c:117` resolvable.

Run `list-categories` and `list-open`. Stop and ask when a category named in the backend's
`## Categories` table is missing from what `list-categories` returns. Never create one.

## Step 2 - Split

One finding per issue: one defect, one cause, closable by one change.

Drop a finding, and report it dropped, when:

- No `file:line` supports it.
- An open issue from `list-open` covers it.
- It restates a `TODO` already in the code.

## Step 3 - Categorize

Exactly one category, from the backend's `## Categories` table. When code and docs
disagree, decide which side is wrong and categorize that side.

## Step 4 - Body

Run `baton:write-deliverables` per body, as a **Tracker issue**.

Title states the symptom, then its consequence:
`hub_set_input and hub_set_output do not commute; reversed order silently yields a dead virtuon`.
Never an imperative (`Fix ...`, `Add ...`).

Open with the symptom and its mechanism, under no heading. Below that, the headings the
chosen category's row gives.

End every body with:

```
Found at <sha> on <branch>.
```

## Step 5 - File

Write every body to its own file under the scratchpad directory before printing anything:
`issue-<n>-<category>.md`.

Print one line per issue - category, title, and the body's absolute path - and stop for
approval. Spell the path in full from `/`. A `~` or a relative path leaves the reader
hunting for the session's scratchpad directory.

Issues are public on creation and close rather than disappear.

On approval, run `create` per issue. It takes `<path>`, never body text: an argument
carrying the body inline mangles backticks, headings and fenced blocks through the shell.

## Done

Every finding is filed or dropped. Report one line per issue - number, category, title -
and one line per dropped finding with its reason.
