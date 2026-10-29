# Bundled issues

`implement-handoff` and `review-handoff` load this file at Step 1 where the handoff header's
`issue` line names more than one issue. Each section adds to the steps it names.

## Both skills

A header naming several issues is the authorization to move all of them: whoever wrote it
decided this one pull request settles that bundle. `started`, `published`, `reviewed` and
`stopped` walk every issue, as `per-issue-calls.md` says.

Every issue the header names resolves against one repository, the locator's.

## implement-handoff

**Step 5.** `closes` is judged per entry. A bundle that finishes one issue and leaves another
open writes a `closes` line for the first and a `refs` line for the second: a `closes` line on
the second shuts it on merge whatever remains open on it, and the run has no way to reopen it.
An issue whose line goes missing from the body is unlinked on merge, and nothing errors.

**Step 6.** The Run report names every issue and says which reference line each got, so every
issue's participants read the same account of what this one pull request settles.

## review-handoff

**Step 5.** The rewritten body keeps one reference line per issue, each in the form the body
Step 1 read gave it.

**Step 6.** The Run report names every issue.
