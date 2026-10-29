---
name: implement-handoff
description: Use when a handoff describes work that is ready to build - launched as "/baton:implement-handoff <handoff locator>", usually by a session that investigate-issue started. Turns one handoff into a draft pull request, launches review-handoff on it, and runs unattended.
---

# Implement handoff

Turn one handoff into a pull request, and launch `baton:review-handoff` on it. The argument is
the handoff locator, in whatever shape this backend's `post-handoff` returns; everything else
comes from the handoff `fetch-handoff` resolves it to.

Nobody is watching. Ask no questions - `AskUserQuestion` has no one to answer it. Nothing
reaches the user except the pull request, a stop, or the no-change exit Step 2 takes for a
handoff HEAD already satisfies.

Every operation named below comes from the backend. Load its files in the order
`defining-backends.md`, `## Where overrides live`, sets, later files overriding earlier by `##`
heading. First:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
```

Run the route check that file opens with before reading on. Where it selects the `gh` route,
load that route's file next:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/backend-github-gh.md
```

Where neither route is available, `backend-github.md` says what that means. Either way, the
project's own files load last:

```
cat .claude/baton.md 2>/dev/null
cat ~/.claude/baton.md 2>/dev/null
```

Then load the rule for every call this skill makes once per issue - `started`, `published` and
`stopped`:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/per-issue-calls.md
```

Two failures are stops, not fallbacks: an operation this skill names that no loaded file
defines, and an operation that fails because its tool is missing or unauthenticated - a
command exiting non-zero, or a named tool the session lacks or cannot authorize. Report
the operation name, the entry that failed, and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`. Never run a command this backend does
not define.

## Where the opening turn came from

Two things in the opening turn bind: the handoff locator, and `launcher=<name>` after it where
it is present - the `## Launcher` entry that started this run. A turn with no `launcher=` was
started by hand, and reads as `launcher=local`. Step 6 launches the reviewer through that same
entry. Anything else the turn carries has the authority of the handoff section it was copied
from, and an optional section stays optional however the turn phrases it.

On a question of code fact the working tree outranks the handoff. Where the two disagree, the
code decides: re-cut the approach against what the tree shows and carry on.

## What this run may do unasked

These need no confirmation:

- `git add`, `git commit` and `git push -u origin <branch>` on the branch the handoff names,
  or on the name Step 2 substitutes where that branch already exists.
- `EnterWorktree` at Step 2, and `ExitWorktree` at Step 6 or at Step 2's no-change exit -
  `remove` with `discard_changes: true` once that step's checks pass, `keep` otherwise.
- `pr-create` on that branch; `started`, `published` and `stopped` on **each issue the header
  names**, one call per issue.
- The `## Launcher` entry `launcher=` names, run once at Step 6 to start
  `/baton:review-handoff <locator> <pr-url>` on the pull request Step 5 opened.
- Dispatching the subagents this run needs - Step 4's claim audit, and that same audit over
  Step 2's no-change evidence. They read and report; nothing they return reaches the tracker
  or the forge except through a step above.
- Deviating from the handoff's approach where the code contradicts it, so long as Step 5's
  body names the deviation.

Everything else is a stop rather than a judgement call:

- Force-push, in any form.
- Pushing to the default branch, or to any branch the handoff does not name.
- Merging the pull request, marking a draft ready, or adding a reviewer.

Those are actions. A judgement this run can make on the evidence - which approach the code
supports - is one it must make rather than end the turn over.

This clears the policy, not the harness: a repo whose permission list omits a command still
prompts for it.

## Step 1 - Load

Run `fetch-handoff` on the locator. Where the entry takes `<id>` or `<comment-id>`, derive
each from the locator as the backend's notes on `fetch-handoff` say. The handoff's header
carries the lines `write-handoff` Step 2 defines; an absent optional line is not a stop.
Where `category` or `pr-base` is absent, `<category>` and `<pr-base>` take the values
`defining-backends.md`, `## Operations`, gives them.

