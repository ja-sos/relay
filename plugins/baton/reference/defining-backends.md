# Defining a backend

Every tracker and forge call the skills make is a named **operation**. The skills ship
GitHub defaults, so a GitHub repo needs no configuration: they run through the GitHub MCP
tools, or through `gh` in a session without those tools. Overriding an operation points
the skills at a different tracker without editing any skill.

## Where overrides live

The skills read up to four files, in this order:

```
${CLAUDE_PLUGIN_ROOT}/reference/backend-github.md      shipped GitHub defaults, over the GitHub MCP tools
${CLAUDE_PLUGIN_ROOT}/reference/backend-github-gh.md   the same three sections as `gh` commands; read only where that file's route check selects it
.claude/baton.md                                        project backend; committed, so an unattended run sees it
~/.claude/baton.md                                      personal defaults across all projects
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
| `## Forge` | checkout verification, pull requests, stack registration, closing keywords |
| `## Review` | collecting review feedback on a pull request, and answering it |
| `## Launcher` | how `investigate-issue` starts an implementation run |
| `## Workflow` | the steps the skills run around the work: posting and finding handoffs, reviewing, publishing |

Every `## Launcher` entry sends one prompt, `/baton:implement-handoff <locator>`. A
run reads the handoff and nothing the starting session holds, so an entry that passes
context instead of that locator starts a session with no work to do. Passing context
*beside* the locator fails the other way: the prompt arrives as a user turn, so a
suggestion copied into it outranks the handoff section it was copied from.

Two callers reach these entries by name. `investigate-issue` Step 6 asks a person which to
use; `implement-handoff` Step 7 takes the name from the finishing handoff's `next` line and
runs it unasked, to start the layer above in a stack. So an entry has to be runnable from
inside an unattended run of the very skill it launches - which is what the tool list below
is about.

## Operations

Entries are `- **<name>:** <value>`. A value spanning lines goes in a fenced block below
the entry, and a fenced block is one multi-line command rather than a sequence of them.

A bare value is a shell command, wherever the operation is one the skills *run*. Three are
values they read instead - `closes`, `refs` and `review-wait` - and those stay literal text
whatever they look like. `verify` is run, but takes one literal besides a command:
`repo-tests`, in the table below. A prefix names something else:

| Value | Meaning |
|---|---|
| `<command>` | run it in a shell |
| `tool: <tool-name> <json-args>` | call that tool, loading it with `ToolSearch select:<tool-name>` first when it is deferred |
| `skill: /<name> <args>` | invoke that skill |
| `agent: <type> <prompt>` | dispatch a subagent of that type with that prompt, through the subagent dispatch tool - `Agent` or `Task`, by harness build |
| `op: <operation> <args>` | run another operation of this backend, with these substitutions |
| a nested bullet list | each bullet is one entry in any of the forms above, run in order; the first failure stops the rest |
| `none` | skip the step. Valid for `started`, `stack-link`, `request-reviewer` and `wrap-up` only - any other operation set to `none` is undefined |
| `repo-tests` | run the repo's full test command, as the run finds it. Valid for `verify` only - anywhere else it is a shell command, and no such binary exists |

`none` and undefined are not the same answer. `none` says the project has decided the step
does not run - that no tracker transition marks the start of implementation, that the forge
tracks no stack to register a layer in, that the review round does not run, that no step runs
when a person-attended flow ends; undefined says the backend is incomplete, and every skill
treats it as a stop - except an undefined `wrap-up`, which the attended skills read as `none`.

`repo-tests` is a literal the skills recognise rather than a command they run, because no
single command is every repo's suite. It is `verify`'s shipped value, and a project that
mandates a sequence of its own - a formatter pass, then a test-and-lint target - writes that
sequence here instead. A sequence that rewrites files does so before any of its checks:
`implement-handoff` commits the tree `verify` leaves, so a rewrite after the checks commits a
tree none of them ran against. In a repo with no test command it passes with nothing run, and
the handoff's own commands are then the only thing checking the change.

`none` is not among `verify`'s values. A project that wants nothing repo-wide already has
`repo-tests`, which runs nothing where there is nothing to run, and a project that has a
sequence should not be able to turn the check off from the same field it configures it in.

