# Changelog

What changed in each baton version that a backend file, a restated section or a handoff
written for an earlier version has to account for. Newest first.

## 0.3.5

- `review-handoff` replies to the findings of the reviewer `request-reviewer` named, at Step 6
  before `reviewed`: one `thread-reply` in each review thread that reviewer opened, and one
  `pr-comment` for that reviewer's findings from `review-bodies` and `pr-comments`, each giving
  the finding's disposition and its evidence. Nothing is posted where `request-reviewer` is
  `none`, where the wait timed out, or to a thread anyone else opened. A failed reply is recorded
  in the Run report and does not stop the run (#62).
- A backend restating `## Review` without `thread-reply` or `pr-comment` now stops
  `review-handoff` at Step 1 wherever `request-reviewer` is not `none`.
- `reviewing-run-output.md` records each thread's first-comment id and author, five facts
  per thread instead of three.
- `write-deliverables` gains a **Review reply** document type, written to fit the replies
  `address-review` posts as well; `address-review` does not yet name it.

## 0.3.4

- The `cloud` entry of `backend-github.md`'s `## Launcher` starts a cloud session directly,
  with `create_session`, or with `claude --cloud` where the session has no `create_session`. It
  no longer lists, creates, updates or fires the `implement <owner>/<repo>` and
  `review <owner>/<repo>` routines. A run whose session has neither tool stops at Step 1 of
  `implement-handoff`, or of `review-handoff` where the header carries `next`, instead of
  reaching a routine. The routines stay on claude.ai/code/routines until
  deleted there.
- The entry looks for `create_session` among the session's loaded tools before `ToolSearch`,
  which does not return a loaded tool.
- A `cloud` entry restated in `.claude/baton.md` or `~/.claude/baton.md` keeps its routine
  routes until it is deleted or the shipped entry is copied in again. A restatement that only
  pins a routine's `environment_id` has nothing left to pin: delete it.

## 0.3.3

- The claim-audit hook, `hooks/gate-subagent-claim-audit.sh`, runs on `SubagentStart` and
  returns its instruction as `additionalContext`, which lands in the subagent's own context. It
  no longer runs on `PreToolUse` and no longer rewrites the `Agent` call's input through
  `updatedInput`, which auto mode refused on Claude Code 2.1.317 (#59). It needs no python,
  python3 or node.
- A dispatch prompt naming `claim-audit` no longer suppresses the hook: `SubagentStart` input
  carries no prompt to test, so such a dispatch receives the instruction twice.

## 0.3.2

- `implement-handoff` and `review-handoff` now fix a failing check and re-run it, under the new
  `reference/fixing-check-failures.md`, which both load before Step 1. A failing check sequence
  gets 3 fix attempts each time it runs, each re-running the sequence from its first step. A
  failure stays a stop where it also occurs at the branch's merge-base, where its fix would edit
  a file the branch's diff does not change or a failing test's assertions, or where no fix is
  found. Run reports and Stopping files name each failure and the fix applied for it.
- The `cloud` entry of `backend-github.md`'s `## Launcher` tries `create_session` first, with no
  `list_triggers` call, then `RemoteTrigger`, then `list_triggers` with `fire_trigger`. The
  `fire_trigger` route and the launch check exclude a routine whose `created_via` is `http_api`,
  which `fire_trigger` refuses. A `cloud` entry restated in `.claude/baton.md` or
  `~/.claude/baton.md` from an earlier version keeps the old route order, and no update to this
  plugin reaches it: copy the shipped entry again.

## 0.3.1

- The `cloud` entry of `backend-github.md`'s `## Launcher` no longer claims that a
  `claude --cloud` session arrives with an uploaded copy of the checkout and no remote, or that
  a routine without `sources` gets no repository. A `cloud` entry restated in
  `.claude/baton.md` or `~/.claude/baton.md` from an earlier version keeps the old wording, and
  no update to this plugin reaches it: copy the shipped entry again.

## 0.3.0

- `implement-handoff` runs no `code-review`. Its review loop and its wait-and-fix round are
  gone, and its steps are renumbered: the claim audit is Step 4, the pull request Step 5 and the
  report Step 6. `review-handoff` is the only unattended review.
- `request-reviewer` and `review-wait` now drive `review-handoff` Step 3: it requests the
  external reviewer, runs its first `code-review` round while the review is pending, and waits
  out what remains of `review-wait` before collecting threads. A `## Workflow` that sets
  `request-reviewer` needs no edit, but the reviewer's threads are now collected and fixed by
  `review-handoff` rather than by `implement-handoff`, and `review-handoff` resolves
  `review-list` and `pr-comments` before it starts wherever `request-reviewer` is not `none`.
- `review-handoff`'s loop ends after the first round with no Critical finding, or at three
  rounds. Rounds after the first review only the previous round's uncommitted fixes, with an
  empty `<target>`. The handoff's commands run after each fixing round; `verify` runs once, before
  the push.
- `write-deliverables` gains a short path for the pull request bodies and Run reports
  `implement-handoff` and `review-handoff` write, and exempts from G11 a claim a claim audit in
  the same run already ruled on.
- The stacked-handoff, assets and several-issue branches of both unattended skills moved to
  `reference/stacked-handoff.md`, `reference/handoff-assets.md` and
  `reference/bundled-issues.md`, loaded only where the header carries the matching line. The
  per-issue call walk is stated once, in `reference/per-issue-calls.md`.
- The shipped `cloud` launcher also runs on the `claude-code-remote` server's `list_triggers`,
  `update_trigger`, `fire_trigger` and `create_session`, where `RemoteTrigger` does not load. A
  cloud session can lack `RemoteTrigger`, and a `cloud` entry restated in `.claude/baton.md` or
  `~/.claude/baton.md` on `RemoteTrigger` alone fails there: copy the shipped entry again.
- `implement-handoff` Step 1, and `review-handoff` Step 1 where the header carries `next`, now
  stop where this session cannot launch through the `## Launcher` entry it will use, instead of
  finding out after the pull request is open.
- Rationale moved from the skills and reference files to `maintainers-notes.md`, and
  version-upgrade notes to this file.

## 0.2.3

- `pr-issues` is a new `## Forge` operation. A `## Forge` restated before 0.2.3 leaves it
  undefined, and `address-review` stops at Step 1: add `- **pr-issues:**       none`, or the
  entry that reads the project's own convention.

## 0.1.22

- `closes` and `refs` each take `none` on their own.

## 0.1.19

- `list-categories` takes `none`, for a tracker that carries no labels at all. A baton before
  0.1.19 reads `none` there as undefined and stops.

## 0.1.15

- `## Assets` is a new optional section. A backend with no `## Assets` behaves as one did
  before 0.1.15 for every handoff carrying no `assets` line, which is every handoff written
  before 0.1.15.

## 0.1.12

- A handoff's `issue` and `closes` lines may name several issues. A handoff written before
  0.1.12 names one, and what a run does with it is unchanged.

## 0.1.11

- `## Repositories` is a new optional section.
- `closes` and `refs` gained `<owner>` and `<repo>`. A `## Forge` restated before 0.1.11 still
  carries the bare, unqualified form, and nothing errors: it resolves against the pull
  request's own repository, which is the right issue for every single-repository handoff and the
  wrong one for a handoff recorded for a repository other than the issue's. Add both
  placeholders to that section's `closes` and `refs` before recording a handoff that spans
  repositories.
- The `local` launcher's `<repo root>` placeholder resolves through `## Repositories`. A
  `## Launcher` restated in `.claude/baton.md` or `~/.claude/baton.md` before 0.1.11 picks that
  up unchanged: its `local` entry still reads `cd <repo root>`, and only what fills the
  placeholder has moved.

## 0.1.10

- `stack-link` is a new `## Forge` operation. A section written before 0.1.10 leaves it
  undefined, which stops a handoff carrying `pr-base` at `implement-handoff` Step 1. Add
  `- **stack-link:**      none`, or the entry the project's forge registers a stack with. Two
  more edits belong to the same upgrade, and neither errors when skipped:
  - An overridden `pr-create` opens a ready pull request until its entry adds the shipped
    routes' `--draft` or `"draft": true`.
  - A `cloud` entry in an overridden `## Launcher` copied before 0.1.10 lacks `RemoteTrigger`,
    and neither the reviewer nor the layer above ever starts. Add it to `allowed_tools`.

## 0.1.9

- `pr-create` gained `<category>` and `<pr-base>`. A `## Forge` written before 0.1.9
  substitutes neither, so its pull requests carry no label and open against the default branch.
  Add both to that section's `pr-create`: until then a `category` line is dropped without an
  error, and a `pr-base` line stops the run at `implement-handoff` Step 1.

## 0.1.8

- `verify` is a new `## Workflow` operation. A `## Workflow` written before 0.1.8 leaves it
  undefined, and runs stop on it before creating a worktree: add
  `- **verify:**           repo-tests`, or the sequence the project runs before a push.

## 0.1.7

- A `## Launcher` entry that names `allowed_tools` names both `Agent` and `Task`. An entry
  written before 0.1.7 names neither - add them, or runs stop at their dispatch-tool check. A
  personal `~/.claude/baton.md` restating `## Launcher` carries its own `allowed_tools` and
  needs the same edit by hand: it lives outside every repo, so no update to this plugin reaches
  it.

## 0.1.6

- `wrap-up` is a new `## Workflow` operation. Leaving it undefined is not a stop, so a
  `## Workflow` written before 0.1.6 keeps working unchanged.

## 0.1.5

- `started` is a new `## Workflow` operation. A `## Workflow` written before 0.1.5 does not
  name it, which leaves it undefined rather than `none`, and `implement-handoff` stops at Step
  2: add `- **started:**          none`, or the entry the project's tracker moves its ticket
  with.

## 0.1.3

- A `## Launcher` entry that names `allowed_tools` names `EnterWorktree` and `ExitWorktree`.
  An entry written before 0.1.3 does not - add them, or its runs stop on a tool they cannot
  call.
