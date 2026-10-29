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
not define.

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

Keep the blank lines inside `<details>` as shown.

Where the header names more than one issue, that whole comment goes on the **primary** issue -
the first entry of `issue` - and every other issue named gets a pointer to it, posted with
`post-handoff` as well and written to a file of its own:

```
<!-- claude-handoff -->
This issue is bundled into the handoff on issue <primary id>: <locator>
That handoff carries the header, the approach and the acceptance criteria for this issue
as well.
```

The marker is the first line and there is **no fenced header anywhere in it**.

The pointer puts the marker on its issue. The locator beside it says which handoff on the
primary issue covers this one, where the primary carries more than one.

Bundle only issues this investigation actually settled. An issue already waiting on a handoff of its own is
work another run is about to do, and bundling it puts two runs on the same ticket, one of
which may carry `closes: yes` and shut it while the other's work is still outstanding. Where
such an issue belongs in the bundle anyway, `closes` for it is `no`.

Work no issue drives has nowhere to anchor. Open the
issue first; `baton:file-issue` covers that.

Post a second handoff for rework rather than editing the first.

## Step 2 - Header

First inside the collapsed section, five required lines in a fenced block:

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

`base` must already be on `origin`. Run the check in the clone of the repository the `repo` line names:

```
git -C <repo root> branch -r --contains <sha>
```

Empty output is a stop: push first, or record a `base` that is pushed.

`<repo root>` is the current checkout's root - `git rev-parse --show-toplevel` - wherever
`repo` names the repository this session is in, which is every handoff for a change that
spans one repository. Where `repo` names another repository, it is that repository's path in
the backend's `## Repositories` section. A repository with no row there is a stop for this
handoff, and the other handoffs of the same investigation are unaffected.

`issue` names every issue this handoff's pull request settles, separated by spaces, and
`closes` carries one value per issue in the same order: `issue: 15 16 17` pairs with
`closes: yes no yes`. Space separation is the `next` line's, below. One value in each is a
handoff naming one issue. Every entry names an issue in the repository this handoff is posted in,
which is where `post-handoff` puts the pointers too - not necessarily the `repo` line's
repository, which names where the work goes.

**The two lists must be the same length.**

**The first entry is the primary issue.** The investigation, this whole handoff comment and the
run's worktree name all come from it, and every other entry gets the pointer Step 1 describes.

`closes` is `yes` on the handoff that finishes the issue and `no` on every other. `no` is the safe value whenever the
split is unsettled. It is judged per entry, not per handoff: a bundle that finishes one issue
and leaves another open writes `yes` for the first and `no` for the second.

`category` is the label the pull request will carry. Read the primary issue's own labels -
a bundle takes the primary's - keep the one matching
a row of the backend's `## Categories` table, and write it exactly as that row
spells it. An issue carrying no such label gets no `category` line.

`pr-base` is for a handoff that is one layer of a stack: its work sits on top of the layer
below, so its pull request opens against that layer's branch rather than the default branch,
and the run cuts its own branch from there. Omit the line everywhere else.

That branch is not checked here, unlike `base`.

`next` names the layer above and authorizes starting it; `review-handoff` Step 6 launches it.
Write two values separated by a space - the name of a `## Launcher` entry the backend defines,
`local` or `cloud` on the shipped one, and the locator `post-handoff` returned for that
layer's handoff. Omit the line on the top layer, and on any handoff that is not part of a
stack; nothing is launched then.

A layer names `pr-base` and `next` independently. The bottom layer of a stack carries `next`
and no `pr-base`; the top carries `pr-base` and no `next`.

