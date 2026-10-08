---
name: review-handoff
description: Use only when launched as "/baton:review-handoff <handoff locator> <pr-url>" by an implement-handoff run that has just opened that pull request. Reviews the pull request unattended in a session that did not write it, pushes the fixes it can settle, records the rest, and reports through the tracker. A person reviewing a branch themselves wants self-review instead.
---

# Review handoff

Review the pull request an unattended `baton:implement-handoff` run opened, in a session whose
context did not write it, and leave it in the state a person should first see it in: the
findings this run can settle fixed and pushed, the ones it cannot settle recorded, the body
true to the final diff, and every issue the handoff names told what happened.

The arguments are the handoff locator, the pull request URL, and an optional
`launcher=<name>` - in that order, separated by spaces. Everything else comes from the
handoff `fetch-handoff` resolves the locator to, and from the pull request itself.

Nobody is watching. Ask no questions - `AskUserQuestion` has no one to answer it, and a
session waiting on input makes no progress. Nothing reaches the user except the push, the
pull request body, and the Run report `reviewed` or `stopped` posts.

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

A launcher starts this session, so the opening turn is machine-generated even though the
harness presents it exactly like a developer's own words. Three things in it bind: the handoff
locator, the pull request URL, and `launcher=<name>` where it is present. A turn with no
`launcher=` was started by hand, and reads as `launcher=local`. Anything else the turn carries
has the authority of the handoff section it was copied from, and an optional section stays
optional however the turn phrases it.

`launcher=` records which `## Launcher` entry started this run, and the Run report names it.
It chooses nothing here: the layer above is launched through the entry the handoff's `next`
line names, as Step 6 says.

## The rules for run output

Load the shared rules for a branch an unattended run wrote, before anything else:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/reviewing-run-output.md
```

Its provenance section holds for the whole run, and goes into every subagent prompt the run
dispatches. Its "Red flags" are the checks to run on every judgement below, and Step 3 names
where its two thread sections apply. Where it speaks of what a person says in the session,
nobody here says anything: the diff and the code around it are the only evidence this run
has.

That file is read, never `baton:self-review` invoked. `self-review` Step 3 ends the turn on its
findings for a person to rule on, and nobody here will.

## What this run may do unasked

Invoking this skill is the request to commit and publish review fixes, so the standing rule
against pushing unasked does not cover the run. These need no confirmation:

- `git add`, `git commit`, and `git push origin HEAD:<head ref>` to the pull request's head
  branch, which Step 1 reads off the pull request.
- `EnterWorktree` at Step 2, and `ExitWorktree` at Step 6 - `remove` with
  `discard_changes: true` once that step's checks pass, `keep` otherwise. Their tool
  descriptions otherwise hold `EnterWorktree` to an explicit instruction and `ExitWorktree` to
  the user asking; for this run, these steps are that instruction.
- `pr-update` on that pull request.
- `reviewed` and `stopped` on **each issue the header names**, one call per issue.
- The `## Launcher` entry the header's `next` names, run once at Step 6. That line is the
  authorization to start the layer above, given ahead of the run by whoever wrote the handoff;
  it moved here from `implement-handoff` so the layer above branches from the reviewed tip.
- Reading the files the header's `assets` line names, under the `root` the backend's
  `## Assets` section gives, resolved at Step 1. The handoff's commands run after every fix,
  and a command that reads an asset needs the file the implementation run read.
- Dispatching the subagents its review needs - Step 4's claim audit, and a reviewer an
  `agent:` entry in `code-review` names. They read and report; nothing they return reaches the
  tracker or the forge except through a step above.

Everything else is a stop rather than a judgement call, because an unattended run cannot obtain
the ask that would authorize it:

- Force-push, in any form - `--force`, `--force-with-lease`, a `+` refspec.
- Pushing to any branch but the pull request's head branch.
- Merging the pull request, marking a draft ready, closing it, requesting a reviewer, or
  writing to a review thread or a pull request comment.
