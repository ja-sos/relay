---
name: write-handoff
description: Use when work has to continue in a session that does not share this context - launching an implementation run in the cloud or in the background, stopping mid-task, or handing work to another person. Posts the handoff to the issue driving the work, and writes the body under write-deliverables.
---

# Write handoff

Record one unit of ready work on the issue driving it, written to the **Handoff /
context note** contract. Applies when the next session starts cold, on a machine that
need not be this one. Does not apply to a document belonging in the repo, or to an issue
body - `baton:file-issue` covers issues.

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

## Step 1 - Place

The handoff is one record against the issue, posted with `post-handoff` once Steps 2-4 have
written it. The marker is what `has-handoff` finds. The update follows it, and the handoff
sits collapsed beneath, labelled as a work order rather than a decision the project has taken:

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
run on the branch the primary handoff already names.

The pointer puts the marker on its issue. The locator beside it says which handoff on the
primary issue covers this one, where the primary carries more than one.

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

Four optional lines may follow them inside that same block, each written only where it has a
value. Their padding is cosmetic - a header is read by line name, not by column:

```
category: <the issue's label matching a row of the backend's ## Categories table>
pr-base:  <the branch the pull request opens against>
next:     <a ## Launcher entry name> <the locator of the layer above>
assets:   <path> [<path> ...]
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

**The two lists must be the same length.**

**The first entry is the primary issue.** The investigation, this whole handoff comment and the
run's worktree name all come from it, and every other entry gets the pointer Step 1 describes.

`closes` is `yes` on the handoff that finishes the issue and `no` on every other, so the
issue is not marked done while work on it remains. `no` is the safe value whenever the
split is unsettled. It is judged per entry, not per handoff: a bundle that finishes one issue
and leaves another open writes `yes` for the first and `no` for the second.

`category` is the label the pull request will carry. Read the primary issue's own labels -
one pull request carries one label, so a bundle takes the primary's - keep the one matching
a row of the backend's `## Categories` table, and write it exactly as that row
spells it - a project can rename its categories, so the row is the spelling, not this
skill. An issue carrying no such label gets no `category` line.

`pr-base` is for a handoff that is one layer of a stack: its work sits on top of the layer
below, so its pull request opens against that layer's branch rather than the default branch,
and the run cuts its own branch from there. Omit the line everywhere else.

That branch is not checked here, unlike `base`. A stack is written top layer first - see
`## Done` - so at the moment this handoff is posted the layer below has usually not pushed
yet, and a check here would fail on every layer but the bottom one.

`next` names the layer above and authorizes starting it; `review-handoff` Step 6 launches it.
Write two values separated by a space - the name of a `## Launcher` entry the backend defines,
`local` or `cloud` on the shipped one, and the locator `post-handoff` returned for that
layer's handoff. Omit the line on the top layer, and on any handoff that is not part of a
stack; nothing is launched then, which is what every handoff written before this line did.

A layer names `pr-base` and `next` independently. The bottom layer of a stack carries `next`
and no `pr-base`; the top carries `pr-base` and no `next`.

