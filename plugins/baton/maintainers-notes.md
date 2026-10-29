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

An issue whose reference line goes missing from the body is unlinked on merge. Nothing errors -
the pull request is valid without it, and the ticket never moves.

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

Done names every issue the header carried because an issue the report leaves out is one nobody
knows to check.

A relaunch in the same clone takes a new name at Step 2 rather than the branch a stopped run
built on.

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

## skills/investigate-issue/SKILL.md

### Preamble (before Step 1, under `# Investigate issue`)

Running a command the backend does not define is forbidden because an improvised equivalent writes to a tracker the project did not choose.

### Step 1 - Load

An issue waiting on an implementation run is settled work, and investigating it again ends in a second plan and a second run against the same change.

The pointer alone says an issue is scoped without saying by what, which leaves the user nothing to overrule.

`view` output need not carry a comment address to match the locator against, so the reader resolves it rather than this step: that reader is present, which is the whole difference between this skill and `implement-handoff`.

A line number located in the wrong clone is worse than no line number at all.

### Step 2 - Verify

Step 5 writes one handoff per repository and every handoff's `base` is its own repository's HEAD, so a HEAD not recorded here is a `base` guessed later.

### Step 4 - Approach

Where the work removes an arrangement, what the code needs today is a product of that arrangement.

Stating the question plainly is also what exposes a mis-framed one - a decision resting on a misread comment dissolves once it is in words.

### Step 5 - Record

This issue stays first because it drove the investigation and it keeps the handoff.

`base` is the HEAD Step 2 reproduced against so the plan stays falsifiable against the code it was formed on.

The implementing session shares no disk with this one, and the run reaches only the asset files that line lists (`write-handoff` Step 3), so a file left off is a file the run silently builds without.

Each `assets` entry is one more thing that can stop a run.

Posting a held handoff now works because nothing here asks for a `base` that does not exist yet.

Every handoff but the last gets `closes: no` so the issue stays open while work on it remains.

### Step 6 - Launch

A held handoff's run would build against an upstream version that does not exist, and the report is what the developer relaunching it later works from.

`<pr-url>` and `<head-branch>` are empty because no pull request exists yet, and the implementation run cuts its own branch.

`wrap-up` runs where the answer names no launcher too because the investigation ended either way.

### Done

A repository reached through `## Repositories` is the user's own working checkout rather than a copy, so an edit there lands in a tree nobody asked this run to touch.

## skills/write-handoff/SKILL.md

### Preamble (before Step 1, under `# Write handoff`)

Running a command the backend does not define is forbidden because an improvised equivalent writes to a tracker the project did not choose.

### Step 1 - Place

Without the blank line after `<summary>`, GitHub renders the fenced header as literal backticks.

The pointer is written to a file of its own since `post-handoff` takes a path.

With a fenced header the pointer would read as a second handoff, and a launcher handed its locator would start a second run on the branch the primary handoff already names.

Bundling is a judgement made from the work just done, and nothing here checks it.

A session on another machine reaches the tracker and nothing else - no file of this machine's, and no path that resolves.

The first handoff is not edited for rework because it alone carries the approach that failed and the constraint that ruled the alternatives out.

### Step 2 - Header

The header is fenced because a tracker renders consecutive lines as one paragraph, so an unfenced header arrives as prose.

`base` must be on `origin` because a session that clones never sees a commit held only here.

A repository with no `## Repositories` row is a stop because the commit cannot be checked in the only clone this machine offers for it, and the check run in the wrong clone answers confidently about the wrong repository rather than failing.

`closes` is `no` on every handoff but the finishing one so the issue is not marked done while work on it remains.

A bundle takes the primary's category because one pull request carries one label.

The category is written exactly as the `## Categories` row spells it because a project can rename its categories, so the row is the spelling, not this skill.

`pr-base` is not checked here because a stack is written top layer first - see `## Done` - so at the moment this handoff is posted the layer below has usually not pushed yet, and a check here would fail on every layer but the bottom one.

Omitting `next` launches nothing, which is what every handoff written before this line did.

The assets-in-a-stack question is settled before posting because the `next` lines are written on the way down and a layer's own header is fixed once it is posted.

An upstream repository's next published version is something no run produces and no branch stands for.

Of the asset path rules, the last two keep the path inside the root. The character rule keeps it out of a shell: the path is spent inside `test -e` by this step and again by the run, so a quote, a `$`, a backtick or a `;` in it would execute there.

`root` is checked before any path because an empty one turns the second line into `test -e "/<path>"`, which answers about the filesystem root and can pass on a file nobody meant.