`tool:` exists so that a tracker reachable only through an MCP connector needs no CLI and
no second set of credentials. Inside its JSON, `<body>` is the text of the file at
`<path>`, JSON-escaped: a tool call has no shell to redirect a file into, so an operation
taking `<path>` sends `<body>` instead.

`agent:` exists for the operation that is a judgement rather than a call - a reviewer that
reads acceptance criteria and checks a diff against them has no CLI form and no tool to
name. `<type>` is one agent type the session offers, `general-purpose` where the project has
none of its own, and everything after it is the prompt, with the placeholders of that
operation substituted into it. A prompt spanning lines goes in a fenced block below the
entry, as any other multi-line value does. What the subagent reports is the operation's
output, read by the caller the same way a command's stdout is. An entry the session cannot
dispatch - no dispatch tool in the run's allowed set, under either name - fails under the
caller's stop rule, the same as a missing binary.

`<locator>` stands for whatever `post-handoff` returned, passed whole - a comment URL, a
bare id, a file path. Only the backend has to understand it: where `fetch-handoff` takes
`<owner>`, `<repo>`, `<id>` or `<comment-id>`, the backend's notes say how each comes from
the locator. `code-review` takes it as well, and there it may arrive empty, from a caller
working on no handoff.

Five placeholders are open to every entry, derived rather than passed by the caller:

| Placeholder | Value |
|---|---|
| `<owner>` `<repo>` | `verify-checkout`'s answer, split at the slash |
| `<head-owner>` | the owner in `origin`'s URL, printed by the command below |
| `<branch>` | `git branch --show-current` |
| `<default-branch>` | `git symbolic-ref --short refs/remotes/origin/HEAD`, without its `origin/`; where that exits non-zero, the name after `refs/heads/` in the `ref:` line of `git ls-remote --symref origin HEAD` |

```
git remote get-url origin | sed -E 's#\.git$##; s#.*[/:]([^/:]+)/[^/]+$#\1#'
```

`<head-owner>` differs from `<owner>` in a fork clone: `verify-checkout` answers with the
upstream repository, and the branch is pushed to `origin`.

| Operation | Called by | Substitutes |
|---|---|---|
| `list-categories` | `file-issue` Step 1 | `<category>` |
| `list-open` | `file-issue` Step 1 | - |
| `list-mine` | `next-issue` Step 1 | - |
| `create` | `file-issue` Step 5 | `<title>` `<category>` `<path>` |
| `view` | `investigate-issue` Step 1 | `<id>` |
| `close-fixed` / `close-invalid` | `investigate-issue` Step 2 | `<id>` |
| `comment` | the `## Workflow` defaults of `post-handoff`, `published` and `stopped` | `<id>` `<path>` |
| `fetch-handoff` | `implement-handoff` Step 1 | `<owner>` `<repo>` `<id>` `<comment-id>` `<locator>` |
| `reachable` | `implement-handoff` Step 1 | - |
| `verify-checkout` | `implement-handoff` Step 1 | - |
| `pr-create` | `implement-handoff` Step 5 | `<title>` `<path>` `<category>` `<pr-base>` |
| `stack-link` | `implement-handoff` Step 5 | `<id>` `<pr-url>` `<pr-base>` |
| `pr-view` | `self-review` Step 1, `review-pr` Step 1, `address-review` Step 1 | `<id>` |
| `pr-update` | `self-review` Step 4, `address-review` Step 5, `implement-handoff` Step 6 | `<id>` `<path>` |
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
| `started` | `implement-handoff` Step 2 | `<id>` |
| `verify` | `implement-handoff` Steps 3, 4 and 6 | - |
| `code-review` | `implement-handoff` Steps 4 and 6, `review-pr` Step 2, `self-review` Step 1 | `<target>` `<locator>` |
| `request-reviewer` | `implement-handoff` Step 6 | `<id>` |
| `review-wait` | `implement-handoff` Step 6 | - |
| `published` | `implement-handoff` Step 7 | `<id>` `<path>` `<pr-url>` |
| `stopped` | `implement-handoff` stop path | `<id>` `<path>` |
| `wrap-up` | `investigate-issue` Step 2 or 6, `review-pr` Step 5, `address-review` Done, `self-review` Step 4 | `<skill>` `<id>` `<pr-url>` `<head-branch>` |

