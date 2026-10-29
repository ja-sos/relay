# Per-issue calls

`implement-handoff` and `review-handoff` load this file at Step 1. It governs every tracker
call they make once per issue: `started`, `published`, `reviewed` and `stopped`.

## The walk

Run the operation **once per issue the header's `issue` line names, in header order**. Each
call takes one issue as its `<id>`, never the list.

Where a call fails, the run stops on it. The report names the operation, the issue it failed
on, and every issue after that one in the list as **not reached**.

`started` runs again from the first issue when a run resumes after a part-way failure, so an
entry for it must be harmless to repeat, or `none`.

## `stopped`

A stop runs `stopped` over the walk above, every call with the same one file: every issue the
run took on hears that it stopped, not just the primary.

A `stopped` that itself fails part-way through the list ends the run there, with the report the
walk gives. Nothing retries it.

A stop inside a `published` or `reviewed` sequence skips the issues that sequence already
reached. Run `stopped` on the issue that sequence failed on and on every one after it, and let
the file name the ones that did get their `published` or `reviewed`.

Two early stops walk a shorter list, or none:

- The stop on an `issue` and `closes` pair of different lengths has a list - `issue` parsed,
  and only the pairing did not. Run `stopped` on every entry of `issue`.
- A stop earlier than that runs `stopped` on the primary alone where only that parsed, and on
  nothing where `fetch-handoff` itself failed. The report says which issues went unnamed.