**A layer carrying `assets` does not belong in a cloud stack, and naming `local` in `next`
does not rescue it** (`backend-github.md` `## Launcher`; `defining-backends.md`, "Tools an
unattended run needs"). A stack with a layer that needs assets runs entirely on the machine
holding them, with `local` in every `next` line, or the layer below it carries no `next` and
that layer is started by hand there, keeping its own `next` for the layer above. Settle this
before posting, because the `next` lines are written on the way down and a layer's own header
is fixed once it is posted.

**Both lines are single-repository.** `pr-base` names a branch in the repository `repo` gives,
and neither line chains repositories. A handoff for a repository downstream of another waits on
that upstream repository's next *published* version, which no run produces and no branch
stands for, so such a handoff carries neither line.

`assets` names files the work needs that live outside every repository, in the one folder the
backend's `## Assets` section roots. Write each path relative to that root, separated by
spaces as `issue` and `next` are; each may name a file or a directory. Omit the line wherever
the work needs nothing outside the checkout, which is most handoffs and every one written
before baton 0.1.15 - a handoff with no `assets` line needs no `## Assets` section anywhere,
and nothing below runs for it.

A path is valid only where **every character is a letter, a digit, `.`, `-`, `_` or `/`**, it
does not start with `/`, and no segment of it is `..`. The last two keep the path inside the
root. The character rule keeps it out of a shell: the path is spent inside `test -e` by this
step and again by the run, so a quote, a `$`, a backtick or a `;` in it would execute there.
Whitespace is not on the list either, which is why a file whose name has a space is named by
listing its containing directory instead.

**Check the line before posting**, in this order. A loaded backend file must define
`## Assets`; its `root` must be an absolute path to an existing directory; and each listed
path must be valid and exist under that root:

```
test -d "<root>"
test -e "<root>/<path>"
```

An undefined `## Assets`, a missing or unusable `root`, an invalid path, or a path `test -e`
does not find is a stop for this handoff alone, naming every path that failed; the other
handoffs of the same investigation are unaffected. Check `root` before any path: an empty one
turns the second line into `test -e "/<path>"`, which answers about the filesystem root and
can pass on a file nobody meant. The check runs here because the session that reads the
handoff has nobody to ask where a file went.

Assets are read-only to the run (`implement-handoff`, "What this run may do unasked"). Name
what the run should read out of an asset, never what it should do to it.

## Step 3 - Body

Write the body under `baton:write-deliverables`, as a **Handoff / context note**.

A handoff that asks its reader to decide something does not ship. The session reading it has
no one to ask, so a banked question stalls that run and returns the decision to the user
anyway - later, and with the work halted. Settle it before posting and fold the answer in.
Record only what cannot be settled until implementation is under way.

Name nothing that exists only on this machine. Cite code as repo-relative `file:line`; an
absolute path, a home directory or a hostname resolves to nothing in the session that
reads it.

**An asset is the one exception.** Where the header carries an `assets` line, the body may name
a file that line lists, by that same path relative to the `## Assets` root and by nothing else.
It resolves in the reading session because Step 2 checked it. Absolute paths, home directories
and hostnames stay banned, an asset's among them: the root is the backend's to supply per
machine, and a body that spells it out is wrong on the next one.

**Call it an asset where you name it.** A bare relative path reads as a repo-relative citation
like every other one in the body, and the reading session would look for it in the checkout
and find nothing - so write "the asset `config/prod.yaml`", or name it under a heading that
says so. Only paths the `assets` line lists may be named this way; a path that is not on the
line is a path the run will not have.

Up to four sections beyond that contract turn the body into a spec the implementing session
can check itself against - three always, and a fourth where the change needs one. They
belong to this collapsed implementation handoff and never to the update Step 4 writes above
it, which is read by the issue's participants and states no criteria:

1. **Steps**, numbered, for the code change - what to edit, in what order.
2. **Acceptance criteria**, numbered, each one an outcome a test can cover and someone who
   was not here can check against the diff. An outcome, not an edit: "a handoff without the
   sections runs with `verify` alone" is a criterion, "add a paragraph to Step 3" is a step,
   and "the review is thorough" is neither. Cover every part of the approach, since a part
   no row names is a part nothing checks.
3. **Commands** that prove those criteria. Every one is headless: the implementation run is
   unattended, so a command opening a window or waiting on a keypress hangs it with nobody
   there to answer. Name the output that counts as a pass beside each, since the run has no
   other way to read the result.
4. **Not verified here**, listing anything needing eyes on a running application: the
   screen, the control, and the expected result, for the reviewer who can open them
   (`implement-handoff` Step 5 copies it into the pull request body). Write it only where the
   change has something to check in a running application, and leave the section out where
   it has nothing: an empty list copied into every pull request body tells the reviewer
   nothing, and pushes the run to fill it with entries that are not checks.

The first three are must-include for every implementation handoff, and the fourth for one
whose change has something to check in a running application. They sit alongside the four
the **Handoff / context note** contract lists. They are named here rather than in that
contract because it also covers the note left when stopping mid-task, which has no criteria
to state. Carry the ones this handoff writes into the Step 2 brief as part of `GOAL`, **Not
verified here** included where it applies, or the outline verdict cuts them as sections no
reader question asks for - the reader here is a run that cannot check itself without them.

Write the criteria for the person reviewing the pull request - they are the list that reviewer
ticks off, and a row only a machine could settle helps nobody.

A handoff for work no test reaches says so under the criteria and still carries Steps,
Acceptance criteria and Commands; `implement-handoff` Step 3 says how it proves such a
criterion.

## Step 4 - Update

Write the update under `baton:write-deliverables` as a separate document.
Its reader is the issue's participants, not the implementation run. It carries the cause, the
approach chosen and what it rules out, and the next step.

Every claim in the update is one the handoff also makes: a claim found only there reaches the
run without the handoff's reasoning.

## Done

`post-handoff` runs once per issue the header names, primary first. That order is forced: the
pointers carry the locator the primary's call returns.

A pointer call that fails is a stop, and the report names which issues carry the marker and
which do not - and the primary locator too, even though the stop lands before `## Done`,
because nothing else in the run recovers it. The primary handoff is already posted by then and
stays posted: it names the whole bundle and is still the handoff to run. What an issue without
its pointer loses is the marker. Post the missing pointer by hand and the bundle is whole
again - nothing here edits a posted comment, so the header stands as written either way.

Print the locator the **primary** call returns, which addresses this handoff rather than the
issue. The pointers' own locators address nothing a run can read, and naming one to a
launcher starts a run with no handoff to work from. Print it as it came back, unparsed.

An issue splits into several handoffs whenever its fix lands as more than one change, so
the issue number addresses none of them and whatever launches the work takes the locator.

**A stack is written top layer first.** Each layer's `next` carries the locator of the layer
above, which exists only once that layer's handoff is posted, so the order is forced: post
the top layer, then the one below it carrying that locator as its `next`, down to the bottom.
Every layer is posted before any of them runs. That is what lets each one name a `pr-base`
branch nothing has pushed yet, and it is why the branch is checked in the run rather than
here.

Starting that work is the caller's decision, not this skill's. For a stack it is one
decision: launch the bottom layer, and `review-handoff` Step 6 launches each layer above.
