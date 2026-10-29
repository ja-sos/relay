# Defining a backend

Every tracker and forge call the skills make is a named **operation**. The skills ship
GitHub defaults, so a GitHub repo needs no configuration; `backend-github.md`'s route check
picks the GitHub MCP tools or `gh`. Overriding an operation points the skills at a different
tracker without editing any skill.

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

A backend an
unattended run must use goes in `.claude/baton.md`.

## Sections

| Section | Supplies |
|---|---|
| `## Tracker` | reading, creating, commenting on and closing issues |
| `## Categories` | the condition-to-label table `file-issue` picks from |
| `## Forge` | checkout verification, pull requests, stack registration, closing keywords, the issues a pull request names |
| `## Review` | collecting review feedback on a pull request, and answering it |
| `## Launcher` | how an implementation run, and the review of its pull request, are started |
| `## Workflow` | the steps the skills run around the work: posting and finding handoffs, reviewing, publishing |
| `## Repositories` | local paths of the repositories one change spans. Optional |
| `## Assets` | the local root of the one folder outside every repository that a handoff's `assets` line names paths under. Optional |

Every `## Launcher` entry launches one of two skills, and takes two placeholders: `<skill>`,
`implement-handoff` or `review-handoff`, and `<args>`, what that skill is started with - the
handoff locator for `implement-handoff`, and the locator and the pull request URL,
`<locator> <pr-url>`, for `review-handoff`. Every entry sends `/baton:<skill> <args>` and
appends `launcher=<its own name>`, so the run knows which entry started it. A run reads the
handoff and nothing the starting session holds, so an entry that passes context instead of
those arguments starts a session with no work to do. Passing context *beside* them fails the
other way: the prompt arrives as a user turn, so a suggestion copied into it outranks the
handoff section it was copied from.

Entries also run unasked inside unattended runs (`implement-handoff` Step 6, `review-handoff`
Step 6), so each must be runnable there - see **Tools an unattended run needs**. An entry's
notes say what a session needs to launch through it, and how to check that without launching;
the skills run that check at Step 1.

`## Repositories` is optional, as `## Workflow` is. It maps
each repository a change spans to an absolute local path:

| Repository | Path |
|---|---|
| `owner/contracts` | `/home/you/src/contracts` |
| `owner/service` | `/home/you/src/service` |

Skills resolve a repository other than the checkout through `## Repositories`; each says what
a missing row does. The checkout's own repository needs no row. The
section belongs in `~/.claude/baton.md` rather than the committed `.claude/baton.md`. The
shipped `cloud` launcher clones and never reads it (`backend-github.md`).

`## Assets` is optional as well. It holds a single entry, the
absolute path of the one folder outside every repository that a handoff may name files in:

- **root:** `/home/you/baton-assets`

A handoff lists what it needs on its `assets` header line, as paths relative to that root.
The entry is a value the skills read, as `closes`, `refs` and `review-wait` are, rather than a
command they run: skills resolve each listed path under `root`, which must be an absolute path
to a directory that exists.

Listed paths follow `write-handoff` Step 2's validity rule. That rule is read off the path's
text, so it bounds what a handoff may *write*, not where the filesystem ends up: a symlink
under `root` resolves wherever it points, for `test -e` and for the read alike. The folder is
therefore trusted as far as its contents are - it is one folder on one machine, filled by the
person who configured it.

The section belongs in `~/.claude/baton.md` rather than the
committed `.claude/baton.md`. A backend with no
`## Assets` resolves nothing and runs no check for a handoff carrying no `assets` line.

The `cloud` launcher cannot resolve the section. A handoff carrying `assets` belongs to `local`, or to a launcher of the
project's own that starts the run on the machine whose `~/.claude/baton.md` defines the root.

Runs treat the folder as read-only (`handoff-assets.md`, `## May not do`).

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
| `none` | skip the step. Valid for `started`, `stack-link`, `request-reviewer`, `wrap-up`, `close-fixed`, `close-invalid`, `closes`, `refs`, `pr-issues` and `list-categories` only - any other operation set to `none` is undefined |
| `repo-tests` | run the repo's full test command, as the run finds it. Valid for `verify` only - anywhere else it is a shell command, and no such binary exists |

`none` and undefined are not the same answer. `none` says the project has decided the step
does not run - that no tracker transition marks the start of implementation, that the forge
tracks no stack to register a layer in, that no external reviewer is requested, that no step runs
when a person-attended flow ends, that this project closes issues outside baton, that a pull
request's body carries no `closes` or no `refs` line, that the project's pull requests name no
issue baton can find, that the tracker carries no labels to check categories against;
undefined says the backend is incomplete, and every skill treats it as a stop - except an
undefined `wrap-up`, which the attended skills read as `none`.