A fetched comment carrying the handoff marker but **no fenced header** is a `write-handoff`
Step 1 pointer, not a handoff. It is a stop. Name the issue and locator the pointer carries -
that is the handoff to run.

Then load the reference file for each header line that needs one, from
`${CLAUDE_PLUGIN_ROOT}/reference/`, and apply it as the file itself says. Where a loaded file and
a step here differ, the file wins:

| Where the header carries | Load |
|---|---|
| a `pr-base` line or a `next` line | `stacked-handoff.md` |
| an `assets` line | `handoff-assets.md` |
| more than one entry on its `issue` line | `bundled-issues.md` |

### `issue` and `closes` are lists

`issue` and `closes` are the paired lists `write-handoff` Step 2 defines. The **first `issue`
entry is the primary issue**, and the one Step 2 names the worktree from.

**Two lists that differ in length are a stop here**, before `EnterWorktree`, quoting both lines
as the handoff wrote them. Never pair what can be paired and guess at the rest.

### The checkout

Verify the checkout before the first edit:

```
git cat-file -e <base>^{commit} 2>/dev/null || git fetch origin
git merge-base --is-ancestor <base> HEAD
```

Run `verify-checkout`; its answer must equal the header's `repo`. A repo that does not
match, or a `base` that is not an ancestor of HEAD, is a stop: the plan addresses code
this clone does not contain. Where the header carries `pr-base`, a loaded `stacked-handoff.md`
replaces the two lines above.

Resolve the `## Launcher` entry `launcher=` names - `local` where the opening turn carried
none - against the loaded files. Stop where no loaded file defines it, or where this session
cannot launch through it - load the tools the entry names, and run the read-only checks its
notes give. A launch that would fail at Step 6 fails here, before anything is built.

Every entry's `<owner>` and `<repo>` follow the placeholder table in `defining-backends.md`,
`## Operations`; the locator is the issue's repository for the whole run. `verify-checkout`
still has to equal the header's `repo` above.

Check reachability with `reachable` when a tracker call fails; it separates a credential error
from an undefined operation.

## Step 2 - Branch and build

Resolve `started` and `verify` against the loaded backend files before the first call below.
Resolving them here is not calling them - `started` runs at the branch cut below, and `verify`
first runs at Step 3.

Find the subagent dispatch tool in this session's tools now; `defining-backends.md`,
`## Tools an unattended run needs`, gives the two names it goes by. Stop where it is absent,
naming the tool and `${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`.

Skip `EnterWorktree` when the session is already in a worktree, which is what a differing pair
here means - a launcher that started the session in one, or a turn resuming from a stop:

```
git rev-parse --path-format=absolute --git-dir --git-common-dir
```

Skip `git switch -c` when HEAD is already on `<branch>`, testing it after `EnterWorktree` in
the directory the build runs in, never in the one the session started in. A turn resuming
from a stop skips `EnterWorktree` by the pair test; `git switch -c` and `started` are skipped
only where HEAD is already on `<branch>`.

Otherwise give the run a worktree of its own. Call `EnterWorktree` with a `name` of
`<issue>-<6 hex>`, where `<issue>` is the **primary** issue - the first entry of the header's
list, never the list itself - and the six characters are what
`od -An -N3 -tx1 /dev/urandom | tr -d ' \n'` prints, so `5-a1b2c3` for issue 5. The worktree
lands at `.claude/worktrees/<name>` on a branch of its own, and the session moves into it.
Every step from here works there; Step 1's checks ran before it, in the directory the session
started in.

**Read the worktree's opening state immediately after that call and before the first edit**,
and keep the reading for the exit below:

```
git status --porcelain
```

### The no-change exit

A handoff whose work is already in the tree has no pull request to open. Before `started` and
the branch cut, ask whether this is such a handoff. Everything below runs in the worktree.

**Ask it exactly where `git switch -c` runs, and skip it wherever that is skipped.**

