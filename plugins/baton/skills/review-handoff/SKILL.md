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

Nobody is watching. Ask no questions - `AskUserQuestion` has no one to answer it. Nothing
reaches the user except the push, the pull request body, and the Run report `reviewed` or
`stopped` posts.

Every operation named below comes from the backend, its files loaded in the order
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md` "Where overrides live" sets. Load the
shipped file and run the route check at its top:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
```

Load `backend-github-gh.md` only where that check selects it:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github-gh.md
```

Then the project's own files, and the rule for every call this skill makes once per issue -
`reviewed` and `stopped`:

```
cat .claude/baton.md 2>/dev/null
cat ~/.claude/baton.md 2>/dev/null
cat ${CLAUDE_PLUGIN_ROOT}/reference/per-issue-calls.md
```

Two failures are stops, not fallbacks: an operation this skill names that no loaded file
defines, and an operation that fails because its tool is missing or unauthenticated - a
command exiting non-zero, or a named tool the session lacks or cannot authorize. Report
the operation name, the entry that failed, and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`. Never run a command this backend does
not define.

## Where the opening turn came from

Three things in the opening turn bind: the handoff locator, the pull request URL, and
`launcher=<name>` where it is present. A turn with no `launcher=` was started by hand, and reads
as `launcher=local`. Anything else the turn carries has the authority of the handoff section it
was copied from, and an optional section stays optional however the turn phrases it.

`launcher=` records which `## Launcher` entry started this run, and the Run report names it.
It chooses nothing here.

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

That file is read, never `baton:self-review` invoked.

## What this run may do unasked

These need no confirmation:

- `git add`, `git commit`, and `git push origin HEAD:<head ref>` to the pull request's head
  branch, which Step 1 reads off the pull request.
- `EnterWorktree` at Step 2, and `ExitWorktree` at Step 6 - `remove` with
  `discard_changes: true` once that step's checks pass, `keep` otherwise.
- `request-reviewer` on that pull request, once, at Step 3.
- `pr-update` on that pull request.
- `reviewed` and `stopped` on **each issue the header names**, one call per issue.
- Dispatching the subagents its review needs - Step 4's claim audit, and a reviewer an
  `agent:` entry in `code-review` names. They read and report; nothing they return reaches the
  tracker or the forge except through a step above.

Everything else is a stop rather than a judgement call:

- Force-push, in any form - `--force`, `--force-with-lease`, a `+` refspec.
- Pushing to any branch but the pull request's head branch.
- Merging the pull request, marking a draft ready, closing it, adding a reviewer beyond what
  `request-reviewer` names, or writing to a review thread or a pull request comment.
- `started` or `published` on any issue.

Those are actions. A judgement this run can make on the evidence - whether a finding holds,
which fix the code supports - is one it must make rather than end the turn over.

This clears the policy, not the harness: a repo whose permission list omits a command still
prompts for it.

## Step 1 - Load

Run `fetch-handoff` on the locator, deriving `<id>` and `<comment-id>` as the backend's notes on
`fetch-handoff` say. Read the header as `implement-handoff` Step 1 does, including its stop on
`issue` and `closes` lists of different lengths. Then load the reference file for each header
line that needs one, from `${CLAUDE_PLUGIN_ROOT}/reference/`. Each file's `review-handoff`
section adds to the steps it names, and replaces what they say where the two differ:

| Where the header carries | Load |
|---|---|
| a `pr-base` line or a `next` line | `stacked-handoff.md` |
| an `assets` line | `handoff-assets.md` |
| more than one entry on its `issue` line | `bundled-issues.md` |

A fetched comment carrying the handoff marker but **no fenced header** is a pointer, not a
handoff, and is a stop naming the issue and locator the pointer carries.

Each operation's `<owner>` and `<repo>` follow what it addresses, per the placeholder table in
`defining-backends.md` `## Operations`.

Run `verify-checkout`; its answer must equal the header's `repo`, or the run stops.

Take the pull request number from the URL - its last path segment - and run `pr-view` with it as
`<id>`. Keep, for the whole run:

- the **head ref**, the branch the pull request merges from;
- the **reviewed head**, the commit that branch pointed at when `pr-view` answered;
- the current body, which Step 5 rewrites from.

Three answers are stops: a pull request that is not open, one whose head repository is not
`origin`'s - its owner differing from `<head-owner>`, ignoring case - since this run pushes to
`origin` alone, and a URL naming a repository other than `verify-checkout`'s answer.

Then resolve, against the loaded backend files and before `EnterWorktree`, every operation this
run calls: `review-threads`, `code-review`, `verify`, `request-reviewer`, `review-wait`,
`review-list`, `pr-comments`, `pr-update`, `reviewed` and `stopped`. `review-wait`,
`review-list` and `pr-comments` need resolving only where `request-reviewer` is not `none`.
Find the subagent dispatch tool - `Agent` in some harness builds, `Task` in others - in this
session's tools. Any of these missing is a stop here.

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

All three are needed: a person's own linked worktree can carry the reviewed head too.