`close-fixed` and `close-invalid` each take `none` on their own. Under `none`
the project closes that kind of issue by its own means - tracker automation, or a person who
owns resolutions. Each caller says what it does under `none`. An undefined close operation
is still a stop: the `wrap-up` exception above covers that operation alone.

`closes` and `refs` each take `none` on their own. Under `none` baton
writes no reference line for that kind of issue, and the project links pull requests to it
itself. What merging does to the issue is that linking's to decide, not the handoff's `closes`
value. An undefined `closes` or `refs` is still a stop.

`repo-tests` is a literal the skills recognise rather than a command they run. It is `verify`'s shipped value, and a project that
mandates a sequence of its own - a formatter pass, then a test-and-lint target - writes that
sequence here instead. A sequence that rewrites files does so before any of its checks. In a repo with no test
command it passes with nothing run, and the handoff's own commands are the only thing checking
the change.

`none` is not among `verify`'s values.

Inside a `tool:` entry's JSON, `<body>` is the text of the file at
`<path>`, JSON-escaped: an operation
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
the locator. `code-review` takes it as well.

Five placeholders are open to every entry, derived or taken from the handoff in play rather
than passed by the caller. What an entry *addresses* decides where its `<owner>` and `<repo>`
come from, not which section holds it:

| Placeholder | Value |
|---|---|
| `<owner>` `<repo>` on an entry addressing the **issue** - every `## Tracker` entry, the `## Workflow` entries resolving through one, and `closes` / `refs` | the **issue's** repository: the locator's, where a handoff is in play; for an issue `pr-issues` returned, the repository it returned with it; and `verify-checkout`'s answer split at the slash otherwise |
| `<owner>` `<repo>` on an entry addressing the **pull request or the checkout** - `## Forge` and `## Review` apart from `closes` / `refs`, and `request-reviewer` | the **checkout's** repository: `verify-checkout`'s answer, split at the slash |
| `<owner>` `<repo>` on a `## Launcher` entry | the **handoff's** `repo` line, split at the slash: the entry starts a run for that repository, in a session that is not in it yet |
| `<head-owner>` | the owner in `origin`'s URL, printed by the command below |
| `<branch>` | `git branch --show-current` |
| `<default-branch>` | `git symbolic-ref --short refs/remotes/origin/HEAD`, without its `origin/`; where that exits non-zero, the name after `refs/heads/` in the `ref:` line of `git ls-remote --symref origin HEAD` |

```
git remote get-url origin | sed -E 's#\.git$##; s#.*[/:]([^/:]+)/[^/]+$#\1#'
```

`<head-owner>` differs from `<owner>` in a fork clone: `verify-checkout` answers with the
upstream repository, and the branch is pushed to `origin`.

`closes` and `refs` sit in `## Forge` and follow the tracker's rule all the same.

| Operation | Substitutes |
|---|---|
| `list-categories` | `<category>` |
| `list-open` | - |
| `list-mine` | - |
| `create` | `<title>` `<category>` `<path>` |
| `view` | `<id>` |
| `close-fixed` / `close-invalid` | `<id>` |
| `comment` | `<id>` `<path>` |
| `fetch-handoff` | `<owner>` `<repo>` `<id>` `<comment-id>` `<locator>` |
| `reachable` | - |
| `verify-checkout` | - |
| `pr-create` | `<title>` `<path>` `<category>` `<pr-base>` |
| `stack-link` | `<id>` `<pr-url>` `<pr-base>` |
| `pr-view` | `<id>` |
| `pr-issues` | `<id>` |
| `pr-update` | `<id>` `<path>` |
| `review-list` | `<owner>` `<repo>` `<id>` |
| `review-post` | `<owner>` `<repo>` `<id>` `<path>` |
| `review-bodies` | `<owner>` `<repo>` `<id>` |
| `pr-comments` | `<owner>` `<repo>` `<id>` |
| `review-threads` | `<owner>` `<repo>` `<id>` |
| `thread-reply` | `<owner>` `<repo>` `<id>` `<comment-id>` `<path>` |
| `pr-comment` | `<id>` `<path>` |
| `closes` / `refs` | `<owner>` `<repo>` `<id>` |
| `post-handoff` | `<id>` `<path>` |
| `has-handoff` | `<id>` |
| `started` | `<id>` |
| `verify` | - |
| `code-review` | `<target>` `<locator>` |
| `request-reviewer` | `<id>` |
| `review-wait` | - |
| `published` | `<id>` `<path>` `<pr-url>` |
| `reviewed` | `<id>` `<path>` `<pr-url>` |
| `stopped` | `<id>` `<path>` |
| `wrap-up` | `<skill>` `<id>` `<pr-url>` `<head-branch>` |

