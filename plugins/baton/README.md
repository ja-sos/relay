# baton

Eleven Claude Code skills that carry one unit of work from a tracker issue to a reviewed pull
request, across sessions that share no context. Every document any of them writes passes an
editing gate before it ships.

Nothing is hardwired to GitHub. Every tracker and forge command is a named operation, and the
shipped GitHub defaults are overridable per project or per person.

## Install

`relay` is the marketplace; `baton` is the plugin inside it.

```
claude plugin marketplace add ja-sos/relay
claude plugin install baton@relay
```

`marketplace add` also takes a path, so a clone installs with no remote involved:

```
claude plugin marketplace add /path/to/relay
```

## The skills

Each is invocable as `/baton:<name>`, and each also fires on its own description.

| Skill | Fires when |
|---|---|
| `setup` | baton has to be pointed at a tracker other than GitHub |
| `next-issue` | the next issue to work on has to be chosen rather than named |
| `file-issue` | review findings need to become issues |
| `investigate-issue` | an issue needs a cause and an approach before code is written |
| `write-handoff` | work has to continue in a session that starts cold |
| `implement-handoff` | a handoff is ready to build, unattended, into a pull request |
| `self-review` | that unattended run's branch needs checking before anyone else sees it |
| `review-pr` | someone else's pull request needs reviewing |
| `address-review` | review feedback has arrived on a pull request you own |
| `write-deliverables` | any text that outlives the session is being written |
| `claim-audit` | a claim about how something behaves is about to be stated |

## Hooks

Two hooks ship alongside the skills, both POSIX `sh`.

| Hook | Event | What it does |
|---|---|---|
| `remind-deliverable-skill` | `UserPromptSubmit` | adds one line naming `write-deliverables` when a prompt asks for text someone else will read |
| `gate-subagent-claim-audit` | `PreToolUse` | adds the `claim-audit` checklist to a subagent dispatch that does not already ask for it |

Neither blocks. Each adds one line of context and every tool call passes through untouched.
`gate-subagent-claim-audit` rewrites the dispatch prompt through `python3`, `python` or `node`
when one is present, and otherwise asks the dispatching session to carry the requirement
instead. `claude plugin disable baton` stops both.

## Pointing it at a different tracker

`/baton:setup` writes `.claude/baton.md` for the tracker you name and verifies it by running
the read-only operations. Hand-editing does the same job: operations resolve from up to four
files, later ones overriding earlier by `##` heading:

```
${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
${CLAUDE_PLUGIN_ROOT}/reference/backend-github-mcp.md   read only when gh is missing or cannot reach GitHub
.claude/baton.md
~/.claude/baton.md
```

An override replaces its whole `##` section rather than one entry, so restate every operation
the section owns. A section left out is not overridden at all, so its GitHub commands stay in
force. `.claude/baton.md` is committed and an unattended cloud run reads it;
`~/.claude/baton.md` never reaches one.

An operation is a shell command by default, and `tool:`, `skill:` or `op:` names a tool call,
a skill or another operation instead - so a tracker reachable only through an MCP connector
needs no wrapper script. `## Workflow` is the sixth section, holding the steps around the work
rather than the work itself: where the handoff is posted and found, which engine reviews, who
is asked to review a pull request, and what runs once one is published. Its defaults resolve
through `## Tracker`, so retargeting the tracker moves them with it.

`reference/defining-backends.md` carries the operation contract.

## Document contracts

`write-deliverables` binds a document type to its reader and its must-include lists. Three
contracts ship and any type not listed is derived, so a project needs none. Add your own in
`.claude/doc-types.md` or `~/.claude/doc-types.md`, per
`skills/write-deliverables/reference/defining-doc-types.md`.

## Requires

`gh`, authenticated, for the shipped defaults - or, in a session without it, the GitHub MCP
tools, which `reference/backend-github-mcp.md` runs the same operations through. A repo with
an `origin` remote: `write-handoff` refuses to record a base that has not been pushed, since
the session that reads the handoff clones rather than shares the disk.

A review engine: `self-review`, `review-pr` and `implement-handoff` all run the `code-review`
operation, whose default is `/code-review`. A project with its own review skill names it there
and edits none of the three.

## License

MIT. See `../../LICENSE`.