Any other differing pair is a session a launcher started in a worktree of its own: skip
`EnterWorktree` alone and run the rest of this step there.
Otherwise give the run a worktree of its own. Call `EnterWorktree` with a `name` of
`<issue>-review-<6 hex>`, where `<issue>` is the primary issue and the six characters are what
`od -An -N3 -tx1 /dev/urandom | tr -d ' \n'` prints. Then, before the first edit:

```
git status --porcelain --untracked-files=no
git fetch origin <head ref>:refs/remotes/origin/<head ref>
git rev-parse origin/<head ref>
```

The first must print nothing, or the run stops. The third must print the reviewed head;
anything else is a stop. Then put the worktree's branch on that commit:

```
git reset --hard <reviewed head>
git branch --show-current
```

Keep the branch the second line prints as the **review branch**. It is never pushed under its
own name; Step 5 pushes its commits to the head ref.

## Step 3 - Review loop

### The external reviewer

Where `request-reviewer` is not `none`, start the external review first:

1. Run `review-list` and `pr-comments`, and keep their combined output.
2. Run `request-reviewer` with the pull request number as `<id>`, and record `date +%s` as the
   wait's start.

Then run the first `code-review` round below. Its output does not wait on the reviewer.

A turn resuming from a stop after item 2 ran runs neither item again: it keeps the copy and
the start it recorded.

### The first round

Run `code-review` with the pull request number as `<target>` and the handoff locator as
`<locator>`.

Where `request-reviewer` is not `none`, wait out what remains of the wait once that call
returns: until a successful run of `review-list` and `pr-comments` returns output different from
the kept copy, or until `review-wait` minutes have passed since the wait's start, capped at 60
(`defining-backends.md`, `## Operations`). The wait takes one of two forms, picked by how this
backend defines `review-list` and `pr-comments`:

- **Both a single shell command.** Run a POSIX `sh` loop through Bash with
  `run_in_background`: it runs both every 30 seconds and exits when the output differs or when
  the wait runs out, counted in iterations so it needs no `timeout` binary.
- **Anything else** - a `tool:` entry, a nested list, an `op:`. Run `sleep 60` through Bash with
  `run_in_background`. On its notification run both operations in their defined form and
  compare with the kept copy: output that differs goes to the check below, output that matches
  sleeps again. The wait runs out when `date +%s` exceeds the start by the wait's minutes times
  60, however many sleeps that took.

A foreground `sleep` is neither form - the harness blocks a standalone one. `Monitor` does the
first form's job where the backend allows that tool, with `timeout_ms` set to what remains of the
wait in milliseconds, but it stays armed to its timeout after the event that matters, so the loop
is the default.

When the new output holds no review by the reviewer `request-reviewer` named, keep it as the
copy and wait again for what is left. On timeout, carry on: the Run report says the reviewer
was requested and no review arrived. A review arriving later is `baton:address-review`'s.

Then collect the pull request's threads as the reference's "Collecting the review threads"
says - after the review arrived or the wait ran out, where a reviewer was requested. Check each
collected thread as the reference's "Checking the threads" says: a thread whose finding stands
joins the round's findings, and every thread keeps its own disposition for the Run report.
Classify every finding against the reference's "Severity" section.

### The loop

Each round runs over its findings - those its `code-review` call returned, and in the first
round the threads whose findings stand:

1. Apply every Critical and Important finding the run can fix. Apply a Minor one only where
   the fix is smaller than the paragraph explaining why it was left.
2. Run the handoff's commands. A failure is a stop, at every turn of the loop. `verify` waits
   for Step 4.
3. Where this round's findings hold no Critical one, or this is the third round: commit what
   item 1 applied, on the review branch, and end the loop. Those last fixes go unreviewed, and
   the Run report says so.
4. Otherwise run `code-review` again, with an empty `<target>` and an empty `<locator>`, while
   this round's fixes are still uncommitted and every file they created is marked with
   `git add -N`: it reviews those fixes alone, and an entry that checks acceptance criteria
   checked them against the whole change in the first round. Once it returns, commit them on
   the review branch. Its findings are the next round's.

Never commit a round's fixes before item 4's `code-review` returns: an empty `<target>` is the
working tree, and a committed tree hands the review an empty diff.

A round whose item 1 applies nothing ends the loop there, skipping items 2 to 4: there is
nothing for another round to review. A run whose loop applied nothing at all has nothing to
push: Step 4's checks and Step 5's push are skipped, and Steps 4 and 5 say what still runs for
the findings it left standing.

A finding the run cannot fix is one whose fix falls outside the handoff's scope, contradicts a
decision the handoff recorded, or needs an answer nobody here can give. Say which. A finding in
code the pull request's own diff does not change is outside the handoff's scope. Each finding,
from `code-review` or from a thread, ends with one of the dispositions in the reference's
"Dispositions" section, applied on the review branch.

A finding the run cannot decide is `unresolved`, never dropped. Keep every round's findings,
with severity and disposition: the Run report names all of them, applied ones included.

