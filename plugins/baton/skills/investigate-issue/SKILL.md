---
name: investigate-issue
description: Use when a tracker issue needs a cause and an approach before any code is written - taking an issue off the backlog, "investigate #12", an invocation naming no issue at all, or checking whether a filed finding still holds. Verifies the finding at current HEAD, names the cause, picks an approach against the issue's constraints, records it as a handoff on the issue, and starts the implementation run the user picks.
---

# Investigate issue

Work out what is wrong behind one issue and leave the answer on the issue. Applies to an
issue describing a defect or a proposal. Does not apply to writing the fix, or to filing
a new issue - `baton:file-issue` covers filing.

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

Then the project's own files:

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

## Step 1 - Load

Without an issue number, resolve one with `baton:next-issue`, put it and everything it skipped
to the user, and wait for confirmation before going on. A resolver returning none is a stop,
not a choice that falls to you.

Run `view` against the issue. An earlier comment may already hold an investigation. Read it
before starting another.

Run `has-handoff` too. When its output carries the handoff marker, read that handoff, put it
to the user with what it already covers, and go no further without their say-so. An issue
waiting on an implementation run is settled work, and investigating it again ends in a second
plan and a second run against the same change. That holds where `baton:implement-handoff`
reported HEAD already satisfying the handoff: what happens to that issue is the user's to
decide.

**The marker may sit in a pointer rather than in a handoff.** An issue bundled into another
issue's handoff carries a pointer: a comment carrying the marker and no fenced header
(`write-handoff` Step 1). Follow it: run `view` against the issue the pointer names and read
the handoff there, then put that handoff to the user as the one covering this issue, naming the
primary issue and quoting the locator the pointer carried. The pointer alone says an issue is
scoped without saying by what, which leaves the user nothing to overrule.

Where that issue carries more than one handoff, put them all to the user with the pointer's
locator beside them and let the user say which one binds. `view` output need not carry a comment
address to match the locator against, so the reader resolves it rather than this step: that
reader is present, which is the whole difference between this skill and `implement-handoff`.

An issue can also carry a pointer **and** a handoff of its own, on separate work. Neither
outranks the other: put both to the user - the handoff read above and the bundle the pointer
names - and go no further without their say-so, the same as for one.

Take the `Found at <sha> on <branch>` line from the body and diff the files it cites:

```
git diff --stat <sha>..HEAD -- <cited paths>
```

Every `file:line` in the body resolves against `<sha>`, not HEAD. When that diff is
non-empty, find each citation by its content and use the HEAD line number from there on.

A body carrying no `Found at` line has no anchor at all. Treat each of its citations as a
line number of unknown age and locate it by content before trusting it.

**A change can span repositories.** Where the issue cites files in a repository other than
this one, that repository is part of the investigation. Read it at the path its row in the
backend's `## Repositories` section gives. A citation resolves against the repository it belongs
to and nothing else, so a line number located in the wrong clone is worse than no line number at
all.

A citation carries no repository of its own, and the `Found at` line anchors only the
repository the issue was filed from (`file-issue` Steps 1 and 4). Attribute each citation by
its path, checking it against this checkout and every mapped repository before assigning it. A
path that resolves in exactly one of them belongs to that one. In this checkout it resolves
against the `Found at` anchor as above; in a mapped repository there is no anchor, so locate it
by content, as a citation with no anchor is above. A path resolving in more than one repository
is ambiguous - say which, and ask rather than picking. A repository the issue cites that
`## Repositories` has no row for cannot be read from here: name that repository and
`${CLAUDE_PLUGIN_ROOT}/reference/defining-backends.md`, and ask the user for the row before
going on rather than investigating it blind.

## Step 2 - Verify

Reproduce at HEAD before forming a theory of the cause.

| Outcome | Action |
|---|---|
| Reproduces | Continue to Step 3. |
| Already fixed | Name the commit that fixed it. Stop. |
| Never held | State the counter-evidence. Stop. |

