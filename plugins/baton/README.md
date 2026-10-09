# baton

Twelve Claude Code skills that carry one unit of work from a tracker issue to a reviewed pull
request, across sessions that share no context.

Nothing is hardwired to GitHub - see [Pointing it at a different
tracker](#pointing-it-at-a-different-tracker).

## Install

`relay` is the marketplace; `baton` is the plugin inside it.

```
claude plugin marketplace add ja-sos/relay
claude plugin install baton@relay
```

The [marketplace README](../../README.md) covers adding from a clone.

## The skills

Each is invocable as `/baton:<name>`, and each also fires on its own description.

- `setup`
- `next-issue`
- `file-issue`
- `investigate-issue`
- `write-handoff`
- `implement-handoff`
- `review-handoff`
- `self-review`
- `review-pr`
- `address-review`
- `write-deliverables`
- `claim-audit`

## Hooks

Two non-blocking POSIX `sh` hooks ship: `remind-deliverable-skill` (`UserPromptSubmit`) and
`gate-subagent-claim-audit` (`PreToolUse` on the subagent dispatch tool). Each script's header,
under `hooks/`, says what it adds. `claude plugin disable baton` stops both.

## Pointing it at a different tracker

`/baton:setup` writes and verifies `.claude/baton.md`. Hand-editing works too;
`reference/defining-backends.md` gives the files, their order, and what an override replaces.

Entries can be a shell command, tool, skill, subagent or another operation
(`reference/defining-backends.md`, "Operations").

Three sections are optional, each defined in `reference/defining-backends.md`:

- `## Workflow` holds the steps around the work.
- `## Repositories`, in `~/.claude/baton.md`, maps the repositories a change spans to local
  paths.
- `## Assets`, in `~/.claude/baton.md`, names a folder outside every repository that handoffs
  may name files in. Cloud runs cannot read it.

## Document contracts

`write-deliverables` binds a document type to its reader and its must-include lists. Contracts
are optional; add your own per `skills/write-deliverables/reference/defining-doc-types.md`.
An optional owner map (`owners.md`) names the file that owns each kind of fact, so a document
points there instead of restating it; see `skills/write-deliverables/reference/defining-owners.md`.

Overriding `Run report` retargets every report `implement-handoff` and `review-handoff` post.
The override sets reader and shape; what each skill requires (`implement-handoff` Step 7,
`review-handoff` Step 6) stays in.

## Requires

- The GitHub MCP tools or an authenticated `gh`; the route check in
  `reference/backend-github.md` picks one.
- A repo with an `origin` remote: `write-handoff` records only a pushed `base`.
- A review engine for the `code-review` operation, default `/code-review`
  (`reference/defining-backends.md`).

## License

MIT. See `../../LICENSE`.