`pr-create` takes two values beyond the title and the body, both from the handoff's header
and both optional there. `<category>` is the label the handoff's `category` line names, and
it is **empty** where that line is absent; each entry substituting it says in its notes what
an empty value drops, because a `tool:` entry has no conditional syntax and the caller
applies the note instead. `<pr-base>` is the handoff's `pr-base` line, or `<default-branch>`
where that line is absent - it is never empty. It does not replace the derived
`<default-branch>` above, which every other entry keeps using.

Open a draft in an overriding `pr-create`, as both shipped routes do.

`stack-link` registers a pull request as one layer of a stack, and is called only for a
handoff carrying `pr-base`. `<pr-url>` is what `pr-create` returned and `<pr-base>` the branch
below. It runs once per pull request, so `<id>` is the **primary** issue - the first entry of
the header's `issue` line.

`pr-update` replaces the pull request body whole. A caller writes the complete body and carries
every issue reference line - `closes`, `refs` - across unchanged.

`review-bodies`, `pr-comments` and `review-threads` are one set, not three alternatives: each
reads a surface the others cannot see, and defining fewer loses a surface with no error. Any
author filtering belongs inside the command.
A `tool:` entry cannot filter its output, so the backend's notes name the filter and the
caller applies it.

Every skill reading review threads stops without `review-threads`: there is no degraded mode
that reviews a branch without its threads.

The last eleven are `## Workflow`. The shipped comment-posting entries resolve through
`op: comment` (`backend-github.md`), so a backend that has overridden `## Tracker` for Jira
posts them to Jira without naming them.

Callers run `post-handoff`, `started`, `published`, `reviewed` and `stopped` once per issue
the handoff's header names, so `<id>` is always one issue and no entry - a shell command, a
`tool:` JSON body, an `op:` - needs anything added to handle a bundle. `closes` and `refs` are
read once per issue as well: the body carries a reference line for each issue whose entry is
not `none`.

Unlike every other operation, leaving `wrap-up` undefined is not a stop:
`investigate-issue`, `review-pr`, `address-review` and `self-review` treat a `wrap-up` no loaded
file defines as `none`. Add the entry the project runs when an attended flow ends to use it.

`wrap-up`'s callers pass `<skill>`, `<id>`, `<pr-url>` and `<head-branch>`, any of which may
be empty.
Quote each in a shell entry - `log-flow "<skill>" "<id>" "<pr-url>" "<head-branch>"`.

`verify` takes no placeholders.

An entry that moves a ticket
belongs in `published`, and `reviewed` says what the review did.

`stopped` also carries the no-change exit (`implement-handoff` Step 2), which is no failure.
**A `stopped` that moves a ticket's state needs to account for that**, the way `started` above
needs a transition that repeats harmlessly: an entry that sends a ticket to Blocked will send
it there on a successful run too. Where a tracker cannot express both, `op: comment` alone says
what happened and moves nothing, which is what the shipped entry does.

`has-handoff` returns the text of an issue's comments, in the order they were posted: callers
test it for the handoff marker and read what each marker sits in, so a yes/no is not enough.
`address-review` reads that order to bind the last of several matching handoffs on one issue.
Its default runs `view`; an entry that cannot return comment text is one to leave at that
default.

`pr-issues` returns the issues a pull request names, each with its `<owner>`, `<repo>` and
`<id>`, and whether the pull request delivers it or only references it. How a pull request names
its issues is the project's workflow - closing keywords in the body, a ticket key in the title,
a prefix on the branch - so the entry decides what counts, and `address-review` Step 1 reads
only its answer to find the spec it rules review rows against. Under `none` no issue is found,
and `address-review` rules on the code alone. An entry may be `op: pr-view <id>` with notes
saying how the caller reads the issues out of it, as the shipped ones are (`backend-github.md`).

`code-review` substitutes two placeholders. `<target>` is what to review - a pull request
number, a branch, or empty for the working tree. `<locator>` is the handoff the work came from,
and may be empty; an entry whose prompt checks acceptance criteria then says so rather than
inventing them. The shipped entry uses neither placeholder beyond `<target>`.

`review-wait` is a number of minutes, not a command: how long `review-handoff` Step 3 waits for
the reviewer `request-reviewer` asked for, counted from the request. The cap is 60. `review-handoff` is the only
skill that runs `request-reviewer` or reads `review-wait`.

