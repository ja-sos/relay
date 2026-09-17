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

- `git add`, `git commit` and `git push -u origin <branch>` on the branch the handoff names,
  or on the name Step 2 substitutes where that branch already exists.
- `EnterWorktree` at Step 2, and `ExitWorktree` at Step 7 - `remove` with
  `discard_changes: true` once both of that step's checks pass, `keep` otherwise. Their tool
  descriptions otherwise hold `EnterWorktree` to an explicit instruction and `ExitWorktree`
  to the user asking; for this run, these two steps are that instruction.
- `pr-create` on that branch; `pr-update`, `request-reviewer`, `thread-reply` and
  `pr-comment` on the pull request it opens; `started`, `published` and `stopped` on the
  issue.
- `stack-link` at Step 5, where the header carries `pr-base`. It writes to the pull request
  below, which belongs to another handoff, so it is named here rather than covered by
  `pr-create`: the header asking for a stacked base is the authorization to register the
  layer in that stack.
- The `## Launcher` entry the header's `next` names, run once at Step 7. That line is the
  authorization to start the layer above, given ahead of the run by whoever wrote the
  handoff.
- Dispatching the subagents Step 4 runs - the claim audit, and a reviewer an `agent:` entry
  names. They read and report; nothing they return reaches the tracker or the forge except
  through a step above.
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
header gives `repo`, `base`, `issue`, `closes` and `branch`. Three more lines are optional,
and a handoff written before they existed carries none of them - an absent line is not a
stop:

| Optional line | Where the line is absent |
|---|---|
| `category` | `<category>` is empty |
| `pr-base` | `<pr-base>` is `<default-branch>`, and the branch is cut from `<base>` |
| `next` | Step 7 launches nothing |

A handoff with a `pr-base` line is a stop where the loaded `pr-create` entry never contains
`<pr-base>`. A `## Forge` written before baton 0.1.9 has no such placeholder, and its pull
request would open against the default branch, carrying the unmerged commits of the layer
below.

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
`pr-base`, since that is the only case Step 5 calls it in: a project whose `## Forge`
override predates the operation keeps running single-layer handoffs.

Where the header carries `next`, resolve the `## Launcher` entry its first value names
against the same loaded files. A name no loaded file defines is a stop here: Step 7 runs that
entry only after the pull request is open and the worktree removed.

The locator also fixes which repository this run's tracker calls address, for the whole run.
One investigation can record a handoff per repository a change spans, so the issue driving
this run may live in a repository other than the one the handoff names:

| Entries | Where `<owner>` and `<repo>` come from |
|---|---|
| `## Tracker` and `## Workflow` - `view`, `comment`, and the `started`, `published` and `stopped` that resolve through it | the locator, as `fetch-handoff`'s own notes take them |
| `closes` and `refs`, though `## Forge` holds them | the locator as well: the keyword references the issue, so it resolves against the issue's repository |
| every other `## Forge` and `## Review` entry - `pr-create`, `pr-view`, `pr-update`, `stack-link`, and the review operations | `verify-checkout`'s answer |

Both name one repository wherever the issue and the work are in the same place, which is every
handoff recorded before baton 0.1.11, and nothing changes there. Where they differ, a tracker
call taking `verify-checkout`'s answer would comment on whatever issue happens to hold `<id>`
in the repository this run is building in. `verify-checkout` still has to equal the header's
`repo` above: that check is about the checkout, and it is unaffected by where the issue lives.

Check reachability with `reachable` when a tracker call fails; it separates a credential error
from an undefined operation. A credential error is the session, not the plan, and the backend
records what each one means.

## Step 2 - Branch and build

Resolve `started` and `verify` against the loaded backend files before the first call below:
an operation no loaded file defines is a stop, and a stop reached after `EnterWorktree`
leaves the run's worktree standing, once per relaunch. Resolving them here is not calling
them - `started` runs at the branch cut below, where the run has committed to changing code,
and `verify` first runs at Step 3. `verify` is resolved this early for that same reason: a
`## Workflow` written before baton 0.1.8 leaves it undefined, and finding that out at Step 3
strands a worktree that already holds the work.

Find the subagent dispatch tool in the same breath, and for the same reason. Harness builds
differ on its name - `Agent` in some, `Task` in others - and a launcher's `allowed_tools`
naming neither leaves Step 4 with no way to run its claim audit. Look for it in this session's
tools now and stop where it is absent, naming the tool and
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
edit one working tree. Call `EnterWorktree` with a `name` of `<issue>-<6 hex>` - the six
characters `od -An -N3 -tx1 /dev/urandom | tr -d ' \n'` prints, so `5-a1b2c3` for issue 5.
The worktree lands at `.claude/worktrees/<name>` on a branch of its own, and the session
moves into it. Every step from here works there; Step 1's checks ran before it, in the
directory the session started in.

