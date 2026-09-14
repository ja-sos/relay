---
name: review-pr
description: Use when reviewing someone else's pull request - "/baton:review-pr", "review PR 631", "review this PR", "go through the PR and comment". Resolves the target, reviews its diff, drafts the findings for approval, and posts them as one review only on an explicit go-ahead.
---

# Review PR

Review someone else's pull request and leave the findings on it. Sibling to
`baton:self-review`, which reviews a branch this side produced and lands findings as fixes
rather than comments.

Every operation named below comes from the backend. Load it, later files overriding earlier by
`##` heading:

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

## Step 1 - Resolve the target, and state it before reviewing

In order:

1. A number in the request - "PR 631", "#631", "pull 631" - is the target.
2. No number: run `pr-view` with an empty `<id>` to get the pull request for the current branch.
3. Still nothing: say so and ask which one.

Never fall back to the local branch diff. That is a different deliverable and it belongs to
`baton:self-review`.

State the resolved target - number, author, head branch - before any review work, and never
announce one target then switch to another inside the same turn. The user cannot see when a
message was composed: an answer that looks like it addresses your latest question may have been
typed before that question existed. State the target first and let them correct it.

A pull request the user authored is not this skill's. Stop and switch to `baton:self-review`:
reviewing your own side's work means applying fixes, not commenting on them.

## Step 2 - Review

Run `code-review` with the pull request number as its `<target>`, so the diff comes from the
forge rather than local git - the branch may be unchecked-out, behind, or on a fork.

Every claim in the pull request body is an unverified assertion. What was tested, why an approach
was chosen, which edge cases are covered: check each against the diff. A body never resolves a
finding.

## Step 3 - Draft, and post nothing

Write the payload to a file, shaped as the backend's `review-post` entry describes: the summary
and one entry per finding with its path and line.

Write every piece of text that ships under `baton:write-deliverables` - the summary and each
inline comment alike.

Then show the user that text and stop. Findings are this step's deliverable; posting is a
separate decision and it is theirs.

## Step 4 - Post on an explicit go-ahead

The go-ahead names the action. Nothing else counts - not a message that merely mentions the pull
request, not a correction to the target, not silence, not an offer of yours going unanswered.

Run `review-list` first. A review already standing is not replaced by a second one, so say it is
there and ask whether to add another or edit it.

Re-read the head SHA immediately before posting: a push since Step 1 invalidates every anchor
built against the older one. Then run `review-post` once, and report the review URL with which
anchors landed.

## Red flags

- Reviewing before the resolved target has been stated.
- Reading a go-ahead out of a message that never named posting.
- A second `review-post` call to correct the first.
- A finding dropped because the pull request body says it was handled.
