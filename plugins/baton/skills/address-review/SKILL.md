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
cat .claude/baton.md 2>/dev/null
cat ~/.claude/baton.md 2>/dev/null
```

Two failures are stops, not fallbacks: an operation this skill names that no loaded file
defines, and an operation that fails because its tool is missing or unauthenticated - a
command exiting non-zero, or a named tool the session lacks or cannot authorize. Report
the operation name, the entry that failed, and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`. Never run a command this backend does
not define - an improvised equivalent writes to a tracker the project did not choose.

## Step 1 - Resolve the target, and state it

In order:

1. A number in the request - "PR 631", "#631", "pull 631" - is the target: run `pr-view`
   with it.
2. No number: run `pr-view` with an empty `<id>` to get the pull request for the current branch.
3. Still nothing: say so and ask which one.

State the resolved target - number, author, head branch - before anything else runs against
it, so the user can correct it before the work is done rather than after.

A pull request this side does not own is not this skill's. Stop and switch to
`baton:review-pr`: someone else's code takes comments, not commits.

Then resolve the **spec**: the issue the pull request delivers and the handoff it was built
from, where either exists. A review row asking for behaviour the pull request was opened to
replace finds that behaviour still in the code wherever the change has not reached yet, so the
code argues for the row; the spec is what says it was replaced. In order:

1. **The issues.** Run `pr-issues` on the pull request. It returns each issue the pull request
   names, with its repository, and whether the pull request delivers it or only references
   it; how a pull request names its issues is the backend's to define (`defining-backends.md`).
   Under `none` no issue is found. Run `view` on each issue returned, in the repository it
   came with.
2. **The handoff.** Run `has-handoff` on each issue found; where it resolves to `op: view`, the
   `view` output already read answers it. Read no issue twice. Follow every pointer its output
   carries - the marker with no fenced header - by running `fetch-handoff` on the locator the
   pointer carries, and add the issue the pointer names to the issues found, running `view`
   and `has-handoff` on it as on any other. An issue can carry a pointer and a handoff of its
   own; collect both. Of the handoffs collected, the binding one is the handoff whose header
   `branch` line equals the pull request's head branch, or, failing that, the head branch
   with a trailing `-<6 hex>` removed - the name `implement-handoff` substitutes where the
   handoff's branch already existed. Where several match on one issue, the one appearing last
   in `has-handoff`'s output binds: rework is posted as a second handoff rather than an edit
   to the first. Where the matches sit on different issues, bind none: no order across issues
   is defined. Where none matches and exactly one handoff was collected, it binds, unless it
   was reached only through an issue the pull request references rather than delivers.
   Otherwise bind none, and name every handoff collected in the statement below.
3. **What counts.** Where a handoff binds, the spec is that handoff and the issues its header
   `issue` line names; run `view` on any of those not yet read, in the repository the handoff
   was posted in. Any other issue found is context, named in the statement as not spec: a
   follow-up `baton:self-review` filed from a finding is one the pull request references too.
   Where none binds, the spec is the issues the pull request delivers, or the ones it only
   references where it delivers none.

A `view` or `fetch-handoff` answering not-found - an issue that does not exist, a handoff since
deleted - is that candidate's answer, not a backend failure: drop the candidate, name it in the
statement, and go on. Any other failure, an access denial included, falls under the stop rule
above. A backend can answer not-found for an issue the session cannot read, so the statement
names a dropped issue as not found or not readable with this session's credentials.
`has-handoff` can miss a handoff that has been delivered; an issue is a spec on its own.

State the resolved spec - each issue id, and the binding handoff's locator, or the issue it
sits on where the output carries no address - before collecting anything, so the user can
correct it too. Where nothing resolves, say "no spec found" and go on: this is a statement,
not a question, and a pull request with no issue and no handoff is ruled against the code
alone.

## Step 2 - Collect every surface

Run `review-bodies`, `pr-comments` and `review-threads` - all three, before evaluating
anything. Apply each entry's author filter during collection, as the backend's notes name it.

Never pre-filter on resolved state.

## Step 3 - Inventory, then stop

Build the inventory before touching code. One summary body routinely carries several distinct
asks alongside meta-requests - rebase this, split that, prefer another name. Each ask is its own
row, recorded with the surface it came from, so its answer later lands in the right venue.

The inventory holds exactly the actionable candidates: every distinct ask from a person, and
every unresolved inline finding. Resolved threads are context for judging related rows, never
rows themselves, and nothing in them is owed an action or a reply.

Rule on each row against the spec - the issue the pull request delivers and the handoff it
was built from - first, and the code second:

- A row asking to keep or restore behaviour the spec replaces is not valid, and its verdict
  quotes the passage that replaces it.
- A row its reviewer calls a product decision, or otherwise leaves open, is not open where the
  spec settles it, and its verdict quotes the passage that does.
- A row the spec says nothing on, or every row where there is no spec, is ruled against the
  code.

The code still decides whether a factual claim about current behaviour holds: the spec says
what the pull request is for, not what the code does. Where the pull request's body records a
deviation from the spec on a row's point, the spec's passage there no longer settles the row,
and neither does the body: it is written by the side under review. Name the deviation in the
verdict and rule the row against the code.

Present the inventory with a verdict on each row - valid or not, and the authority it rests
on - and the action proposed, as the **final message of the turn**. End the turn there with no
tool call after it. The ruling is input only the user can give. A message between tool calls does not
satisfy this gate, because mid-turn text may never be shown to them at all.

## Step 4 - Address

Judge each row's relevance against the spec, where there is one, and its correctness against
the code, and push back with technical reasoning where a suggestion is wrong. Performative
agreement helps nobody. Take them one at a time, changing code first.

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
2. Run `pr-update` when the changes left the body inaccurate, carrying every issue reference
   line across unchanged (`defining-backends.md`, `pr-update`).
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

Then run `wrap-up` as the last action of the run, with `address-review` as `<skill>`, the pull
request number as `<id>`, and its URL and head branch as `<pr-url>` and `<head-branch>`, from
Step 1's `pr-view`.

Run it where the user declines the push, too. An undefined `wrap-up` reads as `none`, and a
failed one is reported by name and not retried (`defining-backends.md`, `wrap-up`).
