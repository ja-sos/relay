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
- **pr-create:**       tool: mcp__github__create_pull_request {"owner": "<owner>", "repo": "<repo>", "title": "<title>", "head": "<head-owner>:<branch>", "base": "<default-branch>", "body": "<body>"}
- **pr-view:**
  - tool: mcp__github__list_pull_requests {"owner": "<owner>", "repo": "<repo>", "head": "<head-owner>:<branch>", "state": "open"}
  - tool: mcp__github__pull_request_read {"method": "get", "owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}
- **pr-update:**       tool: mcp__github__update_pull_request {"owner": "<owner>", "repo": "<repo>", "pullNumber": <id>, "body": "<body>"}
- **closes:**          Closes #<id>
- **refs:**            Refs #<id>

`verify-checkout` prints `<owner>/<repo>` from the `upstream` remote's URL, or from
`origin`'s where there is no `upstream`, in HTTPS, SSH and proxied forms alike, with no
GitHub call. `pr-create` and `pr-view` name the branch by `<head-owner>` instead, the owner
in `origin`'s URL: in a fork clone `<owner>` is the upstream repository's owner, which does
not hold the branch.

`pr-create` returns `{"id", "url"}`, and `url` is the pull request's URL.

`pr-view` with an `<id>` runs only its second entry. With `<id>` empty, the first finds the
open pull request for the current branch and its `number` is the second entry's `<id>`; an
empty list means the branch has no open pull request.

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

- **cloud:** one routine per repository, reused. Load the tool with
  `ToolSearch select:RemoteTrigger`. `action: "list"` finds the routine named for this
  repository; `action: "update"` re-points it and `action: "create"` builds it when
  absent, both taking this body:

```json
{"name": "implement <owner>/<repo>",
 "run_once_at": "<RFC3339 UTC, a few minutes ahead>",
 "enabled": true,
 "job_config": {"ccr": {
   "environment_id": "<from the schedule skill's environment list>",
   "session_context": {
     "model": "<the model this session is running>",
     "sources": [{"git_repository": {"url": "https://github.com/<owner>/<repo>"}}],
     "allowed_tools": ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Skill",
                       "Agent", "Task", "EnterWorktree", "ExitWorktree"]},
   "events": [{"data": {
     "uuid": "<fresh lowercase v4 uuid>", "session_id": "", "type": "user",
     "parent_tool_use_id": null,
     "message": {"role": "user", "content": "/baton:implement-handoff <comment url>"}}}]}}}
```

  `sources` is what attaches the repository - the field `claude --cloud` leaves empty,
  which is why a `--cloud` session arrives with an uploaded copy of the checkout and no
  remote. `model` takes the model this session is running: an investigation formed under
  one model does not hand its plan to a weaker one. An update carries `"enabled": true`
  alongside the new prompt, because the previous run left the routine disabled.

  Fire it with `action: "run"` rather than waiting for the slot, then `action: "update"`
  with `{"enabled": false}` so the pending slot adds no duplicate. Nothing deletes a
  routine except claude.ai/code/routines. A run already firing holds its own copy of the
  prompt, so re-pointing the routine cannot disturb it. `action: "list_runs"` returns the
  run's session URL; `action: "get_run_log"` reads the run, permission denials included.

  `EnterWorktree` and `ExitWorktree` are on the list because `implement-handoff` Step 2
  creates the run's worktree and Step 7 removes it. A cloud run has a disposable clone to
  itself and isolates from nothing, and that cost is accepted rather than made conditional.

  `Agent` and `Task` are on the list because Step 4's claim audit dispatches a subagent whose
  context did not write the code, and a `code-review` entry may itself be an `agent:` one. The
  list names both so the run has the dispatch tool under either name. Routine creation keeps a
  name the build does not carry, and the session ignores it: a cloud run whose list held
  `Agent`, `Task` and a made-up name started, carried only `Agent`, and dispatched through it.
  Both names were added in baton 0.1.7, so a `## Launcher` entry copied from this file before
  then, into a project's `.claude/baton.md` or a personal `~/.claude/baton.md`, names neither.
  Add both: that run also carried tools its list did not name, such as `ToolSearch`, so
  whether a list naming neither still gets `Agent` is untested, and Step 2 stops a run that
  lacks it.

- **local:** `cd <repo root> && claude --bg "/baton:implement-handoff <comment url>"`

  No `--worktree <branch>`: `implement-handoff` Step 2 creates the run's worktree itself,
  and inside a session started with that flag `EnterWorktree` refuses with "Already in a
  worktree session." Check the repo ignores `.claude/worktrees/` first all the same, since
  Step 2's worktree lands there and an unignored path leaves it in `git status`, where an
  autonomous `git add -A` commits it:
  `git check-ignore -q .claude/worktrees/ || echo "add .claude/worktrees/ to .gitignore first"`.
  A `.gitignore` that keeps a tracked `.claude/settings.json` visible ignores the contents
  rather than the directory - `.claude/*` with `!.claude/settings.json` - so `.claude/`
  itself tests as unignored while `.claude/worktrees/` does not.
  `--bg` and `--print` conflict, because `--print` leaves no session for
  `claude attach <id>` to open. The command returns a short id taken by
  `claude agents --json`, `claude logs <id>` and `claude stop <id>`.

## Workflow

- **post-handoff:**     op: comment <id> <path>
- **has-handoff:**      op: view <id>
- **started:**          none
- **code-review:**      skill: /code-review <target>
- **request-reviewer:** none
- **review-wait:**      10
- **published:**        op: comment <id> <path>
- **stopped:**          op: comment <id> <path>
- **wrap-up:**          none

Every entry here resolves through `## Tracker`, so a project that has retargeted the
tracker moves these with it and restates none of them.

`post-handoff` returns the locator `fetch-handoff` is later given. On this backend that is
the comment's URL - `comment`'s `url` field, or its stdout under the `gh` route.
`<owner>` and `<repo>` are the URL's two path segments after the host, replacing the
derived ones; `<comment-id>` is the digits of the trailing `#issuecomment-<n>`, and `<id>`
the number after `/issues/`.

`has-handoff` prints the issue with its comments, and the caller scopes the answer to the
`<!-- claude-handoff -->` marker in that output.

`started` is `none`: a GitHub issue has no in-progress state to move into, so nothing runs
when the implementation run cuts its branch. A tracker that has one defines the transition
here, and the operation takes `<id>` alone.

`wrap-up` is `none` as well: nothing on GitHub needs writing when `investigate-issue`,
`review-pr`, `address-review` or `self-review` finishes, each having already posted what it
produced. A project that logs time, notifies a channel or closes out a ticket when an
attended flow ends defines that here.

`code-review` reviews the working tree where `<target>` is empty, and otherwise the pull
request number or branch `<target>` names. It ignores `<locator>`: `/code-review` checks
correctness, not a handoff's acceptance criteria. A project that wants those checked keeps
this entry and pairs it with an `agent:` one in a nested list - `defining-backends.md` carries
the example.

`request-reviewer` is `none`, so the review round does not run. Either form turns it on:

- `tool: mcp__github__request_copilot_review {"owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}`
- `gh pr edit <id> --add-reviewer @copilot`

`review-wait` is then how long the round waits for that reviewer, in minutes. Copilot's
reviews carry the login `copilot-pull-request-reviewer[bot]` in `review-list`. The `gh`
fallback swaps no `## Workflow` entry, so a project that sets `request-reviewer` keeps
whichever form it wrote on both routes - pick the one its sessions can run.