## Step 4 - Verify and audit

The checks below are skipped where the loop applied nothing, and the audit wherever Step 5
writes no body - a loop that applied nothing and left no finding standing.

Over the tip of the review branch, with nothing uncommitted, run `verify`, commit on the review
branch any file it rewrote, then run the handoff's commands. A failure is a stop. The push in
Step 5 never carries a tree these checks did not pass on.

Then dispatch a fresh subagent with the dispatch tool Step 1 found, and give it the instruction
to run `baton:claim-audit` - naming the **resolved absolute path** of
`${CLAUDE_PLUGIN_ROOT}/skills/claim-audit/SKILL.md`, expanded here, since the dispatched agent's
shell does not carry this session's environment - and every claim Step 5's body will add or
change: what the fixes do, what the checks returned, each finding left standing and why.
Carry the provenance rule into the prompt as well.

The audit's verdict decides what the body may say, by the verdict table in `implement-handoff`
Step 4. A dispatch that fails is a stop.

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

Anything but the reviewed head is a stop: another push landed while this review ran. Then,
where the loop applied fixes:

```
git push origin HEAD:<head ref>
```

Never with force. A rejected push is a stop too.

Then run `pr-update` with the pull request number as `<id>` and a body written on
`baton:write-deliverables`' short path, as a **PR description**, to a file in the scratchpad
directory. Start from the body Step 1 read, and make it describe what the code does now, as
though the final diff were the only version that ever existed: delete what the diff no longer
supports, state each claim Step 4's audit ruled on in the form its verdict gave, and never
narrate the review.

Carry every issue reference line across unchanged (`defining-backends.md`, `pr-update`): "what
the diff no longer supports" is about claims, never about these lines. Add each claim Step 4's
audit labelled under `## Unverified claims`, writing the heading where it is absent.

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
`action: "remove"` and `discard_changes: true`. Either failing: call `ExitWorktree` with
`action: "keep"`, and the Run report names `.claude/worktrees/<name>` and which check failed.
Where a launcher started the session in a worktree of its own - Step 2 skipped `EnterWorktree`
alone - the call is `keep` and nothing further is asked: that worktree is the launcher's to
remove.

Then run `reviewed` on each issue the header names, as `per-issue-calls.md` walks it, each with
that issue's id as `<id>`, the pull request URL as `<pr-url>`, and the same one file as
`<path>`, written on `baton:write-deliverables`' short path as a **Run report**. It says:

- the pull request URL, its head ref, and the `launcher=` value this run received;
- the commit this run pushed, or that it pushed nothing because no fix was applied;
- how the handoff's commands and `verify` came out over the pushed tip, or that they did not run
  because nothing was pushed;
- whether an external reviewer was requested, and whether a review arrived or the wait ran
  out - or that `request-reviewer` is `none`;
- every finding every round collected, each with its severity and its disposition, and every
  thread with its disposition and the evidence that settled it;
- that the loop's last fixes went unreviewed, where its last round applied any, and so did any
  file `verify` rewrote in Step 4;
- whether the pull request body carries `## Not verified here` or `## Unverified claims`,
  pointing to each heading present without repeating its entries;
- after a `keep`, the worktree path and which check failed.

**A Run report from this run never carries `<!-- claude-handoff -->`, not even quoted.**

The findings, their dispositions, the thread dispositions and the external review's outcome are
required content whatever contract **Run report** resolves to.

## Stopping

Every stop takes one of two shapes, set by whether Step 5 has changed the pull request - by
its push, or by a `pr-update` where nothing was pushed. Both write one file on
`baton:write-deliverables`' short path as a **Run report**, carrying no handoff marker, and run
`stopped` with it on each issue the header names, as `per-issue-calls.md` walks it - never
`reviewed`.

- Before that: push nothing and leave the pull request as it was. The file names the step,
  what stopped it, and the pull request URL.
- After it, in `pr-update` or Step 6: push nothing further. The file says what is on the pull
  request - the fixes and the commit that carries them, the rewritten body, or both - then the
  step and what stopped it. A stop in `pr-update` after a push leaves a body describing the diff
  before those fixes, and the file says so.

**The file carries the review as far as it got.** Every finding judged so far takes its
disposition, and every finding collected but never judged is unresolved, with "run stopped" as
what blocks the call. A fix not on `origin` is not applied, whether uncommitted or committed on
the review branch: mark it unresolved with what stopped the run. A stop before Step 3 has
collected no findings and says nothing about them. This is required content under any
contract, the same as Step 6's.

No stop calls `ExitWorktree`. The file names `.claude/worktrees/<name>` and the review branch
wherever the worktree still stands: whatever was not pushed is in that directory.

Then end the turn.

## Done

Report the pull request URL, the head ref, the commit pushed or that nothing was, how the
handoff's commands and `verify` came out, and whether an external review arrived - or the
blocker, the step it stopped at, and whether the push had run. Name every issue the header
carried and whether `reviewed` or `stopped` reached it.
