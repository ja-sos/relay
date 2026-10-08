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
request, a stop, or the no-change exit Step 2 takes for a handoff HEAD already satisfies.

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

Two failures are stops, not fallbacks: an operation this skill names that no loaded file
defines, and an operation that fails because its tool is missing or unauthenticated - a
command exiting non-zero, or a named tool the session lacks or cannot authorize. Report
the operation name, the entry that failed, and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`. Never run a command this backend does
not define - an improvised equivalent writes to a tracker the project did not choose.

## Where the opening turn came from

A launcher usually starts this session, so the opening turn is often machine-generated even
though the harness presents it exactly like a developer's own words. Two things in it bind: the
handoff locator, and `launcher=<name>` after it where it is present - the `## Launcher` entry
that started this run. A turn with no `launcher=` was started by hand, and reads as
`launcher=local`. Step 7 launches the reviewer through that same entry. Anything else the turn
carries has the authority of the handoff section it was copied from, and an optional section
stays optional however the turn phrases it.

The handoff is a plan written against `base`, so on a question of code fact the working tree
outranks it. Where the two disagree, the code
decides: re-cut the approach against what the tree shows and carry on.

## What this run may do unasked

Invoking this skill is the request to commit and publish, so the standing rule against pushing
unasked does not cover the run. These need no confirmation:

- `git add`, `git commit` and `git push -u origin <branch>` on the branch the handoff names,
  or on the name Step 2 substitutes where that branch already exists.
- `EnterWorktree` at Step 2, and `ExitWorktree` at Step 7 or at Step 2's no-change exit -
  `remove` with `discard_changes: true` once that step's checks pass, `keep` otherwise. Their
  tool descriptions otherwise hold `EnterWorktree` to an explicit instruction and
  `ExitWorktree` to the user asking; for this run, these steps are that instruction.
- `pr-create` on that branch; `pr-update`, `request-reviewer`, `thread-reply` and
  `pr-comment` on the pull request it opens; `started`, `published` and `stopped` on **each
  issue the header names**, one call per issue. A header naming several issues is the
  authorization to move all of them: whoever wrote it decided this one pull request settles
  that bundle.
- `stack-link` at Step 5, where the header carries `pr-base`. It writes to the pull request
  below, which belongs to another handoff, so it is named here rather than covered by
  `pr-create`: the header asking for a stacked base is the authorization to register the
  layer in that stack.
- The `## Launcher` entry `launcher=` names, run once at Step 7 to start
  `/baton:review-handoff <locator> <pr-url>` on the pull request Step 5 opened. Every pull
  request this skill opens gets that review, so the skill's invocation is the authorization.
  The header's `next` is `review-handoff` Step 6's to launch, not this run's.
- Dispatching the subagents this run needs - Step 4's claim audit, that same audit over Step
  2's no-change evidence, and a reviewer an `agent:` entry names. They read and report;
  nothing they return reaches the tracker or the forge except through a step above.
- Reading the files the header's `assets` line names, under the `root` the backend's
  `## Assets` section gives. They are inputs to the work, resolved at Step 1, and reading them
  is what the line exists for.
- Deviating from the handoff's approach where the code contradicts it, so long as Step 5's
  body names the deviation.

Everything else is a stop rather than a judgement call, because an unattended run cannot obtain
the ask that would authorize it:

- Force-push, in any form.
- Pushing to the default branch, or to any branch the handoff does not name.
- Merging the pull request, marking a draft ready, or adding a reviewer beyond what
  `request-reviewer` names. That operation is the project's standing answer to who reviews
  this, given ahead of the run, so Step 6 runs it without asking.
- Writing, moving or deleting anything under the `## Assets` `root`, and copying an asset into
  the worktree or a commit. Assets are read-only to the run: the folder is shared across every
  repository on the machine, and some of what it holds is not cleared to live in one.

Those are actions. A judgement this run can make on the evidence - which approach the
code supports, whether a review finding holds - is one it must make rather than end the turn
over.

This clears the policy, not the harness: a repo whose permission list omits a command still
prompts for it.

## Step 1 - Load

Run `fetch-handoff` on the locator. Where the entry takes `<id>` or `<comment-id>`, derive
each from the locator as the backend's notes on `fetch-handoff` say. The handoff's header
carries the lines `write-handoff` Step 2 defines; an absent optional line is not a stop.
Where `category` or `pr-base` is absent, `<category>` and `<pr-base>` take the values
`defining-backends.md`, `## Operations`, gives them; without `pr-base` the branch is cut from
`<base>`.

A handoff with a `pr-base` line is a stop where the loaded `pr-create` entry never contains
`<pr-base>`.

A fetched comment carrying the handoff marker but **no fenced header** is a `write-handoff`
Step 1 pointer, not a handoff. It is a stop. Name the issue and locator the pointer carries -
that is the handoff to run - rather than building from a comment that records no branch, no
base and no approach.

### `issue` and `closes` are lists

`issue` and `closes` are the paired lists `write-handoff` Step 2 defines. The **first `issue`
entry is the primary issue**, and the one Step 2 names the worktree from.

