---
name: address-review
description: Use when addressing code-review feedback on a pull request this side owns - "/baton:address-review", "address the review comments", "handle the PR feedback". Collects every surface feedback lands on, builds an inventory, stops for a ruling, then applies, verifies, publishes, and answers each item where it arrived.
---

# Address review

Turn review feedback on one pull request into changes and answers. Sibling to
`baton:review-pr`, which is the outbound direction: someone else's code, findings that leave
as a review.

Every operation named below comes from the backend. Load it, later files overriding earlier by
`##` heading:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
cat .claude/baton.md 2>/dev/null
cat ~/.claude/baton.md 2>/dev/null
```

Two failures are stops, not fallbacks: an operation this skill names that no loaded file
defines, and an operation whose command exits non-zero because its tool is missing or
unauthenticated. Report the operation name, the command, and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`. Never run a command this backend does
not define - an improvised equivalent writes to a tracker the project did not choose.

## Step 1 - Resolve the target, and state it

In order:

1. A number in the request - "PR 631", "#631", "pull 631" - is the target.
2. No number: run `pr-view` with an empty `<id>` to get the pull request for the current branch.
3. Still nothing: say so and ask which one.

State the resolved target - number, author, head branch - before collecting anything, so the
user can correct it before the work is done rather than after.

A pull request this side does not own is not this skill's. Stop and switch to
`baton:review-pr`: someone else's code takes comments, not commits.

## Step 2 - Collect every surface

Run `review-bodies`, `pr-comments` and `review-threads`. All three, before evaluating anything:
each reads a surface the others cannot see, and two of them are invisible to the endpoint that
returns inline comments.

Run them as the backend defines them. Their author filters are part of collection, not a step to
defer and redo later.

Never pre-filter on resolved state. It exists on `review-threads` alone, so an unresolved-only
query drops the other two surfaces wholesale rather than narrowing them.

## Step 3 - Inventory, then stop

Build the inventory before touching code. One summary body routinely carries several distinct
asks alongside meta-requests - rebase this, split that, prefer another name. Each ask is its own
row, recorded with the surface it came from, so its answer later lands in the right venue.

The inventory holds exactly the actionable candidates: every distinct ask from a person, and
every unresolved inline finding. Resolved threads are context for judging related rows, never
rows themselves, and nothing in them is owed an action or a reply.

Present the inventory with a verdict on each row - valid or not, verified against the code - and
the action proposed, as the **final message of the turn**. End the turn there with no tool call
after it. The ruling is input only the user can give. A message between tool calls does not
satisfy this gate, because mid-turn text may never be shown to them at all.

## Step 4 - Address

Check each row against the code for correctness and relevance, and push back with technical
reasoning where a suggestion is wrong. Performative agreement helps nobody. Take them one at a
time, changing code first.

Verify before publishing, never after: verification is worth running only while what it finds is
still cheap to fix.

Ask about any pre-publish check the repo's own instructions leave to a human - one its
`CLAUDE.md` or `AGENTS.md` says to run before publishing, or forbids running unprompted. A check
never asked about leaves this step open rather than merely unused.

Keep that question separate from asking to publish: asking to push while verification is still
undecided inverts the order.

## Step 5 - Publish, then answer

Only once verification clears and the user approves, in this order:

1. Push.
2. Run `pr-update` when the changes left the body inaccurate.
3. Answer every Step 3 row in the venue it arrived: an inline finding takes `thread-reply` in its
   own thread, while rows from summary bodies and conversation comments take one `pr-comment`
   covering them, there being no thread to reply into.

Answering an *inline* finding at top level is the failure to avoid - its thread stays open and
the reviewer never sees the answer. Feedback that arrived at top level is answered where it
arrived.

Write the pull request body and every reply under `baton:write-deliverables`, the body as a
**PR description** describing the branch as it now stands rather than the rounds it went through.

## Done

Every inventory row is answered or declined with its reasoning. Report what changed, what was
pushed back on, and anything still open.
