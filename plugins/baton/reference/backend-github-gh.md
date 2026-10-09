# GitHub backend over gh

The shipped `## Tracker`, `## Forge` and `## Review` sections as `gh` commands, replacing
the GitHub MCP entries in `backend-github.md`. Read only where `backend-github.md`'s route
check selects it. It defines those three sections and nothing else - `## Categories`,
`## Launcher` and `## Workflow` stay as `backend-github.md` gives them.

## Tracker

- **list-categories:** gh label list --limit 100
- **list-open:**       gh issue list --state open --limit 500
- **list-mine:**       gh issue list --assignee @me --state open --limit 100 --search "sort:created-asc"
- **create:**          gh issue create --title "<title>" --label "<category>" --body-file <path>
- **view:**            gh issue view <id> -R <owner>/<repo> --comments
- **close-fixed:**     gh issue close <id> -R <owner>/<repo> --reason completed
- **close-invalid:**   gh issue close <id> -R <owner>/<repo> --reason "not planned"
- **comment:**         gh issue comment <id> -R <owner>/<repo> --body-file <path>
- **fetch-handoff:**   gh api repos/<owner>/<repo>/issues/comments/<comment-id> --jq .body
- **reachable:**       gh api user

`view`, `comment`, `close-fixed` and `close-invalid` pass `-R` because they address the
issue's repository, which may not be the checkout's (`defining-backends.md`).

`comment` prints the created comment's URL on stdout, and that is the locator
`post-handoff` reports. Do not re-derive it by listing an issue's comments: the listing is
paginated, so the newest comment is not the last entry of the first page.

`list-open` is capped at 500. `gh label list` defaults to 30, so `list-categories` carries a
limit, and returns every label.

`create` drops `--label "<category>"` where `<category>` is empty, and runs the rest of the
command as written.

`list-mine` carries `--search "sort:created-asc"` because `gh issue list` defaults to
newest first, and `list-mine` returns pick order, oldest first.

`gh auth status` reports failure in every cloud session: it validates the literal
`GH_TOKEN`, which the proxy leaves as the sentinel `proxy-injected` while substituting
real credentials on outbound requests. `reachable` is the check that works.

## Forge

- **verify-checkout:** gh repo view --json nameWithOwner -q .nameWithOwner
- **pr-create:**
  - gh pr create --draft --title "<title>" --base "<pr-base>" --body-file <path>
  - gh pr edit <pr-url> --add-label "<category>"
- **stack-link:**      none
- **pr-view:**         gh pr view <id> --json number,url,title,body,author,headRefName,headRefOid,isDraft
- **pr-issues:**       op: pr-view <id>
- **pr-update:**       gh pr edit --body-file <path>
- **closes:**          Closes <owner>/<repo>#<id>
- **refs:**            Refs <owner>/<repo>#<id>

`pr-create` returns its first command's stdout, the pull request's URL, and the second command
takes that URL as `<pr-url>`. Skip the second command where `<category>` is empty.
`--base "<pr-base>"` is always passed: `<pr-base>` is never empty (`defining-backends.md`).

The label is a separate command so the URL is in hand before anything can fail on the label.
A failed `gh pr edit` leaves the pull request open and unlabelled.

`--draft` is unconditional; `implement-handoff` Step 5 says why.

`stack-link` is `none` here as it is on the MCP route, and the note there says why.

`pr-view` takes an empty `<id>` to mean the pull request for the current branch.

`pr-issues` reads `pr-view`'s answer the way the MCP route's note says.

`closes` and `refs` match the MCP route; the note there says why.

## Review

- **review-list:**     gh api repos/<owner>/<repo>/pulls/<id>/reviews
- **review-post:**     gh api -X POST repos/<owner>/<repo>/pulls/<id>/reviews --input <path>
- **review-bodies:**   gh api repos/<owner>/<repo>/pulls/<id>/reviews --jq '.[] | select(.body != "" and .user.type == "User") | {id, user: .user.login, state, body}'
- **pr-comments:**     gh api repos/<owner>/<repo>/issues/<id>/comments --jq '.[] | select(.user.type == "User") | {id, user: .user.login, body}'
- **review-threads:**  see the query below
- **thread-reply:**    gh api -X POST repos/<owner>/<repo>/pulls/<id>/comments/<comment-id>/replies --input <path>
- **pr-comment:**      gh pr comment <id> --body-file <path>

`pr-comments` uses the `issues` path because every pull request is also an issue - it is the
only endpoint returning top-level notes that belong to no review.

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
{"commit_id": "<headRefOid>",
 "event": "COMMENT",
 "body": "<summary>",
 "comments": [{"path": "<file>", "line": 42, "side": "RIGHT", "body": "<finding>"}]}
```

`commit_id` is required and a push invalidates every anchor built against an older one. Omitting
`event` leaves the review PENDING and invisible. A multi-line comment adds `start_line` beside
`line`.
