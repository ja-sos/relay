# baton

Ten Claude Code skills that carry one unit of work from a tracker issue to a finished
implementation on a pull request, across sessions sharing no context: picking the issue, investigating it, handing it off, building
it unattended, and reviewing what comes back. Every document any of them writes passes an editing
gate before it ships.

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
claude plugin install baton@relay
```

## The skills

Each is invocable as `/baton:<name>`, and each also fires on its own description.

| Skill | Fires when |
|---|---|
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

Two hooks ship alongside the skills, both POSIX `sh` with no `jq`, Python or other
dependency.

| Hook | Event | What it does |
|---|---|---|
| `remind-deliverable-skill` | `UserPromptSubmit` | adds one line naming `write-deliverables` when a prompt asks for text someone else will read |
| `gate-subagent-claim-audit` | `PreToolUse` | adds the `claim-audit` checklist to a subagent dispatch that does not already ask for it |

Neither blocks. Each adds one line of context and every tool call passes through untouched.
`claude plugin disable baton` stops both.

## Pointing it at a different tracker

Operations resolve from three files, later ones overriding earlier by `##` heading:

```
${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md
.claude/baton.md
~/.claude/baton.md
```

An override replaces its whole `##` section rather than one entry, so restate every operation the
section owns. `.claude/baton.md` is committed and an unattended cloud run reads it;
`~/.claude/baton.md` never reaches one.

`reference/defining-backends.md` carries the operation contract.

## Document contracts

`write-deliverables` binds a document type to its reader and its must-include lists. Three
contracts ship. Add your own in `.claude/doc-types.md` or `~/.claude/doc-types.md`,
per `skills/write-deliverables/reference/defining-doc-types.md`.

## Requires

`gh`, authenticated, for the shipped defaults. A repo with an `origin` remote: `write-handoff`
refuses to record a base that has not been pushed, since the session that reads the handoff
clones rather than shares the disk.

`/code-review` drives `self-review` and `review-pr`, and runs inside `implement-handoff`.

## License

MIT. See `../../LICENSE`.
