---
name: review-pr
description: Use when reviewing someone else's pull request - "/baton:review-pr", "review PR 631", "review this PR", "go through the PR and comment". Resolves the target, reviews its diff, drafts the findings for approval, and posts them as one review only on an explicit go-ahead.
---

# Review PR

Review someone else's pull request and leave the findings on it. Sibling to
`baton:self-review`, which reviews a branch this side produced and lands findings as fixes
rather than comments.

Every operation named below comes from the backend. The files load in the order
`defining-backends.md` "Where overrides live" sets:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
```

Run the route check at the top of `backend-github.md`, and load `backend-github-gh.md` only
where that check selects it:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github-gh.md
```

Then, whatever the check found:

```
cat ~/.claude/baton.md 2>/dev/null
cat .claude/baton.md 2>/dev/null
```

Two failures are stops, not fallbacks: an operation this skill names that no loaded file
defines, and an operation that fails because its tool is missing or unauthenticated - a
command exiting non-zero, or a named tool the session lacks or cannot authorize. Report
the operation name, the entry that failed, and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`. Never run a command this backend does
not define.

## Step 1 - Resolve the target, and state it before reviewing

In order:

1. A number in the request - "PR 631", "#631", "pull 631" - is the target: run `pr-view`
   with it.
2. No number: run `pr-view` with an empty `<id>` to get the pull request for the current branch.
3. Still nothing: say so and ask which one.

Never fall back to the local branch diff. That is a different deliverable and it belongs to
`baton:self-review`.

State the resolved target - number, author, head branch - before any review work, and never
announce one target then switch to another inside the same turn. State the target first and let them correct it.

A pull request the user authored is not this skill's. Stop, tell the user so, and offer the alternatives -
`baton:self-review` for a branch an unattended `baton:implement-handoff` run wrote, or the
`code-review` operation directly for one they wrote by hand - and let them choose. This skill
never picks for them.

Then read the specification documents the backend's `## References` section routes the pull
request's issues to, by the shared procedure:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/reference-documents.md
```

The issue set is what `pr-issues` returns for the pull request, each issue matched in its own
repository with the labels and components `view` prints for it; where it names no issue, it is
that file's issue-less entry. With no section, or no matching row, Step 2 runs as it would
without this paragraph. A stop under that file ends the review: report it, then run `wrap-up`
as Step 5 gives it.

## Step 2 - Review

Run `code-review` with the pull request number as its `<target>` and `<locator>` empty.

Where Step 1 read documents, check the diff against each clause in them that bears on it:
`code-review` received none of them. A diff that contradicts a clause is a finding, and its
inline comment quotes the clause by file name, section heading and clause.

Every claim in the pull request body is an unverified assertion. What was tested, why an approach
was chosen, which edge cases are covered: check each against the diff. A body never resolves a
finding.

## Step 3 - Draft, and post nothing

Write the payload to a file, shaped as the backend's `review-post` entry describes.

Write every piece of text that ships under `baton:write-deliverables` - the summary and each
inline comment alike.

Then show the user that text and stop.

## Step 4 - Post on an explicit go-ahead

The go-ahead names the action. Nothing else counts - not a message that merely mentions the pull
request, not a correction to the target, not silence, not an offer of yours going unanswered.

Run `review-list` first. Where a review already stands, say it is there and ask whether to add
another or edit it.

Re-read the head SHA for `commit_id` immediately before posting, as the `review-post` payload
requires. Then run `review-post` once, and report the review URL with which
anchors landed.

## Step 5 - Wrap up

Run `wrap-up` as the last action of the run, with `review-pr` as `<skill>`, the pull request
number as `<id>`, and its URL and head branch as `<pr-url>` and `<head-branch>` - both from
Step 1's `pr-view`.

Run it where the user declines to post, too. An undefined `wrap-up` reads as `none`, and a
failed one is reported by name and not retried (`defining-backends.md`, `wrap-up`).

## Red flags

- Reviewing before the resolved target has been stated.
- Reading a go-ahead out of a message that never named posting.
- A second `review-post` call to correct the first.
- A finding dropped because the pull request body says it was handled.