**Two lists that differ in length are a stop here**, before `EnterWorktree`, quoting both lines
as the handoff wrote them. Pairing what can be paired guesses at the rest, and a guess landing
on `yes` shuts an issue the handoff said to leave open - on merge, with nothing left to undo
it.

Three operations then run **once per issue, in header order**, each taking one issue as its
`<id>` and never the list: `started` at Step 2, `published` at Step 7, and `stopped` on any
stop. Where one of those calls fails, the run stops on it and the report names the operation,
the issue it failed on, and every issue after that one in the list as **not reached** - that
list is what tells a person which tickets are still theirs to move by hand.

Verify the checkout before the first edit:

```
git cat-file -e <base>^{commit} 2>/dev/null || git fetch origin
git merge-base --is-ancestor <base> HEAD
```

Run `verify-checkout`; its answer must equal the header's `repo`. A repo that does not
match, or a `base` that is not an ancestor of HEAD, is a stop: the plan addresses code
this clone does not contain.

**Where the header carries `pr-base`, run this pair instead of the second line:**

```
git cat-file -e <base>^{commit} 2>/dev/null || git fetch origin <base>
git cat-file -e <base>^{commit}
```

`base` is then a commit on the layer below, which is unmerged by definition, so it is not an
ancestor of the default branch this clone arrives on and `--is-ancestor <base> HEAD` fails on
every stacked handoff. Step 2 asks the same question of `origin/<pr-base>`, the branch the
work actually sits on, where `base` does have to be an ancestor.

What does not move is this step's own question: does this clone hold `base` at all. The first
line answers it with a fetch and then discards the answer - `||` makes the whole line succeed
whenever the fetch does, and a fetch that silently brought nothing exits 0. The second line is
what turns a missing `base` into a stop here, rather than into a confusing `pr-base` failure
at Step 2.

Also resolve `stack-link` against the loaded backend files, for the same reason Step 2
resolves `started` early - an operation no loaded file defines is a stop, and one reached
after `EnterWorktree` leaves a worktree standing. Resolve it only where the header carries
`pr-base`, since that is the only case Step 5 calls it in.

Resolve the `## Launcher` entry `launcher=` names - `local` where the opening turn carried
none - and, where the header carries `next`, the entry its first value names, against the same
loaded files. Stop where no loaded file defines either one. Step 7 launches the reviewer
through the first, and the reviewer carries the second; a name that cannot launch is
cheapest caught here, before anything is built.

Every entry's `<owner>` and `<repo>` follow the placeholder table in `defining-backends.md`,
`## Operations`; the locator is the issue's repository for the whole run. `verify-checkout`
still has to equal the header's `repo` above: that check is about the checkout, and it is
unaffected by where the issue lives.

Check reachability with `reachable` when a tracker call fails; it separates a credential error
from an undefined operation. A credential error is the session, not the plan, and the backend
records what each one means.

### `assets`

**Where the header carries `assets`, resolve every path it lists - here, and before
`EnterWorktree`.** The line is space-separated, and each entry is a path relative to the
`root` of the backend's `## Assets` section. Check the root first, then each path:

```
test -d "<root>"
test -e "<root>/<path>"
```

Four things are a stop, each **naming every path that did not resolve** rather than the first:

- No loaded backend file defines `## Assets`. A cloud run always reaches this stop
  (`defining-backends.md`, `## Sections`, on `## Assets`); the report says so rather than
  reporting a broken backend.
- `root` fails what `defining-backends.md`, `## Sections`, on `## Assets`, requires of it.
  Check it before any path.
- A path is invalid by `write-handoff` Step 2's validity rule. Never quote around an invalid
  path to make it run - it is a stop.
- A path `test -e` does not find under `root`.

Every read here is outside the checkout, so a harness that prompts for reads outside the
working directory prompts for these - and an unattended run has nobody to answer. A read
that is denied or left unanswered is a path that did not resolve, and it takes the stop
above; never work around the denial, and never carry on without the file.

The stop is here rather than at the first read for the reason `started` and `verify` are
resolved early: a stop after `EnterWorktree` leaves a worktree standing. Never substitute a
path that resolves for one that does not, and never carry on with the assets that did resolve
- the handoff listed all of them because the work needs all of them.

Everything under `root` stays read-only for the rest of the run. Writing, moving or deleting
under it, and copying an asset into the worktree or a commit, are on the list of things this
run may not do unasked, above - so a handoff asking for any of them is asking for a stop, and
the stop is taken when the run reaches that instruction rather than here.

Resolve a body path under `root` only where the body names it as an asset (`write-handoff`
Step 3) and the `assets` line lists it: a path the line does not carry is not an asset this
run has, whatever the body calls it. Where a body path is genuinely ambiguous,
the checkout decides, as it does on every other question of code fact.

## Step 2 - Branch and build

Resolve `started` and `verify` against the loaded backend files before the first call below:
an operation no loaded file defines is a stop, and a stop reached after `EnterWorktree`
leaves the run's worktree standing, once per relaunch. Resolving them here is not calling
them - `started` runs at the branch cut below, where the run has committed to changing code,
and `verify` first runs at Step 3.