The name comes from the issue rather than the branch because a branch-named directory is
long enough to push a test binary's path past the 259 characters Windows `CreateProcess`
accepts, and the run then reports a failing suite in which no test failed. The random suffix
keeps two handoffs on one issue in separate directories.

Seeding is `EnterWorktree`'s and not this step's: a worktree checks out tracked files only,
and it copies in whatever the project lists in `.worktreeinclude`. That list is the
project's to write, and it is a prerequisite rather than a detail - a gitignored
`.claude/settings.local.json` that is not on it does not follow the session into the
worktree, and the run stalls on a permission prompt with nobody there to answer.

Run `started` on the header's `issue` immediately before the branch cut below, under that
cut's condition rather than one of its own: skipped exactly where `git switch -c` is skipped,
run exactly where it runs. `none` is its shipped default, and that value skips the call the
way it skips Step 6's. That gate, and not `EnterWorktree`'s, is what holds the call to one per
branch this run cuts - a turn resuming from a stop skips all three, while a launcher that
started the session in a worktree skips only `EnterWorktree` and still cuts the branch -
unless that worktree already sits on `<branch>`, which is indistinguishable from a resume
and skipped as one. It runs above the cut rather than inside the retry below, which would
fire it once per attempt.

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
not pushed `<pr-base>` yet, so this run was started out of order - the launch at Step 7 of the
layer below is what starts this one. A failed ancestor check means `<pr-base>` is not the
branch the plan was formed on top of, whatever its name says, and the `file:line` citations in
the handoff resolve against a history that branch does not carry.

This is the check `write-handoff` Step 2 does not run. A stack is posted top layer first, so
at posting time `<pr-base>` usually names a branch nothing has pushed; here it has to exist,
and that is why the check sits in the run.

The third exiting non-zero because `<branch>` already exists is neither a stop nor a reuse:
run it again with `<branch>-<6 hex>`, six fresh characters from the command above, until one
succeeds. From there `<branch>` means the name that succeeded - Step 5 pushes it, Step 7
fetches it, and Step 5's body and Step 7's report both name it beside the name the handoff
asked for. Step 7 also stops launching `next` when that happens, for the reason given there.

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

1. The commands the handoff names beside its acceptance criteria. These prove the outcome
   this change was asked for; `verify` checks the repo, not that outcome.
2. `verify`, the project's own sequence over the whole repo. Its shipped value is the
   literal `repo-tests`, meaning the repo's whole suite as the run finds it; any other
   value runs in the form `defining-backends.md` gives it.

A failure of either is a stop.

Nothing is committed until both pass - here, and again at each later point this pair runs.
A `verify` sequence that rewrites files - a formatter pass - does so before any of its
checks, the order `defining-backends.md` gives, so the tree its checks last passed on is the
tree Step 5 pushes. A sequence whose rewrite runs after its checks pushes a tree no check ran
against.

A handoff naming neither is run with `verify` alone. A handoff posted before baton 0.1.7
names neither, and one posted under 0.1.7 names criteria without commands; stopping on
either would strand them. A handoff naming one
and not the other runs what it names; Step 5's body records which of the two the run had.

## Step 4 - Review loop and claim audit

Run `code-review` with an empty `<target>`, so it reviews the working tree this run wrote,
and with `<locator>` set to the handoff locator this session opened with. An entry that
checks acceptance criteria reads them from the handoff there; the shipped entry names
neither placeholder in its prompt and ignores both.

### Severity

The loop needs a severity the stopping rule can read, and `code-review` resolves to whatever
engine the project named, on whatever scale that engine uses. So the run classifies every
finding itself, against this table, before deciding anything. Where an engine attaches a
severity of its own, it is evidence about the finding and not the answer: map it onto a row
here, and where it maps onto none, class the finding from what it says.

| Severity | The finding says |
|---|---|
| Critical | The change is wrong or unsafe as written - a defect this diff introduces, a security hole, data loss, or a contradiction of an acceptance criterion the handoff set. |
| Important | The change works, and a reviewer would still send it back - a case it fails to handle, a statement in code or docs it leaves false, a missing test for behaviour the handoff names. |
| Minor | Everything else - style, naming, a cleanup in code this diff did not touch. |

Severity is about the finding, not about how hard it is to fix. A Critical finding the run
cannot fix stays Critical and goes in the body as one.

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
`code-review`. What the cap costs is a review of those last fixes, and the Step 5 body says so
wherever the loop ended that way - a reviewer reading it then knows which hunks nothing looked
at twice.

A finding the run cannot fix is one whose fix falls outside the handoff's scope, contradicts
a decision the handoff recorded, or needs an answer nobody here can give. Say which: "could
not fix" on its own tells a reviewer nothing.

Every finding still standing when the loop ends goes in the Step 5 body - the Critical and
Important ones the run could not fix, and each Minor one it left - with its severity and the
reason it stands.

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