The assets check runs here because the session that reads the handoff has nobody to ask where a file went.

### Step 3 - Body

The session reading a handoff has no one to ask, so a banked question stalls that run and returns the decision to the user anyway - later, and with the work halted.

An asset path resolves in the reading session because Step 2 checked it.

An asset's absolute path stays banned because the root is the backend's to supply per machine, and a body that spells it out is wrong on the next one.

A bare relative path reads as a repo-relative citation like every other one in the body, and the reading session would look for it in the checkout and find nothing.

A path that is not on the `assets` line is a path the run will not have.

Acceptance criteria cover every part of the approach since a part no row names is a part nothing checks.

Commands are headless because the implementation run is unattended, so a command opening a window or waiting on a keypress hangs it with nobody there to answer.

The pass output is named beside each command since the run has no other way to read the result.

**Not verified here** is left out where there is nothing to check because an empty list copied into every pull request body tells the reviewer nothing, and pushes the run to fill it with entries that are not checks.

These sections are named here rather than in the **Handoff / context note** contract because it also covers the note left when stopping mid-task, which has no criteria to state.

Without being carried into the brief's `GOAL`, the outline verdict cuts them as sections no reader question asks for - the reader here is a run that cannot check itself without them.

### Step 4 - Update

A claim found only in the update reaches the run without the handoff's reasoning.

### Done

The primary-first order is forced: the pointers carry the locator the primary's call returns.

The primary locator is reported even though the stop lands before `## Done`, because nothing else in the run recovers it.

The pointers' own locators address nothing a run can read, and naming one to a launcher starts a run with no handoff to work from.

An issue splits into several handoffs whenever its fix lands as more than one change, so the issue number addresses none of them and whatever launches the work takes the locator.

Each layer's `next` carries the locator of the layer above, which exists only once that layer's handoff is posted, so the order is forced.

Posting every layer before any runs is what lets each one name a `pr-base` branch nothing has pushed yet, and it is why the branch is checked in the run rather than here.

## skills/setup/SKILL.md

### Step 1 - Route on what exists

For a `## Repositories`-only request, the full Step 3 counts and the Step 4 check table test a backend's operations, which this request neither writes nor changes. It overrides no shipped operation, so it is not the duplicate the no-backend-file rows refuse.

For an `## Assets`-only request, the section defines no operation, so Step 4 has nothing of it to run.

`## Repositories` and `## Assets` are the two optional per-machine sections and neither overrides a shipped operation, so a request for both is still not the duplicate the no-backend-file rows refuse.

With no backend file on route 1 or 2, a copy of the shipped defaults is a second file to keep in sync.

### Step 3 - Write the file

`~/.claude/baton.md` is written only on request because a cloud or CI session clones the repo and never sees a home directory.

`## Forge` gets its own count for the same reason as `## Workflow`: `stack-link` writes to the forge, so Step 4 never runs it.

Missing `## Workflow` operations are added before Step 4 because Step 4 never runs the writing operations, so it cannot catch one left out.

A relative `## Repositories` path resolves against whatever directory a launcher happens to start in.

The `## Assets` root check is skipped where the user did not ask for the section because the file carries no `root`, and running it there prints a failure about an entry nobody meant to write.

A relative `root` resolves against whatever directory the run happens to start in.

### Step 4 - Verify by running

A wrong `## Repositories` path sends a run into the wrong tree rather than failing.

`verify-checkout` reads and writes nothing, so running it once per row adds nothing to the list below.

Each of the never-run operations writes to the tracker or the forge - `stack-link` to a pull request belonging to somebody else's handoff.

`verify` is never run because a project's sequence may rewrite files in the user's checkout.

## skills/next-issue/SKILL.md

### Preamble (before Step 1, under `# Next issue`)

Running a command the backend does not define is forbidden because an improvised equivalent writes to a tracker the project did not choose.

### Step 2 - Skip what is already scoped

An issue carrying the marker has been investigated, and picking it up again produces a second investigation of settled work.

The walk stops at the first unmarked candidate because `has-handoff` costs a call per issue, and the ones below the answer do not need one.

### Step 3 - Report

Skipped issues are listed so the choice can be overruled. A skip the report does not explain is one nobody can judge.

Each skipped handoff's `closes` value is reported because under `closes: no` the marker may record finished work rather than pending work.

When nothing survives, the skipped list is what a person picks from.

## skills/address-review/SKILL.md

### Address review

Never run a command this backend does not define, because an improvised equivalent writes to a tracker the project did not choose.

### Step 1 - Resolve the target, and state it

