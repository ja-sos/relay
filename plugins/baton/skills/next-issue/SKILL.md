---
name: next-issue
description: Use when the next issue to work on has to be chosen rather than named - "what should I work on", "pick the next issue", "/baton:next-issue", or investigate-issue invoked with no issue number. Resolves one issue assigned to the user that no handoff already covers, and reports what it skipped.
---

# Next issue

Answer which issue to pick up next, and nothing else. This resolves; it does not investigate,
comment, or change anything on the tracker.

Every operation named below comes from the backend, its files loaded in the order
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md` "Where overrides live" sets. Load the
shipped file and run the route check at its top:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
```

Load `backend-github-gh.md` only where that check selects it:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github-gh.md
```

Then the project's own files:

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

Run `list-mine` and keep its order (`defining-backends.md`, `list-mine`). The first candidate
Step 2 does not skip is the answer.

## Step 2 - Skip what is already scoped

Walking the list from the top, run `has-handoff` on each candidate and read its output for the
marker that heads a handoff or a pointer to one:

```
<!-- claude-handoff -->
```

**Skip every issue whose output carries the marker**, whatever became of the handoff it sits
in. The issue has been investigated, and picking it up again produces a second investigation of
settled work. That holds for a pointer as for a handoff, and whether the run it scoped is
pending or has already merged.

A comment carrying the marker and no fenced header is a pointer (`write-handoff` Step 1). Keep
what each marker sat in, and for a pointer the issue it names: Step 3 reports both.

An issue whose handoff carried `closes: no` stays open after its pull request merges and keeps
its marker, so this step goes on skipping it after its run has finished - an issue deliberately
left open for further work is not offered again here.

Stop walking at the first candidate whose output carries no marker - `has-handoff` costs a call
per issue, and the ones below the answer do not need one.

## Step 3 - Report

Name the surviving issue by number and title. List every issue skipped above it and why, so the
choice can be overruled. "Why" is what the marker sat in: a handoff of the issue's own, or a
pointer into another issue's bundle - and for a pointer, the issue it names. A skip the report
does not explain is one nobody can judge.

Add each skipped issue's `closes` value where the marker sat in a handoff: under `closes: no`
the marker may record finished work rather than pending work. A pointer carries no `closes`
value, so report that value as unread and name the primary issue whose handoff holds it, rather
than asserting one this step never saw.

When nothing survives, say so and name what was skipped; that list is what a person picks from.
Never invent an issue, and never return one carrying the marker because the list would
otherwise be empty.

## Done

One issue number, or none, with the skipped list beside it. Starting work on it is the caller's
decision, not this skill's.