Find the subagent dispatch tool in this session's tools now, in the same breath and for the
same reason; `defining-backends.md`, `## Tools an unattended run needs`, gives the two names it
goes by. Stop where it is absent, naming the tool and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`. That stop costs a run that has not
built anything; the same stop at Step 4 discards a finished, tested, reviewed branch that was
never pushed.

Two of the calls below are skipped on a condition of their own, because neither survives a
second run. Skip `EnterWorktree` when the session is already in a worktree, which is what a
differing pair here means - a launcher that started the session in one, or a turn resuming
from a stop:

```
git rev-parse --path-format=absolute --git-dir --git-common-dir
```

Skip `git switch -c` when HEAD is already on `<branch>`, testing it after `EnterWorktree` in
the directory the build runs in, never in the one the session started in. A turn resuming
from a stop skips all three and goes straight to the build. Test the pair rather than the
branch name: a fresh run in a clone that happens to sit on `<branch>` would otherwise skip
isolation entirely and build in the working tree it was meant to leave alone.

Otherwise give the run a worktree of its own, so two runs started in one checkout do not
edit one working tree. Call `EnterWorktree` with a `name` of `<issue>-<6 hex>`, where
`<issue>` is the **primary** issue - the first entry of the header's list, never the list
itself - and the six characters are what `od -An -N3 -tx1 /dev/urandom | tr -d ' \n'` prints,
so `5-a1b2c3` for issue 5. The worktree lands at `.claude/worktrees/<name>` on a branch of
its own, and the session moves into it. Every step from here works there; Step 1's checks ran
before it, in the directory the session started in.

The name comes from one issue rather than the branch because a branch-named directory is
long enough to push a test binary's path past the 259 characters Windows `CreateProcess`
accepts, and the run then reports a failing suite in which no test failed. The random suffix
keeps two handoffs on one issue in separate directories.

**Read the worktree's opening state immediately after that call and before the first edit**,
and keep the reading for the exit below:

```
git status --porcelain
```

It is what tells that exit whether the directory held anything before this run, and it is
worthless taken later: the handoff's commands run in there, and a suite's own `dist` or cache
answers it exactly as a source file the run wrote and never added would. Taken here, before
anything has run, it cannot confuse the two.

Seeding is `EnterWorktree`'s and not this step's: a worktree checks out tracked files only,
and it copies in whatever the project lists in `.worktreeinclude`. That list is the
project's to write, and it is a prerequisite rather than a detail - a gitignored
`.claude/settings.local.json` that is not on it does not follow the session into the
worktree, and the run stalls on a permission prompt with nobody there to answer.

### The no-change exit

A handoff whose work is already in the tree has no pull request to open. Step 3 requires tests
that fail at the branch point and pass against the change, and against a HEAD that already does
what the handoff asks there is no such test to write. So before `started` and the branch cut,
ask whether this is such a handoff. Everything below runs in the worktree, which is what keeps
the handoff's commands out of the directory the session started in.

**Ask it exactly where `git switch -c` runs, and skip it wherever that is skipped** - HEAD
already on `<branch>` is a turn resuming from a stop, and what satisfies the handoff there is
the run's own unpushed work. Taking the exit on that evidence would report a branch this run
built as code that was already in the tree, then delete it: the one reading of "already
satisfied" that is never true. The gate is the branch cut's, not `EnterWorktree`'s, for the
reason `started` takes the same one.

**A handoff carrying `pr-base` never takes this exit**, before any of the below is asked. Its
work sits on an unmerged layer that HEAD does not carry, so a HEAD that looks satisfied is
evidence about a different tree - and the layer above names this layer's branch as its base,
which only the build will push.

The tree to ask about is the tip of `<default-branch>` on `origin`, the branch this one would
merge back into. The worktree's HEAD is wherever `EnterWorktree` or a launcher left it, which
need not be that tip, so move it there first:

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

- **The handoff numbers acceptance criteria.** Commands alone cannot carry this exit: a
  handoff may name commands and no criteria, and a project suite that passes at HEAD says
  nothing about work nobody did.
- **Every criterion it numbers** is satisfied by code at HEAD, and the run can name the
  `file:line` there that satisfies it.
- **Every command it names** beside those criteria passes at HEAD.

Anything less is ordinary work: the run re-cuts the approach against what it found, as above,
and builds the rest. `verify` is no part of this evidence either.

Then put that evidence through the claim audit before acting on it, dispatched exactly as Step
4 dispatches it - the same skill named the same way, at the same resolved absolute path,
through the dispatch tool found above - with the criteria, their `file:line` citations and each
command's result as the claims. The verdict decides the exit:

| The audit's verdicts | The run |
|---|---|
| every claim ACCEPTED | takes the exit |
| a claim CORRECTED | re-read it - the exit stands only where the corrected form still says HEAD satisfies that criterion, and the report carries the corrected form |
| any claim RETRACTED or LABELLED unverified | takes no exit - continue to `started`, the branch cut and the build |

A correction that fixes a line number leaves the exit standing; one narrowing "satisfies
criterion 3" to "satisfies it for the expired case only" has destroyed the premise and cancels
it. This is the claim a person closes an issue on. An unaudited one closes an issue whose work
nobody did.

**A dispatch that fails here is a stop**, and Step 4's reason is not why. There the branch is
finished and the stop discards it; here nothing is built, so the stop costs a run that had
nothing to lose - and the alternative is worse in both directions. Taking the exit unaudited
posts the one claim this run must not get wrong. Continuing to the build sends the run to
Step 3 for a change the tree already carries, where it can write no test that fails at the
branch point. Stop here instead, with
the evidence gathered so far in the report, so a person can judge the close by hand.

On the exit the run pushes nothing, opens no pull request, runs no `started`, launches no
reviewer, and closes nothing - closing the issue is left to a person reading the report. It
does three things, in this order.

**First the worktree**, because the report names its path wherever it still stands and so
cannot be written before the decision. Only a worktree this run created is its to remove.
Where a launcher started the session in a worktree, the call is `keep` and nothing further is
asked. Where this run's own `EnterWorktree` created it - in this turn, or in an earlier turn of
this session that stopped and was resumed - two readings are the whole test: an empty
`git status --porcelain` at entry and a HEAD still at the checked commit means this run wrote
nothing into that directory, and the exit calls `ExitWorktree` with `action: "remove"` and
`discard_changes: true`. A resumed turn that no longer holds the entry reading calls `keep`.

Anything else is `keep`, with `.claude/worktrees/<name>` named in the report - and say which
of the two failed, since a dirty entry state means the run inherited something rather than left
it. What the directory holds **now** decides nothing: the handoff's commands ran in there and
their artifacts are this exit's to discard, having been written by a check rather than by a
change. Step 7's `origin` comparison has nothing to ask here either, since this exit pushes no
branch for `origin` to hold.

**Then the report**, one file written under `baton:write-deliverables` as a **Run report**.
**It never carries the handoff marker, not even quoted.** It carries the evidence: the checked
commit, as `Checked at <sha>`, then each acceptance criterion with the `file:line` at that
commit that satisfies it, each command the handoff names with its one-line result, and, where
`git log -S` or `git blame` names it, the commit that introduced the satisfying code. Where the
header carries `next`, the report also quotes the locator it did not launch and says the layer
above was not started: this report is the only place the locator reaches anyone.

**Last `stopped`**, once per issue the header names, in header order, each call with that
issue's id and that one file. A failure part-way through the list ends the run there, naming
the operation, the issue it failed on, and every issue after it as not reached - the shape
Step 1 sets for `started` and `published`.

Then end the turn at `## Done`. This exit is neither the pull request nor a stop: nothing went
wrong, and nothing shipped.