The resolved target is stated before anything else runs against it so the user can correct it before the work is done rather than after.

A pull request this side does not own goes to `baton:review-pr` because someone else's code takes comments, not commits.

The spec is resolved because a review row asking for behaviour the pull request was opened to replace finds that behaviour still in the code wherever the change has not reached yet, so the code argues for the row; the spec is what says it was replaced.

Where several handoffs match on one issue, the one appearing last binds because rework is posted as a second handoff rather than an edit to the first.

Where the matches sit on different issues, none binds because no order across issues is defined.

Other issues found are context, not spec: a follow-up `baton:self-review` filed from a finding is one the pull request references too.

A dropped issue is named as not found or not readable with this session's credentials because a backend can answer not-found for an issue the session cannot read.

The resolved spec is stated before collecting anything so the user can correct it too.

### Step 3 - Inventory, then stop

Each ask is recorded with the surface it came from so its answer later lands in the right venue.

The code still decides whether a factual claim about current behaviour holds because the spec says what the pull request is for, not what the code does.

The pull request body does not settle a row where it records a deviation from the spec because it is written by the side under review.

The ruling is input only the user can give.

A message between tool calls does not satisfy this gate because mid-turn text may never be shown to the user at all.

### Step 4 - Address

Performative agreement helps nobody.

Verification comes before publishing, never after, because verification is worth running only while what it finds is still cheap to fix.

The pre-publish check question is kept separate from asking to publish because asking to push while verification is still undecided inverts the order.

### Step 5 - Publish, then answer

Rows from summary bodies and conversation comments take one `pr-comment` because there is no thread to reply into.

Answering an inline finding at top level is the failure to avoid because its thread stays open and the reviewer never sees the answer.

## skills/file-issue/SKILL.md

### File issue

Never run a command this backend does not define, because an improvised equivalent writes to a tracker the project did not choose.

### Step 1 - Anchor

The SHA is recorded because line numbers rot; the SHA is what keeps `src/hub.c:117` resolvable.

### Step 5 - File

The path is spelled in full from `/` because a `~` or a relative path leaves the reader hunting for the session's scratchpad directory.

Issues are public on creation and close rather than disappear.

Where `list-categories` is `none`, `<category>` is passed empty because the tracker has no label to give it.

## skills/review-pr/SKILL.md

### Review PR

Never run a command this backend does not define, because an improvised equivalent writes to a tracker the project did not choose.

### Step 1 - Resolve the target, and state it before reviewing

The user cannot see when a message was composed: an answer that looks like it addresses your latest question may have been typed before that question existed.

A pull request the user authored is not this skill's because reviewing your own side's work means applying fixes, not commenting on them.

This skill never picks between self-review and code-review for the user because it cannot tell the two apart.

### Step 3 - Draft, and post nothing

Findings are this step's deliverable; posting is a separate decision and it is the user's.

### Step 5 - Wrap up

The pull request URL and head branch come from Step 1's `pr-view` because the pull request under review may not be the checked-out branch.

## skills/self-review/SKILL.md

### Self review

Never run a command this backend does not define, because an improvised equivalent writes to a tracker the project did not choose.

### Step 0 - Collect the review threads

With no pull request, the target is the full branch diff against the merge target so every commit on the branch is covered rather than only uncommitted edits.

### Step 1 - Review

`<locator>` is empty because this skill takes a branch rather than a handoff.

Findings land as fixes, never as comments on the pull request, because the branch is yours to fix, not yours to have written.

### Step 3 - The gate

Which fixes to apply is input only the user can give, so stopping is this step's required outcome.

### Step 4 - Apply and verify

The pre-publish check question is kept separate from asking to publish because asking to push while verification is still undecided inverts the order.

### Step 5 - Publish

`pr-update` runs whenever Step 2 collected an item because closing an item changes the body.

## skills/write-deliverables/SKILL.md

### Write deliverables

A mandated heading is never dropped as redundant because an empty mandated section is a signal to its reader, not padding.

What a reader could look up elsewhere is exactly what a mandated claim is often for: that they do not have to.

Re-read these steps rather than recalling them because a half-remembered checklist is the failure this skill exists to prevent.

### Step 2 - Name the reader and what they already have

Every deletion below follows from the five lines.

### Step 3 - Outline verdict, before a word is written

This pass prevents; Step 5 only cleans up, and a section is far harder to delete once it exists and reads well.

### Step 4 - Draft, in the file

Draft in the file itself because the gate runs on real text, not on intent.

Value claims are unfalsifiable, and no reader acts on them.

### Step 5 - The gate