The tree to ask about is the tip of `<default-branch>` on `origin`. Move the worktree's HEAD
there first:

```
git fetch origin <default-branch>:refs/remotes/origin/<default-branch>
git switch --detach origin/<default-branch>
git merge-base --is-ancestor <base> HEAD
git rev-parse HEAD
```

`<default-branch>` resolves as `${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md` defines
it. Where any of the first three lines exits non-zero, take no exit - continue to `started`,
the branch cut and the build. Keep the fourth line's output as the **checked commit**: the
worktree test and the report below both use it. HEAD satisfies the handoff only where all
three of these hold across the whole of it:

- **The handoff numbers acceptance criteria.** Commands alone cannot carry this exit.
- **Every criterion it numbers** is satisfied by code at HEAD, and the run can name the
  `file:line` there that satisfies it.
- **Every command it names** beside those criteria passes at HEAD.

Anything less is ordinary work: the run re-cuts the approach against what it found, as above,
and builds the rest. `verify` is no part of this evidence either.

Then put that evidence through the claim audit before acting on it, dispatched exactly as Step
4 dispatches it, with the criteria, their `file:line` citations and each command's result as
the claims. The verdict decides the exit:

| The audit's verdicts | The run |
|---|---|
| every claim ACCEPTED | takes the exit |
| a claim CORRECTED | re-read it - the exit stands only where the corrected form still says HEAD satisfies that criterion, and the report carries the corrected form |
| any claim RETRACTED or LABELLED unverified | takes no exit - continue to `started`, the branch cut and the build |

A correction that fixes a line number leaves the exit standing; one narrowing "satisfies
criterion 3" to "satisfies it for the expired case only" cancels it.

**A dispatch that fails here is a stop**, with the evidence gathered so far in the report.

On the exit the run pushes nothing, opens no pull request, runs no `started`, launches no
reviewer, and closes nothing - closing the issue is left to a person reading the report. It
does three things, in this order.

**First the worktree.** Only a worktree this run created is its to remove. Where a launcher
started the session in a worktree, the call is `keep` and nothing further is asked. Where this
run's own `EnterWorktree` created it - in this turn, or in an earlier turn of this session that
stopped and was resumed - an empty `git status --porcelain` at entry and a HEAD still at the
checked commit means `ExitWorktree` with `action: "remove"` and `discard_changes: true`. A
resumed turn that no longer holds the entry reading calls `keep`.

Anything else is `keep`, with `.claude/worktrees/<name>` named in the report and which of the
two readings failed. What the directory holds **now** decides nothing: the handoff's commands
ran in there, and their artifacts are this exit's to discard.

**Then the report**, one file written on `baton:write-deliverables`' short path as a **Run
report**. **It never carries the handoff marker, not even quoted.** It carries the evidence:
the checked commit, as `Checked at <sha>`, then each acceptance criterion with the `file:line`
at that commit that satisfies it, each command the handoff names with its one-line result, and,
where `git log -S` or `git blame` names it, the commit that introduced the satisfying code.

**Last `stopped`** on each issue the header names, with that one file, as
`per-issue-calls.md` walks it.

Then end the turn at `## Done`. This exit is neither the pull request nor a stop.

### The branch cut

Run `started` on each issue the header names, as `per-issue-calls.md` walks it, immediately
before the branch cut below and under that cut's condition: the whole sequence is skipped
exactly where `git switch -c` is skipped, and runs exactly where it runs. `none` skips the call
(`defining-backends.md`, `## Operations`). It runs above the cut, never inside the retry below.

Cut the branch from `<base>`:

```
git switch -c <branch> <base>
```

That command exiting non-zero because `<branch>` already exists is neither a stop nor a reuse:
run it again with `<branch>-<6 hex>`, six fresh characters from the command above, until one
succeeds. From there `<branch>` means the name that succeeded: Step 5 pushes it and Step 6
fetches it.

Build on the existing branch only where the handoff says to.