### The branch cut

Run `started` once per issue the header names, in header order, immediately before the branch
cut below, under that cut's condition rather than one of its own: the whole sequence is
skipped exactly where `git switch -c` is skipped, and runs exactly where it runs. Each call
takes one issue - the tracker moves every bundled ticket's status, and the branch cut is the
moment implementation starts on all of them. A failure part-way through the list is the stop
Step 1 describes, naming the issue it failed on and the ones after it as not reached.

`none` skips the call (`defining-backends.md`, `## Operations`). The branch cut's gate, and
not `EnterWorktree`'s, is what holds the call to one per branch this run cuts - a turn
resuming from a stop skips all three, while a launcher that started the session in a worktree
skips only `EnterWorktree` and still cuts the branch - unless that worktree already sits on
`<branch>`, which is indistinguishable from a resume and skipped as one. It runs
above the cut rather than inside the retry below, which would fire it once per attempt.

The gate holds the sequence to one pass per branch cut, and not to one call per issue for
all time: a stop part-way through the list leaves the branch uncut, so the resuming turn
finds HEAD off `<branch>`, cuts it, and runs the whole list again from the first issue. Every
issue ahead of the failure therefore takes a second `started`, this one behind a call that
already succeeded. What that asks of `started` is that repeating it be harmless - moving a
ticket that is already moved - and that is what buys a partial failure its freedom from
bookkeeping carried across the stop. An entry that cannot be repeated safely is one the
project writes as `none`, which gives up the call on every issue rather than duplicating it
on some.

Where the header carries no `pr-base`, the branch is cut from `<base>`:

```
git switch -c <branch> <base>
```

Where it carries one, the branch is cut from that branch's tip on `origin` instead, because
the layer below has pushed commits since the plan was formed and this layer's work belongs on
top of all of them:

```
git fetch origin <pr-base>:refs/remotes/origin/<pr-base>
git merge-base --is-ancestor <base> origin/<pr-base>
git switch -c <branch> origin/<pr-base>
```

The fetch names both sides of the refspec on purpose. A clone made with `--single-branch` -
which `--depth 1` implies, and which is how a cloud run's checkout arrives - narrows
`remote.origin.fetch` to the default branch alone, and a bare `git fetch origin <pr-base>`
there updates `FETCH_HEAD` and creates no `origin/<pr-base>` for the next two lines to name.
The explicit destination creates it in a narrowed clone and in a wildcard one alike.

Either of the first two exiting non-zero is a stop. A failed fetch means the layer below has
not pushed `<pr-base>` yet, so this run was started out of order. A failed ancestor check
means `<pr-base>` is not the branch the plan was formed on top of, whatever its name says, and
the `file:line` citations in the handoff resolve against a history that branch does not carry.