Fixes introduce new violations - that is why the gate restarts at G1.

A CUT is deleted, never shortened, because a shortened section leaves the skeleton behind.

## reference/defining-backends.md

### Where overrides live

A backend an unattended run must use goes in `.claude/baton.md` because a cloud or CI session clones the repo and never sees your home directory.

### Sections

`## Repositories` belongs in `~/.claude/baton.md` rather than the committed `.claude/baton.md` because paths differ per machine.

`## Assets` belongs in `~/.claude/baton.md` rather than the committed `.claude/baton.md` because the root differs per machine, for the reason `## Repositories` does.

The `cloud` launcher cannot resolve `## Assets` because it clones the repository and never sees a home directory.

### Operations

`close-fixed` and `close-invalid` each take `none` on their own because a tracker can let baton resolve an issue as done while a triager owns "not planned", or the reverse.

`repo-tests` is a literal the skills recognise rather than a command they run because no single command is every repo's suite.

A `verify` sequence that rewrites files does so before any of its checks because `implement-handoff` commits the tree `verify` leaves (`implement-handoff` Step 3), so a rewrite after the checks commits a tree none of them ran against.

`none` is not among `verify`'s values because a project that wants nothing repo-wide already has `repo-tests`, which runs nothing where there is nothing to run, and a project that has a sequence should not be able to turn the check off from the same field it configures it in.

`tool:` exists so that a tracker reachable only through an MCP connector needs no CLI and no second set of credentials.

An operation taking `<path>` sends `<body>` in a `tool:` entry because a tool call has no shell to redirect a file into.

`closes` and `refs` follow the tracker's rule because what they reference is the issue rather than the pull request.

An overriding `pr-create` opens a draft because no run marks one ready (`implement-handoff`, `## What this run may do unasked`).

A `pr-update` caller carries every issue reference line across unchanged because each one dropped is an issue the merge stops settling.

Author filtering belongs inside the `review-bodies` / `pr-comments` / `review-threads` command because it is part of what the operation collects.

`wrap-up`'s placeholders are quoted in a shell entry so an empty value still arrives as its own argument instead of shifting the ones after it.

`verify` takes no placeholders because what it checks is the whole repo, not this change, which is what the handoff's own commands cover.

`reviewed` is kept apart from `published` so that a `published` moving a ticket's status does not move it again when the review finishes.

The `review-wait` cap of 60 keeps the wait inside `Monitor`'s `timeout_ms` maximum of 3600000 ms.

An entry that prints the `## Categories` labels back is not a substitute for `none` because it passes whatever the tracker holds, and records no decision that the tracker has no labels.

`<path>` is always a file because a tracker CLI that takes body text on the command line mangles backticks and fenced blocks through the shell.

### Tools an unattended run needs

The shipped defaults run through the `mcp__github__*` tools because a cloud session can have those tools and no `gh`.

### Operations, `review-wait`

The cap of 60 minutes exists because an unattended run that waits longer is holding a finished
branch for a reviewer who is not coming.

## reference/backend-github.md

### GitHub backend (preamble, route step 1)

Route 1 requires `list_issues` because `get_me` takes no repository, so only `list_issues` shows the MCP account can read this one.

### Tracker

`mcp__github__list_label` enumerates a repository's labels, but it belongs to the server's `labels` toolset, which a connection sending no `X-MCP-Toolsets` header does not enable.

`list-open`'s cap of 500 is well above the open-issue count of any repo these skills are pointed at.

`list-mine` reads every page because the assignee filter runs on each page's issues.

`ASC` gives the pick order `defining-backends.md` asks of `list-mine`: oldest first.

### Forge

The label needs `pr-create`'s second call because `create_pull_request` has no `labels` parameter - its parameters are `owner`, `repo`, `title`, `head`, `base`, `body`, `draft`, `maintainer_can_modify` and `reviewers`. Every pull request is also an issue, so `issue_write` sets the label on it.

`"draft": true` is unconditional for the reason this file gives under `implement-handoff` Step 5.

`pr-view`'s passes compare owner and name ignoring case because GitHub returns `full_name` in the repository's own case, while a remote URL keeps whatever case it was cloned with. The first pass compares the owner alone because a repository renamed since the clone keeps its old name in `origin`'s URL - fetching still succeeds through GitHub's redirect - while `full_name` carries the new one. The second pass separates a fork from its parent where one account owns both and both carry the branch.

GitHub links neither a `#<n>` in the title nor a `<n>-` head-branch prefix, so those two are this example's convention rather than GitHub's.

GitHub documents the cross-repository form `<owner>/<repo>#<id>` for closing keywords.