Where the change spans repositories, reproduce against each one's HEAD, in its own clone, and
record each HEAD as you go. Step 5 writes one handoff per repository and every handoff's
`base` is its own repository's HEAD, so a HEAD not recorded here is a `base` guessed later.

On either stop, report to the user and propose closing - `close-fixed` for a fix that landed,
`close-invalid` for a finding that never held - unless that stop's operation is `none`. Never
close an issue without approval.

Each stop's `none` test reads only its own operation. Where `close-fixed` is `none`, an
`Already fixed` stop reports the fixing commit and proposes no close; where `close-invalid` is
`none`, a `Never held` stop reports the counter-evidence and proposes no close. Either way, say
the close belongs to the tracker's own process.

Either stop ends the investigation, so run `wrap-up` as the last action of the run, with the
arguments Step 6 gives it.

## Step 3 - Cause

Name the cause at `file:line` at HEAD. The cause accounts for every symptom the issue
lists. One that accounts for only some means a second defect is present: report that
separately and keep it out of this investigation.

## Step 4 - Approach

Decide against the constraints the issue names. Its `Fix`, `Proposal` or `Correction`
section lists alternatives so that this step chooses between them rather than inventing a
third. Name what loses, and the constraint that rules it out.

**The issue states the target; the code states where it lands.** Step 3 names where the cause
lives, never whether a part of the issue is needed. Scope comes from the issue and what
it links, including one named as the follow-on, whose target state this one must not foreclose.

Do not propose dropping or deferring a part because nothing in the code requires it yet. Where
the work removes an arrangement, what the code needs today is a product of that arrangement. A
part that looks genuinely unnecessary gets one sentence saying so, and stays in scope.

Settle any decision the user must make here, while the code is in front of you. Stating the
question plainly is also what exposes a mis-framed one - a decision resting on a misread
comment dissolves once it is in words.

**Decide which repositories change, and in what order.** A change spanning repositories that
depend on one another splits by repository, one handoff each. For every repository, name what
its change needs from the repositories below it:

| The change needs | The handoff is |
|---|---|
| nothing another repository has yet to publish | **unheld** - Step 6 launches it |
| another repository's next *published* version - a release, not a branch | **held** - Step 6 reports it, and a person launches it once that release exists |

The dependency is between repositories, so a stack does not express it (`write-handoff` Step 2,
"Both lines are single-repository").

Order the repositories by that dependency: contracts before what is built on them. That order
is what Step 5 puts `closes: yes` at the end of and what Step 6 reports.

Check whether work already exists before proposing any:

```
git branch -a --list '*<n>*'
```

## Step 5 - Record

Write the handoff under `baton:write-handoff`, which posts it to this issue and takes the
body through `baton:write-deliverables`.

Where the approach settles other issues in the same pull request, name them on the header's
`issue` line after this one, each with its own `closes` value. This issue stays first - it
drove the investigation and it keeps the handoff - and `write-handoff` Step 1 posts a pointer
to it on each of the others. Bundle only issues this investigation actually covered; one that
merely looks related is a separate investigation, and `closes: no` is the answer wherever a
bundled issue keeps work beyond this change.

**Every issue on that line lives in the repository this one does** (`write-handoff` Step 2).
An issue in another repository takes a handoff of its own, which the split below writes where
the change spans repositories.

Its `base` is the HEAD that Step 2 reproduced against and Step 3 named the cause at, so
the plan stays falsifiable against the code it was formed on.

**Where the implementation will need a file under the backend's `## Assets` root, list it on
the handoff's `assets` line.** What decides the line is what the run needs, not what this
session happened to open: a file identified here and never read is still a file the run has to
have, and one read here that the plan has already extracted everything from is not. The
implementing session shares no disk with this one, and the run reaches only the asset files
that line lists (`write-handoff` Step 3), so a file left off is a file the run silently builds
without.