The third exiting non-zero because `<branch>` already exists is neither a stop nor a reuse:
run it again with `<branch>-<6 hex>`, six fresh characters from the command above, until one
succeeds. From there `<branch>` means the name that succeeded: Step 5 pushes it and Step 7
fetches it.

Build on the existing branch only where the handoff says to.

Follow the approach the handoff records. Constraints written beside the alternatives it
lists already rule those out.

An approach that does not survive contact with the code is yours to re-cut. A pull request
naming its deviation is worth more than a stop naming the problem: the deviation gets
reviewed, the stop waits for someone to look. Record what changed and the evidence that
forced it, for the Step 5 body.

## Step 3 - Test and verify

Add tests that fail against the commit this branch was cut from and pass against the
change, whatever the handoff carries. Where it numbers acceptance criteria, each criterion
gets at least one of them. The exception is a criterion the handoff marks as out of any
test's reach: the handoff's commands prove that one, and Step 5's body names it as untested.
Follow the conventions of the tests already in the repo.

That commit is `<base>` for an ordinary handoff, and `origin/<pr-base>` for a stacked one -
the branch point Step 2 used, not the header's `base`. A stacked branch carries the layer
below, so a test run at `<base>` measures this change against a tree missing that layer's
work, and a test that fails there may be failing on the layer below rather than on anything
this run wrote.

Then run two checks, in this order:

1. The commands the handoff names beside its acceptance criteria.
2. `verify`, in the form `defining-backends.md`, `## Operations`, gives its value.

A failure of either is a stop.

Nothing is committed until both pass - here, and again at each later point this pair runs.

A handoff naming neither is run with `verify` alone. A handoff naming one and not the other
runs what it names; Step 5's body records which of the two the run had.

## Step 4 - Review loop and claim audit

Run `code-review` with an empty `<target>`, so it reviews the working tree this run wrote,
and with `<locator>` set to the handoff locator this session opened with. An entry that
checks acceptance criteria reads them from the handoff there.

### Severity

Load the severity and disposition scales this run shares with its reviewer:

```
cat ${CLAUDE_PLUGIN_ROOT}/reference/reviewing-run-output.md
```

Classify every finding against its "Severity" section before deciding anything about it. Its
"Severity" and "Dispositions" sections apply to this run; every other section there governs a
review of this run's output by another session, and none of it applies here.

### The loop

1. Apply every Critical and Important finding the run can fix. Apply a Minor one only where
   the fix is smaller than the paragraph explaining why it was left.
2. Run the handoff's commands and `verify`, in that order. A failure of either is a stop,
   the same as Step 3's, at every turn of the loop.
3. Run `code-review` again, with the same `<target>` and `<locator>`.

The loop ends when a round leaves no Critical or Important finding the run can fix, or when
three `code-review` rounds have run, whichever comes first. The opening run above is the first
of those three, so item 3 fires at most twice. Neither exit is a stop.

The cap ends the reviewing, not the fixing. Every round's findings go through items 1 and 2,
the third round's included: apply what it found, run both checks, then end without a fourth
`code-review`. What the cap costs is a review of those last fixes.

Give a finding the run cannot fix the disposition the reference's "Dispositions" section maps
its reason to, and say which reason: "could not fix" on its own tells a reviewer nothing.

Every finding still standing when the loop ends goes in the Step 5 body - the Critical and
Important ones the run could not fix, and each Minor one it left - with its severity and the
reason it stands.

Keep the rest too, round by round: every finding each `code-review` returned, with its
severity and what the loop did with it. The body needs only the ones still standing, so
nothing else here would hold on to a finding the loop fixed - and Step 7's report names every
finding, applied ones included. A round's output discarded once its fixes land cannot be
recovered later.

### The claim audit

The loop leaves the run holding a set of claims it is about to put in front of a reviewer:
what the tests did, what the change covers, each deviation from the handoff and the evidence
that forced it. The run wrote the code, so it is the worst-placed context to judge them.

Before the push, dispatch a fresh subagent with the dispatch tool Step 2 found - one whose
context did not write this code - and give it:

- the instruction to run `baton:claim-audit`, naming the **resolved absolute path** of
  `${CLAUDE_PLUGIN_ROOT}/skills/claim-audit/SKILL.md`. Expand the variable here and paste the
  path it prints: the dispatched agent's shell does not carry this session's environment, so
  the unexpanded form reads as a literal and the audit runs without its checklist. A path
  rather than the skill name, because an agent type carrying no `Skill` tool can still `Read`;
- every claim the run intends to make, quoted as it will appear in the body: the handoff's
  commands and `verify` with their results, what the change covers and what it leaves alone, each deviation and its
  evidence, and each finding the loop left standing.

Name `claim-audit` in that prompt, so `hooks/gate-subagent-claim-audit.sh` stands down.

The audit's verdict on each claim decides what the body may say:

| Verdict | In the body |
|---|---|
| ACCEPTED | stated as it stands |
| CORRECTED | rewritten to the corrected form |
| RETRACTED | left out |
| LABELLED unverified | moved under the body's `## Unverified claims` heading |

A dispatch that fails here is a stop. Step 2 has already established the tool exists, so a
failure at this point is the dispatch and not the launcher. Writing the body without the audit
is not the fallback: an unaudited claim is what this step exists to keep out of the pull
request.

