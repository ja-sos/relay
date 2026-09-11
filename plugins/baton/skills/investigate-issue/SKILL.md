---
name: investigate-issue
description: Use when a tracker issue needs a cause and an approach before any code is written - taking an issue off the backlog, "investigate #12", an invocation naming no issue at all, or checking whether a filed finding still holds. Verifies the finding at current HEAD, names the cause, picks an approach against the issue's constraints, records it as a handoff on the issue, and starts the implementation run the user picks.
---

# Investigate issue

Work out what is wrong behind one issue and leave the answer on the issue. Applies to an
issue describing a defect or a proposal. Does not apply to writing the fix, or to filing
a new issue - `baton:file-issue` covers filing.

Every operation named below comes from the backend. Load it, later files overriding
earlier by `##` heading:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
command -v gh >/dev/null && gh api user >/dev/null 2>&1 || cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github-mcp.md
cat .claude/baton.md 2>/dev/null
cat ~/.claude/baton.md 2>/dev/null
```

The second line loads the GitHub MCP route when `gh` is missing or cannot reach GitHub. That
file opens with the check that confirms its tools, and says when no route is left.

Two failures are stops, not fallbacks: an operation this skill names that no loaded file
defines, and an operation that fails because its tool is missing or unauthenticated - a
command exiting non-zero, or a named tool the session lacks or cannot authorize. Report
the operation name, the entry that failed, and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`. Never run a command this backend does
not define - an improvised equivalent writes to a tracker the project did not choose.

## Step 1 - Load

Without an issue number, resolve one with `baton:next-issue`, put it and everything it skipped
to the user, and wait for confirmation before going on. A resolver returning none is a stop:
an empty answer means every candidate is already scoped, not that the choice falls to you.

Run `view` against the issue. An earlier comment may already hold an investigation. Read it
before starting another.

Run `has-handoff` too. When its output carries the handoff marker, read that handoff, put it
to the user with what it already covers, and go no further without their say-so. An issue
waiting on an implementation run is settled work, and investigating it again ends in a second
plan and a second run against the same change.

Take the `Found at <sha> on <branch>` line from the body and diff the files it cites:

```
git diff --stat <sha>..HEAD -- <cited paths>
```

Every `file:line` in the body resolves against `<sha>`, not HEAD. When that diff is
non-empty, find each citation by its content and use the HEAD line number from there on.

A body carrying no `Found at` line has no anchor at all. Treat each of its citations as a
line number of unknown age and locate it by content before trusting it.

## Step 2 - Verify

Reproduce at HEAD before forming a theory of the cause.

| Outcome | Action |
|---|---|
| Reproduces | Continue to Step 3. |
| Already fixed | Name the commit that fixed it. Stop. |
| Never held | State the counter-evidence. Stop. |

On either stop, report to the user and propose closing - `close-fixed` for a fix that
landed, `close-invalid` for a finding that never held. Never close an issue without
approval.

## Step 3 - Cause

Name the cause at `file:line` at HEAD. The cause accounts for every symptom the issue
lists. One that accounts for only some means a second defect is present: report that
separately and keep it out of this investigation.

## Step 4 - Approach

Decide against the constraints the issue names. Its `Fix`, `Proposal` or `Correction`
section lists alternatives so that this step chooses between them rather than inventing a
third. Name what loses, and the constraint that rules it out.

**The issue states the target; the code states where it lands.** Step 3 names where the cause
lives, never whether a part of the issue is needed. Scope comes from the issue and what
it links, including one named as the follow-on, whose target state this one must not foreclose.

Do not propose dropping or deferring a part because nothing in the code requires it yet. Where
the work removes an arrangement, what the code needs today is a product of that arrangement. A
part that looks genuinely unnecessary gets one sentence saying so, and stays in scope.

Settle any decision the user must make here, while the code is in front of you. Stating the
question plainly is also what exposes a mis-framed one - a decision resting on a misread
comment dissolves once it is in words.

Check whether work already exists before proposing any:

```
git branch -a --list '*<n>*'
```

## Step 5 - Record

Write the handoff under `baton:write-handoff`, which posts it to this issue and takes the
body through `baton:write-deliverables`.

Its `base` is the HEAD that Step 2 reproduced against and Step 3 named the cause at, so
the plan stays falsifiable against the code it was formed on.

## Step 6 - Launch

Implementation belongs in its own session against its own checkout. Ask which of the
backend's `## Launcher` entries to use, and start only what the answer names. Report what
each would do and create nothing when the answer is none of them.

The entry carries a `<locator>` or a `<comment url>` placeholder; substitute the locator
Step 5 returned for either one. A launcher that starts with anything else starts a session
with no handoff to read.

## Done

Stop before editing any file the repo tracks.

Report the issue number, the Step 2 outcome, the cause in one line, the chosen approach
in one line, the handoff locator, and where the implementation is running.
