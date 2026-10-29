# Maintainers' notes

Why the baton skills and reference files say what they say. A run never reads this file: each
note below explains a rule its source states, and removing the note from the source changed no
action a run takes. Before changing a rule, read its note here.

Headings name the source file and the step or section the note came from, by the name it has
in that file now.

## skills/implement-handoff/SKILL.md

### Opening

A session waiting on input makes no progress, which is why the run asks no questions.

An improvised equivalent of an undefined operation writes to a tracker the project did not
choose, which is why the run never runs a command the backend does not define.

### Where the opening turn came from

A launcher usually starts this session, so the opening turn is often machine-generated even
though the harness presents it exactly like a developer's own words. That is why only the
locator and `launcher=` bind.

The handoff is a plan written against `base`, so on a question of code fact the working tree
outranks it.

### What this run may do unasked

Invoking this skill is the request to commit and publish, so the standing rule against pushing
unasked does not cover the run.

The `EnterWorktree` and `ExitWorktree` tool descriptions otherwise hold `EnterWorktree` to an
explicit instruction and `ExitWorktree` to the user asking; for this run, the steps that call
them are that instruction.

Every pull request this skill opens gets a `review-handoff` review, so the skill's invocation is
the authorization to launch it.

The may-not list holds actions an unattended run cannot obtain the ask that would authorize.

### Step 1 - Load

Pairing `issue` and `closes` entries where the lists differ in length guesses at the rest, and
a guess landing on `yes` shuts an issue the handoff said to leave open - on merge, with nothing
left to undo it.

A launcher name that cannot launch is cheapest caught at Step 1, before anything is built.

`verify-checkout` has to equal the header's `repo` whatever repository the issue lives in: that
check is about the checkout.

A credential error is the session, not the plan, and the backend records what each one means;
`reachable` separates it from an undefined operation.

### Step 2 - Branch and build

`started` and `verify` are resolved before `EnterWorktree` because an operation no loaded file
defines is a stop, and a stop reached after `EnterWorktree` leaves the run's worktree standing,
once per relaunch. The same holds for every operation, launcher entry and asset resolved at
Step 1.

The dispatch tool is checked at Step 2 because that stop costs a run that has not built
anything; the same stop at Step 4 would discard a finished, tested branch that was never pushed.

`EnterWorktree` and `git switch -c` are skipped on conditions of their own because neither
survives a second run. The worktree pair is tested rather than the branch name because a fresh
run in a clone that happens to sit on `<branch>` would otherwise skip isolation and build in the
working tree it was meant to leave alone.

The run gets a worktree of its own so two runs started in one checkout do not edit one working
tree. The worktree's name comes from one issue rather than the branch because a branch-named
directory is long enough to push a test binary's path past the 259 characters Windows
`CreateProcess` accepts, and the run then reports a failing suite in which no test failed. The
random suffix keeps two handoffs on one issue in separate directories.

The worktree's opening state is read immediately because it tells the no-change exit whether the
directory held anything before this run, and it is worthless taken later: the handoff's commands
run in there, and a suite's own `dist` or cache answers it exactly as a source file the run
wrote and never added would.

Seeding is `EnterWorktree`'s: a worktree checks out tracked files only, and copies in whatever
the project lists in `.worktreeinclude`. That list is the project's to write, and it is a
prerequisite - a gitignored `.claude/settings.local.json` that is not on it does not follow the
session into the worktree, and the run stalls on a permission prompt with nobody there to
answer.

#### The no-change exit

Step 3 requires tests that fail at the branch point and pass against the change, and against a
HEAD that already does what the handoff asks there is no such test to write - so a satisfied
handoff exits instead of building. The exit runs in the worktree, which keeps the handoff's
commands out of the directory the session started in.

The exit is gated by the branch cut and not by `EnterWorktree`: HEAD already on `<branch>` is a
turn resuming from a stop, and what satisfies the handoff there is the run's own unpushed work.
Taking the exit on that evidence would report a branch this run built as code that was already
in the tree, then delete it.

HEAD is moved to the tip of `<default-branch>` because the worktree's HEAD is wherever
`EnterWorktree` or a launcher left it, which need not be that tip.

Commands alone cannot carry the exit: a handoff may name commands and no criteria, and a project
suite that passes at HEAD says nothing about work nobody did.

The evidence is audited because it is the claim a person closes an issue on; an unaudited one
closes an issue whose work nobody did. A failed dispatch is a stop rather than either
alternative: taking the exit unaudited posts the one claim the run must not get wrong, and
continuing to the build sends the run to Step 3 for a change the tree already carries, where it
can write no test that fails at the branch point. The stop costs a run that had nothing built.

The worktree is settled before the report because the report names its path wherever it still
stands. A dirty entry state means the run inherited something rather than left it. The
directory's current contents decide nothing because they were written by a check rather than by
a change; and Step 6's `origin` comparison has nothing to ask, since the exit pushes no branch.

The exit is neither the pull request nor a stop: nothing went wrong, and nothing shipped.

#### The branch cut