## Step 5 - Pull request

```
git push -u origin <branch>
```

Write the body under `baton:write-deliverables`, as a **PR description**, to a file in
the scratchpad directory. Beside the issue references and standing findings below, four
things the run knows and a reviewer cannot recover go in it:

- The handoff's "Not verified here" list where it carries one, copied as it stands under
  the body's `## Not verified here` heading. That heading holds the handoff's list alone.
- Every claim Step 4's audit labelled unverified, placed as its verdict table sets. They are
  statements the run made and could not probe, kept apart from the handoff's checks on a
  running application.
- What Step 3 had to check against: the handoff's acceptance criteria and the commands
  that prove them, with each criterion no test covers named as such, or - where it named
  neither - a sentence saying so, and that `verify` alone checked the change.
- Where Step 4's loop ended on its cap: that it did, and which fixes the last round applied,
  since no `code-review` ran over them.

That body carries the issue reference lines this step's table below chooses, written into it
before `pr-create` runs: the operation sends a file, so a line added after the call reaches
nothing, and `pr-update` at Step 6 is the only way back to a body already posted.

Run `pr-create` with that file, with `<category>` and `<pr-base>` as Step 1 resolved them.
Where `<category>` is empty, the backend's notes on its own `pr-create` say what that drops.

The body states each audited claim in the form Step 4's verdict table gives it, a labelled
one listed rather than dropped so a reviewer knows which claims to probe. Neither heading is
written without its source: `## Not verified here` only where the handoff carries its list,
`## Unverified claims` only where the audit labelled at least one claim.

The findings the loop left standing go in the body as well, each with its severity and the
reason it stands.

`pr-create` opens a draft, as the backend's notes on it say. An unattended run's branch has
been reviewed by nobody but itself, and a draft says so to everyone looking at the pull
request list. Marking it ready is a stop, above - the
person who reads the branch does that.

Then, **only where the header carries `pr-base`**, run `stack-link` with the pull request
`pr-create` returned and that branch below it. It registers this layer in the stack its base
belongs to. `none` skips the call (`defining-backends.md`, `## Operations`). A `stack-link`
failure after `pr-create` succeeded is a stop of the second shape below - the pull request is
open, and the report says the layer went unregistered.

The issue references come from the header, because a merged `closes` shuts an issue whatever
else is outstanding. The body carries **one line per issue the header names**, in header order,
each issue's line chosen by that issue's own `closes` value:

| That issue's `closes` value | Line in the body |
|---|---|
| `yes` | the backend's `closes` line, with that issue as `<id>` |
| `no` | the backend's `refs` line, with that issue as `<id>` |

Where the backend's `closes` or `refs` entry is `none`, an issue whose value selects that entry
gets no line, and the project links it to the pull request by its own means.

A header naming one issue writes one line, unless the entry its value selects is `none`.
`closes` is judged per entry, so a bundle that finishes one issue and leaves another open
writes a `closes` line for the first and a `refs` line for the second: a `closes` line on the
second would shut it on merge whatever remains open on it, and the run has no way to reopen it.

An issue whose line goes missing from the body is unlinked on merge. Nothing errors - the pull
request is valid without it, and the ticket never moves.

Fill each line's `<owner>`, `<repo>` and `<id>` from the locator, per the placeholder table
Step 1 points to. The reference names the issue's repository, which is not this pull
request's wherever the handoff was recorded for a repository other than the issue's. Every
issue the header names resolves against that one repository, the locator's.

Keep what `pr-create` returns. Step 6 addresses the pull request by it and Step 7 reports
it, and nothing else in the run recovers it.

The pull request is open once `pr-create` returns its URL, even where the operation has calls
left to run. A later call in `pr-create` that fails is a stop after Step 5, carrying that URL:
taken for a stop before Step 5, it leaves an open pull request the issue never hears of.

## Step 6 - Review round

Skip this step when `request-reviewer` is `none`. That is the only thing that skips it: the
round runs on whatever entry form `## Review` uses.

1. Run `review-list` and `pr-comments`, and keep their combined output.
2. Run `request-reviewer` on the pull request, and record `date +%s` as the wait's start.
3. Wait until a successful run of both returns output different from the kept copy, or
   until `review-wait` minutes have passed, capped at 60 (`defining-backends.md`,
   `## Operations`). The wait takes one of two forms, picked by how this backend defines
   `review-list` and `pr-comments`:
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
5. On timeout, go to Step 7. Its report is where the timeout is said: that the round was
   requested and no review arrived, and - because a timeout cuts short what this round found,
   not what the run has to report - Step 4's findings and their dispositions alongside it. A
   reviewer that answers later is `baton:address-review`'s to handle, not this run's.
