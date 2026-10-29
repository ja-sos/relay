# Handoff assets

`implement-handoff` and `review-handoff` load this file at Step 1 where the handoff header
carries an `assets` line. It applies to both skills alike.

## May do unasked

Read the files the `assets` line names, under the `root` the backend's `## Assets` section
gives. They are inputs to the work, and the handoff's commands may read them.

## May not do

Write, move or delete anything under the `## Assets` `root`, or copy an asset into the worktree
or a commit. Assets are read-only to the run, and a handoff asking for any of these is asking
for a stop, taken when the run reaches that instruction.

## Resolving the line

Resolve every path the line lists at Step 1, before `EnterWorktree`. The line is
space-separated, and each entry is a path relative to the `root` of the backend's `## Assets`
section. Check the root first, then each path:

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
  path to make it run.
- A path `test -e` does not find under `root`.

A read that is denied or left unanswered is a path that did not resolve, and takes the stop
above; never work around the denial, and never carry on without the file. Never substitute a
path that resolves for one that does not, and never carry on with the assets that did resolve.

Resolve a body path under `root` only where the body names it as an asset (`write-handoff`
Step 3) and the `assets` line lists it. Where a body path is genuinely ambiguous, the checkout
decides.