`started` runs once per issue at the branch cut because the tracker moves every bundled ticket's
status, and the cut is the moment implementation starts on all of them. The cut's gate, not
`EnterWorktree`'s, holds the call to one per branch the run cuts: a resuming turn skips all
three calls, while a launcher that started the session in a worktree skips only
`EnterWorktree` and still cuts the branch. It runs above the cut rather than inside the retry,
which would fire it once per attempt.

The gate holds the sequence to one pass per cut, not one call per issue for all time: a stop
part-way through the list leaves the branch uncut, so the resuming turn cuts it and runs the
whole list again. Asking `started` to be harmless to repeat buys a partial failure its freedom
from bookkeeping carried across the stop; an entry that cannot be repeated safely is one the
project writes as `none`.

A pull request naming its deviation from the handoff is worth more than a stop naming the
problem: the deviation gets reviewed, the stop waits for someone to look.

### Step 4 - Claim audit

The run wrote the code, so it is the worst-placed context to judge its own claims; a fresh
subagent audits them.

The audit is given the skill's path rather than its name because an agent type carrying no
`Skill` tool can still `Read`. The path is expanded first because the dispatched agent's shell
does not carry the session's environment, so the unexpanded form reads as a literal and the
audit runs without its checklist.

Step 2 has already established the dispatch tool exists, so a failure at Step 4 is the dispatch
and not the launcher. An unaudited claim is what the step exists to keep out of the pull request.

### Step 5 - Pull request

Claims the audit labelled unverified are statements the run made and could not probe, kept
apart from the handoff's checks on a running application.

Reference lines are written into the body before `pr-create` because the operation sends a
file, so a line added after the call reaches nothing.

`pr-create` opens a draft because an unattended run's branch has been reviewed by nobody but
itself, and a draft says so to everyone looking at the pull request list.

Reference lines come from the header because a merged `closes` shuts an issue whatever else is
outstanding. They name the issue's repository, which is not the pull request's wherever the
handoff was recorded for a repository other than the issue's.

A failed later call in `pr-create` is a stop after Step 5 because, taken for a stop before Step
5, it leaves an open pull request the issue never hears of.

### Step 6 - Report

`ExitWorktree` `remove` refuses without `discard_changes` once the worktree's branch holds a
commit, and Step 6's checks stand in for the confirmation it asks for. Removal deletes the
worktree directory and the branch `EnterWorktree` opened, while `<branch>` keeps its commits and
`origin` already has them. Where a check fails, whatever it found exists nowhere but that
directory.

`git status --porcelain` counts untracked files, so a build artifact the run left behind sends
it down the `keep` path. That is the right way to be wrong: the same output is also how a source
file the run wrote but never added looks, and `remove` cannot be undone.

The pull request URL is passed to the reviewer rather than derived from the header's `branch`
because Step 2 may have cut `<branch>-<6 hex>` instead. The launch runs once because two
reviewers on one pull request race to push to the same branch. A failed check holds the launch
back because `origin` does not hold the branch's work, so the reviewer would review a tree other
than the one in that directory.

The Run report contract governs who the report is written for and the order, emphasis and
wording it gets; the step governs what is present.

### Stopping

A stop after Step 5 puts the pull request URL in the `stopped` file because only Step 6's
`published` would otherwise carry it to the issue.

The no-change exit settles its own worktree because a stop is where work sits unpushed, and
that exit wrote none. No stop calls `ExitWorktree`, because Step 6's two checks are the only
thing that establishes the work is pushed.

A relaunch in the same clone takes a new name at Step 2 rather than the branch a stopped run
built on.

## reference/per-issue-calls.md

A stop inside the `published` or `reviewed` sequence skips the issues already reached because
they have been told the pull request shipped or was reviewed, and a `stopped` behind that says
the opposite of the call before it on the same ticket.

The list of issues not reached is what tells a person which tickets are still theirs to move by
hand.

## reference/stacked-handoff.md

`implement-handoff` Step 1 runs a different checkout pair on a stacked handoff because `base` is
then a commit on the layer below, which is unmerged by definition, so it is not an ancestor of
the default branch the clone arrives on and `--is-ancestor <base> HEAD` fails on every stacked
handoff. The pair's first line answers whether the clone holds `base` with a fetch and then
discards the answer - `||` makes the whole line succeed whenever the fetch does, and a fetch
that brought nothing exits 0 - so the second line is what turns a missing `base` into a stop at
Step 1 rather than a confusing `pr-base` failure at Step 2.

A stacked handoff never takes the no-change exit because its work sits on an unmerged layer that
HEAD does not carry, so a HEAD that looks satisfied is evidence about a different tree - and the
layer above names this layer's branch as its base, which only the build will push.

The branch is cut from `origin/<pr-base>` because the layer below has pushed commits since the
plan was formed, and this layer's work belongs on top of all of them. The fetch names both sides
of its refspec because a clone made with `--single-branch` - which `--depth 1` implies, and
which is how a cloud run's checkout arrives - narrows `remote.origin.fetch` to the default branch
alone, and a bare `git fetch origin <pr-base>` there updates `FETCH_HEAD` and creates no
`origin/<pr-base>`. A failed ancestor check means the `file:line` citations in the handoff
resolve against a history `<pr-base>` does not carry.

