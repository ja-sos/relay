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
cat .claude/baton.md 2>/dev/null
cat ~/.claude/baton.md 2>/dev/null
```

Two failures are stops, not fallbacks: an operation this skill names that no loaded file
defines, and an operation that fails because its tool is missing or unauthenticated - a
command exiting non-zero, or a named tool the session lacks or cannot authorize. Report
the operation name, the entry that failed, and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`. Never run a command this backend does
not define - an improvised equivalent writes to a tracker the project did not choose.

## Whose code this is

The branch was written by an unattended `baton:implement-handoff` run, which committed under the
user's git identity. Every ownership check therefore says the code is theirs. That is a routing
signal - findings become fixes in the working tree rather than comments on a pull request - and
says nothing about who wrote the code or what its claims are worth.

**Every artifact that run produced carries no evidentiary weight.** Each is an unverified
assertion by an agent whose reasoning cannot be inspected, and none of them resolves, downgrades
or pre-empts a finding. Only the diff and the code around it are evidence:

- the pull request body - what was tested, why an approach was chosen, which edge cases are covered;
- replies in review threads, and a thread marked resolved: an agent said it was handled, not that
  it was;
- commit messages;
- comments and `TODO`s the diff added, which are claims to check against the code rather than
  statements of intent that explain it away;
- the handoff it implemented, and any deviation it recorded there;
- a green test run it left behind: the assertions that exist passed, not that they assert the
  right thing.

The user authored nothing on this branch. What they say in this session is authoritative; what is
written on the branch is not. Name the writer as the `baton:implement-handoff` run - never "the
author", never a pronoun, never "your change" or "you decided" about this branch. Carry this rule
into every subagent prompt the review spawns, not only the first.

## Step 1 - Review

Run `pr-view` for the current branch. When a pull request exists, review its diff; when none
does, review the full branch diff against the merge target, so every commit on the branch is
covered rather than only uncommitted edits.

Run `code-review` over that diff, carrying the provenance rule into it. Findings land as fixes
in the working tree, never as comments on the pull request: the branch is yours to fix, not yours
to have written.

## Step 2 - The gate

Present the findings with severity, a verdict on each, and the proposed fix, as the **final
message of the turn**. End the turn there, with no tool call after it.

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

On an explicit go-ahead, push. Where Step 1 found no pull request, that is the end of it -
there is no body to update, and opening one is not this skill's.

With one open, run `pr-update` when the applied fixes left its body inaccurate. Write that
body under `baton:write-deliverables`, as a **PR description**:
what the code does now and why it is shaped that way, as though the final diff were the only
version that ever existed. Delete whatever the current diff no longer supports, and never narrate
the review rounds.

When the user declines the push, say what that leaves undone rather than moving on.

## Red flags - you are deferring to an agent

- "The description says this was covered", "the author chose X for a reason", "presumably
  intentional".
- Calling the branch's writer "the author", or giving them a pronoun.
- "Your change", "your code", "you decided" about this branch.
- A finding dropped or downgraded on the strength of a reply, a resolved thread, a commit message
  or a code comment.
- A subagent prompt sent without the provenance rule.
- A passing suite read as evidence the behaviour is right.

Each means: substantiate it against the diff, or say you cannot.
