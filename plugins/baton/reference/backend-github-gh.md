# GitHub backend over gh

The shipped `## Tracker`, `## Forge` and `## Review` sections as `gh` commands, replacing
the GitHub MCP entries in `backend-github.md`. A skill reads this file only when that
file's route check selects it: the MCP route fails that check and `gh api user` succeeds.

This file loads second, ahead of `.claude/baton.md` and `~/.claude/baton.md`. It defines
those three sections and nothing else - `## Categories`, `## Launcher` and `## Workflow`
stay as `backend-github.md` gives them.

## Tracker

- **list-categories:** gh label list --limit 100
- **list-open:**       gh issue list --state open --limit 500
- **list-mine:**       gh issue list --assignee @me --state open --limit 100 --search "sort:created-asc"
- **create:**          gh issue create --title "<title>" --label "<category>" --body-file <path>
- **view:**            gh issue view <id> --comments
- **close-fixed:**     gh issue close <id> --reason completed
- **close-invalid:**   gh issue close <id> --reason "not planned"
- **comment:**         gh issue comment <id> --body-file <path>
- **fetch-handoff:**   gh api repos/<owner>/<repo>/issues/comments/<comment-id> --jq .body
- **reachable:**       gh api user

`comment` prints the created comment's URL on stdout, and that is the locator
`post-handoff` reports. Do not re-derive it by listing an issue's comments: the listing is
paginated, so the newest comment is not the last entry of the first page.

`list-open` caps the dedupe `file-issue` runs against, so it is set well above the
open-issue count of any repo these skills are pointed at. `gh label list` defaults to 30,
which is low enough for a repo's own labels to hide a category from `file-issue` Step 1, so
it carries a limit too.

`list-categories` returns every label here, rather than answering for one `<category>` at a
time as it does over the MCP tools. Step 1 reads both forms the same way.

`list-mine` carries `--search "sort:created-asc"` because `gh issue list` defaults to
newest first, and the first issue it returns is the one `next-issue` picks up: oldest
assigned issue first, matching the MCP route's `"direction": "ASC"`.

`gh auth status` reports failure in every cloud session: it validates the literal
`GH_TOKEN`, which the proxy leaves as the sentinel `proxy-injected` while substituting
real credentials on outbound requests. `reachable` is the check that works.

## Forge

- **verify-checkout:** gh repo view --json nameWithOwner -q .nameWithOwner
- **pr-create:**
  - gh pr create --draft --title "<title>" --base "<pr-base>" --body-file <path>
  - gh pr edit <pr-url> --add-label "<category>"
- **stack-link:**      none
- **pr-view:**         gh pr view <id> --json number,url,body,author,headRefName,headRefOid,isDraft
- **pr-update:**       gh pr edit --body-file <path>
- **closes:**          Closes #<id>
- **refs:**            Refs #<id>

`pr-create` returns its first command's stdout, the pull request's URL, and the second command
takes that URL as `<pr-url>`. Skip the second command where `<category>` is empty.
`--base "<pr-base>"` is always passed, since `<pr-base>` falls back to `<default-branch>` and
is never empty.

The label is a separate command so the URL is in hand before anything can fail on the label.
A failed `gh pr edit` leaves the pull request open and unlabelled - a stop after
`implement-handoff` Step 5, whose `stopped` file carries that URL.

`--draft` is unconditional, matching the MCP route - every pull request these skills open
starts as a draft, and `implement-handoff` Step 5 says why.

`stack-link` is `none` here as it is on the MCP route, and the note there says why. No
`gh stack link` ships: the `github/gh-stack` extension that would supply it was not installed
where this was written, so its syntax is unverified.

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

Both `review-list` and `pr-comments` are single shell commands here, so
`implement-handoff` Step 6 waits with its `sh` loop rather than a background sleep.