Name the skill in that prompt. The plugin's `PreToolUse` hook on the dispatch tool appends its
own audit instruction to a dispatch that does not mention `claim-audit`, and stands down for
one that does (`hooks/gate-subagent-claim-audit.sh`), so naming it is what keeps the wording
this step asks for rather than the hook's.

The audit's verdict on each claim decides what the body may say:

| Verdict | In the body |
|---|---|
| ACCEPTED | stated as it stands |
| CORRECTED | rewritten to the corrected form |
| RETRACTED | left out |
| LABELLED unverified | moved under the body's `## Not verified here` heading |

A dispatch that fails here is a stop. Step 2 has already established the tool exists, so a
failure at this point is the dispatch and not the launcher. Writing the body without the audit
is not the fallback: an unaudited claim is what this step exists to keep out of the pull
request.

## Step 5 - Pull request

```
git push -u origin <branch>
```

Write the body under `baton:write-deliverables`, as a **PR description**, to a file in
the scratchpad directory. Two things the run knows and a reviewer cannot recover go in it:

- The handoff's "Not verified here" list where it carries one, copied as it stands under
  the body's `## Not verified here` heading.
  Each entry names a screen, a control and an expected result, and Step 3 covered none of
  them - the list is what tells a reviewer which of them to open.
- What Step 3 had to check against: the handoff's acceptance criteria and the commands
  that prove them, with each criterion no test covers named as such, or - where it named
  neither - a sentence saying so, and that `verify` alone checked the change.

Run `pr-create` with that file, with `<category>` and `<pr-base>` as Step 1 resolved them.
Where `<category>` is empty, the backend's notes on its own `pr-create` say what that drops -
a label, or the call that would have set one.

The body states only what Step 4's audit accepted, in the form it accepted it. A corrected
claim is rewritten, a retracted one is left out, and every claim the audit could only label
unverified goes under a `## Not verified here` heading - listed rather than dropped, so a
reviewer knows which claims to probe. With no such claim and no handoff list, there is no
such heading.

The findings the loop left standing go in the body as well, each with its severity and the
reason it stands.

`pr-create` opens a draft, on both shipped routes and whether or not this handoff is part of
a stack. An unattended run's branch has been reviewed by nobody but itself, and a draft says
so to everyone looking at the pull request list. Marking it ready is a stop, above - the
person who reads the branch does that.

Then, **only where the header carries `pr-base`**, run `stack-link` with the pull request
`pr-create` returned and that branch below it. It registers this layer in the stack its base
belongs to. `none` is its shipped default, which skips the call the way it skips `started`'s
and Step 6's: a forge with no stack of its own to register in loses nothing, since the base
`pr-create` already passed is what makes the layer a layer. A `stack-link` failure after
`pr-create` succeeded is a stop of the second shape below - the pull request is open, and the
report says the layer went unregistered.

The issue reference comes from the header, because a merged `closes` shuts an issue
whatever else is outstanding:

| Header | Reference in the body |
|---|---|
| `closes: yes` | the backend's `closes` line |
| `closes: no` | the backend's `refs` line |

Fill that line's `<owner>`, `<repo>` and `<id>` from the locator, per Step 1's table. The
reference names the issue's repository, which is not this pull request's wherever the handoff
was recorded for a repository other than the issue's; there, a bare `#<id>` would reference
whatever issue holds that number here. Where the two are one repository the line reads as it
always did.

Keep what `pr-create` returns. Step 6 addresses the pull request by it and Step 7 reports
it, and nothing else in the run recovers it.

