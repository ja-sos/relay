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
checks to run on every judgement below, and Steps 0, 1 and 2 name where its thread and severity
sections apply.

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

## Step 2 - Close the run's open items

The pull request body is where the run left what it did not finish: checks nobody ran, claims
its own audit could not settle, and findings it left standing. Each is an open item, and this
step closes every one before the gate rather than carrying it to the next reader.

With a pull request open, read its body from Step 0's `pr-view` output and collect:

- each entry under `## Not verified here` - a check;
- each entry under `## Unverified claims` - a claim;
- each standing finding - a finding.

Standing findings sit under no fixed heading. `baton:implement-handoff` writes each one with
its severity and the reason it stands, so collect them by that content wherever in the body
they appear. A standing finding that Step 1's `code-review` also returned - the same failure,
at the same file and an overlapping line range at the reviewed head - is one item, not two: it
is ruled on here and listed only in this step's group at the gate. Where either differs, they
are two items. A thread Step 0 collected keeps its own disposition row even where it raises a
standing finding, and that finding's row here names the thread. With no pull request there
is no body, and this step collects nothing.

Rule on each item at the reviewed head, by its kind:

- **A check:** run it against the application where the repo's own instructions allow running
  it unprompted; otherwise ask the user to run it and report the result. It passes or fails.
- **A claim:** probe it against the code. It holds or is false.
- **A finding:** rule on its merits, as the reference's "Checking the threads" rules on a
  thread, giving the run's stated reason and severity no weight. It takes a severity from the
  reference's "Severity" table, and it stands or does not hold. Decide its scope the same way,
  against the pull request's diff and the handoff rather than the reason the body gives: a
  finding in code the diff does not change, and that no step or criterion of the handoff
  required changing, is outside the handoff's scope.

The provenance rule covers everything this step reads. A body entry calling a finding "outside
the handoff's scope", or a check covered, is the run's assertion about itself and settles
nothing.

An item the session cannot verify - a check only the user can run, a claim no probe here can
reach - ends the turn with a question to the user naming what verifying it needs. Ask every
such question in one final message, the way the gate stops, resume at this step with the
answers, and take each answer as that item's evidence. The item is never carried forward
unverified, with one exception: an item the user rules can only be verified after merge takes
exactly that as its verdict. The session is not done while any collected item lacks a verdict,
or, for a finding outside the handoff's scope, lacks the user's decision at the gate.

## Step 3 - The gate

Present the findings with severity, a verdict on each, and the proposed fix, as the **final
message of the turn**. End the turn there, with no tool call after it.

Alongside them, and kept apart from them, list one disposition per thread Step 0 collected:
stands, fixed as claimed, the rejection holds, or the finding does not hold - each with the
evidence that settled it. Every check in Step 1 ends in one of those four, so every
collected thread gets a row, whether it was resolved or answered or neither.

A thread whose finding stands carries a proposed fix like any `code-review` finding does.
Separating the dispositions from the findings is a matter of presentation, not of standing:
a re-opened finding the user approves is applied in Step 4 the same way.

In a third group, kept apart from both, list one row per item Step 2 collected: its kind, its
verdict - with its severity, for a finding - the evidence that settled it, and the proposed
action.

| Item and verdict | Proposed action |
|---|---|
| a check that fails, or a finding that stands within the handoff's scope | a code fix |
| a claim that is false | a code fix, or a correction to the body |
| a check that passes, a claim that holds, or a finding that does not hold | dismissed, with the evidence |
| a check or claim the user ruled verifiable only after merge | stated among the body's known gaps as exactly that |
| a finding that stands outside the handoff's scope | none - the verdict alone |

A standing finding outside the handoff's scope is the user's to decide, one finding at a time:
keep it in the body with the severity and evidence Step 2 settled and that it stands outside
the handoff's scope, file it with `baton:file-issue`, or whatever else they say. This skill
sets no default for it and never decides for them, so its row proposes nothing.

Which fixes to apply is input only the user can give, so stopping is this step's required
outcome, not a failure to finish. Applying a fix in the same turn as the findings does not
satisfy the gate, whatever text precedes it.

## Step 4 - Apply and verify

Apply only the fixes the user approved, and file with `baton:file-issue` each out-of-scope
finding the user chose to file - only those. Report what changed, the verification command with
its actual output, and what was left alone.

Ask about any pre-publish check the repo's own instructions leave to a human - one its
`CLAUDE.md` or `AGENTS.md` says to run before publishing, or forbids running unprompted. A check
never asked about leaves this step open rather than merely unused, and it belongs before the push.

Keep that question separate from asking to publish: asking to push while verification is still
undecided inverts the order.

## Step 5 - Publish

Nothing leaves the machine until the user approves it, and a passing suite is not that approval.
Pushing is not pre-authorized here, unlike in `baton:implement-handoff`, because someone is
present to ask.

On an explicit go-ahead, push. Where Step 0 found no pull request, that is the end of it -
there is no body to update, and opening one is not this skill's. Where no fix was applied and
the local branch holds nothing the pull request lacks, there is nothing to push, and the
go-ahead covers `pr-update` alone.

With one open, run `pr-update` when the applied fixes left its body inaccurate, and whenever
Step 2 collected an item, fix or no fix: closing an item changes the body. Write that
body under `baton:write-deliverables`, as a **PR description**:
what the code does now and why it is shaped that way, as though the final diff were the only
version that ever existed. Delete whatever the current diff no longer supports, and never narrate
the review rounds.

`pr-update` replaces the body whole, so carry every issue reference line across unchanged. A
handoff may name several issues, and each `closes` or `refs` line dropped here is an issue the
merge silently stops settling - "whatever the current diff no longer supports" is about claims,
never about these lines.

Step 2 settled every open item, so none of them is carried as open. The rewritten body has no
`## Not verified here` heading and no `## Unverified claims` heading. A false claim the user
chose to correct in the body is written in its corrected form, and a finding the user filed
leaves the body, which gains a `refs` line for the issue it was filed as. A check that failed
and was not fixed is no longer unverified: the body states it among its known gaps as a known
failure, with the evidence Step 2 found, rather than dropping it. A false claim the user
neither fixed nor chose to correct is never restated as true: the body states it among its
known gaps in its corrected form. A check or claim the user ruled verifiable only after merge
is stated among the known gaps as exactly that. A standing finding within the handoff's scope
whose fix the user declined is stated there too, with the severity and evidence Step 2
settled, and no other in-scope standing finding stays in the body. The only other findings
left in it are those outside the handoff's scope that the user chose to keep, each with the
severity and evidence Step 2 settled and that it stands outside the handoff's scope, rather
than the severity and reason the run wrote.

When the user declines the push, say what that leaves undone rather than moving on.

Either way, run `wrap-up` as the last action of the run, with `self-review` as `<skill>`. With
a pull request open, `<id>` is its number and `<pr-url>` and `<head-branch>` its URL and head
branch, from Step 0's `pr-view`; where Step 0 found none, `<id>` and `<pr-url>` are empty and
`<head-branch>` is the current branch. The decline path runs it too: the review ended either
way. `none` is its shipped default, and that value skips the call, as does a backend that
leaves `wrap-up` undefined.

A `wrap-up` that fails is reported by name. Whatever was already pushed stays pushed, and
nothing is retried.