`pr-create` takes two values beyond the title and the body, both from the handoff's header
and both optional there. `<category>` is the label the handoff's `category` line names, and
it is **empty** where that line is absent; each entry substituting it says in its notes what
an empty value drops, because a `tool:` entry has no conditional syntax and the caller
applies the note instead. `<pr-base>` is the handoff's `pr-base` line, or `<default-branch>`
where that line is absent - it is never empty. It does not replace the derived
`<default-branch>` above, which every other entry keeps using.

Both placeholders were added in baton 0.1.9. A `## Forge` written before then substitutes
neither, so its pull requests carry no label and open against the default branch. Add
`<category>` and `<pr-base>` to that section's `pr-create`: until then `implement-handoff`
stops at Step 1 on any handoff with a `pr-base` line, and drops a `category` line without
an error.

`pr-create` also opens a draft on both shipped routes, unconditionally. An entry a project
writes for itself decides that for itself, but `implement-handoff` treats marking a pull
request ready as outside what an unattended run may do, so an entry that opens a ready one
ships branches no person has looked at.

`stack-link` registers a pull request as one layer of a stack. It runs at `implement-handoff`
Step 5, immediately after `pr-create` and **only where the handoff's header carries
`pr-base`** - which is why a project whose `## Forge` predates the operation keeps running
single-layer handoffs and stops only on a stacked one. `<pr-url>` is what `pr-create`
returned and `<pr-base>` the branch below; `<id>` is the issue's number, as it is everywhere
else in that step. Both shipped routes ship `none`: a pull request opened against another's
branch already reads as stacked on GitHub, and `pr-create` has passed that base already.

`review-bodies`, `pr-comments` and `review-threads` are one set, not three alternatives: each
reads a surface the others cannot see, and defining fewer loses a surface with no error. Any
author filtering belongs inside the command, since it is part of what the operation collects.
A `tool:` entry cannot filter its output, so the backend's notes name the filter and the
caller applies it.

The last ten are `## Workflow`, and the shipped defaults of `post-handoff`, `published`
and `stopped` are `op: comment <id> <path>` - so a backend that has overridden `## Tracker`
for Jira posts all three to Jira without naming them at all.

`started` is the eighth, added in baton 0.1.5. A `## Workflow` written before it does not
name `started` at all, which leaves it undefined rather than `none`, and
`implement-handoff` stops at Step 2 - add `- **started:**          none` to that section,
or the entry the project's tracker moves its ticket with.

`wrap-up` is the ninth, added in baton 0.1.6. Unlike every other operation, leaving it
undefined is not a stop: `investigate-issue`, `review-pr`, `address-review` and
`self-review` treat a `wrap-up` no loaded file defines as `none`, so a `## Workflow` written
before 0.1.6 keeps working unchanged. Add the entry the project runs when an attended flow
ends to use it.

`wrap-up` is each of those four skills' final action, and it runs on the path where the user
declines the last push or post as well: the flow ended either way. `<skill>` is the calling
skill's name without the `baton:` prefix. `<id>` is the issue number for
`investigate-issue` and the pull request number for the other three, and `<pr-url>` and
`<head-branch>` are the pull request's URL and head branch from `pr-view`, both empty for
`investigate-issue`. `self-review` on a branch carrying no pull request passes an empty
`<id>` and `<pr-url>`, and the current branch as `<head-branch>`. A shell entry quotes each
placeholder - `log-flow "<skill>" "<id>" "<pr-url>" "<head-branch>"` - so an empty value
still arrives as its own argument instead of shifting the ones after it.

`<head-branch>` is passed by the caller rather than derived, unlike `<branch>` above:
`review-pr` reviews a pull request whose head may not be checked out, so the checked-out
branch is the wrong answer there. A `wrap-up` that fails is reported by name; the skill
leaves everything it already published in place and does not retry.

`verify` is the tenth, added in baton 0.1.8. A `## Workflow` written before it leaves
`verify` undefined the same way, and the same run stops at Step 2 - add
`- **verify:**           repo-tests` to that section, or the sequence the project runs
before a push. It takes no placeholders: what it checks is the whole repo, not this
change, which is what the handoff's own commands cover.