List the paths relative to that root, and list only what the implementation needs: each entry
is one more thing that can stop a run. Omit the line where the work needs nothing outside the
repository, which is the usual case.

**One handoff per affected repository.** Where Step 4 named more than one, post one handoff
for each, held and unheld alike, in this same investigation. Each handoff's `repo` names its
own repository, and its `base` is that repository's HEAD from Step 2, so a held handoff is
posted now rather than written later: nothing here asks for a `base` that does not exist yet.
The accepted cost is that a held plan can go stale before it is launched, and what it waits on
is recorded so its reader can tell.

`closes: yes` goes on the one handoff launched last - the top of Step 4's dependency order,
whose pull request finishes the issue - and every other handoff gets `closes: no`, so the
issue stays open while work on it remains.

Where Step 4 split the work into a stack of pull requests, each layer is its own handoff. Post
the layers top first, as `write-handoff` `## Done` requires, with `next` and `pr-base` as its
Step 2 defines them. Where any layer of the stack carries `assets`, `write-handoff` Step 2
constrains the launcher; say so when reporting the entries below.

A `next` line also names the `## Launcher` entry that starts the layer above, so **for a
stack, ask which launcher here** rather than at Step 6 - the answer is written into every
layer but the top before any of them is posted. Report what each entry would do, as Step 6
does. An answer of none of them is not a stack without launchers: it means no `next` lines
and no launch, so every layer has to be started by hand, in order. Say that before taking the
answer. Step 6 then starts the bottom layer through the entry already chosen, and asks
nothing further.

## Step 6 - Launch

Implementation belongs in its own session against its own checkout. Ask which of the
backend's `## Launcher` entries to use, and start only what the answer names. Report what
each would do and create nothing when the answer is none of them. Where Step 5 posted a
stack, that question was already asked and answered there; use that answer and ask again for
nothing.

The entry takes `<skill>` and `<args>`: launch `implement-handoff`, with the locator Step 5
returned as `<args>`. The run launches its reviewer through the same entry
(`defining-backends.md` `## Sections`), so the answer also chooses where the reviewer runs.

**A handoff carrying `assets` cannot run under `cloud`** (`backend-github.md` `## Launcher`),
and the report says so. Report `local` as the shipped entry that resolves those paths, name any
entry of the project's own that starts the run on a machine defining the root, and where the
answer is `cloud` all the same, say what will happen before taking it. A handoff with no
`assets` line is unaffected and launches under either.

**Launch the unheld handoffs; report the held ones.** Start every handoff Step 4 called unheld,
each through the chosen entry and each with its own locator. Then report each held handoff in
the order it is to be launched: its locator, the repository it belongs to, and what it waits
on, named as the upstream repository and the release. Launch none of them. A held handoff's run
would build against an upstream version that does not exist, and the report is what the
developer relaunching it later works from.

**A stack is launched once, at the bottom.** Start the bottom layer alone and nothing else.

Then run `wrap-up` as the last action of the run, with `investigate-issue` as `<skill>` and
the issue number as `<id>`. `<pr-url>` and `<head-branch>` are empty: no pull request exists
yet, and the implementation run cuts its own branch. It runs where the answer names no
launcher too - the investigation ended either way. An undefined `wrap-up` reads as `none`, and
a failed one is reported by name and not retried (`defining-backends.md`, `wrap-up`).

## Done

Stop before editing any file the repo tracks - in every repository this investigation read,
not only this one. A repository reached through `## Repositories` is the user's own working
checkout rather than a copy, so an edit there lands in a tree nobody asked this run to touch.

Report the issue number, the Step 2 outcome, the cause in one line, the chosen approach
in one line, the handoff locator, and where the implementation is running.

Where the change spans repositories, report one line per handoff instead: its repository, its
locator, and either where its run is or - for a held handoff - what it waits on and its place
in the launch order.
