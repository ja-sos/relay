---
name: address-review
description: Use when addressing code-review feedback on a pull request this side owns - "/baton:address-review", "address the review comments", "handle the PR feedback". Collects every surface feedback lands on, builds an inventory, stops for a ruling, then applies, verifies, publishes, and answers each item where it arrived.
---

# Address review

Turn review feedback on one pull request into changes and answers. Sibling to
`baton:review-pr`, which is the outbound direction: someone else's code, findings that leave
as a review.

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

## Step 1 - Resolve the target, and state it

In order:

1. A number in the request - "PR 631", "#631", "pull 631" - is the target: run `pr-view`
   with it.
2. No number: run `pr-view` with an empty `<id>` to get the pull request for the current branch.
3. Still nothing: say so and ask which one.

State the resolved target - number, author, head branch - before anything else runs against
it.

A pull request this side does not own is not this skill's. Stop and switch to
`baton:review-pr`.

Then resolve the **spec**: the issue the pull request delivers and the handoff it was built
from, where either exists, by the shared procedure:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/resolving-the-spec.md
```

Then read the specification documents the backend's `## References` section routes the spec's
issues to, by the shared procedure:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/reference-documents.md
```

The issue set is the spec's issues, each matched in its own repository with the labels and
components its `view` printed; where the spec holds no issue, it is that file's issue-less
entry. The documents read join the spec. With no section, or no matching row, the spec is
what `resolving-the-spec.md` resolved. A stop under `reference-documents.md` ends the run:
report it, then run `wrap-up` as `## Done` gives it.

State the resolved spec - each issue id, the binding handoff's locator, or the issue it
sits on where the output carries no address, and each document read by its file name - before
collecting anything. Where nothing resolves, say "no spec found" and go on: this is a statement,
not a question, and a pull request with no issue, no handoff and no document is ruled against
the code alone.

## Step 2 - Collect every surface

Run `review-bodies`, `pr-comments` and `review-threads` - all three, before evaluating
anything. Apply each entry's author filter during collection, as the backend's notes name it.

Never pre-filter on resolved state.

## Step 3 - Inventory, then stop

Build the inventory before touching code. One summary body routinely carries several distinct
asks alongside meta-requests - rebase this, split that, prefer another name. Each ask is its own
row, recorded with the surface it came from.

The inventory holds exactly the actionable candidates: every distinct ask from a person, and
every unresolved inline finding. Resolved threads are context for judging related rows, never
rows themselves, and nothing in them is owed an action or a reply.

Rule on each row against the spec first, and the code second. Within the spec the routed
documents come first, then the issue the pull request delivers and the handoff it was built
from:

- A row a document's clause settles is ruled on that clause, and its verdict quotes it by file
  name, section heading and clause.
- Where a document and the issue or the handoff disagree on a row's point, the skill does not
  settle it. The verdict quotes the clause and the passage it conflicts with, and the user rules
  at this step's stop. A handoff that disagrees with a document is itself a finding against the
  handoff, named in the verdict.

Where no document bears on a row, it is ruled against the issue and the handoff:

- A row asking to keep or restore behaviour the spec replaces is not valid, and its verdict
  quotes the passage that replaces it.
- A row its reviewer calls a product decision, or otherwise leaves open, is not open where the
  spec settles it, and its verdict quotes the passage that does.
- A row the spec says nothing on, or every row where there is no spec, is ruled against the
  code.

The code still decides whether a factual claim about current behaviour holds. Where the pull
request's body records a deviation from the issue or the handoff on a row's point, that passage
no longer settles the row, and neither does the body. Name the deviation in the verdict and rule
the row against the code. Where the body records a deviation from a document's clause, the skill
does not settle it: the verdict quotes the clause and the deviation, and the user rules at this
step's stop.

Present the inventory with a verdict on each row - valid or not, and the authority it rests
on - and the action proposed, as the **final message of the turn**. End the turn there with no
tool call after it. A message between tool calls does not satisfy this gate.

## Step 4 - Address

Judge each row's relevance against the spec, where there is one, and its correctness against
the code, and push back with technical reasoning where a suggestion is wrong. Take them one at a time, changing code first.

Verify before publishing, never after.

Ask about any pre-publish check the repo's own instructions leave to a human - one its
`CLAUDE.md` or `AGENTS.md` says to run before publishing, or forbids running unprompted. A check
never asked about leaves this step open rather than merely unused.

Keep that question separate from asking to publish.

## Step 5 - Publish, then answer

Only once verification clears and the user approves, in this order:

1. Push.
2. Run `pr-update` when the changes left the body inaccurate, carrying every issue reference
   line across unchanged (`defining-backends.md`, `pr-update`).
3. Answer every Step 3 row in the venue it arrived: an inline finding takes `thread-reply` in its
   own thread, while rows from summary bodies and conversation comments take one `pr-comment`
   covering them.

Answering an *inline* finding at top level is the failure to avoid. Feedback that arrived at top level is answered where it
arrived.

Write the pull request body and every reply under `baton:write-deliverables`, the body as a
**PR description** describing the branch as it now stands rather than the rounds it went through.

## Done

Every inventory row is answered or declined with its reasoning. Report what changed, what was
pushed back on, and anything still open.

Then run `wrap-up` as the last action of the run, with `address-review` as `<skill>`, the pull
request number as `<id>`, and its URL and head branch as `<pr-url>` and `<head-branch>`, from
Step 1's `pr-view`.

Run it where the user declines the push, too. An undefined `wrap-up` reads as `none`, and a
failed one is reported by name and not retried (`defining-backends.md`, `wrap-up`).