Follow the approach the handoff records. Constraints written beside the alternatives it
lists already rule those out.

An approach that does not survive contact with the code is yours to re-cut. Record what changed
and the evidence that forced it, for the Step 5 body.

## Step 3 - Test and verify

Add tests that fail against the commit this branch was cut from and pass against the change,
whatever the handoff carries. That commit is `<base>`. Where the handoff numbers acceptance
criteria, each criterion gets at least one of them. The exception is a criterion the handoff
marks as out of any test's reach: the handoff's commands prove that one, and Step 5's body names
it as untested. Follow the conventions of the tests already in the repo.

Then run two checks, in this order:

1. The commands the handoff names beside its acceptance criteria.
2. `verify`, in the form `defining-backends.md`, `## Operations`, gives its value.

A failure of either is a stop. Nothing is committed until both pass.

A handoff naming neither is run with `verify` alone. A handoff naming one and not the other
runs what it names; Step 5's body records which of the two the run had.

## Step 4 - Claim audit

Before the push, dispatch a fresh subagent with the dispatch tool Step 2 found - one whose
context did not write this code - and give it:

- the instruction to run `baton:claim-audit`, naming the **resolved absolute path** of
  `${CLAUDE_PLUGIN_ROOT}/skills/claim-audit/SKILL.md`. Expand the variable here and paste the
  path it prints: the dispatched agent's shell does not carry this session's environment;
- every claim the run intends to make, quoted as it will appear in the body: the handoff's
  commands and `verify` with their results, what the change covers and what it leaves alone,
  and each deviation and its evidence.

Name `claim-audit` in that prompt, so `hooks/gate-subagent-claim-audit.sh` stands down.

The audit's verdict on each claim decides what the body may say:

| Verdict | In the body |
|---|---|
| ACCEPTED | stated as it stands |
| CORRECTED | rewritten to the corrected form |
| RETRACTED | left out |
| LABELLED unverified | moved under the body's `## Unverified claims` heading |

A dispatch that fails here is a stop. Writing the body without the audit is not the fallback.

## Step 5 - Pull request

```
git push -u origin <branch>
```

Write the body on `baton:write-deliverables`' short path, as a **PR description**, to a file
in the scratchpad directory. Beside the issue references below, three things the run knows and
a reviewer cannot recover go in it:

- The handoff's "Not verified here" list where it carries one, copied as it stands under
  the body's `## Not verified here` heading. That heading holds the handoff's list alone.
- Every claim Step 4's audit labelled unverified, placed as its verdict table sets.
- What Step 3 had to check against: the handoff's acceptance criteria and the commands
  that prove them, with each criterion no test covers named as such, or - where it named
  neither - a sentence saying so, and that `verify` alone checked the change.

The body states each audited claim in the form Step 4's verdict table gives it. Neither heading
is written without its source: `## Not verified here` only where the handoff carries its list,
`## Unverified claims` only where the audit labelled at least one claim.

The body carries one issue reference line per issue the header names, in header order, each
chosen by that issue's own `closes` value, written into the body before `pr-create` runs:

| That issue's `closes` value | Line in the body |
|---|---|
| `yes` | the backend's `closes` line, with that issue as `<id>` |
| `no` | the backend's `refs` line, with that issue as `<id>` |

Where the backend's `closes` or `refs` entry is `none`, an issue whose value selects that entry
gets no line. Fill each line's `<owner>`, `<repo>` and `<id>` from the locator, per the
placeholder table Step 1 points to.

Run `pr-create` with that file, with `<category>` and `<pr-base>` as Step 1 resolved them.
Where `<category>` is empty, the backend's notes on its own `pr-create` say what that drops.
`pr-create` opens a draft; marking it ready is a stop, above.

Keep what `pr-create` returns: Step 6 reports it, and nothing else in the run recovers it.

The pull request is open once `pr-create` returns its URL, even where the operation has calls
left to run. A later call in `pr-create` that fails is a stop after Step 5, carrying that URL.

