# Defining a backend

Every tracker and forge command the skills run is a named **operation**. The skills ship
GitHub defaults, so a repo using `gh` needs no configuration. Overriding an operation
points the skills at a different tracker without editing any skill.

## Where overrides live

The skills read three files, in this order:

```
${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md   shipped GitHub defaults
.claude/baton.md                                     project backend; committed, so an unattended run sees it
~/.claude/baton.md                                   personal defaults across all projects
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

Every `## Launcher` entry sends one prompt, `/baton:implement-handoff <comment url>`. A
run reads the handoff and nothing the starting session holds, so an entry that passes
context instead of that locator starts a session with no work to do. Passing context
*beside* the locator fails the other way: the prompt arrives as a user turn, so a
suggestion copied into it outranks the handoff section it was copied from.

## Operations

Entries are `- **<name>:** <command>`. A value spanning lines goes in a fenced block
below the entry.

| Operation | Called by | Substitutes |
|---|---|---|
| `list-categories` | `file-issue` Step 1 | - |
| `list-open` | `file-issue` Step 1 | - |
| `list-mine` | `next-issue` Step 1 | - |
| `create` | `file-issue` Step 5 | `<title>` `<category>` `<path>` |
| `view` | `investigate-issue` Step 1, `next-issue` Step 2 | `<id>` |
| `close-fixed` / `close-invalid` | `investigate-issue` Step 2 | `<id>` |
| `comment` | `write-handoff` Step 1, `implement-handoff` Step 5 | `<id>` `<path>` |
| `fetch-handoff` | `implement-handoff` Step 1 | `<owner>` `<repo>` `<comment-id>` |
| `reachable` | `implement-handoff` Step 1 | - |
| `verify-checkout` | `implement-handoff` Step 1 | - |
| `pr-create` | `implement-handoff` Step 5 | `<title>` `<path>` |
| `pr-view` | `self-review` Step 1, `review-pr` Step 1, `address-review` Step 1 | `<id>` |
| `pr-update` | `self-review` Step 4, `address-review` Step 5 | `<path>` |
| `review-list` | `review-pr` Step 4 | `<owner>` `<repo>` `<id>` |
| `review-post` | `review-pr` Step 4 | `<owner>` `<repo>` `<id>` `<path>` |
| `review-bodies` | `address-review` Step 2 | `<owner>` `<repo>` `<id>` |
| `pr-comments` | `address-review` Step 2 | `<owner>` `<repo>` `<id>` |
| `review-threads` | `address-review` Step 2 | `<owner>` `<repo>` `<id>` |
| `thread-reply` | `address-review` Step 5 | `<owner>` `<repo>` `<id>` `<comment-id>` `<path>` |
| `pr-comment` | `address-review` Step 5 | `<id>` `<path>` |
| `closes` / `refs` | `implement-handoff` Step 5 | `<id>` |

`review-bodies`, `pr-comments` and `review-threads` are one set, not three alternatives: each
reads a surface the others cannot see, and defining fewer loses a surface with no error. Any
author filtering belongs inside the command, since it is part of what the operation collects.

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

## Checks

| Check | Test |
|---|---|
| Section loads | `grep -n '^## Tracker' .claude/baton.md ~/.claude/baton.md` prints a line |
| Heading depth | `##`; `#` and `###` do not match |
| Entries complete | every operation the section owns is present |
| Placeholders spelled | `<id>` not `<issue>`; an unrecognised placeholder is passed through literally |
| Body arrives as a file | each operation taking `<path>` reads the file rather than a string |
| Runs standalone | paste the command with real values into a shell; it must succeed there first |

A backend is done when every row passes.
