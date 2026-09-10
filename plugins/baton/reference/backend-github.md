# GitHub backend

Maps every operation the baton skills call to a GitHub command. These are the shipped
defaults; override any section in `.claude/baton.md` or `~/.claude/baton.md`, to the
contract `defining-backends.md` sets.

## Tracker

- **list-categories:** gh label list
- **list-open:**       gh issue list --state open --limit 500
- **list-mine:**       gh issue list --assignee @me --state open --limit 100
- **create:**          gh issue create --title "<title>" --label "<category>" --body-file <path>
- **view:**            gh issue view <id> --comments
- **close-fixed:**     gh issue close <id> --reason completed
- **close-invalid:**   gh issue close <id> --reason "not planned"
- **comment:**         gh issue comment <id> --body-file <path>
- **fetch-handoff:**   gh api repos/<owner>/<repo>/issues/comments/<comment-id> --jq .body
- **reachable:**       gh api user

`comment` prints the created comment's URL on stdout, and that is the locator `write-handoff`
reports. Do not re-derive it by listing an issue's comments: the listing is paginated, so the
newest comment is not the last entry of the first page.

`list-open` caps the dedupe `file-issue` runs against, so it is set well above the open-issue
count of any repo these skills are pointed at.

`gh auth status` reports failure in every cloud session: it validates the literal
`GH_TOKEN`, which the proxy leaves as the sentinel `proxy-injected` while substituting
real credentials on outbound requests. `reachable` is the check that works.

## Categories

| Condition | Category | Body headings |
|---|---|---|
| Code contradicts its documented or intended behavior | bug | `## Effect`, `## Reproduce`, `## Fix` |
| Code is correct; docs are wrong, missing or misleading | documentation | `## Says`, `## Actually`, `## Correction` |
| Code behaves as intended; something new is wanted | enhancement | `## Motivation`, `## Proposal`, `## Constraints` |

## Forge

- **verify-checkout:** gh repo view --json nameWithOwner -q .nameWithOwner
- **pr-create:**       gh pr create --title "<title>" --body-file <path>
- **pr-view:**         gh pr view <id> --json number,url,body,author,headRefName,headRefOid,isDraft
- **pr-update:**       gh pr edit --body-file <path>
- **closes:**          Closes #<id>
- **refs:**            Refs #<id>

`pr-view` takes an empty `<id>` to mean the pull request for the current branch.

A 403 naming `add_repo` means the session holds no grant for the repo, not that the
credentials are wrong. Attach the repo at `access: push`; the read default covers neither
the API calls nor the push.

## Review

- **review-list:**     gh api repos/<owner>/<repo>/pulls/<id>/reviews
- **review-post:**     gh api -X POST repos/<owner>/<repo>/pulls/<id>/reviews --input <path>
- **review-bodies:**   gh api repos/<owner>/<repo>/pulls/<id>/reviews --jq '.[] | select(.body != "" and .user.type == "User") | {id, user: .user.login, state, body}'
- **pr-comments:**     gh api repos/<owner>/<repo>/issues/<id>/comments --jq '.[] | select(.user.type == "User") | {id, user: .user.login, body}'
- **review-threads:**  see the query below
- **thread-reply:**    gh api -X POST repos/<owner>/<repo>/pulls/<id>/comments/<comment-id>/replies --input <path>
- **pr-comment:**      gh pr comment <id> --body-file <path>

Feedback lands on three surfaces and two are invisible to the inline-comment endpoint.
`review-bodies` and `pr-comments` carry only what people wrote: a bot delivers its findings as
inline threads, and its summary body is boilerplate. `pr-comments` uses the `issues` path because
every pull request is also an issue - it is the only endpoint returning top-level notes that
belong to no review.

`review-threads` needs GraphQL, since `isResolved` has no REST equivalent, and `databaseId` is the
id `thread-reply` takes while GraphQL's own `id` is not. `<owner>` and `<repo>` are not substituted
here the way they are on `gh api repos/...`, so they are passed:

```
gh api graphql -f owner=<owner> -f repo=<repo> -F pr=<id> -f query='
query($owner:String!,$repo:String!,$pr:Int!){ repository(owner:$owner,name:$repo){ pullRequest(number:$pr){
  reviewThreads(first:100){ nodes { isResolved path
    comments(first:20){ nodes { databaseId body author{login} } } } } } } }' \
--jq '.data.repository.pullRequest.reviewThreads.nodes[]'
```

`review-post` and `thread-reply` read a JSON file. A review payload carries the summary and every
inline comment in one call, and a second call adds a second summary rather than replacing the
first; a reply payload is `{"body": "<text>"}`:

```json
{"commit_id": "<headRefOid, re-read immediately before posting>",
 "event": "COMMENT",
 "body": "<summary>",
 "comments": [{"path": "<file>", "line": 42, "side": "RIGHT", "body": "<finding>"}]}
```

`commit_id` is required and a push invalidates every anchor built against an older one. Omitting
`event` leaves the review PENDING and invisible. A multi-line comment adds `start_line` beside
`line`.

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
     "allowed_tools": ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Skill"]},
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

- **local:** `cd <repo root> && claude --bg --worktree <branch> "/baton:implement-handoff <comment url>"`

  Check the repo ignores `.claude/` first, since an unignored `.claude/` leaves the new
  worktree in `git status`, where an autonomous `git add -A` commits it:
  `git check-ignore -q .claude/ || echo "add .claude/ to .gitignore first"`.
  `--bg` and `--print` conflict, because `--print` leaves no session for
  `claude attach <id>` to open. The command returns a short id taken by
  `claude agents --json`, `claude logs <id>` and `claude stop <id>`.

## Workflow

- **post-handoff:**     op: comment <id> <path>
- **has-handoff:**      op: view <id>
- **code-review:**      skill: /code-review <target>
- **request-reviewer:** none
- **review-wait:**      10
- **published:**        op: comment <id> <path>
- **stopped:**          op: comment <id> <path>

Every entry here resolves through `## Tracker`, so a project that has retargeted the
tracker moves these with it and restates none of them.

`post-handoff` returns the locator `fetch-handoff` is later given. On this backend that is
`comment`'s stdout URL, which carries every substitution `fetch-handoff` takes: `<owner>`
and `<repo>` are its path, and `<comment-id>` the digits of its trailing
`#issuecomment-<n>`.

`has-handoff` prints the issue with its comments, and the caller scopes the answer to the
`<!-- claude-handoff -->` marker in that output.

`request-reviewer` is `none`, so the review round does not run. `gh pr edit <id>
--add-reviewer @copilot` turns it on; `review-wait` is then how long the round waits for
that reviewer, in minutes.