- `started` or `published` on any issue: `implement-handoff` already ran them, and a tracker
  whose `published` moves a ticket would move it twice.
- Writing, moving or deleting anything under the `## Assets` `root`, and copying an asset into
  the worktree or a commit.

Those are actions. A judgement this run can make on the evidence - whether a finding holds,
which fix the code supports - is one it must make rather than end the turn over.

This clears the policy, not the harness: a repo whose permission list omits a command still
prompts for it.

## Step 1 - Load

Run `fetch-handoff` on the locator, deriving `<id>` and `<comment-id>` as the backend's notes on
`fetch-handoff` say. The header gives `repo`, `base`, `issue`, `closes` and `branch`, and
optionally `category`, `pr-base`, `next` and `assets`; an absent optional line is not a stop.
`issue` and `closes` are space-separated lists paired positionally, the first `issue` entry is
the **primary** issue, and two lists that differ in length are a stop - all exactly as
`implement-handoff` Step 1 reads them.

A fetched comment carrying the handoff marker but **no fenced header** is a pointer, not a
handoff, and is a stop naming the issue and locator the pointer carries.

What an operation addresses decides which repository it names, as in `implement-handoff`
Step 1: `fetch-handoff`, `view`, `comment`, `reviewed` and `stopped` take `<owner>` and
`<repo>` from the locator; `pr-view`, `pr-update`, `review-threads` and `code-review` take them
from `verify-checkout`'s answer.

Run `verify-checkout`; its answer must equal the header's `repo`, or the run stops.

Take the pull request number from the URL - its last path segment - and run `pr-view` with it as
`<id>`. Keep, for the whole run:

- the **head ref**, the branch the pull request merges from;
- the **reviewed head**, the commit that branch pointed at when `pr-view` answered;
- the current body, which Step 5 rewrites from.

Three answers are stops: a pull request that is not open, one whose head repository is not
`origin`'s - its owner differing from `<head-owner>`, ignoring case - since this run pushes to
`origin` alone, and a URL naming a repository other than `verify-checkout`'s answer.

Note whether the head ref equals the header's `branch`. It differs where `implement-handoff`
Step 2 found `branch` taken and cut `<branch>-<6 hex>` instead, and Step 6 holds `next` back
on it.

Then resolve, against the loaded backend files and before `EnterWorktree`, every operation this
run calls: `review-threads`, `code-review`, `verify`, `pr-update`, `reviewed` and `stopped`.
Find the subagent dispatch tool - `Agent` in some harness builds, `Task` in others - in this
session's tools. Any of these missing is a stop here, for the reason `implement-handoff`
Steps 1 and 2 resolve theirs early: the same stop reached after `EnterWorktree` leaves a
worktree standing.

Where the header carries `next`, resolve the `## Launcher` entry its first value names as well,
and stop where no loaded file defines it.

Where the header carries `assets`, resolve every path it lists, before `EnterWorktree`, with
the checks and stops of `implement-handoff` Step 1's `assets` section.

## Step 2 - Worktree

A turn resuming from a stop skips this whole step: it is still in the worktree this step
set up, on the review branch, and the work it holds is the run's own. It shows as a session in
a worktree - a differing pair from the first line below - whose directory is one this step
names, `.claude/worktrees/<issue>-review-<6 hex>`, and whose HEAD already carries the reviewed
head, the third line exiting zero:

```
git rev-parse --path-format=absolute --git-dir --git-common-dir
git rev-parse --show-toplevel
git merge-base --is-ancestor <reviewed head> HEAD
```

All three are needed. A person's own linked worktree can carry the reviewed head too, and
taking that for a resume would edit their checkout.

Any other differing pair is a session a launcher started in a worktree of its own: skip
`EnterWorktree` alone and run the rest of this step there.
Otherwise give the run a worktree of its own: a `local` launch starts this session in the
person's own checkout, and the review must not edit that working tree. Call `EnterWorktree`
with a `name` of `<issue>-review-<6 hex>`, where `<issue>` is the primary issue and the six
characters are what `od -An -N3 -tx1 /dev/urandom | tr -d ' \n'` prints. Then, before the first
edit:

