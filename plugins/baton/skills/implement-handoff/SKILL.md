---
name: implement-handoff
description: Use when a handoff describes work that is ready to build - launched as "/baton:implement-handoff <handoff locator>", usually by a session that investigate-issue started. Turns one handoff into a reviewed pull request and runs unattended.
---

# Implement handoff

Turn one handoff into a reviewed pull request. The argument is the handoff locator, in
whatever shape this backend's `post-handoff` returns; everything else comes from the
handoff `fetch-handoff` resolves it to.

Nobody is watching. Ask no questions - `AskUserQuestion` has no one to answer it, and a
session waiting on input makes no progress. Nothing reaches the user except the pull
request or a stop.

Every operation named below comes from the backend. Load it, later files overriding
earlier by `##` heading:

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

## Where the opening turn came from

A launcher usually starts this session, so the opening turn is often machine-generated even
though the harness presents it exactly like a developer's own words. Only the handoff locator
in it binds. Anything else it carries has the authority of the handoff section it was copied
from, and an optional section stays optional however the turn phrases it.

The session that wrote the handoff read this repo from elsewhere and ran none of its tests, so
on a question of code fact the working tree outranks the plan. Where the two disagree, the code
decides: re-cut the approach against what the tree shows and carry on.

## What this run may do unasked

Invoking this skill is the request to commit and publish, so the standing rule against pushing
unasked does not cover the run. These need no confirmation:

- `git add`, `git commit` and `git push -u origin <branch>` on the branch the handoff names.
- `pr-create` on that branch, and `request-reviewer`, `published` and `stopped` on what
  each one addresses.
- Deviating from the handoff's approach where the code contradicts it, so long as Step 5's
  body names the deviation.

Everything else is a stop rather than a judgement call, because an unattended run cannot obtain
the ask that would authorize it:

- Force-push, in any form.
- Pushing to the default branch, or to any branch the handoff does not name.
- Merging the pull request, marking a draft ready, or adding a reviewer beyond what
  `request-reviewer` names. That operation is the project's standing answer to who reviews
  this, given ahead of the run, so Step 6 runs it without asking.

Those are actions. A judgement this run can make on the evidence - which approach the
code supports, whether a review finding holds - is one it must make rather than end the turn
over.

This clears the policy, not the harness: a repo whose permission list omits a command still
prompts for it.

## Step 1 - Load

Run `fetch-handoff` on the locator. Its header gives `repo`, `base`, `issue`, `closes`
and `branch`. Verify the checkout before the first edit:

```
git cat-file -e <base>^{commit} 2>/dev/null || git fetch origin
git merge-base --is-ancestor <base> HEAD
```

Run `verify-checkout`; its answer must equal the header's `repo`. A repo that does not
match, or a `base` that is not an ancestor of HEAD, is a stop: the plan addresses code
this clone does not contain.

Check reachability with `reachable` when a tracker call fails; it separates a credential error
from an undefined operation. A credential error is the session, not the plan, and the backend
records what each one means.

## Step 2 - Branch and build

```
git switch -c <branch> <base>
```

Continue when HEAD is already on `<branch>`. Follow the approach the handoff records.
Constraints written beside the alternatives it lists already rule those out.

An approach that does not survive contact with the code is yours to re-cut. A pull request
naming its deviation is worth more than a stop naming the problem: the deviation gets
reviewed, the stop waits for someone to look. Record what changed and the evidence that
forced it, for the Step 5 body.

## Step 3 - Test

Add tests that fail against `<base>` and pass against the change. Follow the conventions
of the tests already in the repo. Run the repo's full test command; a red suite is a
stop.

## Step 4 - Review

Run `code-review` with an empty `<target>`, so it reviews the working tree this run wrote.
Apply what it finds, and run the tests again afterwards.

## Step 5 - Pull request

```
git push -u origin <branch>
```

Write the body under `baton:write-deliverables`, as a **PR description**, to a file in
the scratchpad directory. Run `pr-create` with that file.

The issue reference comes from the header, because a merged `closes` shuts an issue
whatever else is outstanding:

| Header | Reference in the body |
|---|---|
| `closes: yes` | the backend's `closes` line |
| `closes: no` | the backend's `refs` line |

Keep what `pr-create` returns. Step 6 addresses the pull request by it and Step 7 reports
it, and nothing else in the run recovers it.

## Step 6 - Review round

Skip this step when `request-reviewer` is `none`, which is the shipped default.

The wait runs `review-list` as a shell command, so the round needs it to be a shell entry.
When it is a `tool:` entry, run no part of this step - no reviewer is requested either -
and say so in Step 7's file.

1. Run `review-list` and keep its output.
2. Run `request-reviewer` on the pull request.
3. Wait until a successful `review-list` returns output different from the kept copy, or
   until `review-wait` minutes have passed. This is one notification at one moment, so run
   a POSIX `sh` loop through Bash with `run_in_background`: it calls `review-list` every 30
   seconds and exits both when the output differs and after `review-wait` minutes, counted
   in iterations so it needs no `timeout` binary. `Monitor` does the same job where the
   backend allows that tool, with `timeout_ms` set to `review-wait` minutes in
   milliseconds - but it is built for a stream of events and stays armed to its timeout
   after the one that matters, so the loop is the default. A foreground `sleep` is neither:
   the harness blocks a standalone one and names these two ways to wait.
4. On timeout, go to Step 7 with a file saying the review did not arrive. A reviewer that
   answers later is `baton:address-review`'s to handle, not this run's.
5. Otherwise read `review-bodies`, `pr-comments` and `review-threads` - the three are one
   set, and a reviewer that writes its findings in a summary body is invisible to the other
   two. Apply the findings that hold, run the tests again, answer each thread with
   `thread-reply` and anything that arrived outside a thread with `pr-comment`, and push
   once.

One round, with no re-request. A finding that holds is yours to judge on the diff, the
same as a Step 4 finding - `request-reviewer` names who reviews, not who decides.

## Step 7 - Report

Run `published` with the issue id, the pull request URL from Step 5, and one file saying
what shipped: the URL, the branch, the test result, any deviation Step 2 recorded, and
whether Step 6 ran, timed out, or was skipped.

## Stopping without a pull request

Every stop above shares one shape: push nothing, open no pull request, and run `stopped`
with one file naming the step and what stopped it. Then end the turn. The session stays
open, so a reply there resumes the run from the answer.

## Done

Both exits end here. Report the pull request URL, the branch and the test result - or the
blocker and the step it stopped at.
