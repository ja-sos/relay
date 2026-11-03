# Fixing check failures

`implement-handoff` and `review-handoff` load this file before Step 1. It governs what a run
does when one of its check sequences fails: fix the failure, re-run the sequence, and stop only
where this file says.

## The check sequences

Each sequence restarts from its own first step:

| Site | The sequence, in order | Restarts from |
|---|---|---|
| `review-handoff` loop item 2 | the handoff's commands | the handoff's first command |
| `review-handoff` Step 4 | `verify`, commit any file it rewrote, then the handoff's commands | `verify` |
| `implement-handoff` Step 3 | the handoff's commands, then `verify` | the handoff's first command |

## The bound

A failing sequence gets **3 fix attempts each time it runs**. One attempt is one fix plus one
re-run of the whole sequence from its first step - never from the step that failed, so a
sequence that rewrites files sees every fix before its checks do. Where the third re-run fails,
the run stops.

The count starts again each time the site runs: each round of `review-handoff`'s loop reaches
item 2 with 3 attempts of its own.

## The stops

These hold whatever attempts remain. Each is a stop at the site, under the skill's own
Stopping section:

1. A failure reported in a file outside the branch's diff.
2. A fix that would edit a file outside the branch's diff.
3. A fix that would edit a failing test's assertions to match the code. That holds for a test
   this run wrote as much as for one already on the branch: a test `implement-handoff` wrote
   in Step 3 failing on its own assertion is a stop.
4. A failure for which the run finds no fix within those limits.

## The branch's diff

The file list these commands print together, run in the worktree:

```
git diff --name-only <branch point>
git ls-files --others --exclude-standard
```

`<branch point>` is the header's `base`, or `origin/<pr-base>` where the header carries
`pr-base`. In `review-handoff` this set covers the pull request's own changes and the review's
fixes alike.

## Where each site's fixes go

- **`review-handoff` loop item 2:** uncommitted, with the round's other fixes. Item 3 or item 4
  commits them with the rest.
- **`review-handoff` Step 4:** committed on the review branch before each re-run, since the
  sequence runs with nothing uncommitted.
- **`implement-handoff` Step 3:** uncommitted until both checks pass.

## What the run records

For each attempt, keep three things for the Run report, or for the Stopping file where the run
stops:

- the check that failed;
- the failure's first error line;
- the files the fix edited.

## Review status of a fix

- **`review-handoff`:** a fix made at loop item 2 of a round that goes on to item 4 counts as
  reviewed, since item 4 reviews the uncommitted tree that holds it. The Run report marks as
  unreviewed the check fixes no later round covered: every fix Step 4 made, and every fix item
  2 made in the round that ended the loop.
- **`implement-handoff`:** marks none of its check fixes unreviewed. Its Run report still names
  each failure and the fix applied for it.
