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

## Step 1 - Place

The handoff is one record against the issue, posted with `post-handoff` once Steps 2-4 have
written it - a comment by default, and whatever the backend says otherwise. The marker is
what `has-handoff` finds. The update follows it, and the handoff sits collapsed beneath,
labelled as a work order rather than a decision the project has taken:

````
<!-- claude-handoff -->
## Investigation

<update - Step 4>

<details>
<summary>Implementation handoff - what one implementation run will attempt</summary>

```
<header - Step 2>
```

<body - Step 3>

</details>
````

Keep the blank lines inside `<details>` as shown. Without the one after `<summary>`, GitHub
renders the fenced header as literal backticks.

Work no issue drives has nowhere to anchor. A session on another machine reaches the
tracker and nothing else - no file of this machine's, and no path that resolves. Open the
issue first; `baton:file-issue` covers that.

Post a second handoff for rework rather than editing the first, which alone carries the
approach that failed and the constraint that ruled the alternatives out.

## Step 2 - Header

First inside the collapsed section, five lines in a fenced block - a tracker renders
consecutive lines as one paragraph, so an unfenced header arrives as prose:

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

The body ends with acceptance criteria: a numbered list of what the finished change must
show, each row checkable against the diff by someone who was not here. "Step 4 stops after
three review rounds" is checkable; "the review is thorough" is not. Cover every part of the
approach, since a part no row names is a part nothing checks.

Who reads them, and how far that goes. `implement-handoff` Step 4 classes a review finding
that contradicts one of these rows as Critical rather than a remark, so a row here changes what
that run must fix before it publishes. Nothing in the shipped backend walks the list row by row
against the diff: `implement-handoff` Step 4 passes this handoff's locator to `code-review`,
and only a backend that has paired that operation with an `agent:` compliance reviewer gets
that check. Write them for the person reviewing the pull request either way - they are the list
that reviewer ticks off, and a row only a machine could settle helps nobody.

## Step 4 - Update

Write the update under `baton:write-deliverables` as a separate document.
Its reader is the issue's participants, not the implementation run. It carries the cause, the
approach chosen and what it rules out, and the next step.

Every claim in the update is one the handoff also makes. `fetch-handoff` returns the whole
comment, so the run reads the update too, and a claim found only there reaches the run
without the handoff's reasoning.

## Done

Print the locator `post-handoff` returns, which addresses this handoff rather than the
issue. Print it as it came back, unparsed: only the backend's own `fetch-handoff` has to
understand its shape.

An issue splits into several handoffs whenever its fix lands as more than one change, so
the issue number addresses none of them and whatever launches the work takes the locator.

Starting that work is the caller's decision, not this skill's.
