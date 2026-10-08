---
name: self-review
description: Use when reviewing the branch an unattended implement-handoff run produced, before anyone else is asked to look at it - "/baton:self-review", "review the handoff branch", "check the work before I push". Reviews on the premise that everything the run wrote is an unverified claim, applies only the fixes the user approves, and publishes nothing without a separate go-ahead.
---

# Self review

Review a branch an unattended run produced, before it reaches another person. Applies when
`baton:implement-handoff` wrote the branch. A branch a person wrote goes to the review
engine directly - the premise here is that every artifact on the branch is agent output.

Every operation named below comes from the backend. Load it, later files overriding earlier by
`##` heading:

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

## The rules for run output

Read the shared rules for a branch an unattended run wrote before anything else, and keep them
for the whole review:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/reviewing-run-output.md
```

Its provenance section, on whose code this is, holds from here on, its "Red flags" are the
checks to run on every judgement below, and Steps 0 and 1 name where its other two sections
apply.

## Step 0 - Collect the review threads

Run `pr-view` for the current branch, and compare the pull request's head commit with
`git rev-parse HEAD`:

- Equal: the target is the pull request's diff.
- Different: one side holds commits the other lacks, and either target misses them. Report
  both commits and ask which to review before running anything.
- No pull request: the target is the full branch diff against the merge target, so every
  commit on the branch is covered rather than only uncommitted edits.

With a pull request settled, collect its threads as the reference's "Collecting the review
threads" says. Where there is no pull request, or it carries no threads, this step collects
nothing and Step 1 reviews the target above alone.

## Step 1 - Review

Run `code-review` over the target Step 0 settled, with the pull request number as its
`<target>` - or the branch name for the local branch - and `<locator>` empty, this skill
taking a branch rather than a handoff. Carry the provenance rule into it. Findings land
as fixes in the working tree, never as comments on the pull request: the branch is yours to
fix, not yours to have written.

Once it returns, check each thread Step 0 collected as the reference's "Checking the threads"
says.

## Step 2 - The gate

Present the findings with severity, a verdict on each, and the proposed fix, as the **final
message of the turn**. End the turn there, with no tool call after it.

Alongside them, and kept apart from them, list one disposition per thread Step 0 collected:
stands, fixed as claimed, the rejection holds, or the finding does not hold - each with the
evidence that settled it. Every check in Step 1 ends in one of those four, so every
collected thread gets a row, whether it was resolved or answered or neither.

A thread whose finding stands carries a proposed fix like any `code-review` finding does.
Separating the dispositions from the findings is a matter of presentation, not of standing:
a re-opened finding the user approves is applied in Step 3 the same way.

Which fixes to apply is input only the user can give, so stopping is this step's required
outcome, not a failure to finish. Applying a fix in the same turn as the findings does not
satisfy the gate, whatever text precedes it.

## Step 3 - Apply and verify

Apply only the fixes the user approved. Report what changed, the verification command with its
actual output, and what was left alone.

Ask about any pre-publish check the repo's own instructions leave to a human - one its
`CLAUDE.md` or `AGENTS.md` says to run before publishing, or forbids running unprompted. A check
never asked about leaves this step open rather than merely unused, and it belongs before the push.

Keep that question separate from asking to publish: asking to push while verification is still
undecided inverts the order.

## Step 4 - Publish

Nothing leaves the machine until the user approves it, and a passing suite is not that approval.
Pushing is not pre-authorized here, unlike in `baton:implement-handoff`, because someone is
present to ask.

On an explicit go-ahead, push. Where Step 0 found no pull request, that is the end of it -
there is no body to update, and opening one is not this skill's.

With one open, run `pr-update` when the applied fixes left its body inaccurate. Write that
body under `baton:write-deliverables`, as a **PR description**:
what the code does now and why it is shaped that way, as though the final diff were the only
version that ever existed. Delete whatever the current diff no longer supports, and never narrate
the review rounds.

`pr-update` replaces the body whole, so carry every issue reference line across unchanged. A
handoff may name several issues, and each `closes` or `refs` line dropped here is an issue the
merge silently stops settling - "whatever the current diff no longer supports" is about claims,
never about these lines.

Carry the `## Not verified here` and `## Unverified claims` headings across the same way. Their
entries are checks and claims the diff cannot support by definition, so the deletion rule above
never reaches them. An entry leaves only where this session verified it, and a heading leaves
with its last entry.

When the user declines the push, say what that leaves undone rather than moving on.

Either way, run `wrap-up` as the last action of the run, with `self-review` as `<skill>`. With
a pull request open, `<id>` is its number and `<pr-url>` and `<head-branch>` its URL and head
branch, from Step 0's `pr-view`; where Step 0 found none, `<id>` and `<pr-url>` are empty and
`<head-branch>` is the current branch. The decline path runs it too: the review ended either
way. `none` is its shipped default, and that value skips the call, as does a backend that
leaves `wrap-up` undefined.

A `wrap-up` that fails is reported by name. Whatever was already pushed stays pushed, and
nothing is retried.
