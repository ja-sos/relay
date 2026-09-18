---
name: write-handoff
description: Use when work has to continue in a session that does not share this context - launching an implementation run in the cloud or in the background, stopping mid-task, or handing work to another person. Posts the handoff to the issue driving the work, and writes the body under write-deliverables.
---

# Write handoff

Record one unit of ready work on the issue driving it, written to the **Handoff /
context note** contract. Applies when the next session starts cold, on a machine that
need not be this one. Does not apply to a document belonging in the repo, or to an issue
body - `baton:file-issue` covers issues.

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

## Step 1 - Place

The handoff is one record against the issue, posted with `post-handoff` once Steps 2-4 have
written it - a comment by default, and whatever the backend says otherwise. The marker is
what `has-handoff` finds. The update follows it, and the handoff sits collapsed beneath,
labelled as a work order rather than a decision the project has taken:

````
<!-- claude-handoff -->
## Investigation

<update - Step 4>

<details>
<summary>Implementation handoff - what one implementation run will attempt</summary>

```
<header - Step 2>
```

<body - Step 3>

</details>
````

Keep the blank lines inside `<details>` as shown. Without the one after `<summary>`, GitHub
renders the fenced header as literal backticks.

Where the header names more than one issue, that whole comment goes on the **primary** issue -
the first entry of `issue` - and every other issue named gets a pointer to it, posted with
`post-handoff` as well and written to a file of its own, since that operation takes a path:

```
<!-- claude-handoff -->
This issue is bundled into the handoff on issue <primary id>: <locator>
That handoff carries the header, the approach and the acceptance criteria for this issue
as well.
```

The marker is the first line and there is **no fenced header anywhere in it**. With one the
pointer would read as a second handoff, and a launcher handed its locator would start a second
run on the branch the primary handoff already names - two runs on one branch, which is the
race `implement-handoff` Step 7 exists to prevent.

What the pointer buys is the marker on that issue. `has-handoff` looks for nothing else, so a
bundled issue is skipped by `next-issue` exactly as its primary is, and `investigate-issue`
reads the primary handoff by looking at the issue the pointer names.

Bundle only issues this investigation actually settled - it is a judgement made from the work
just done, and nothing here checks it. An issue already waiting on a handoff of its own is
work another run is about to do, and bundling it puts two runs on the same ticket, one of
which may carry `closes: yes` and shut it while the other's work is still outstanding. Where
such an issue belongs in the bundle anyway, `closes` for it is `no`.

Work no issue drives has nowhere to anchor. A session on another machine reaches the
tracker and nothing else - no file of this machine's, and no path that resolves. Open the
issue first; `baton:file-issue` covers that.

Post a second handoff for rework rather than editing the first, which alone carries the
approach that failed and the constraint that ruled the alternatives out.

## Step 2 - Header

First inside the collapsed section, five required lines in a fenced block - a tracker renders
consecutive lines as one paragraph, so an unfenced header arrives as prose:

```
repo:   <owner>/<name>
base:   <sha the plan was formed against>
issue:  <number, or several separated by spaces>
closes: <yes or no, one value per issue in the same order>
branch: <branch the work belongs on>
```

Three optional lines may follow them inside that same block, each written only where it has a
value. Their padding is cosmetic - a header is read by line name, not by column:

```
category: <the issue's label matching a row of the backend's ## Categories table>
pr-base:  <the branch the pull request opens against>
next:     <a ## Launcher entry name> <the locator of the layer above>
```

`base` must already be on `origin`, because a session that clones never sees a commit
held only here. Run the check in the clone of the repository the `repo` line names:

```
git -C <repo root> branch -r --contains <sha>
```

Empty output is a stop: push first, or record a `base` that is pushed.

`<repo root>` is the current checkout's root - `git rev-parse --show-toplevel` - wherever
`repo` names the repository this session is in, which is every handoff for a change that
spans one repository. Where `repo` names another repository, it is that repository's path in
the backend's `## Repositories` section. A repository with no row there is a stop for this
handoff, and the other handoffs of the same investigation are unaffected: the commit cannot
be checked in the only clone this machine offers for it, and the check run in the wrong clone
answers confidently about the wrong repository rather than failing.