`stack-link` is the same shape of addition to `## Forge`, in baton 0.1.10. A section written
before it leaves the operation undefined, and `implement-handoff` stops at Step 1 - but only
on a handoff whose header carries `pr-base`, because that is the only case the run resolves
it in. Add `- **stack-link:**      none`, or the entry the project's forge registers a stack
with. Two more edits belong to the same upgrade and neither errors when skipped, which is why
they are named here:

- An overridden `pr-create` opens a ready pull request until its entry adds the shipped
  routes' `--draft` or `"draft": true`.
- An overridden `## Launcher` keeps its own `allowed_tools`, so a `cloud` entry copied before
  0.1.10 lacks `RemoteTrigger` and cannot launch the layer above. See **Tools an unattended
  run needs**.

`has-handoff` answers whether an issue already carries a handoff. Its default runs `view`,
and the caller scopes the answer by looking for the handoff marker in that output; a
backend that can ask the question directly returns output the caller reads the same way.

`code-review` substitutes two placeholders. `<target>` is what to review - a pull request
number, a branch, or empty for the working tree. `<locator>` is the handoff the work came
from: `implement-handoff` Step 4 fills it with the locator its run opened with, while
`review-pr` Step 2 and `self-review` Step 1 pass it empty, having none. An entry whose prompt
checks acceptance criteria reads them from the handoff at `<locator>` where one is given;
where it is empty, that entry has no criteria to read and says so rather than inventing them.
The shipped entry uses neither placeholder beyond `<target>`.

`review-wait` is a number of minutes, not a command. The cap is 60: an unattended run that
waits longer than that is holding a finished branch for a reviewer who is not coming, and
the cap also keeps the wait inside `Monitor`'s `timeout_ms` maximum of 3600000 ms, for a
backend that allows that tool.

`list-mine` returns the issues assigned to the user in the order they should be picked up;
the tracker's own ranking belongs in that command, not in the skill reading its output. Both
shipped GitHub routes order it oldest first, so the longest-waiting assigned issue is the one
`next-issue` offers.

`list-categories` either returns every category the tracker offers, or answers for one
`<category>` at a time - a tracker with no call that enumerates its labels can only do the
second. The backend's notes say which, and a caller that gets the second form runs the
operation once per row of `## Categories`. Either way `file-issue` Step 1 asks the same
question: is a category from that table missing from the tracker.

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
them. The shipped defaults are the template to copy from:
`reference/backend-github.md` for a tracker reached through an MCP connector,
`reference/backend-github-gh.md` for one reached through a CLI.

Turning the review round on, and logging time after the pull request is published. All
ten `## Workflow` operations are restated, because the heading replaces the section
whole and the seven left at their defaults would otherwise be undefined:

```markdown
## Workflow

- **post-handoff:**     op: comment <id> <path>
- **has-handoff:**      op: view <id>
- **started:**          none
- **verify:**           repo-tests
- **code-review:**      skill: /code-review <target>
- **request-reviewer:** tool: mcp__github__request_copilot_review {"owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}
- **review-wait:**      20
- **published:**
  - op: comment <id> <path>
  - tool: jira_add_worklog {"issueKey": "<id>", "comment": "Shipped <pr-url>"}
- **stopped:**          op: comment <id> <path>
- **wrap-up:**          none
```

`published` runs two entries in order, and the comment goes first: a worklog that fails
must not swallow the only notice that the run finished.

Pairing the correctness review with a compliance reviewer. `code-review` becomes a nested
list, and `implement-handoff` Step 4 classifies the findings of both by the same severity
table:

````markdown
## Workflow

- **post-handoff:**     op: comment <id> <path>
- **has-handoff:**      op: view <id>
- **started:**          none
- **verify:**           repo-tests
- **code-review:**
  - skill: /code-review <target>
  - agent: general-purpose

    ```
    Review the change at <target> - the working tree, where that is empty - against the
    acceptance criteria of the handoff at <locator>. Read the handoff first. An empty
    <locator> means there is no handoff: report that and stop, rather than inferring
    criteria from the diff.

    Report one row per criterion: the criterion, the file:line that satisfies it, and MET,
    UNMET or UNCLEAR. A criterion no hunk of the diff satisfies is UNMET, whatever the
    change's own documentation says about it. Recommend nothing - what an UNMET row costs
    is the caller's to weigh.
    ```
- **request-reviewer:** none
- **review-wait:**      10
- **published:**        op: comment <id> <path>
- **stopped:**          op: comment <id> <path>
- **wrap-up:**          none
````

