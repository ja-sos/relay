---
name: next-issue
description: Use when the next issue to work on has to be chosen rather than named - "what should I work on", "pick the next issue", "/baton:next-issue", or investigate-issue invoked with no issue number. Resolves one issue assigned to the user that is not already waiting on a handoff, and reports what it skipped.
---

# Next issue

Answer which issue to pick up next, and nothing else. This resolves; it does not investigate,
comment, or change anything on the tracker.

Every operation named below comes from the backend. Load it, later files overriding earlier
by `##` heading:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
```

That file's `## Tracker`, `## Forge` and `## Review` run through the GitHub MCP tools, and it
opens with the check that picks the route. Run the check before reading on. Where it selects
the `gh` fallback - the MCP route failing its check, `gh` authenticated - load that route's
file next, so it replaces those three sections:

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

## Step 1 - Candidates

Run `list-mine`. It returns the issues assigned to the user in the order they should be picked
up, so the first survivor of Step 2 is the answer. Ordering is the backend's job; do not re-rank
the list here.

## Step 2 - Skip what is already scoped

Walking the list from the top, run `has-handoff` on each candidate and skip any whose output
contains the handoff marker:

```
<!-- claude-handoff -->
```

That issue has been investigated and is waiting for its implementation run. Picking it up again
produces a second investigation of settled work.

An issue bundled into another issue's handoff carries the marker too, in a pointer comment
`baton:write-handoff` posts on every issue its header names beyond the first. Nothing here
changes for it: the marker is the whole test, so a pointer skips its issue exactly as a handoff
does - and correctly, because that issue is waiting on the same implementation run as its
primary. Keep what the marker sat in and, for a pointer, the issue it names: Step 3 reports
that, and the marker alone does not carry it.

An issue whose handoff carried `closes: yes` is closed by its merged pull request once that
handoff is implemented, so it never reaches `list-mine` again. One that carried `closes: no`
stays open and keeps its marker, and this step goes on skipping it after the run that
implemented it has finished - so an issue deliberately left open for further work is not
offered again here. Say so in Step 3 rather than treating every skip as settled scope: a
marker records that an implementation run was scoped, not that one is still pending.

Stop walking at the first candidate that survives - `has-handoff` costs a call per issue, and
the ones below the answer do not need one.

## Step 3 - Report

Name the surviving issue by number and title. List every issue skipped above it and why, so the
choice can be overruled. "Why" is what the marker sat in: a handoff of the issue's own, or a
pointer into another issue's bundle - and for a pointer, the issue it names. A skip the report
does not explain is one nobody can judge.

When nothing survives, say so and name what was skipped. Never invent an issue, and never
return one that carries the marker because the list would otherwise be empty.

## Done

One issue number, or none. Starting work on it is the caller's decision, not this skill's.
