# Defining a backend

Every tracker and forge command the skills run is a named **operation**. The skills ship
GitHub defaults, so a GitHub repo needs no configuration: they run through `gh`, or
through the GitHub MCP tools where `gh` is missing. Overriding an operation points the
skills at a different tracker without editing any skill.

## Where overrides live

The skills read up to four files, in this order:

```
${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md       shipped GitHub defaults
${CLAUDE_PLUGIN_ROOT}/reference/backend-github-mcp.md   the same through the GitHub MCP tools; read only when `gh` is missing or `gh api user` fails
.claude/baton.md                                         project backend; committed, so an unattended run sees it
~/.claude/baton.md                                       personal defaults across all projects
```

A `##` heading is the key, and a matching heading replaces the shipped section
**wholesale** - not operation by operation. Overriding one entry of `## Tracker` means
restating all of them; an omitted entry is undefined, not inherited.

A cloud or CI session clones the repo and never sees your home directory. A backend an
unattended run must use goes in `.claude/baton.md`.

## Sections

| Section | Supplies |
|---|---|
| `## Tracker` | reading, creating, commenting on and closing issues |
| `## Categories` | the condition-to-label table `file-issue` picks from |
| `## Forge` | checkout verification, pull requests, closing keywords |
| `## Review` | collecting review feedback on a pull request, and answering it |
| `## Launcher` | how `investigate-issue` starts an implementation run |
| `## Workflow` | the steps the skills run around the work: posting and finding handoffs, reviewing, publishing |

Every `## Launcher` entry sends one prompt, `/baton:implement-handoff <locator>`. A
run reads the handoff and nothing the starting session holds, so an entry that passes
context instead of that locator starts a session with no work to do. Passing context
*beside* the locator fails the other way: the prompt arrives as a user turn, so a
suggestion copied into it outranks the handoff section it was copied from.

## Operations

Entries are `- **<name>:** <value>`. A value spanning lines goes in a fenced block below
the entry, and a fenced block is one multi-line command rather than a sequence of them.

A bare value is a shell command, wherever the operation is one the skills *run*. Three are
values they read instead - `closes`, `refs` and `review-wait` - and those stay literal text
whatever they look like. A prefix names something else:

| Value | Meaning |
|---|---|
| `<command>` | run it in a shell |
| `tool: <tool-name> <json-args>` | call that tool, loading it with `ToolSearch select:<tool-name>` first when it is deferred |
| `skill: /<name> <args>` | invoke that skill |
| `op: <operation> <args>` | run another operation of this backend, with these substitutions |
| a nested bullet list | each bullet is one entry in any of the forms above, run in order; the first failure stops the rest |
| `none` | skip the step. Valid for `request-reviewer` only - any other operation set to `none` is undefined |

`none` and undefined are not the same answer. `none` says the project has decided the
review round does not run; undefined says the backend is incomplete, and every skill
treats it as a stop.

`tool:` exists so that a tracker reachable only through an MCP connector needs no CLI and
no second set of credentials. Inside its JSON, `<body>` is the text of the file at
`<path>`, JSON-escaped: a tool call has no shell to redirect a file into, so an operation
taking `<path>` sends `<body>` instead.

`<locator>` stands for whatever `post-handoff` returned, passed whole - a comment URL, a
bare id, a file path. Only the backend has to understand it: where `fetch-handoff` takes
`<owner>`, `<repo>`, `<id>` or `<comment-id>`, the backend's notes say how each comes from
the locator.

Four placeholders are open to every entry, derived rather than passed by the caller:

| Placeholder | Value |
|---|---|
| `<owner>` `<repo>` | `verify-checkout`'s answer, split at the slash |
| `<branch>` | `git branch --show-current` |
| `<default-branch>` | `git symbolic-ref --short refs/remotes/origin/HEAD`, without its `origin/`; where that exits non-zero, the name after `refs/heads/` in the `ref:` line of `git ls-remote --symref origin HEAD` |

| Operation | Called by | Substitutes |
|---|---|---|
| `list-categories` | `file-issue` Step 1 | - |
| `list-open` | `file-issue` Step 1 | - |
| `list-mine` | `next-issue` Step 1 | - |
| `create` | `file-issue` Step 5 | `<title>` `<category>` `<path>` |
| `view` | `investigate-issue` Step 1 | `<id>` |
| `close-fixed` / `close-invalid` | `investigate-issue` Step 2 | `<id>` |
| `comment` | the `## Workflow` defaults of `post-handoff`, `published` and `stopped` | `<id>` `<path>` |
| `fetch-handoff` | `implement-handoff` Step 1 | `<owner>` `<repo>` `<id>` `<comment-id>` `<locator>` |
| `reachable` | `implement-handoff` Step 1 | - |
| `verify-checkout` | `implement-handoff` Step 1 | - |
| `pr-create` | `implement-handoff` Step 5 | `<title>` `<path>` |
| `pr-view` | `self-review` Step 1, `review-pr` Step 1, `address-review` Step 1 | `<id>` |
| `pr-update` | `self-review` Step 4, `address-review` Step 5 | `<id>` `<path>` |
| `review-list` | `review-pr` Step 4, `implement-handoff` Step 6 | `<owner>` `<repo>` `<id>` |
| `review-post` | `review-pr` Step 4 | `<owner>` `<repo>` `<id>` `<path>` |
| `review-bodies` | `address-review` Step 2, `implement-handoff` Step 6 | `<owner>` `<repo>` `<id>` |
| `pr-comments` | `address-review` Step 2, `implement-handoff` Step 6 | `<owner>` `<repo>` `<id>` |
| `review-threads` | `address-review` Step 2, `implement-handoff` Step 6 | `<owner>` `<repo>` `<id>` |
| `thread-reply` | `address-review` Step 5, `implement-handoff` Step 6 | `<owner>` `<repo>` `<id>` `<comment-id>` `<path>` |
| `pr-comment` | `address-review` Step 5, `implement-handoff` Step 6 | `<id>` `<path>` |
| `closes` / `refs` | `implement-handoff` Step 5 | `<id>` |
| `post-handoff` | `write-handoff` Step 1 | `<id>` `<path>` |
| `has-handoff` | `next-issue` Step 2, `investigate-issue` Step 1 | `<id>` |
| `code-review` | `implement-handoff` Step 4, `review-pr` Step 2, `self-review` Step 1 | `<target>` |
| `request-reviewer` | `implement-handoff` Step 6 | `<id>` |
| `review-wait` | `implement-handoff` Step 6 | - |
| `published` | `implement-handoff` Step 7 | `<id>` `<path>` `<pr-url>` |
| `stopped` | `implement-handoff` stop path | `<id>` `<path>` |