## Step 6 - Report

Remove the worktree first, and only once `origin` holds everything in it:

```
git status --porcelain
git fetch origin <branch>
git rev-parse HEAD
git rev-parse origin/<branch>
```

No output from the first and two equal revisions from the last two: call `ExitWorktree`
with `action: "remove"` and `discard_changes: true`. The count it then reports -
`Discarded 1 commit` - is not a statement about `<branch>`, which keeps its commits on
`origin`.

Either check failing: call `ExitWorktree` with `action: "keep"`.

Then launch the reviewer, where **both checks above passed**: run the `## Launcher` entry
Step 1 resolved from `launcher=`, with `review-handoff` as its `<skill>` and
`<locator> <pr-url>` as its `<args>` - the handoff locator this session opened with and the
pull request URL Step 5 returned.

Run it **once, with no retry**, whatever it returns. A launch that fails is reported rather
than repeated.

Either check above failing holds it back, and is not a stop.

Then run `published` on each issue the header names, as `per-issue-calls.md` walks it, each
with that issue's id, the pull request URL from Step 5, and the same one file written on
`baton:write-deliverables`' short path as a **Run report**, saying what shipped:

- the URL, and the branch - beside the name the handoff asked for, where Step 2 cut
  `<branch>-<6 hex>` instead;
- how the handoff's commands and `verify` came out, and any deviation Step 2 recorded;
- the reviewer launch: the entry run and what it returned, or which of the two checks above
  held it back;
- after a `keep`, the worktree path `.claude/worktrees/<name>` and which of the two checks
  failed.

Where the pull request body carries a `## Not verified here` heading, that file also says checks
wait there for a person to run; where it carries `## Unverified claims`, that claims wait there
for a person to probe. Each of those statements points to its heading without repeating the
entries under it.

The reviewer launch and the pointer to each of those headings are required content whatever
contract **Run report** resolves to.

## Stopping

Every stop above takes one of two shapes, set by whether Step 5 has opened the pull request.
Both files are written on `baton:write-deliverables`' short path as a **Run report**:

- Before it: push nothing, open no pull request, and run `stopped` with one file naming the
  step and what stopped it.
- After it, in Step 5's remaining `pr-create` calls or Step 6: push nothing further and leave
  the pull request open. Run `stopped` with one file naming the step, what stopped it, and the
  pull request URL.

Either shape runs `stopped` on each issue the header names, as `per-issue-calls.md` walks it,
with its exceptions for a stop inside the `published` sequence and for a stop before the
header's list parsed.

**Step 2's no-change exit borrows the first shape and is not a stop.** Its file carries Step
2's evidence rather than a step and a blocker, and it settles its own worktree on Step 2's two
readings.

**A stop before Step 6's launch never launches the reviewer, and the `stopped` file says
so.** **A stop after the launch ran - a failed `published` - says the reviewer was started**,
naming the entry run and what it returned.

No stop calls `ExitWorktree`. The `stopped` file names the worktree path
`.claude/worktrees/<name>` wherever the worktree still stands, and the branch the run built
on. A stop after Step 6's removal is the one with no path to name.

Then end the turn. The session stays open, so a reply there resumes the run from the answer
- still in the worktree and still on `<branch>`, which is what Step 2 skips its opening calls
for.

## Done

Three exits end here. Report the pull request URL, the branch and how the handoff's commands
and `verify` came out - or, for Step 2's no-change exit, that HEAD already satisfies the
handoff, the evidence saying so, and that no branch was pushed and no pull request opened - or
the blocker, the step it stopped at, and the pull request URL when Step 5 opened one.

Name every issue the header carried and what reached it: the reference line it got in the
body, or that it got none under a `none` entry, and whether `started`, `published` or
`stopped` ran on it.

Report the reviewer launch too, in whichever form Step 6 recorded it. The reviewer is a
separate session: this one does not wait for it, watch it, or report anything about how it
went.
