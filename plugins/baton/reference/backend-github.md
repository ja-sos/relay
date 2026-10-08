# GitHub backend

Maps every operation the baton skills call to a GitHub call. These are the shipped
defaults; override any section in `.claude/baton.md` or `~/.claude/baton.md`, to the
contract `defining-backends.md` sets. `## Tracker`, `## Forge` and `## Review` run
through the GitHub MCP tools. Where that route fails the check below and `gh` is
authenticated, `backend-github-gh.md` replaces those three sections with the same operations
as `gh` commands.

Before the first operation, load the tools:

```
ToolSearch select:mcp__github__get_me,mcp__github__issue_read,mcp__github__issue_write,mcp__github__list_issues,mcp__github__add_issue_comment,mcp__github__get_label,mcp__github__create_pull_request,mcp__github__list_pull_requests,mcp__github__pull_request_read,mcp__github__update_pull_request,mcp__github__pull_request_review_write,mcp__github__add_comment_to_pending_review,mcp__github__add_reply_to_pull_request_comment
```

Then pick the route, in this order:

1. Every tool named comes back, `mcp__github__get_me` succeeds, and
   `mcp__github__list_issues {"owner": "<owner>", "repo": "<repo>", "perPage": 1}` returns,
   with `<owner>` and `<repo>` from `verify-checkout` below: this file's sections stand as
   they are. `get_me` is this route's `reachable`, as `gh api user` is the other's. It takes
   no repository, so only `list_issues` shows the MCP account can read this one.
2. Otherwise, where `command -v gh >/dev/null && gh api user >/dev/null 2>&1` succeeds,
   load `backend-github-gh.md`. It replaces `## Tracker`, `## Forge` and `## Review`; the
   other three sections here stay in force.
3. Otherwise keep this file's entries. Each one fails under the skill's stop rule when the
   skill reaches it - directly or through `op:` - and not before, where its tool did not
   load or cannot read this repository. Name the part of route 1 that failed - a tool not
   loaded, `get_me`, or `list_issues` - and `gh` as absent or unauthenticated. When
   `stopped` resolves to a failing entry too, report the stop in the session only.

`backend-github-gh.md` loads second, ahead of `.claude/baton.md` and `~/.claude/baton.md`.
Later files replace earlier ones by `##` heading, so loaded last it would overwrite a
project's own `## Tracker` with `gh` commands.

## Tracker

- **list-categories:** tool: mcp__github__get_label {"owner": "<owner>", "repo": "<repo>", "name": "<category>"}
- **list-open:**        tool: mcp__github__list_issues {"owner": "<owner>", "repo": "<repo>", "state": "OPEN", "perPage": 100}
- **list-mine:**
  - tool: mcp__github__get_me {}
  - tool: mcp__github__list_issues {"owner": "<owner>", "repo": "<repo>", "state": "OPEN", "orderBy": "CREATED_AT", "direction": "ASC", "perPage": 100}