The pull request is open once `pr-create` returns its URL, even where the operation has calls
left to run. A later call in `pr-create` that fails is a stop after Step 5, carrying that URL:
taken for a stop before Step 5, it leaves an open pull request the issue never hears of.

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
   awk '/^## Step 2 /{f=1} /^## Step 4 /{f=0} f' \
     ${CLAUDE_PLUGIN_ROOT}/skills/address-review/SKILL.md
   ```

   The range ends before that skill's Step 4, so its pre-publish question for a human and
   its push gated on approval never reach this run. Empty output means a renamed heading,
   and that is a stop rather than an empty inventory.

   Step 3's end-of-turn stop is not this run's: judge each finding here. Apply the findings
   that hold and run the handoff's commands and `verify` over them - a failure of either is a
   stop. Run them here rather than leaving them to the loop below: that loop's checks sit after
   the findings it applies, so a round applying none skips them, and these fixes would reach
   the pull request with nothing run over them.

   Then commit those fixes and run Step 4 over them with `<target>` set to `<branch>` rather
   than empty, committing each loop round's fixes before the `code-review` that follows them.
   After Step 5's push an empty `<target>` shows only uncommitted fixes, and the compliance
   entry `defining-backends.md` pairs with `code-review` marks UNMET every criterion no hunk
   in front of it satisfies - which is every criterion the pushed commits already meet. Step 4 runs here with a fresh
   cap of three `code-review` rounds - a failure at any of its checks is a stop too - and
   its claim audit over the claims these fixes add or change, which is a second dispatch and
   not a re-reading of the first audit's table.

   Then, in this order: push once, run `pr-update` with a rewritten body, and answer each
   thread with `thread-reply` and anything that arrived outside a thread with `pr-comment`.
   The rewritten body is written the way Step 5 writes one, and starts from Step 5's body
   rather than from this round alone, because this round's audit rules only on the claims
   these fixes add or change. A claim from Step 5's body stays unless this round's audit ruled
   on it, and then takes the form Step 4's verdict table gives. A finding from Step 5's body
   stays unless a fix this round resolved it. To those the body adds the claims this round's
   audit accepted, the findings this round's loop left standing, the `## Not verified here`
   list as it now stands, and - the one line easiest to lose - the same issue reference Step
   5's table chose. `pr-update` replaces the body whole rather than appending to it, so a
   rewrite that drops a `closes` line leaves a pull request that no longer shuts its issue on
   merge. The body describes the branch as it is
   now, and never narrates the round that changed it.

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

Then launch the layer above, where the header carries `next` and **both checks above
passed**. Split the line at its space: the first value names a `## Launcher` entry the
backend defines, and the second is the locator to substitute into it, for the `<locator>` or
`<comment url>` placeholder that entry carries. A first value naming no entry this backend
defines is undefined, and undefined is a stop.

Run it **once, with no retry**, whatever it returns. Two runs on one branch race: both cut
the same branch name, the second takes a suffix at Step 2, and the stack gains a layer nobody
asked for. A launch that fails is reported rather than repeated.

Two things hold it back, and neither is a stop:

- **Either check above failed.** `origin` does not hold this layer's work, so the run above
  would branch from a `pr-base` missing the commits it builds on.
- **Step 2 renamed the branch.** `<branch>` already existed, so this layer sits on
  `<branch>-<6 hex>` while the next layer's `pr-base` still names `<branch>` - a branch
  holding somebody else's work. Launching would stack the layer above onto the wrong history.

Then run `published` with the issue id, the pull request URL from Step 5, and one file
saying what shipped: the URL, the branch, how the handoff's commands and `verify` came out,
any deviation Step 2 recorded, and whether Step 6 ran, timed out, or was skipped - skipped
meaning only that
`request-reviewer` is `none`. After a `keep`, that file also names the worktree path
`.claude/worktrees/<name>` and which of the two checks failed.

Where the header carried `pr-base`, that file names the branch the pull request opens
against and whether `stack-link` ran or is `none`. Where it carried `next`, it records the
launch: the entry run and what it returned, or, when one of the two conditions above held
it back, which one - naming both branch names on a rename, and the locator that went
unlaunched either way. That locator is how a person resumes the stack by hand.

## Stopping

Every stop above takes one of two shapes, set by whether Step 5 has opened the pull request:

- Before it: push nothing, open no pull request, and run `stopped` with one file naming the
  step and what stopped it.
- After it, in Step 5's remaining `pr-create` calls or its `stack-link`, Step 6 or Step 7:
  push nothing further and leave the pull request open. Run `stopped` with one file naming
  the step, what stopped it, and the pull request URL - only Step 7's `published` would
  otherwise carry that URL to the issue.

**A stop before Step 7's launch never launches `next`, and the `stopped` file carries the
locator it did not launch.** A stop there strands every layer above it, and a stop runs
`stopped` rather than `published`, so this file is the only place that locator reaches
anyone. Name it, and say the layer above was not started.

**A stop after the launch ran - a failed `published` - says the layer above was started.**
Name the entry run and what it returned, and do not present the locator as unlaunched: a
person who starts that layer again puts two runs on one branch, the race Step 7 names.

No stop calls `ExitWorktree`. A stop is where work sits unpushed, and Step 7's two checks
are the only thing that establishes it does not. The `stopped` file names the worktree path
`.claude/worktrees/<name>` wherever the worktree still stands, and the branch the run built
on: the work is in that directory, and a relaunch in the same clone takes a new name at Step
2 rather than that branch. A stop after Step 7's removal is the one with no path to name.

Then end the turn. The session stays open, so a reply there resumes the run from the answer
- still in the worktree and still on `<branch>`, which is what Step 2 skips its opening calls
for.

## Done

Both exits end here. Report the pull request URL, the branch and how the handoff's commands
and `verify` came out - or the blocker, the step it stopped at, and the pull request URL
when Step 5 opened one.

A handoff carrying `next` reports the launch too, in whichever form Step 7 recorded it. The
run above is a separate session: this one does not wait for it, watch it, or report anything
about how it went.
