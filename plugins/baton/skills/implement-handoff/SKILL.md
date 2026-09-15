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
- `pr-create` on that branch; `request-reviewer`, `thread-reply` and `pr-comment` on the
  pull request it opens; `published` and `stopped` on the issue.
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

Run `fetch-handoff` on the locator. Where the entry takes `<id>` or `<comment-id>`, derive
each from the locator as the backend's notes on `fetch-handoff` say. The handoff's
header gives `repo`, `base`, `issue`, `closes` and `branch`. Verify the checkout before the
first edit:

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

Skip this step when `request-reviewer` is `none`, which is the shipped default. That is the
only thing that skips it: the round runs on whatever entry form `## Review` uses.

1. Run `review-list` and `pr-comments`, and keep their combined output.
2. Run `request-reviewer` on the pull request, and record `date +%s` as the wait's start.
3. Wait until a successful run of both returns output different from the kept copy, or
   until `review-wait` minutes have passed, capped at 60. The wait takes one of two forms,
   picked by how this backend defines `review-list` and `pr-comments`:
   - **Both a single shell command.** Run a POSIX `sh` loop through Bash with
     `run_in_background`: it runs both every 30 seconds and exits when the output differs
     or when the wait runs out, counted in iterations so it needs no `timeout` binary. The
     polling happens inside the shell, so the loop notifies once, at the moment that
     matters.
   - **Anything else** - a `tool:` entry, a nested list, an `op:`. Run `sleep 60` through
     Bash with `run_in_background`. On its notification run both operations in their
     defined form and compare with the kept copy: output that differs goes to item 4,
     output that matches sleeps again. The wait runs out when `date +%s` exceeds the start
     by the wait's minutes times 60, however many sleeps that took.

   A foreground `sleep` is neither form - the harness blocks a standalone one and names
   `run_in_background` as the way to wait. `Monitor` does the first form's job where the
   backend allows that tool, with `timeout_ms` set to the wait in milliseconds, but it is
   built for a stream of events and stays armed to its timeout after the one that matters,
   so the loop is the default.
4. When the new output holds no review by the reviewer `request-reviewer` named, keep it
   as the copy and return to item 3 for what is left of the wait.
5. On timeout, go to Step 7 with a file saying the review did not arrive. A reviewer that
   answers later is `baton:address-review`'s to handle, not this run's.
6. Otherwise collect the round as `baton:address-review` Step 2 does - `review-bodies`,
   `pr-comments` and `review-threads`, with the author filters the backend defines - and
   keep the findings its Step 3 admits to the inventory. Read those two steps rather than
   invoking the skill, which would run its own Step 1 and stop at its Step 3:

   ```
   cat ${CLAUDE_PLUGIN_ROOT}/skills/address-review/SKILL.md
   ```

   Step 3's end-of-turn stop is not this run's: judge each finding here. Apply the findings
   that hold, run the tests again - a red suite is a stop - answer each thread with
   `thread-reply` and anything that arrived outside a thread with `pr-comment`, and push
   once.

One round, with no re-request. A finding that holds is yours to judge on the diff, the
same as a Step 4 finding - `request-reviewer` names who reviews, not who decides.

## Step 7 - Report

Run `published` with the issue id, the pull request URL from Step 5, and one file saying
what shipped: the URL, the branch, the test result, any deviation Step 2 recorded, and
whether Step 6 ran, timed out, or was skipped - skipped meaning only that
`request-reviewer` is `none`.

## Stopping

Every stop above takes one of two shapes, set by whether Step 5 has opened the pull request:

- Before it: push nothing, open no pull request, and run `stopped` with one file naming the
  step and what stopped it.
- After it, in Step 6 or 7: push nothing further and leave the pull request open. Run
  `stopped` with one file naming the step, what stopped it, and the pull request URL - only
  Step 7's `published` would otherwise carry that URL to the issue.

Then end the turn. The session stays open, so a reply there resumes the run from the answer.

## Done

Both exits end here. Report the pull request URL, the branch and the test result - or the
blocker, the step it stopped at, and the pull request URL when Step 5 opened one.