**A layer carrying `assets` does not belong in a cloud stack, and naming `local` in `next`
does not rescue it** (`backend-github.md` `## Launcher`; `defining-backends.md`, "Tools an
unattended run needs"). A stack with a layer that needs assets runs entirely on the machine
holding them, with `local` in every `next` line, or the layer below it carries no `next` and
that layer is started by hand there, keeping its own `next` for the layer above. Settle this
before posting.

**Both lines are single-repository.** `pr-base` names a branch in the repository `repo` gives,
and neither line chains repositories. A handoff for a repository downstream of another waits on
that upstream repository's next *published* version, so such a handoff carries neither line.

`assets` names files the work needs that live outside every repository, in the one folder the
backend's `## Assets` section roots. Write each path relative to that root, separated by
spaces as `issue` and `next` are; each may name a file or a directory. Omit the line wherever
the work needs nothing outside the checkout, which is most handoffs - a handoff with no `assets` line needs no `## Assets` section anywhere,
and nothing below runs for it.

A path is valid only where **every character is a letter, a digit, `.`, `-`, `_` or `/`**, it
does not start with `/`, and no segment of it is `..`.
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
handoffs of the same investigation are unaffected. Check `root` before any path.

Assets are read-only to the run (`reference/handoff-assets.md`, "May not do"). Name
what the run should read out of an asset, never what it should do to it.

## Step 3 - Body

Write the body under `baton:write-deliverables`, as a **Handoff / context note**.

A handoff that asks its reader to decide something does not ship. Settle it before posting and fold the answer in.
Record only what cannot be settled until implementation is under way.

Name nothing that exists only on this machine. Cite code as repo-relative `file:line`; an
absolute path, a home directory or a hostname resolves to nothing in the session that
reads it.

**An asset is the one exception.** Where the header carries an `assets` line, the body may name
a file that line lists, by that same path relative to the `## Assets` root and by nothing else.
Absolute paths, home directories
and hostnames stay banned, an asset's among them.

**Call it an asset where you name it.** Write "the asset `config/prod.yaml`", or name it under a heading that
says so. Only paths the `assets` line lists may be named this way.

Up to four sections beyond that contract turn the body into a spec the implementing session
can check itself against - three always, and a fourth where the change needs one. They
belong to this collapsed implementation handoff and never to the update Step 4 writes above
it, which is read by the issue's participants and states no criteria:

1. **Steps**, numbered, for the code change - what to edit, in what order.
2. **Acceptance criteria**, numbered, each one an outcome a test can cover and someone who
   was not here can check against the diff. An outcome, not an edit: "a handoff without the
   sections runs with `verify` alone" is a criterion, "add a paragraph to Step 3" is a step,
   and "the review is thorough" is neither. Cover every part of the approach.
3. **Commands** that prove those criteria. Every one is headless. Name the output that counts as a pass beside each.
4. **Not verified here**, listing anything needing eyes on a running application: the
   screen, the control, and the expected result, for the reviewer who can open them
   (`implement-handoff` Step 5 copies it into the pull request body). Write it only where the
   change has something to check in a running application, and leave the section out where
   it has nothing.

The first three are must-include for every implementation handoff, and the fourth for one
whose change has something to check in a running application. They sit alongside the four
the **Handoff / context note** contract lists. Carry the ones this handoff writes into the Step 2 brief as part of `GOAL`, **Not
verified here** included where it applies.

Write the criteria for the person reviewing the pull request - they are the list that reviewer
ticks off, and a row only a machine could settle helps nobody.

A handoff for work no test reaches says so under the criteria and still carries Steps,
Acceptance criteria and Commands; `implement-handoff` Step 3 says how it proves such a
criterion.

## Step 4 - Update

Write the update under `baton:write-deliverables` as a separate document.
Its reader is the issue's participants, not the implementation run. It carries the cause, the
approach chosen and what it rules out, and the next step.

Every claim in the update is one the handoff also makes.

## Done

`post-handoff` runs once per issue the header names, primary first.

A pointer call that fails is a stop, and the report names which issues carry the marker and
which do not - and the primary locator too. The primary handoff is already posted by then and
stays posted: it names the whole bundle and is still the handoff to run. What an issue without
its pointer loses is the marker. Post the missing pointer by hand and the bundle is whole
again - nothing here edits a posted comment, so the header stands as written either way.

Print the locator the **primary** call returns, which addresses this handoff rather than the
issue. Print it as it came back, unparsed. Never print a pointer's locator for a launcher: it
addresses nothing a run can read.

**A stack is written top layer first.** Post
the top layer, then the one below it carrying that layer's locator as its `next`, down to the bottom.
Every layer is posted before any of them runs.

Starting that work is the caller's decision, not this skill's. For a stack it is one
decision: launch the bottom layer, and `review-handoff` Step 6 launches each layer above.