`review-bodies`, `pr-comments` and `review-threads` are one set, not three alternatives: each
reads a surface the others cannot see, and defining fewer loses a surface with no error. Any
author filtering belongs inside the command, since it is part of what the operation collects.
A `tool:` entry cannot filter its output, so the backend's notes name the filter and the
caller applies it.

The last seven are `## Workflow`, and the shipped defaults of `post-handoff`, `published`
and `stopped` are `op: comment <id> <path>` - so a backend that has overridden `## Tracker`
for Jira posts all three to Jira without naming them at all.

`has-handoff` answers whether an issue already carries a handoff. Its default runs `view`,
and the caller scopes the answer by looking for the handoff marker in that output; a
backend that can ask the question directly returns output the caller reads the same way.

`review-wait` is a number of minutes, not a command. The cap is 60: an unattended run that
waits longer than that is holding a finished branch for a reviewer who is not coming, and
the cap also keeps the wait inside `Monitor`'s `timeout_ms` maximum of 3600000 ms, for a
backend that allows that tool.

`list-mine` returns the issues assigned to the user in the order they should be picked up;
the tracker's own ranking belongs in that command, not in the skill reading its output.

`<path>` is always a file. A tracker CLI that takes body text on the command line mangles
backticks and fenced blocks through the shell, so an operation that cannot read a file
needs a wrapper that does.

## Example

Renaming the three categories. Only the labels change, but the section is replaced whole, so
its third column is restated rather than inherited:

```markdown
## Categories

| Condition | Category | Body headings |
|---|---|---|
| Code contradicts its documented or intended behavior | defect | `## Effect`, `## Reproduce`, `## Fix` |
| Code is correct; docs are wrong, missing or misleading | docs | `## Says`, `## Actually`, `## Correction` |
| Code behaves as intended; something new is wanted | feature | `## Motivation`, `## Proposal`, `## Constraints` |
```

Retargeting the tracker itself means restating `## Tracker` with the other tool's
commands, keeping the operation names and placeholders exactly as the table above spells
them. The shipped defaults in `reference/backend-github.md` are the template to copy from.

Turning the review round on, and logging time after the pull request is published. All
seven `## Workflow` operations are restated, because the heading replaces the section
whole and the five left at their defaults would otherwise be undefined:

```markdown
## Workflow

- **post-handoff:**     op: comment <id> <path>
- **has-handoff:**      op: view <id>
- **code-review:**      skill: /code-review <target>
- **request-reviewer:** gh pr edit <id> --add-reviewer @copilot
- **review-wait:**      20
- **published:**
  - op: comment <id> <path>
  - tool: jira_add_worklog {"issueKey": "<id>", "comment": "Shipped <pr-url>"}
- **stopped:**          op: comment <id> <path>
```

`published` runs two entries in order, and the comment goes first: a worklog that fails
must not swallow the only notice that the run finished.

## Checks

| Check | Test |
|---|---|
| Section loads | `grep -n '^## Tracker' .claude/baton.md ~/.claude/baton.md` prints a line |
| Heading depth | `##`; `#` and `###` do not match |
| Entries complete | every operation the section owns is present |
| Placeholders spelled | `<id>` not `<issue>`; an unrecognised placeholder is passed through literally |
| Body arrives as a file | each operation taking `<path>` reads the file rather than a string, or sends `<body>` when it is a `tool:` entry |
| Runs standalone | paste the command with real values into a shell; it must succeed there first |
| Tool entries called | call each `tool:` entry of a read operation with real values, since it has no shell form to paste; never call one `baton:setup` Step 4 forbids running |

A backend is done when every row passes.

## Tools an unattended run needs

A cloud session can have the `mcp__github__*` tools and no `gh`; the shipped defaults then
run through `backend-github-mcp.md`. A cloud run whose `## Launcher` entry's `allowed_tools`
held only `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep` and `Skill` loaded `ToolSearch`
and the GitHub MCP tools it needed, and called them with no permission denial.

Under that route `review-list` and `pr-comments` are `tool:` entries, so the review round
does not run: its wait is a `Bash` loop. With `gh`, the round needs no tool beyond `Bash`,
which every entry allows; adding `Monitor` to the list lets the round use that instead.