The first entry's failure stops the second, so the compliance reviewer never runs against a
diff the correctness review could not read.

## Checks

| Check | Test |
|---|---|
| Section loads | `grep -n '^## Tracker' .claude/baton.md ~/.claude/baton.md` prints a line |
| Heading depth | `##`; `#` and `###` do not match |
| Entries complete | every operation the section owns is present |
| Placeholders spelled | `<id>` not `<issue>`; an unrecognised placeholder is passed through literally |
| Body arrives as a file | each operation taking `<path>` reads the file rather than a string, or sends `<body>` when it is a `tool:` entry |
| Runs standalone | paste the command with real values into a shell; it must succeed there first. A literal - `none`, `repo-tests`, `closes`, `refs`, `review-wait` - is not a command and is exempt. So is `verify` whatever its value: its sequence may rewrite files, and `baton:setup` Step 4 never runs it |
| Tool entries called | call each `tool:` entry of a read operation with real values, since it has no shell form to paste; never call one `baton:setup` Step 4 forbids running |
| Agent entries dispatchable | each `agent:` entry names an agent type this session offers, and every `## Launcher` entry that names `allowed_tools` at all names both `Agent` and `Task` |

A backend is done when every row passes.

## Tools an unattended run needs

A cloud session can have the `mcp__github__*` tools and no `gh`, which is why the shipped
defaults run through those tools. A cloud run whose `## Launcher` entry's `allowed_tools`
held only `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep` and `Skill` loaded `ToolSearch`
and the GitHub MCP tools it needed, and called them with no permission denial.

`implement-handoff` adds the subagent dispatch tool to that need: Step 4's claim audit
dispatches a subagent whose context did not write the code, and an `agent:` entry in
`code-review` dispatches one too. Harness builds differ on that tool's name - `Agent` in some,
`Task` in others - so a `## Launcher` entry that names `allowed_tools` at all names both and
lets a build ignore the name it does not carry. An entry written before baton 0.1.7 names
neither - add them, or its runs stop at Step 2, which looks for the tool before the build
rather than leaving Step 4 to discard one. A personal `~/.claude/baton.md` restating
`## Launcher` carries its own `allowed_tools` and needs the same edit by hand: it lives
outside every repo, so no update to this plugin reaches it.

`implement-handoff` adds `EnterWorktree` and `ExitWorktree` to that need: Step 2 creates the
run's worktree and Step 7 removes it. A `## Launcher` entry that names `allowed_tools` at all
names those two, and an entry written before baton 0.1.3 does not - add them to it, or its
runs stop on a tool they cannot call, at Step 2 or at Step 7. An entry that starts the
session in a worktree already, `claude --worktree` among them, names both as well: Step 2
skips `EnterWorktree` there, which refuses a second worktree, and Step 7 calls
`ExitWorktree`, which removes the worktree the launcher created.

A `cloud` entry adds whatever tool it itself is written with - `RemoteTrigger` on the shipped
one, added in baton 0.1.10. `implement-handoff` Step 7 runs the entry the finishing handoff's
`next` names, so a cloud run launching a cloud layer executes those same lines from inside
the run, and the tool that creates the routine has to be on the list the routine grants. The
shipped entry is self-consistent; an entry copied into `.claude/baton.md` or
`~/.claude/baton.md` before 0.1.10 is not, and the layer above never starts.

A `local` entry needs nothing beyond `Bash`, but it starts a session on the machine the
launching run is on, and that is the constraint a stack's `next` has to be written around.
Launched from a developer's own checkout it is the cheaper route; launched by
`implement-handoff` Step 7 from inside a cloud run it puts the layer above in a container
that is reclaimed when that run ends, and the launch reports success either way because the
command returns before the session does. So a stack whose layers run in the cloud names
`cloud` in every `next` line, `local` only where every run is on one long-lived machine, and
the two are not mixed down a stack.

The review round runs on either route. Where `review-list` and `pr-comments` are `tool:`
entries its wait is a background `sleep 60` and the operations run between sleeps; where
they are single shell commands the wait is a `Bash` loop that polls inside the shell.
Either form needs no tool beyond `Bash`, which every entry allows; adding `Monitor` to the
list lets the shell form use that instead.
