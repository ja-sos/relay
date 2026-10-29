# Stacked handoff

`implement-handoff` and `review-handoff` load this file at Step 1 where the handoff header
carries a `pr-base` line, a `next` line, or both. Each section adds to the steps it names; a
paragraph about one of the two lines applies only where the header carries that line.

`pr-base` names the branch of the layer below, which this layer is cut from and opens its pull
request against. `next` is `<launcher entry> <locator>`: the layer above, launched once this
layer's review has pushed.

## implement-handoff

**May do unasked.** `stack-link` at Step 5, where the header carries `pr-base`. It writes to
the pull request below, which belongs to another handoff: the header asking for a stacked base
is the authorization to register this layer in that stack. The header's `next` is
`review-handoff`'s to launch, never this run's.

**Step 1.** A `pr-base` line is a stop where the loaded `pr-create` entry never contains
`<pr-base>`.

Where the header carries `pr-base`, run this pair in place of the checkout check's two lines:

```
git cat-file -e <base>^{commit} 2>/dev/null || git fetch origin <base>
git cat-file -e <base>^{commit}
```

The second line exiting non-zero is a stop: this clone does not hold `base`. Step 2 checks that
`base` is an ancestor of `origin/<pr-base>`.

Where the header carries `pr-base`, resolve `stack-link` against the loaded backend files too.
Where it carries `next`, resolve the `## Launcher` entry its first value names. Stop where no
loaded file defines either.

**Step 2.** A handoff carrying `pr-base` never takes the no-change exit. Ask nothing of HEAD;
go to `started` and the branch cut.

Where the header carries `pr-base`, cut the branch from that branch's tip on `origin` instead
of from `<base>`:

```
git fetch origin <pr-base>:refs/remotes/origin/<pr-base>
git merge-base --is-ancestor <base> origin/<pr-base>
git switch -c <branch> origin/<pr-base>
```

Name both sides of the fetch's refspec, as written: a single-branch clone creates no
`origin/<pr-base>` from a bare `git fetch origin <pr-base>`. The first line exiting non-zero is
a stop - the layer below has not pushed `<pr-base>`, so this run started out of order. The
second exiting non-zero is a stop - `<pr-base>` is not the branch the plan was formed on top of.
The third exiting non-zero because `<branch>` exists takes the retry the skill's branch cut
gives.

**Step 3.** The tests fail against `origin/<pr-base>`, the branch point, and not against
`<base>`.

**Step 5.** Where the header carries `pr-base`, run `stack-link` with the pull request
`pr-create` returned and that branch below it, once `pr-create` has returned. `none` skips the
call. A `stack-link` failure is a stop after Step 5: the pull request is open, and the report
says the layer went unregistered.

**Step 6.** The Run report names the branch the pull request opens against and whether
`stack-link` ran or is `none`. Where the header carries `next`, it says the reviewer carries
that launch; where the reviewer launch was held back or failed, it quotes the `next` locator as
unlaunched.

**No-change exit and stops.** Where the header carries `next` and the run ends before Step 6's
reviewer launch - the no-change exit, or any stop - the report quotes the `next` locator and
says the layer above was not started. A stop after the launch ran - a failed `published` -
says the reviewer carries `next`, and does not present the locator as unlaunched.

## review-handoff

**May do unasked.** The `## Launcher` entry the header's `next` names, run once at Step 6.

**Step 1.** Note whether the head ref equals the header's `branch`. Where the header carries
`next`, resolve the `## Launcher` entry its first value names, and stop where no loaded file
defines it.

**Step 3.** On a pull request whose header carries `pr-base`, a finding in the layer below is
outside the handoff's scope. A review engine given a branch may compare it with the default
branch rather than with the pull request's base, and show that layer's commits as well.

**Step 6.** Where the header carries `next`, launch the layer above once the worktree is
settled. Split the line at its space: the first value is the `## Launcher` entry Step 1
resolved, run with `implement-handoff` as its `<skill>` and the second value as its `<args>`.
Run it **once, with no retry**, whatever it returns: two runs on one branch race. A launch that
fails is reported rather than repeated.

Two things hold it back, and neither is a stop:

- **`HEAD` and `origin/<head ref>` differ.** The run above would branch from a `pr-base`
  missing the commits it builds on. Output from `git status --porcelain` alone decides the
  worktree, not this launch.
- **The head ref differs from the header's `branch`.** The next layer's `pr-base` names
  `branch`, which holds somebody else's work.

The Run report says what became of `next`: the entry run and what it returned, or which
condition held it back and the locator that went unlaunched.

**Stops.** A stop before Step 6's launch never launches `next`, and the file quotes the locator
it did not launch, saying the layer above was not started. A stop after the launch ran - a
failed `reviewed` - names the entry run and what it returned, and does not present the locator
as unlaunched: starting that layer again puts two runs on one branch.