`issue` names every issue this handoff's pull request settles, separated by spaces, and
`closes` carries one value per issue in the same order: `issue: 15 16 17` pairs with
`closes: yes no yes`. Space separation is the `next` line's, below. One value in each is a
handoff naming one issue - every handoff written before baton 0.1.12, and what a run does with
it is unchanged. Every entry names an issue in the repository this handoff is posted in,
which is where `post-handoff` puts the pointers too - not necessarily the `repo` line's
repository, which names where the work goes.

**The two lists must be the same length.** `implement-handoff` Step 1 stops on a pair that is
not, rather than pairing what it can: a guess that lands on `yes` shuts an issue this handoff
said to leave open, and a merge cannot be taken back.

**The first entry is the primary issue.** The investigation, this whole handoff comment and the
run's worktree name all come from it, and every other entry gets the pointer Step 1 describes.

`closes` is `yes` on the handoff that finishes the issue and `no` on every other, so the
issue is not marked done while work on it remains. `no` is the safe value whenever the
split is unsettled. It is judged per entry, not per handoff: a bundle that finishes one issue
and leaves another open writes `yes` for the first and `no` for the second, and the run writes
each issue's reference line from that issue's own value.

`category` is the label the pull request will carry. Read the primary issue's own labels -
one pull request carries one label, so a bundle takes the primary's - keep the one matching
a row of the backend's `## Categories` table, and write it exactly as that row
spells it - a project can rename its categories, so the row is the spelling, not this
skill. An issue carrying no such label gets no `category` line, and the run opens an
unlabelled pull request.

`pr-base` is for a handoff that is one layer of a stack: its work sits on top of the layer
below, so its pull request opens against that layer's branch rather than the default branch,
and the run cuts its own branch from there. Omit the line everywhere else.

That branch is not checked here, unlike `base`. A stack is written top layer first - see
`## Done` - so at the moment this handoff is posted the layer below has usually not pushed
yet, and a check here would fail on every layer but the bottom one. `implement-handoff`
Step 2 checks it instead, at the one moment it has to hold: when the run cuts its branch.

`next` names the layer above, and it is the authorization to start that layer: the run that
finishes this one launches it at `implement-handoff` Step 7, once and with no retry. Write
two values separated by a space - the name of a `## Launcher` entry the backend defines,
`local` or `cloud` on the shipped one, and the locator `post-handoff` returned for that
layer's handoff. Omit the line on the top layer, and on any handoff that is not part of a
stack; nothing is launched then, which is what every handoff written before this line did.

A layer names `pr-base` and `next` independently. The bottom layer of a stack carries `next`
and no `pr-base`; the top carries `pr-base` and no `next`.

**Both lines are single-repository.** `pr-base` names a branch in the repository `repo` gives,
and `next` fires at `implement-handoff` Step 7, the moment the layer below opens its pull
request. Neither chains repositories. What a handoff for a repository downstream of another
waits on is that upstream repository's next *published* version, which no run produces and no
branch stands for, so such a handoff carries neither line: it is posted with the rest and
launched by hand, in the order `investigate-issue` Step 6 reports.

## Step 3 - Body

Write the body under `baton:write-deliverables`, as a **Handoff / context note**.

A handoff that asks its reader to decide something does not ship. The session reading it has
no one to ask, so a banked question stalls that run and returns the decision to the user
anyway - later, and with the work halted. Settle it before posting and fold the answer in.
Record only what cannot be settled until implementation is under way.

Name nothing that exists only on this machine. Cite code as repo-relative `file:line`; an
absolute path, a home directory or a hostname resolves to nothing in the session that
reads it.

Four sections beyond that contract turn the body into a spec the implementing session can
check itself against. They belong to this collapsed implementation handoff and never to
the update Step 4 writes above it, which is read by the issue's participants and states no
criteria:

1. **Steps**, numbered, for the code change - what to edit, in what order.
2. **Acceptance criteria**, numbered, each one an outcome a test can cover and someone who
   was not here can check against the diff. An outcome, not an edit: "a handoff without the
   sections runs with `verify` alone" is a criterion, "add a paragraph to Step 3" is a step,
   and "the review is thorough" is neither. Cover every part of the approach, since a part
   no row names is a part nothing checks.
3. **Commands** that prove those criteria, which `implement-handoff` Step 3 runs and reruns
   after every round of fixes. Every one is headless: that run is unattended, so a command
   opening a window or waiting on a keypress hangs it with nobody there to answer. Name
   the output that counts as a pass beside each, since the run has no other way to read
   the result.
4. **Not verified here**, listing anything needing eyes on a running application: the
   screen, the control, and the expected result. The run carries this list into the pull
   request body, so it reaches the reviewer who can open them.

These four are must-include for the implementation handoff, alongside the four the **Handoff / context
note** contract lists. They are named here rather than in that contract because it also
covers the note left when stopping mid-task, which has no criteria to state. Carry them
into the Step 2 brief as part of `GOAL`, or the outline verdict cuts Acceptance criteria
and Commands as sections no reader question asks for - the reader here is a run that
cannot check itself without them.

Each criterion changes what that run does. `implement-handoff` Step 3 writes at least one
test for it, and Step 4 classes a review finding that contradicts it as Critical rather than
a remark. Nothing in the shipped backend walks the list row by row against the diff: only a
backend that has paired `code-review` with an `agent:` compliance reviewer gets that check.
Write the criteria for the person reviewing the pull request either way - they are the list
that reviewer ticks off, and a row only a machine could settle helps nobody.

A handoff for work no test reaches states that under the criteria rather than dropping the
sections, and `implement-handoff` Step 3 proves such a criterion with the Commands alone.
Dropped, the sections are indistinguishable from a handoff written before baton 0.1.7,
which the run executes with `verify` alone.

## Step 4 - Update

Write the update under `baton:write-deliverables` as a separate document.
Its reader is the issue's participants, not the implementation run. It carries the cause, the
approach chosen and what it rules out, and the next step.

Every claim in the update is one the handoff also makes. `fetch-handoff` returns the whole
comment, so the run reads the update too, and a claim found only there reaches the run
without the handoff's reasoning.

## Done

`post-handoff` runs once per issue the header names, primary first. That order is forced: the
pointers carry the locator the primary's call returns. The operation's signature does not
change - each call takes one `<id>` and one file, and never a list.

A pointer call that fails is a stop, and the report names which issues carry the marker and
which do not - and the primary locator too, even though the stop lands before `## Done`,
because nothing else in the run recovers it. The primary handoff is already posted by then
and stays posted: it names the whole bundle and is still the handoff to run. What an issue
without its pointer loses is the marker, so `next-issue` offers it as fresh work and a second
investigation of it begins. Post the missing pointer by hand and the bundle is whole again -
nothing here edits a posted comment, so the header stands as written either way.

Print the locator the **primary** call returns, which addresses this handoff rather than the
issue. The pointers' own locators address nothing a run can read, and naming one to a
launcher starts a run with no handoff to work from. Print it as it came back, unparsed: only
the backend's own `fetch-handoff` has to understand its shape.

An issue splits into several handoffs whenever its fix lands as more than one change, so
the issue number addresses none of them and whatever launches the work takes the locator.

**A stack is written top layer first.** Each layer's `next` carries the locator of the layer
above, which exists only once that layer's handoff is posted, so the order is forced: post
the top layer, then the one below it carrying that locator as its `next`, down to the bottom.
Every layer is posted before any of them runs. That is what lets each one name a `pr-base`
branch nothing has pushed yet, and it is why the branch is checked in the run rather than
here.

Starting that work is the caller's decision, not this skill's. For a stack it is one
decision: launch the bottom layer, whose `next` carries the rest up.