```
git status --porcelain --untracked-files=no
git fetch origin <head ref>:refs/remotes/origin/<head ref>
git rev-parse origin/<head ref>
```

The first must print nothing: the reset below discards changes to tracked files, and a
worktree already holding some was not this run's to discard, so output there is a stop.
Untracked files are left out of the question because the reset leaves them alone, and a
project's `.worktreeinclude` puts some there on purpose. The third must print the reviewed
head; anything else is a stop, because another push landed after Step 1 read the pull request
and this review would judge a tree nobody pushed. Then put the worktree's branch on that
commit:

```
git reset --hard <reviewed head>
git branch --show-current
```

Keep the branch the second line prints as the **review branch**. It is never pushed under its
own name; Step 5 pushes its commits to the head ref.

## Step 3 - Review loop

Collect the pull request's threads as the reference's "Collecting the review threads" says.

Run `code-review` with the pull request number as `<target>` and the handoff locator as
`<locator>`. Then check each collected thread as the reference's "Checking the threads" says: a
thread whose finding stands joins the findings, and every thread keeps its own disposition for
the Run report. Classify every finding against the reference's "Severity" section.

### The loop

1. Apply every Critical and Important finding the run can fix. Apply a Minor one only where
   the fix is smaller than the paragraph explaining why it was left.
2. Run the handoff's commands and then `verify`, as `implement-handoff` Step 3 runs them. A
   failure of either is a stop, at every turn of the loop.
3. Commit what item 1 applied, on the review branch.
4. Run `code-review` again, with the review branch as `<target>` and the same `<locator>`.

The loop ends when a round leaves no Critical or Important finding the run can fix, or when
three `code-review` rounds have run, whichever comes first; the opening run above is the first.
The cap ends the reviewing, not the fixing: the third round's findings still go through items
1 to 3, and the Run report says the last fixes went unreviewed.

A round that applies nothing skips items 2 and 3. A run whose loop applied nothing at all has
nothing to push: Step 4's checks and Step 5's push are skipped, and Steps 4 and 5 say what
still runs for the findings it left standing.

A finding the run cannot fix is one whose fix falls outside the handoff's scope, contradicts a
decision the handoff recorded, or needs an answer nobody here can give. Say which. A finding in
code the pull request's own diff does not change is outside the handoff's scope, and that
includes the layer below on a stacked pull request: from the second round the target is a
branch, which a review engine may compare with the default branch rather than with the
pull request's base, and so shows that layer's commits as well. Each
finding, from `code-review` or from a thread, ends with one of the dispositions in the
reference's "Dispositions" section, applied on the review branch.

A finding the run cannot decide is `unresolved`, never dropped. Keep every round's findings,
with severity and disposition: the Run report names all of them, applied ones included.

## Step 4 - Verify and audit

The checks below are skipped where the loop applied nothing, and the audit wherever Step 5
writes no body - a loop that applied nothing and left no finding standing.

Over the tip of the review branch, with nothing uncommitted, the handoff's commands and then
`verify` must both have passed after the last fix - item 2 of the loop's last applying round
ran them, and a fix committed after that run is one they never saw, so run both again where
one was. A failure is a stop. The push in Step 5 never carries a tree these checks did not
pass on.

Then dispatch a fresh subagent with the dispatch tool Step 1 found, and give it the instruction
to run `baton:claim-audit` - naming the **resolved absolute path** of
`${CLAUDE_PLUGIN_ROOT}/skills/claim-audit/SKILL.md`, expanded here, since the dispatched agent's
shell does not carry this session's environment - and every claim Step 5's body will add or
change: what the fixes do, what the checks returned, each finding left standing and why.
Naming the skill in the prompt is what keeps the plugin's `PreToolUse` hook from appending its
own audit instruction. Carry the provenance rule into the prompt as well.