### Review

`review-bodies` and `pr-comments` drop bots because a bot delivers its findings as inline threads, and its summary body is boilerplate.

### Launcher

The `cloud` launcher's Step 3 updates `model` because an investigation formed under one model does not hand its plan to a weaker one, and a launch from a session on another model would otherwise run under the routine's stored one.

A cloud run has a disposable clone to itself and isolates from nothing, and the cost of putting `EnterWorktree` and `ExitWorktree` on its list anyway is accepted rather than made conditional.

The routine's `name` takes the handoff's `repo` line too, keeping each repository's routines apart.

The `local` launcher's ignore check takes the same root because the worktree Step 2 creates lands in the repository being launched rather than this one.

`--bg` and `--print` conflict because `--print` leaves no session for `claude attach <id>` to open.

### Workflow

`started` is `none` because a GitHub issue has no in-progress state.

`reviewed` and `published` are separate for the reason this file gives under `defining-backends.md`, Operations.

`wrap-up` is `none` because each attended skill has already posted what it produced.

`verify` is `repo-tests` because GitHub says nothing about how a project is built.

## reference/backend-github-gh.md

### Tracker

`view`, `comment`, `close-fixed` and `close-invalid` pass `-R` because they address the issue's repository, which may not be the checkout's (`defining-backends.md`).

The `post-handoff` locator is not re-derived by listing an issue's comments because the listing is paginated, so the newest comment is not the last entry of the first page.

`list-categories` carries a limit because `gh label list` defaults to 30.

`list-mine` carries `--search "sort:created-asc"` because `gh issue list` defaults to newest first, and `list-mine` returns pick order, oldest first.

### Forge

`--base "<pr-base>"` is always passed because `<pr-base>` is never empty (`defining-backends.md`).

The label is a separate command so the URL is in hand before anything can fail on the label.

`--draft` is unconditional for the reason this file gives under `implement-handoff` Step 5.

### Review

`pr-comments` uses the `issues` path because every pull request is also an issue - it is the only endpoint returning top-level notes that belong to no review.

`review-threads` needs GraphQL because `isResolved` has no REST equivalent.

## reference/reviewing-run-output.md

### Whose code this is

Each artifact the run produced is an unverified assertion by an agent whose reasoning cannot be inspected.

### Collecting the review threads

There is no resolved-state filter because, unlike in `address-review`, a resolved thread here records an agent's claim and nothing more.

### Dispositions

The two judgements a round makes on its own take a disposition so neither reaches the reader as silence.

Every finding carries its severity because an unresolved Critical and a Minor left alone are different news.

## reference/per-issue-calls.md

Moved from `implement-handoff` Step 1 and Stopping, and `review-handoff` Step 6 and Stopping.

A stop inside the `published` or `reviewed` sequence skips the issues already reached because
they have been told the pull request shipped or was reviewed, and a `stopped` behind that says
the opposite of the call before it on the same ticket.

The list of issues not reached is what tells a person which tickets are still theirs to move by
hand.

## reference/stacked-handoff.md

Moved from `implement-handoff` Steps 1, 2, 3, 6 and Stopping, and `review-handoff` Steps 1, 3, 6
and Stopping.

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

`review-handoff` holds `next` back where the head ref differs from the header's `branch` because
launching would stack the layer above onto the wrong history.

`review-handoff` launches `next` rather than `implement-handoff` so the layer above branches
from the reviewed tip.

## reference/handoff-assets.md

Moved from `implement-handoff` Step 1 (`assets`) and `review-handoff`, What this run may do
unasked.

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

## reference/backend-github.md, `## Launcher`, `cloud`

The `claude-code-remote` route exists because a cloud `implement-handoff` run on 2026-10-29
(issue #53) had no `RemoteTrigger` tool - `ToolSearch select:RemoteTrigger` found nothing - and
so opened its pull request without launching `review-handoff`. The same session carried
`mcp__Claude_Code_Remote__list_triggers`, `fire_trigger` and `create_session`; the review session
then started for it carried `mcp__claude-code-remote__list_triggers` and `fire_trigger` but no
`create_session`. That is why the entry names the tools by search rather than by prefix, and why
`create_session` is only the fallback for a missing routine.

`create_session` with `source_url` started that review session with the repository attached.
`create_trigger` was passed over because it takes no `sources`.

## skills/implement-handoff/SKILL.md, Step 1, the launcher check

The launcher is checked for a usable tool at Step 1, not only for a definition, because a launch
that fails at Step 6 leaves a finished pull request with no reviewer, and the run cannot recover
it.