6. Otherwise collect the round and build its inventory as `baton:address-review` Steps 2
   and 3 do. Read those two steps rather than invoking the skill:

   ```
   awk '/^## Step 2 /{f=1} /^## Step 4 /{f=0} f' \
     ${CLAUDE_PLUGIN_ROOT}/skills/address-review/SKILL.md
   ```

   Empty output means a renamed heading, and that is a stop rather than an empty inventory.

   Step 3's end-of-turn stop is not this run's: judge each finding here, and give it a
   severity from Step 4's table whether or not it holds. Apply the findings
   that hold and run the handoff's commands and `verify` over them - a failure of either is a
   stop. Run them here rather than leaving them to the loop below: that loop's checks sit after
   the findings it applies, so a round applying none skips them, and these fixes would reach
   the pull request with nothing run over them.

   Then commit those fixes and run Step 4 over them with `<target>` set to `<branch>` rather
   than empty, committing each loop round's fixes before the `code-review` that follows them.
   After Step 5's push an empty `<target>` shows only uncommitted fixes. Step 4 runs here with
   a fresh cap of three `code-review` rounds - a failure at any of its checks is a stop too -
   and its claim audit over the claims these fixes add or change, which is a second dispatch
   and not a re-reading of the first audit's table.

   Then, in this order: push once, run `pr-update` with a rewritten body, and answer each
   thread with `thread-reply` and anything that arrived outside a thread with `pr-comment`.
   The rewritten body is written the way Step 5 writes one, and starts from Step 5's body
   rather than from this round alone, because this round's audit rules only on the claims
   these fixes add or change. A claim from Step 5's body stays unless this round's audit ruled
   on it, and then takes the form Step 4's verdict table gives. A finding from Step 5's body
   stays unless a fix this round resolved it. To those the body adds the claims this round's
   audit ruled on, each in the form Step 4's verdict table gives, and the findings this
   round's loop left standing. `## Not verified here` holds the handoff's list as Step 5
   copied it. `## Unverified claims` is written wherever a claim from either audit sits under
   it, so a claim this round's audit labels gets the heading even where Step 5's body had none.
   The body also carries - the lines easiest to lose - **every** issue reference Step 5's
   table chose, one per issue the header names and each keeping the form that table gave it.
   An issue Step 5 wrote no line for, under a `none` entry, gets none here either.
   `pr-update` posts the body as `defining-backends.md`, `pr-update`, describes, so a
   reference line the rewrite drops is gone from the pull request - silently, since a body
   missing a reference is as valid as one carrying it. The body describes the
   branch as it is now, and never narrates the round that changed it.

One round, with no re-request. A finding that holds is yours to judge on the diff, the
same as a Step 4 finding - `request-reviewer` names who reviews, not who decides.

## Step 7 - Report

Remove the worktree first, and only once `origin` holds everything in it:

```
git status --porcelain
git fetch origin <branch>
git rev-parse HEAD
git rev-parse origin/<branch>
```

No output from the first and two equal revisions from the last two: call `ExitWorktree`
with `action: "remove"` and `discard_changes: true`. `remove` refuses without that flag
once the worktree's branch holds a commit, and these checks are what stands in for the
confirmation it asks for. The count it then reports - `Discarded 1 commit` - is not a
statement about `<branch>`: removal deletes the worktree directory and the branch
`EnterWorktree` opened, while `<branch>` keeps its commits and `origin` already has them.

Either check failing: call `ExitWorktree` with `action: "keep"`. Whatever the check found
exists nowhere but that directory.

`git status --porcelain` counts untracked files, so a build artifact the run left behind
sends it down the `keep` path. That is the right way to be wrong: the same output is also
how a source file the run wrote but never added looks, and `remove` cannot be undone.

Then launch the reviewer, where **both checks above passed**: run the `## Launcher` entry
Step 1 resolved from `launcher=`, with `review-handoff` as its `<skill>` and
`<locator> <pr-url>` as its `<args>` - the handoff locator this session opened with and the
pull request URL Step 5 returned. The URL is passed rather than derived from the header's
`branch`, because Step 2 may have cut `<branch>-<6 hex>` instead.

Run it **once, with no retry**, whatever it returns. Two reviewers on one pull request race to
push to the same branch, and a launch that fails is reported rather than repeated.

Either check above failing holds it back, and is not a stop: `origin` does not hold this
branch's work, so the reviewer would review a tree other than the one in that directory.

The header's `next` is not launched here: the reviewer carries it.

Then run `published` once per issue the header names, in header order, each with that issue's
id, the pull request URL from Step 5, and the same one file written under
`baton:write-deliverables` as a **Run report**, saying what shipped: the URL, the branch -
beside the name the handoff asked for, where Step 2 cut `<branch>-<6 hex>` instead - how
the handoff's commands and `verify` came out, any deviation Step 2 recorded, and whether Step 6
ran, timed out, or was skipped - skipped meaning only that `request-reviewer` is `none`, and
said so that a reader takes it as no external review having run rather than as nothing worth
mentioning. After a `keep`, that file also names the worktree path `.claude/worktrees/<name>`
and which of the two checks failed.

Where the header named more than one issue, that file names them all and says which reference
line each got, so every ticket's participants read the same account of what this one pull
request settles. A `published` that fails part-way through the list is the stop Step 1
describes: the report names the issue it failed on and the ones after it as not reached, and
the pull request stays open and unaffected.

Where the header carried `pr-base`, that file names the branch the pull request opens against
and whether `stack-link` ran or is `none`. It records the reviewer launch: the entry run and
what it returned, or which of the two checks above held it back. Where the header carried
`next`, it says the reviewer carries that launch and, where the reviewer launch was held back
or failed, quotes the `next` locator as unlaunched. That locator is how a person resumes the stack by hand.

