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
up, so the first survivor of Step 2 that carries no marker at all is the answer - Step 2 says
why an answered issue survives without being that answer. Ordering is the backend's job; do not
re-rank the list here.

## Step 2 - Skip what is already scoped

Walking the list from the top, run `has-handoff` on each candidate and read its output for two
markers. The first heads a handoff, or a pointer to one:

```
<!-- claude-handoff -->
```

That issue has been investigated and is waiting for its implementation run. Picking it up again
produces a second investigation of settled work.

The second heads an obsolete report, which `baton:implement-handoff` posts on every issue its
handoff's header named when it finds the work already done at HEAD and exits without a pull
request:

```
<!-- claude-handoff-obsolete -->
```

**Test each marker as a whole string, never as a prefix.** The two share the opening
`<!-- claude-handoff`, and a scan for that prefix reads every obsolete report as a second
handoff - one carrying `base` and `branch` lines, which is exactly what an unanswered handoff
looks like, so the issue stays skipped for good and this step's own fix does nothing. The
handoff marker ends in a space and `-->` where the obsolete marker continues into `-obsolete`,
which is what tells them apart and why they are spelled this way.

**Skip the issue while any handoff or pointer on it is unanswered.** A handoff is answered by
an obsolete report on that issue naming the handoff's header `base` and `branch`; a pointer is
answered by one naming the locator the pointer carries. Matching is by that content and never
by comment order or comment address: `view` output need not carry an address, and nothing fixes
the order comments come back in - so a count of markers, or the newest comment, decides
nothing here.

An issue whose every handoff and pointer is answered survives this step. Its scope is no longer
pending work: an implementation run has reported that HEAD already satisfies it, and what it
waits on is a person to close it - which it will never get while this step keeps hiding it.

An issue bundled into another issue's handoff carries the handoff marker too, in a pointer
comment `baton:write-handoff` posts on every issue its header names beyond the first. A pointer
skips its issue exactly as a handoff does, and is answered exactly as one is - by its own
locator rather than by a `base` and `branch` it never carried. What the marker records is that
an implementation run was scoped over that issue, which holds for a pointer as for a handoff,
and holds whether that run is still pending or has already merged. Keep what the marker sat in,
for a pointer the issue it names, and for either whether a report answered it: Step 3 reports
all three, and the markers alone carry none of it.

An issue whose handoff carried `closes: yes` is closed by its merged pull request once that
handoff is implemented, so it never reaches `list-mine` again. One that carried `closes: no`
stays open and keeps its marker, and this step goes on skipping it after the run that
implemented it has finished - so an issue deliberately left open for further work is not
offered again here. Say so in Step 3 rather than treating every skip as settled scope.

**`closes` decides what an answered issue is waiting for, and this step does not assume.** Read
it off the handoff that the obsolete report answers, the same output both came out of. `yes`
leaves an issue waiting on a close that its pull request will never perform, since there is no
pull request. `no` leaves one its author meant to keep open, and calling that a close candidate
would shut a ticket on the strength of work it was never scoped for. A pointer carries no
`closes` value at all - report it unread, as below, and name the primary issue whose handoff
holds it.

Stop walking at the first candidate that survives carrying no marker at all - `has-handoff`
costs a call per issue, and the ones below the answer do not need one.

**An answered issue does not stop the walk.** It survives, and it is reported, but what it
needs is a close rather than a session's work, so keep walking past it and let the first
unmarked survivor be the answer. Stopping there would return an issue with nothing to build and
hide every workable issue beneath it, on this call and on every call until a person closes it -
one skip traded for another. Where the walk reaches the end of the list with only answered
issues to show, those are the answer, and Step 3 says what they are waiting on.

## Step 3 - Report

Name the surviving issue by number and title. List every issue skipped above it and why, so the
choice can be overruled. "Why" is what the unanswered marker sat in: a handoff of the issue's
own, or a pointer into another issue's bundle - and for a pointer, the issue it names. A skip
the report does not explain is one nobody can judge.

**Name every answered issue the walk passed**, each with the obsolete report that answered it
and the `closes` value its handoff carried, above the answer and apart from the skips. Such an
issue is not work waiting to start: an implementation run found HEAD already satisfying its
handoff, and the report holds the evidence a close would rest on. It is listed so a person can
act on it, and marked so a caller does not take it for fresh work and investigate a change
already in the tree. Under `closes: yes` what it waits on is that close; under `closes: no` its
author meant it to stay open, so report it as answered and say the close is not this handoff's
to ask for; under a pointer, report the value unread beside the primary issue it names.

When only answered issues survive, they are what this step returns, said as what each is
waiting on rather than as work. When nothing survives at all, say so and name what was skipped.
Never invent an issue, and never return one carrying a handoff or pointer that no obsolete
report answers, because the list would otherwise be empty. Add each skipped
issue's `closes` value where the marker sat in a handoff: `closes: no` leaves an issue open
after its pull request merges, so the marker there may record finished work rather than pending
work. A pointer carries no `closes` value - the marker, the primary issue's id and the locator
are the whole comment - so report that value as unread and name the primary issue whose handoff
holds it, rather than asserting one this step never saw. Either way the skipped list is what a
person picks from when the answer is none.

## Done

One issue number, or none - beside it, the answered issues the walk passed, each waiting on a
close rather than on work. Starting work on any of them, or closing one, is the caller's
decision, not this skill's.