- **create:**           tool: mcp__github__issue_write {"method": "create", "owner": "<owner>", "repo": "<repo>", "title": "<title>", "labels": ["<category>"], "body": "<body>"}
- **view:**
  - tool: mcp__github__issue_read {"method": "get", "owner": "<owner>", "repo": "<repo>", "issue_number": <id>}
  - tool: mcp__github__issue_read {"method": "get_comments", "owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "perPage": 100}
- **close-fixed:**      tool: mcp__github__issue_write {"method": "update", "owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "state": "closed", "state_reason": "completed"}
- **close-invalid:**    tool: mcp__github__issue_write {"method": "update", "owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "state": "closed", "state_reason": "not_planned"}
- **comment:**          tool: mcp__github__add_issue_comment {"owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "body": "<body>"}
- **fetch-handoff:**    tool: mcp__github__issue_read {"method": "get_comments", "owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "perPage": 100, "page": 1}
- **reachable:**        tool: mcp__github__get_me {}

`mcp__github__list_label` enumerates a repository's labels, but it belongs to the server's
`labels` toolset, which a connection sending no `X-MCP-Toolsets` header does not enable.
`get_label` is in the default `issues` toolset, so `list-categories` uses it and answers
for one category at a time: run it once per row of `## Categories`, substituting
that row's label as `<category>`. That is the only question `file-issue` Step 1 puts to it,
and taking the rows as they come means this entry needs no restating when a project renames
its categories.

A `<category>` the repository does not carry comes back not-found. That is this operation's
answer - the missing category Step 1 stops and asks about - and not a backend failure: the
tool loaded and replied. Reserve the stop rule for a tool that never loaded or could not
authorize.

`list_issues` returns at most 100 issues a call, so `list-open` and `list-mine` both page:
pass the response's `pageInfo.endCursor` as `after` while `pageInfo.hasNextPage` is true.
`list-open` stops at 500, well above the open-issue count of any repo these skills are
pointed at, since it caps the dedupe `file-issue` runs against; `list-mine` reads every
page, because the assignee filter below runs on each page's issues. `issue_read` with
`get_comments` pages with `page` instead: read on while a page comes back with 100 comments.

`list_issues` has no assignee filter. For `list-mine`, keep the issues whose `assignees`
include the `login` that `get_me` returned. Its `ASC` order is the pick order `next-issue`
reads off the top: oldest assigned issue first.

`create` leaves `labels` out of the call where `<category>` is empty, as `file-issue` passes it
under a `list-categories` of `none`. An issue meant to carry no label must not be sent `[""]`.

`comment` returns `{"id", "url"}`, and `url` is the comment's URL - the locator
`post-handoff` reports.

`fetch-handoff` takes the locator apart: `<owner>` and `<repo>` are the two path segments
after the host, `<id>` is the number after `/issues/` and `<comment-id>` the digits of the
trailing `#issuecomment-<n>`. The locator's `<owner>` and `<repo>` replace the derived
ones. The handoff is the `body` of the returned comment whose `id` equals `<comment-id>`;
raise `page` by one until it appears.

## Categories

| Condition | Category | Body headings |
|---|---|---|
| Code contradicts its documented or intended behavior | bug | `## Effect`, `## Reproduce`, `## Fix` |
| Code is correct; docs are wrong, missing or misleading | documentation | `## Says`, `## Actually`, `## Correction` |
| Code behaves as intended; something new is wanted | enhancement | `## Motivation`, `## Proposal`, `## Constraints` |

## Forge

- **verify-checkout:** { git remote get-url upstream 2>/dev/null || git remote get-url origin; } | sed -E 's#\.git$##; s#.*[/:]([^/:]+/[^/]+)$#\1#'
- **pr-create:**
  - tool: mcp__github__create_pull_request {"owner": "<owner>", "repo": "<repo>", "title": "<title>", "head": "<head-owner>:<branch>", "base": "<pr-base>", "body": "<body>", "draft": true}
  - tool: mcp__github__issue_write {"method": "update", "owner": "<owner>", "repo": "<repo>", "issue_number": <pr-number>, "labels": ["<category>"]}
- **stack-link:**      none
- **pr-view:**
  - tool: mcp__github__list_pull_requests {"owner": "<owner>", "repo": "<repo>", "state": "open", "fields": ["number", "html_url", "head"], "perPage": 100}
  - tool: mcp__github__pull_request_read {"method": "get", "owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}
- **pr-update:**       tool: mcp__github__update_pull_request {"owner": "<owner>", "repo": "<repo>", "pullNumber": <id>, "body": "<body>"}
- **closes:**          Closes <owner>/<repo>#<id>
- **refs:**            Refs <owner>/<repo>#<id>

`verify-checkout` prints `<owner>/<repo>` from the `upstream` remote's URL, or from
`origin`'s where there is no `upstream`, in HTTPS, SSH and proxied forms alike, with no
GitHub call. `pr-create` and `pr-view` name the branch by `<head-owner>` instead, the owner
in `origin`'s URL: in a fork clone `<owner>` is the upstream repository's owner, which does
not hold the branch.

`pr-create` returns its **first** call's `{"id", "url"}`, and `url` is the pull request's
URL; the second call returns nothing the caller keeps. The pull request exists from the
first call on, so a failed label call leaves it open and unlabelled - a stop after
`implement-handoff` Step 5, whose `stopped` file carries that URL.

The label needs that second call because `create_pull_request` has no `labels` parameter -
its parameters are `owner`, `repo`, `title`, `head`, `base`, `body`, `draft`,
`maintainer_can_modify` and `reviewers`. Every pull request is also an issue, so
`issue_write` sets the label on it.

`<pr-number>` is spelled apart from `<id>` on purpose, and the caller passes neither: at
`implement-handoff` Step 5 `<id>` is the *issue's* number, which `closes` and `refs` take,
and a label sent to that number lands on the issue while the pull request ships unlabelled.
The second entry fills `<pr-number>` from the first entry's own result - the last path
segment of the `url` it returned.

Skip the second call entirely where `<category>` is empty - a pull request meant to carry no
label must not be sent `[""]`.

`"draft": true` is unconditional: every pull request these skills open starts as a draft,
stacked or not. `implement-handoff` Step 5 says why, and marking one ready stays outside what
an unattended run may do.

`stack-link` is `none`. GitHub has no stack of its own for a pull request to join - a pull
request opened against another pull request's branch already shows as stacked, and
`<pr-base>` is what `pr-create` passes to do that. A project whose forge does track stacks
defines the operation here, taking `<id>`, `<pr-url>` and `<pr-base>`; `implement-handoff`
Step 5 runs it after `pr-create`, and only where the handoff's header carries `pr-base`.
The `gh` route ships `none` for the same reason and one more: the `github/gh-stack` extension
that would supply a command was not installed where this was written, so its syntax is
unverified and no guess at it ships.

`pr-view` with an `<id>` runs only its second entry. With `<id>` empty, the first lists the
open pull requests and the caller picks out the current branch's in two passes:

1. Keep each one whose `head.ref` equals `<branch>` exactly and whose `head.repo.full_name`,
   up to the `/`, equals `<head-owner>` ignoring case.
2. Where the first pass kept more than one, keep only those whose whole
   `head.repo.full_name` equals `origin`'s `owner/name` ignoring case, which this prints:

   ```
   git remote get-url origin | sed -E 's#\.git$##; s#.*[/:]([^/:]+/[^/]+)$#\1#'
   ```

   Where this pass keeps none, stop and report the numbers the first pass kept: the branch's
   pull request cannot be told apart from them.

A match's `number` is the second entry's `<id>`. The list pages with `page`: read on while a
page comes back with 100 pull requests, and run both passes over every page read. No match
across them means the branch has no open pull request.

Owner and name are compared ignoring case because GitHub returns `full_name` in the
repository's own case, while a remote URL keeps whatever case it was cloned with. The first
pass compares the owner alone because a repository renamed since the clone keeps its old name
in `origin`'s URL - fetching still succeeds through GitHub's redirect - while `full_name`
carries the new one. The second pass separates a fork from its parent where one account owns
both and both carry the branch.

The entry passes no `head` filter because, over REST, that filter returns `[]` in a fork
whose owner also owns the parent, which reads as "no open pull request" for a branch that
has one.

`closes` and `refs` name the issue's repository as well as its number. One investigation can
record a handoff per repository a change spans, so the pull request may open in a repository
other than the issue's, and a bare `#<id>` there resolves against whatever issue holds that
number in the pull request's own repository. `implement-handoff` Step 5 fills `<owner>`,
`<repo>` and `<id>` from the locator, not from `verify-checkout` - the one place a `## Forge`
entry follows the tracker's placeholder rule, which `defining-backends.md` states. Where the
issue and the work are in one repository, which is every handoff recorded before baton 0.1.11,
the reference reads as `Closes owner/repo#12` and resolves to the same issue `Closes #12` did.

GitHub documents that cross-repository form for closing keywords.

A 403 naming `add_repo` means the session holds no grant for the repo, not that the
credentials are wrong. Attach the repo at `access: push`; the read default covers neither
the API calls nor the push.

## Review

- **review-list:**     tool: mcp__github__pull_request_read {"method": "get_reviews", "owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}
- **review-post:**
  - tool: mcp__github__pull_request_review_write {"method": "create", "owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}
  - tool: mcp__github__add_comment_to_pending_review {"owner": "<owner>", "repo": "<repo>", "pullNumber": <id>, "subjectType": "LINE"}
  - tool: mcp__github__pull_request_review_write {"method": "submit_pending", "owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}
- **review-bodies:**   tool: mcp__github__pull_request_read {"method": "get_reviews", "owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}
- **pr-comments:**     tool: mcp__github__pull_request_read {"method": "get_comments", "owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}
- **review-threads:**  tool: mcp__github__pull_request_read {"method": "get_review_comments", "owner": "<owner>", "repo": "<repo>", "pullNumber": <id>, "perPage": 100}
- **thread-reply:**    tool: mcp__github__add_reply_to_pull_request_comment {"owner": "<owner>", "repo": "<repo>", "pullNumber": <id>, "commentId": <comment-id>, "body": "<body>"}
- **pr-comment:**      tool: mcp__github__add_issue_comment {"owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "body": "<body>"}

Feedback lands on three surfaces and two are invisible to the inline-comment call.
`review-bodies` and `pr-comments` carry only what people wrote: a bot delivers its findings
as inline threads, and its summary body is boilerplate. `pr-comments` reads the top-level
notes that belong to no review - the surface neither of the other two returns.

`review-post` reads the payload file at `<path>` and spreads it over three calls. The
payload carries the summary and every inline comment:

```json
{"commit_id": "<the pull request's head SHA, re-read immediately before posting>",
 "event": "COMMENT",
 "body": "<summary>",
 "comments": [{"path": "<file>", "line": 42, "side": "RIGHT", "body": "<finding>"}]}
```

The first call opens a pending review, adding the payload's `commit_id` as `commitID`. The
second runs once per `comments` entry, adding its `path`, `line`, `side` and `body`, and
`start_line` as `startLine` for a multi-line comment. The third submits, adding the
payload's `event` and `body`. `commit_id` is required and a push invalidates every anchor
built against an older one. A review left pending is invisible, so a failure after the
first call is a stop, and its report says a pending review is open on the pull request for
the user to submit or discard in GitHub.

The user objects these tools return carry a `login` and no `type`. For `review-bodies`,
keep the reviews with a non-empty `body` whose author's `login` does not end in `[bot]`; for
`pr-comments`, the comments whose author's `login` does not end in `[bot]`.

`review-threads` returns each thread's `is_resolved` and its comments, which carry an
`html_url` but no numeric id. The `<comment-id>` `thread-reply` takes is the number after
`#discussion_r` in a thread comment's `html_url`.

## Launcher

Each entry takes `<skill>` - `implement-handoff` or `review-handoff` - and `<args>`, the
arguments that skill is started with, and appends `launcher=<entry name>` to them. That last
argument is how the run knows which entry started it: `implement-handoff` launches its
reviewer through the same entry.

- **cloud:** two routines per repository, each holding a fixed prompt, reused for every
  launch. Load the tool with `ToolSearch select:RemoteTrigger`. `<skill>` picks the routine:
  `implement <owner>/<repo>` for `implement-handoff`, `review <owner>/<repo>` for
  `review-handoff`. Each launch runs, in order:

  1. `action: "list"`, finding the routine by that name.
  2. Where it is absent, `action: "create"` with the body below.
  3. Where it exists and its stored `model` differs from the model this session is running,
     `action: "update"` with the body's `model`.
  4. One `action: "run"` on it, with the body `{"text": "<args> launcher=cloud"}`.

```json
{"name": "<implement or review> <owner>/<repo>",
 "enabled": false,
 "job_config": {"ccr": {
   "environment_id": "<from the schedule skill's environment list>",
   "session_context": {
     "model": "<the model this session is running>",
     "sources": [{"git_repository": {"url": "https://github.com/<owner>/<repo>"}}],
     "allowed_tools": ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Skill",
                       "Agent", "Task", "EnterWorktree", "ExitWorktree",
                       "RemoteTrigger"]},
   "events": [{"data": {
     "uuid": "<fresh lowercase v4 uuid>", "session_id": "", "type": "user",
     "parent_tool_use_id": null,
     "message": {"role": "user", "content": "This is a cloud run. Invoke the `baton:<skill>` skill with the text of the routine-fire-payload below, verbatim, as its arguments. If there is no routine-fire-payload, or it is empty, end the turn without doing anything."}}}]}}}
```

  The stored prompt never changes between launches; the arguments ride in the `run` payload.
  A `run` carrying `{"text": ...}` delivers the text to the run as a second user turn, wrapped
  in `<routine-fire-payload>` and marked as data to follow only where the stored prompt says
  to - which this one does - and a run given a stored prompt naming a skill invokes it with the
  payload verbatim as its arguments. A run with no payload ends in one turn. A `run` that
  passes `job_config.ccr.events`, `events` or `prompt` instead gets HTTP 200 and the stored
  prompt alone. That is why each launch is one call: re-pointing one routine with `update` and
  then firing it with `run` lets two interleaved launches both run the second launch's prompt.

  The routines are created disabled and stay disabled. `run` starts a disabled routine and
  delivers its payload, so no launch toggles `enabled`, and with no schedule there is no
  pending slot to add a duplicate run. Nothing deletes a routine except
  claude.ai/code/routines. `action: "list_runs"` returns a run's session URL;
  `action: "get_run_log"` reads the run, permission denials included.

  Step 3 updates `model` because an investigation formed under one model does not hand its plan
  to a weaker one, and a launch from a session on another model would otherwise run under the
  routine's stored one. It is the one place two launches can still interleave: two launches
  from sessions on different models at the same moment can each run under the other's.

  `sources` is what attaches the repository - the field `claude --cloud` leaves empty,
  which is why a `--cloud` session arrives with an uploaded copy of the checkout and no
  remote.

  `EnterWorktree` and `ExitWorktree` are on the list because `implement-handoff` and
  `review-handoff` each create their run's worktree at Step 2 and remove it at their last
  step. A cloud run has a disposable clone to itself and isolates from nothing, and that cost
  is accepted rather than made conditional.

  `Agent` and `Task` are on the list because each skill's claim audit dispatches a subagent
  whose context did not write the claims, and a `code-review` entry may itself be an `agent:`
  one. The list names both so the run has the dispatch tool under either name. Routine
  creation keeps a name the build does not carry, and the session ignores it: a cloud run
  whose list held `Agent`, `Task` and a made-up name started, carried only `Agent`, and
  dispatched through it. Both names were added in baton 0.1.7, so a `## Launcher` entry copied
  from this file before then, into a project's `.claude/baton.md` or a personal
  `~/.claude/baton.md`, names neither. Add both: that run also carried tools its list did not
  name, such as `ToolSearch`, so whether a list naming neither still gets `Agent` is untested,
  and `implement-handoff` Step 2 and `review-handoff` Step 1 stop a run that lacks it.

  `RemoteTrigger` is on both routines' lists because both runs launch through these very
  lines from inside the cloud: every `implement-handoff` run launches its reviewer at Step 7,
  and a `review-handoff` run launches the layer above where the handoff carries
  `next: cloud <locator>`. Without the tool that run cannot call it, and the launch fails at
  the last step of an otherwise finished run. It was added in baton 0.1.10, so a
  `## Launcher` section restated in `.claude/baton.md` or `~/.claude/baton.md` before then
  needs the name adding by hand - the heading replaces this one whole.

  This entry's `<owner>` and `<repo>` are the handoff's `repo` line rather than
  `verify-checkout`'s answer, in `name` as much as in `sources`. The routine clones the
  repository the work belongs in, and for a handoff an investigation of another repository
  recorded that is not the repository the launching session sits in. `name` takes the same line
  because it keeps each repository's routines apart: two handoffs of one investigation, for
  two repositories, would otherwise share one routine, whose `sources` clone only one of them.
  It is also why this entry needs no `## Repositories` row - it clones rather than reading a path
  on this machine.

  **A handoff carrying an `assets` line stops under this entry.** The run clones the repository
  and never sees `~/.claude/baton.md`, where `## Assets` lives, so the section is undefined in
  it and every listed path is unresolved: the routine fires, the session starts, and
  `implement-handoff` Step 1 stops before creating its worktree. Nothing here can fix that -
  the asset folder is on the launching machine, not in the clone - so such a handoff goes to
  `local` below. A handoff with no `assets` line is unaffected.

- **local:** `cd <repo root> && claude --bg "/baton:<skill> <args> launcher=local"`

  No `--worktree <branch>`: `implement-handoff` and `review-handoff` Step 2 each create the
  run's worktree themselves, and inside a session started with that flag `EnterWorktree`
  refuses with "Already in a worktree session." Check the repo ignores `.claude/worktrees/`
  first all the same, since Step 2's worktree lands there and an unignored path leaves it in
  `git status`, where an autonomous `git add -A` commits it:
  `git -C <repo root> check-ignore -q .claude/worktrees/ || echo "add .claude/worktrees/ to <repo root>/.gitignore first"`.
  A `.gitignore` that keeps a tracked `.claude/settings.json` visible ignores the contents
  rather than the directory - `.claude/*` with `!.claude/settings.json` - so `.claude/`
  itself tests as unignored while `.claude/worktrees/` does not.

  `<repo root>` is the root of the checkout of the repository the handoff's `repo` line names.
  Where that is the repository this session is in, it is the current checkout's root,
  `git rev-parse --show-toplevel`. Where it is another repository, it is that repository's path
  in `## Repositories`, and a repository with no row there is a stop for this launch alone -
  the other handoffs of the same investigation still launch. The map applies to the
  placeholder, so a `## Launcher` restated in `.claude/baton.md` or `~/.claude/baton.md` before
  baton 0.1.11 picks it up unchanged: its `local` entry still reads `cd <repo root>`, and only
  what fills the placeholder has moved. The ignore check above takes the same root, since the
  worktree Step 2 creates lands in the repository being launched rather than this one.
  `--bg` and `--print` conflict, because `--print` leaves no session for
  `claude attach <id>` to open. The command returns a short id taken by
  `claude agents --json`, `claude logs <id>` and `claude stop <id>`.

  This is the shipped entry that can resolve a handoff's `assets` line: the run is a local
  session, so it reads `~/.claude/baton.md` and with it the `## Assets` root, and Step 1
  resolves each listed path against the folder on this machine. That holds only where the
  machine running the command is the one whose `~/.claude/baton.md` defines the root and holds
  the files - `<repo root>` moves the run between checkouts, never between machines.

  The command grants no access of its own. It starts an ordinary session, so the asset root is
  read under whatever permissions that machine already gives a session for paths outside the
  checkout; where the harness prompts for them, an unattended run has nobody to answer and
  stops at `implement-handoff` Step 1 naming the paths. Settle that access on the machine
  before pointing a handoff's `assets` line at it.

## Workflow

- **post-handoff:**     op: comment <id> <path>
- **has-handoff:**      op: view <id>
- **started:**          none
- **verify:**           repo-tests
- **code-review:**      skill: /code-review <target>
- **request-reviewer:** none
- **review-wait:**      10
- **published:**        op: comment <id> <path>
- **reviewed:**         op: comment <id> <path>
- **stopped:**          op: comment <id> <path>
- **wrap-up:**          none

Every entry here resolves through `## Tracker`, so a project that has retargeted the
tracker moves these with it and restates none of them.

`post-handoff` returns the locator `fetch-handoff` is later given. On this backend that is
the comment's URL - `comment`'s `url` field, or its stdout under the `gh` route.
`<owner>` and `<repo>` are the URL's two path segments after the host, replacing the
derived ones; `<comment-id>` is the digits of the trailing `#issuecomment-<n>`, and `<id>`
the number after `/issues/`.

`has-handoff` prints the issue with its comments, and the caller scopes the answer out of that
output: the `<!-- claude-handoff -->` marker in it, and, since baton 0.1.16, each handoff's
`base` and `branch`,
each pointer's locator, and the obsolete reports that answer them. The comment text is what
carries all of that, which is why this entry prints the comments rather than answering the
question itself.

`started` is `none`: a GitHub issue has no in-progress state to move into, so nothing runs
when the implementation run cuts its branch. A tracker that has one defines the transition
here, and the operation takes `<id>` alone.

`reviewed` posts the Run report `review-handoff` writes when its review of an
`implement-handoff` pull request finishes, once per issue the handoff names, taking `<id>`,
`<path>` and `<pr-url>`. It is not `published` because both run on every pull request: a tracker
whose `published` moves the issue's status would move it a second time when the review
finished. On GitHub both are a comment, and a project whose tracker moves tickets keeps the
transition in `published` and leaves `reviewed` a comment.

`wrap-up` is `none` as well: nothing on GitHub needs writing when `investigate-issue`,
`review-pr`, `address-review` or `self-review` finishes, each having already posted what it
produced. A project that logs time, notifies a channel or closes out a ticket when an
attended flow ends defines that here.

`code-review` reviews the working tree where `<target>` is empty, and otherwise the pull
request number or branch `<target>` names. It ignores `<locator>`: `/code-review` checks
correctness, not a handoff's acceptance criteria. A project that wants those checked keeps
this entry and pairs it with an `agent:` one in a nested list - `defining-backends.md` carries
the example.

`verify` is `repo-tests`, the literal standing for the repo's full test command as the run
finds it - GitHub says nothing about how a project is built, so there is no better default
to ship. A project that mandates a pre-push sequence writes it here, and that sequence then
runs at every point `implement-handoff` checks its work.

`request-reviewer` is `none`, so the review round does not run. Either form turns it on:

- `tool: mcp__github__request_copilot_review {"owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}`
- `gh pr edit <id> --add-reviewer @copilot`

`review-wait` is then how long the round waits for that reviewer, in minutes. Copilot's
reviews carry the login `copilot-pull-request-reviewer[bot]` in `review-list`. The `gh`
fallback swaps no `## Workflow` entry, so a project that sets `request-reviewer` keeps
whichever form it wrote on both routes - pick the one its sessions can run.