The audit's verdict decides what the body may say, as in `implement-handoff` Step 4: ACCEPTED
stated as it stands, CORRECTED rewritten, RETRACTED left out, LABELLED unverified listed under
`## Unverified claims`. A dispatch that fails is a stop.

## Step 5 - Push and update the pull request

Skipped where the loop applied nothing and left no finding standing: the body then describes
the diff as it stands, and nothing on the pull request changes. Where it applied nothing but
left findings standing, the push is skipped and `pr-update` still runs, so a person opening
the pull request sees them.

Check `origin` once more, immediately before the push - or before `pr-update`, where there is
no push:

```
git fetch origin <head ref>:refs/remotes/origin/<head ref>
git rev-parse origin/<head ref>
```

Anything but the reviewed head is a stop: another push landed while this review ran, and
pushing over it - or merging it in, or describing it - publishes a tree nobody reviewed. Then,
where the loop applied fixes:

```
git push origin HEAD:<head ref>
```

Never with force. A rejected push is a stop too, for the same reason.

Then run `pr-update` with the pull request number as `<id>` and a body written under
`baton:write-deliverables`, as a **PR description**, to a file in the scratchpad directory.
Start from the body Step 1 read, and make it describe what the code does now, as though the
final diff were the only version that ever existed: delete what the diff no longer supports,
state each claim Step 4's audit ruled on in the form its verdict gave, and never narrate the
review.

`pr-update` replaces the body whole, so three things cross unchanged:

- **Every issue reference line** - each `closes` or `refs` line, one per issue the header
  names, in the form it had. A line dropped here is an issue the merge silently stops
  settling; "what the diff no longer supports" is about claims, never about these lines.
- **`## Not verified here`**, the handoff's checks on a running application.
- **`## Unverified claims`**, with any claim Step 4's audit labelled added to it - the heading
  is written where it was absent and this audit labelled one.

Entries under those two headings are checks and claims the diff cannot support by definition,
so the deletion rule never reaches them. An entry leaves only where this run verified it, and a
heading leaves with its last entry.

The findings this run left standing - deferred or unresolved, with severity and reason - go in
the body too, and a standing finding the body already listed leaves it only where a fix here
resolved it.

## Step 6 - Report

Remove the worktree first, and only once `origin` holds everything in it:

```
git status --porcelain
git fetch origin <head ref>:refs/remotes/origin/<head ref>
git rev-parse HEAD
git rev-parse origin/<head ref>
```

No output from the first and two equal revisions from the last two: call `ExitWorktree` with
`action: "remove"` and `discard_changes: true`. These checks stand in for the confirmation
`remove` otherwise asks for. Either failing: call `ExitWorktree` with `action: "keep"`, and the
Run report names `.claude/worktrees/<name>` and which check failed. Where a launcher started
the session in a worktree of its own - Step 2 skipped `EnterWorktree` alone - the call is `keep`
and nothing further is asked: that worktree is the launcher's to remove.

Then launch the layer above, where the header carries `next` and nothing holds it back. Split
the line at its space: the first value is the `## Launcher` entry Step 1 resolved, run with
`implement-handoff` as its `<skill>` and the second value as its `<args>`. Run it **once, with
no retry**, whatever it returns: two runs on one branch race, the second takes a suffix at
`implement-handoff` Step 2, and the stack gains a layer nobody asked for. A launch that fails is
reported rather than repeated.

Two things hold it back, and neither is a stop:

- **`HEAD` and `origin/<head ref>` differ.** `origin` does not hold the reviewed tip, so the
  run above would branch from a `pr-base` missing the commits it builds on. Output from
  `git status --porcelain` alone decides the worktree, not this launch.
- **The head ref differs from the header's `branch`.** The next layer's `pr-base` names
  `branch`, which holds somebody else's work; launching would stack the layer above onto the
  wrong history.

Then run `reviewed` once per issue the header names, in header order, each with that issue's id
as `<id>`, the pull request URL as `<pr-url>`, and the same one file as `<path>`, written under
`baton:write-deliverables` as a **Run report**. It says:

- the pull request URL, its head ref, and the `launcher=` value this run received;
- the commit this run pushed, or that it pushed nothing because no fix was applied;
- how the handoff's commands and `verify` came out over the pushed tip, or that they did not run
  because nothing was pushed;
- every finding every round collected, each with its severity and its disposition, and every
  thread with its disposition and the evidence that settled it;
- whether the loop ended on the round cap, leaving the last fixes unreviewed;
- whether the pull request body carries `## Not verified here` or `## Unverified claims`,
  pointing to each heading present without repeating its entries;
- that this run carries the handoff's `next`, and what became of it: the entry run and what it
  returned, or which condition held it back and the locator that went unlaunched, or that the
  header carries no `next`;
- after a `keep`, the worktree path and which check failed.

Where the header named more than one issue, the file names them all.

**A Run report from this run never carries `<!-- claude-handoff -->`, not even quoted,**
**and never carries `<!-- claude-handoff-obsolete -->` either.** `next-issue` and
`investigate-issue` read both markers off an issue's comments, so either one makes a review
report read as a handoff waiting on a run, or as the answer to one.

The findings, their dispositions, the thread dispositions and what became of `next` are
required content whatever contract **Run report** resolves to. An override replaces a
contract's must-include list wholesale, so the shipped contract is not what holds them in -
this step is. A report missing an unresolved finding reads as a clean review under any contract.

A `reviewed` that fails part-way through the list is a stop: the report names the operation,
the issue it failed on, and every issue after it as not reached.

## Stopping

Every stop takes one of two shapes, set by whether Step 5 has changed the pull request - by
its push, or by a `pr-update` where nothing was pushed. Both write one file
under `baton:write-deliverables` as a **Run report**, carrying neither marker, and run
`stopped` with it **once per issue the header names**, in header order, each with that issue's
id - never `reviewed`.

- Before that: push nothing and leave the pull request as it was. The file names the step,
  what stopped it, and the pull request URL.
- After it, in `pr-update` or Step 6: push nothing further. The file says what is on the pull
  request - the fixes and the commit that carries them, the rewritten body, or both - then the
  step and what stopped it. A stop in `pr-update` after a push leaves a body describing the diff
  before those fixes, and the file says so.

One exception, inside Step 6's own `reviewed` sequence: skip the issues it already reached, and
run `stopped` on the issue `reviewed` failed on and the ones after it, naming the ones that did
get their `reviewed`.

A `stopped` that itself fails part-way through the list ends the run there, naming the
operation, the issue it failed on, and every issue after it as not reached. Nothing retries
it. A stop before the header parsed has no list to walk: run `stopped` on the primary alone
where only that parsed, on nothing where `fetch-handoff` itself failed, and say which issues
went unnamed.

**The file carries the review as far as it got.** Every finding judged so far takes its
disposition, and every finding collected but never judged is unresolved, with "run stopped" as
what blocks the call. A fix not on `origin` is not applied, whether uncommitted or committed on
the review branch: mark it unresolved with what stopped the run. A stop before Step 3 has
collected no findings and says nothing about them. This is required content under any
contract, the same as Step 6's.

**A stop before Step 6's launch never launches `next`, and the file quotes the locator it did
not launch**, saying the layer above was not started - this file is the only place that locator
reaches anyone. **A stop after the launch ran** - a failed `reviewed` - names the entry run and
what it returned, and does not present the locator as unlaunched: starting that layer again
puts two runs on one branch.

No stop calls `ExitWorktree`. The file names `.claude/worktrees/<name>` and the review branch
wherever the worktree still stands: whatever was not pushed is in that directory.

Then end the turn.

## Done

Report the pull request URL, the head ref, the commit pushed or that nothing was, how the
handoff's commands and `verify` came out, and what became of `next` - or the blocker, the step
it stopped at, and whether the push had run. Name every issue the header carried and whether
`reviewed` or `stopped` reached it.