`list-mine` returns the issues assigned to the user in the order they should be picked up;
the tracker's own ranking belongs in that command, not in the skill reading its output.

`list-categories` either returns every category the tracker offers, or answers for one
`<category>` at a time - a tracker with no call that enumerates its labels can only do the
second. The backend's notes say which, and a caller that gets the second form runs the
operation once per row of `## Categories`.

The third form is `none`, for a tracker that carries no labels at all. An entry that prints the `## Categories`
labels back is not a substitute. Only an explicit `none` takes this path - a `list-categories`
left undefined is still a stop.

Under `none`, `## Categories` stays required: `file-issue` still picks a row per finding.
`create` receives an empty `<category>`; as with `pr-create`, each `create` entry substituting
it says in its notes what an empty value drops.

`<path>` is always a file. An operation that cannot read a file
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

Turning the external reviewer on, and logging time after the pull request is published. The block
shows the three entries that change; the heading replaces the section whole, so restate the
other eight exactly as `backend-github.md` ships them:

```markdown
## Workflow

- **request-reviewer:** tool: mcp__github__request_copilot_review {"owner": "<owner>", "repo": "<repo>", "pullNumber": <id>}
- **review-wait:**      20
- **published:**
  - op: comment <id> <path>
  - tool: jira_add_worklog {"issueKey": "<id>", "comment": "Shipped <pr-url>"}
```

`published` runs two entries in order, and the comment goes first: a worklog that fails
must not swallow the only notice that the run finished.

Pairing the correctness review with a compliance reviewer. `code-review` becomes a nested
list; restate the other ten entries exactly as `backend-github.md` ships them:

````markdown
## Workflow

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
| Runs standalone | paste the command with real values into a shell; it must succeed there first. A literal - `none`, `repo-tests`, `closes`, `refs`, `review-wait`, `## Assets`'s `root` - is not a command and is exempt. So is `verify` whatever its value: its sequence may rewrite files |
| Tool entries called | call each `tool:` entry of a read operation with real values, since it has no shell form to paste; never call one `baton:setup` Step 4 forbids running |
| Launcher tools load | for each `## Launcher` entry, the check its notes give passes in the kind of session that launches through it |
| Agent entries dispatchable | each `agent:` entry names an agent type this session offers, and every `## Launcher` entry that names `allowed_tools` at all names both `Agent` and `Task` |

A backend is done when every row passes.

## Tools an unattended run needs

A cloud session can have the `mcp__github__*` tools and no `gh`. A cloud run whose `## Launcher` entry's `allowed_tools`
held only `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep` and `Skill` loaded `ToolSearch`
and the GitHub MCP tools it needed, and called them with no permission denial.

`implement-handoff` and `review-handoff` add the subagent dispatch tool to that need. Harness
builds differ on that tool's name - `Agent` in some, `Task` in others - so a `## Launcher` entry
that names `allowed_tools` at all names both and lets a build ignore the name it does not
carry. Without them, runs stop at their dispatch-tool check.

A `## Launcher` entry that names `allowed_tools` at all names `EnterWorktree` and
`ExitWorktree`, which both runs call - an entry that starts the session in a worktree already,
`claude --worktree` among them, included.

A `cloud` entry adds whatever tools it itself is written with. The shipped one runs on
`RemoteTrigger`, or on the `claude-code-remote` server's `list_triggers`, `fire_trigger` and
`create_session` where `RemoteTrigger` does not load (`backend-github.md`). **Every** cloud
`implement-handoff` run needs one of those sets, not only a stacked one, and so does a cloud
`review-handoff` run carrying `next`: both launch through this entry from inside the run
(`implement-handoff` Step 6, `review-handoff` Step 6). A cloud session does not always carry
`RemoteTrigger`, so an entry written on it alone fails there, and the run finds out at Step 1.

A `local` entry needs nothing beyond `Bash`, but it starts a session on the machine the
launching run is on, and that is the constraint a stack's `next` has to be written around.
Launched from a developer's own checkout it is the cheaper route; launched from inside a cloud
run, it puts the new session in a container that is reclaimed when that run ends, and the
launch reports success either way because the command returns before the session does. So a
stack whose layers run in the cloud names `cloud` in every `next` line, `local` only where
every run is on one long-lived machine, and the two are not mixed down a stack.

A hand-started run in a cloud session launches its reviewer through `local`, into that
container, under the constraint above.

The external reviewer's wait needs only `Bash` (`review-handoff` Step 3).
