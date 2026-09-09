---
name: write-handoff
description: Use when work has to continue in a session that does not share this context - launching an implementation run in the cloud or in the background, stopping mid-task, or handing work to another person. Posts the handoff to the issue driving the work, and writes the body under write-deliverables.
---

# Write handoff

Record one unit of ready work on the issue driving it, written to the **Handoff /
context note** contract. Applies when the next session starts cold, on a machine that
need not be this one. Does not apply to a document belonging in the repo, or to an issue
body - `baton:file-issue` covers issues.

Every operation named below comes from the backend. Load it, later files overriding
earlier by `##` heading:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
cat .claude/baton.md 2>/dev/null
cat ~/.claude/baton.md 2>/dev/null
```

## Step 1 - Place

The handoff is one comment on the issue, posted with `comment` once Step 3 has written the
body. It opens with the marker and heading, so that a session finds it and everyone else on
the issue reads it as a work order rather than a decision the project has taken:

```
<!-- claude-handoff -->
## Implementation handoff

*What one implementation run will attempt.*
```

Work no issue drives has nowhere to anchor. A session on another machine reaches the
tracker and nothing else - no file of this machine's, and no path that resolves. Open the
issue first; `baton:file-issue` covers that.

Post a second comment for rework rather than editing the first, which alone carries the
approach that failed and the constraint that ruled the alternatives out.

## Step 2 - Header

Below the heading, five lines inside a fenced block - a tracker renders consecutive lines
as one paragraph, so an unfenced header arrives as prose:

```
repo:   <owner>/<name>
base:   <sha the plan was formed against>
issue:  <number>
closes: <yes, or no>
branch: <branch the work belongs on>
```

`base` must already be on `origin`, because a session that clones never sees a commit
held only here:

```
git branch -r --contains <sha>
```

Empty output is a stop: push first, or record a `base` that is pushed.

`closes` is `yes` on the handoff that finishes the issue and `no` on every other, so the
issue is not marked done while work on it remains. `no` is the safe value whenever the
split is unsettled.

## Step 3 - Body

Write the body under `baton:write-deliverables`, as a **Handoff / context note**.

A handoff that asks its reader to decide something does not ship. The session reading it has
no one to ask, so a banked question stalls that run and returns the decision to the user
anyway - later, and with the work halted. Settle it before posting and fold the answer in.
Record only what cannot be settled until implementation is under way.

Name nothing that exists only on this machine. Cite code as repo-relative `file:line`; an
absolute path, a home directory or a hostname resolves to nothing in the session that
reads it.

## Done

Print the locator `comment` returns, which addresses this comment rather than the issue.

An issue splits into several handoffs whenever its fix lands as more than one change, so
the issue number addresses none of them and whatever launches the work takes the locator.

Starting that work is the caller's decision, not this skill's.