That file also carries every review finding the run collected: every round of Step 4's loop,
both the loop before Step 5's push and the one Step 6 item 6 runs over the reviewer's fixes,
and, where Step 6 ran, every finding its reviewer round collected including the ones judged
not to hold. Each carries one disposition from the reference's "Dispositions" section.

Where the pull request body, as Step 5 or Step 6 last wrote it, carries a `## Not verified
here` heading, that file also says checks wait there for a person to run; where it carries
`## Unverified claims`, that claims wait there for a person to probe. Each of those
statements points to its heading without repeating the entries under it. With neither
heading, this step requires nothing here, and whether the report says that nothing waits for
a person is for the contract **Run report** resolves to.

The findings, their dispositions, Step 6's outcome and the pointer to each of those headings
the body carries are required content whatever contract **Run report** resolves to: this step
holds them in, and a must-not-include that would cut them does not reach a file this step
mandates. The type governs who the report is written for and the order, emphasis and wording it
gets; this step governs what is present. A report missing an unresolved finding, or silent
about a round that never ran, reads as a clean review under any contract.

## Stopping

Every stop above takes one of two shapes, set by whether Step 5 has opened the pull request.
Both files are written under `baton:write-deliverables` as a **Run report**, the type Step 7
uses:

- Before it: push nothing, open no pull request, and run `stopped` with one file naming the
  step and what stopped it.
- After it, in Step 5's remaining `pr-create` calls or its `stack-link`, Step 6 or Step 7:
  push nothing further and leave the pull request open. Run `stopped` with one file naming
  the step, what stopped it, and the pull request URL - only Step 7's `published` would
  otherwise carry that URL to the issue.

**Step 2's no-change exit borrows this shape and is not a stop.** It runs `stopped` over the
header's issues exactly as the before-Step-5 shape does - one Run report, the same per-issue
walk, the same failure shape part-way through that list, the same `next` locator quoted as
unlaunched.
Two things differ. Its file carries Step 2's evidence rather than a step and a blocker; and
it settles its own worktree on the two checks Step 2 gives it, rather than leaving
it standing as every stop below does - a stop is where work sits unpushed, and that exit wrote
none. Nothing went wrong on it, so it ends at `## Done` rather than here.

Either shape runs `stopped` **once per issue the header names**, in header order, each call
with that issue's id and the same file: every ticket the run took on hears that it stopped,
not just the primary. Where the header named one issue that is one call, as it always was.

One exception, and it is the stop inside Step 7's own `published` sequence: skip the issues
that sequence already reached. They have been told the pull request shipped, and a `stopped`
behind that says the opposite of the call before it on the same ticket. Run `stopped` on the
issue `published` failed on and on the ones after it - exactly the issues that step reported
as not reached - and let the file name the ones that did get their `published`.

A `stopped` that itself fails part-way through the list ends the run there, and the report
names the operation, the issue it failed on, and every issue after it as not reached - the
same shape Step 1 sets for `started` and `published`. Nothing retries it: a stop reporting a
stop has no further step to reach.

Step 1's stop on a mismatched pair still has a list: `issue` parsed, and only the pairing with
`closes` did not. Run `stopped` on every entry of it - each issue was named for this work
whatever `closes` failed to say about it. A stop earlier than that has nothing to walk: run
`stopped` on the primary alone where only that parsed, on nothing at all where
`fetch-handoff` itself failed, and say in the report which issues went unnamed.

**A stop can land part-way through a review.** Wherever Step 4's loop or Step 6's round had
started, the file carries the findings judged so far with their dispositions, as Step 7's
report does, and marks unresolved every finding it collected but never judged, with "run
stopped" as what blocks the call - so the count a reader sees is the count the round found. A
fix still uncommitted when the run stops is not on the branch, so its finding is not applied:
mark it unresolved, with what stopped the run as what blocks the call. A
stop before Step 4 has collected no findings and says nothing about them. This is required
content under any contract loaded for **Run report**, the same as Step 7's.

**A stop before Step 7's launch never launches the reviewer, and the `stopped` file says
so.** With no reviewer, nothing carries `next` either: where the header has one, the file
quotes its locator as unlaunched and says the layer above was not started. A stop strands
every layer above it, and this file is the only place that locator reaches anyone.

**A stop after the launch ran - a failed `published` - says the reviewer was started.** Name
the entry run and what it returned, and do not present the `next` locator as unlaunched: the
reviewer carries it, and a person who starts that layer as well puts two runs on one branch.

No stop calls `ExitWorktree`. A stop is where work sits unpushed, and Step 7's two checks
are the only thing that establishes it does not. The `stopped` file names the worktree path
`.claude/worktrees/<name>` wherever the worktree still stands, and the branch the run built
on: the work is in that directory, and a relaunch in the same clone takes a new name at Step
2 rather than that branch. A stop after Step 7's removal is the one with no path to name.

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
`stopped` ran on it. An issue the report leaves out is one nobody knows to check.

Report the reviewer launch too, in whichever form Step 7 recorded it, and where the header
carries `next`, that the reviewer carries it. The reviewer is a separate session: this one does
not wait for it, watch it, or report anything about how it went.