Tests are measured against `origin/<pr-base>` because a stacked branch carries the layer below,
so a test run at `<base>` measures the change against a tree missing that layer's work, and a
test failing there may be failing on the layer below.

A stop or the no-change exit quotes the `next` locator because a stop strands every layer above
it, and that file is the only place the locator reaches anyone; it is how a person resumes the
stack by hand. A stop after the reviewer launched does not quote it as unlaunched because the
reviewer carries it, and a person who starts that layer as well puts two runs on one branch.

`review-handoff` launches `next` rather than `implement-handoff` so the layer above branches
from the reviewed tip.

## reference/handoff-assets.md

Assets are read-only because the folder is shared across every repository on the machine, and
some of what it holds is not cleared to live in one.

`review-handoff` reads assets because the handoff's commands run after every fix, and a command
that reads an asset needs the file the implementation run read.

Every read of an asset is outside the checkout, so a harness that prompts for reads outside the
working directory prompts for these - and an unattended run has nobody to answer. That is why a
denied or unanswered read is a stop.

Assets are resolved at Step 1 rather than at the first read because a stop after
`EnterWorktree` leaves a worktree standing. The run never carries on with the assets that did
resolve because the handoff listed all of them because the work needs all of them. A path the
`assets` line does not carry is not an asset the run has, whatever the body calls it.

## skills/review-handoff/SKILL.md

### Opening

A session waiting on input makes no progress, and an improvised equivalent of an undefined
operation writes to a tracker the project did not choose.

### Where the opening turn came from

A launcher starts this session, so the opening turn is machine-generated even though the
harness presents it exactly like a developer's own words. `launcher=` chooses nothing because
the layer above is launched through the entry the handoff's `next` line names.

### What this run may do unasked

Invoking this skill is the request to commit and publish review fixes, so the standing rule
against pushing unasked does not cover the run. The `EnterWorktree` and `ExitWorktree` tool
descriptions otherwise hold them to an explicit instruction and to the user asking; for this
run, the steps that call them are that instruction. The may-not list holds actions an
unattended run cannot obtain the ask that would authorize.

`request-reviewer` belongs to this run rather than `implement-handoff` so the external review
arrives while this run can still act on it: requesting it at `implement-handoff` Step 5 with no
wait would leave a review this run collects before it lands.

### Step 1 - Load

Every operation is resolved before `EnterWorktree` because the same stop reached after it
leaves a worktree standing.

### Step 2 - Worktree

All three resume checks are needed because a person's own linked worktree can carry the reviewed
head too, and taking that for a resume would edit their checkout.

The run takes a worktree of its own because a `local` launch starts the session in the person's
own checkout, and the review must not edit that working tree.

`git status --porcelain --untracked-files=no` must print nothing because the reset discards
changes to tracked files, and a worktree already holding some was not this run's to discard.
Untracked files are left out because the reset leaves them alone, and a project's
`.worktreeinclude` puts some there on purpose. `origin/<head ref>` must equal the reviewed head
because otherwise another push landed after Step 1 read the pull request, and the review would
judge a tree nobody pushed.

### Step 3 - Review loop

The external review is requested before the first `code-review` round so the reviewer's wait
overlaps that round rather than following it.

The `sh` loop wait form polls inside the shell, so the loop notifies once, at the moment that
matters. A foreground `sleep` is blocked by the harness, which names `run_in_background` as the
way to wait. `Monitor` is built for a stream of events.

On the shipped route `review-list` and `pr-comments` are `tool:` entries, so the wait takes the
`sleep 60` form: one model turn over the full context for every minute of `review-wait`.

Rounds after the first review only the previous round's fixes, through an empty `<target>`,
because the shipped `/code-review` is built to keep finding things - its prompt targets at least
five findings - and a whole-change re-review hands it code the previous rounds already passed. A commit-range `<target>` was rejected: whether `/code-review` takes
a range is untested. The loop ends on the first round with no Critical finding because the early
exit on "no Critical or Important finding" never fired in the runs reported on #41, #47 and #50.
The ending round's fixes are still applied because the cap ends the reviewing, not the fixing.

The handoff's commands run after each fixing round and `verify` once before the push, because
`verify` checks the whole repository rather than the change.

### Step 5 - Push and update the pull request

A push landing while the review ran is a stop because pushing over it - or merging it in, or
describing it - publishes a tree nobody reviewed. A rejected push is a stop for the same reason.

### Step 6 - Report

The worktree checks stand in for the confirmation `remove` otherwise asks for. A report missing
an unresolved finding reads as a clean review under any contract, which is why the findings are
required content.

## reference/defining-backends.md

### Operations, `review-wait`

The cap of 60 minutes exists because an unattended run that waits longer is holding a finished
branch for a reviewer who is not coming.
