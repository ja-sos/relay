# GitHub backend over MCP

The shipped `## Tracker`, `## Forge` and `## Review` sections, reached through the GitHub
MCP tools instead of `gh`. A skill reads this file only when `gh` is missing or `gh api user`
fails.

Before the first operation, load the tools:

```
ToolSearch select:mcp__github__get_me,mcp__github__issue_read,mcp__github__issue_write,mcp__github__list_issues,mcp__github__add_issue_comment,mcp__github__list_label,mcp__github__create_pull_request,mcp__github__list_pull_requests,mcp__github__pull_request_read,mcp__github__update_pull_request,mcp__github__pull_request_review_write,mcp__github__add_comment_to_pending_review,mcp__github__add_reply_to_pull_request_comment
```

- PASS: `mcp__github__get_me` comes back.
- FAIL: no GitHub route is left. Stop, and report that `gh` is missing or unauthenticated
  and the GitHub MCP tools are not loaded. Report it in the session: `stopped` and every
  other write to the tracker have no route either. The exception is a project whose
  `.claude/baton.md` or `~/.claude/baton.md` restates `## Tracker`, `## Forge` and
  `## Review` all; it needs neither route.

A tool missing from the result fails the operations that call it, and the skill's own stop
rule applies to them.

## Tracker

- **list-categories:** tool: mcp__github__list_label {"owner": "<owner>", "repo": "<repo>"}
- **list-open:**       tool: mcp__github__list_issues {"owner": "<owner>", "repo": "<repo>", "state": "OPEN", "perPage": 100}
- **list-mine:**
  - tool: mcp__github__get_me {}
  - tool: mcp__github__list_issues {"owner": "<owner>", "repo": "<repo>", "state": "OPEN", "orderBy": "CREATED_AT", "direction": "DESC", "perPage": 100}
- **create:**          tool: mcp__github__issue_write {"method": "create", "owner": "<owner>", "repo": "<repo>", "title": "<title>", "labels": ["<category>"], "body": "<body>"}
- **view:**
  - tool: mcp__github__issue_read {"method": "get", "owner": "<owner>", "repo": "<repo>", "issue_number": <id>}
  - tool: mcp__github__issue_read {"method": "get_comments", "owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "perPage": 100}
- **close-fixed:**     tool: mcp__github__issue_write {"method": "update", "owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "state": "closed", "state_reason": "completed"}
- **close-invalid:**   tool: mcp__github__issue_write {"method": "update", "owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "state": "closed", "state_reason": "not_planned"}
- **comment:**         tool: mcp__github__add_issue_comment {"owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "body": "<body>"}
- **fetch-handoff:**   tool: mcp__github__issue_read {"method": "get_comments", "owner": "<owner>", "repo": "<repo>", "issue_number": <id>, "perPage": 100, "page": 1}
- **reachable:**       tool: mcp__github__get_me {}

`list_issues` returns at most 100 issues a call. Pass the response's `pageInfo.endCursor`
as `after` while `pageInfo.hasNextPage` is true; `list-open` stops at 500, the cap
`backend-github.md` gives it. `issue_read` with `get_comments` pages with `page` instead:
read on while a page comes back with 100 comments.

`list_issues` has no assignee filter. For `list-mine`, keep the issues whose `assignees`
include the `login` that `get_me` returned.

`comment` returns `{"id", "url"}`, and `url` is the comment's URL - the locator
`post-handoff` reports.

`fetch-handoff` takes the locator apart: `<id>` is the number after `/issues/` and
`<comment-id>` the digits of the trailing `#issuecomment-<n>`. The handoff is the `body` of
the returned comment whose `id` equals `<comment-id>`; raise `page` by one until it appears.

## Forge

- **verify-checkout:** git remote get-url origin | sed -E 's#\.git$##; s#.*[/:]([^/:]+/[^/]+)$#\1#'
- **pr-create:**       tool: mcp__github__create_pull_request {"owner": "<owner>", "repo": "<repo>", "title": "<title>", "head": "<branch>", "base": "<default-branch>", "body": "<body>"}
- **pr-view:**
  - tool: mcp__github__list_pull_requests {"owner": "<owner>", "repo": "<repo>", "head": "<owner>:<branch>", "state": "open"}
  - tool: mcp__github__pull_request_read {"method": "get", "owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}
- **pr-update:**       tool: mcp__github__update_pull_request {"owner": "<owner>", "repo": "<repo>", "pullNumber": <id>, "body": "<body>"}
- **closes:**          Closes #<id>
- **refs:**            Refs #<id>

`verify-checkout` prints `<owner>/<repo>` from the `origin` URL, in its HTTPS, SSH and
proxied forms alike, with no GitHub call.

`pr-create` returns `{"id", "url"}`, and `url` is the pull request's URL.

`pr-view` with an `<id>` runs only its second entry. With `<id>` empty, the first finds the
open pull request for the current branch and its `number` is the second entry's `<id>`; an
empty list means the branch has no open pull request.

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

`review-post` reads the payload file at `<path>` - the same JSON `backend-github.md`
describes - and spreads it over three calls. The first opens a pending review, adding the
payload's `commit_id` as `commitID`. The second runs once per `comments` entry, adding its
`path`, `line`, `side` and `body`, and `start_line` as `startLine`. The third submits,
adding the payload's `event` and `body`. A review left pending is invisible, so a failure
after the first call is a stop.

The user objects these tools return carry a `login` and no `type`. For `review-bodies`,
keep the reviews with a non-empty `body` whose author's `login` does not end in `[bot]`; for
`pr-comments`, the comments whose author's `login` does not end in `[bot]`.

`review-threads` returns each thread's `is_resolved` and its comments, which carry an
`html_url` but no numeric id. The `<comment-id>` `thread-reply` takes is the number after
`#discussion_r` in a thread comment's `html_url`.
