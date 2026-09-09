# Defining a document type

A **contract** binds one document type: it fills three of the five Step 2 brief lines, and
gives Step 2 its must-include and must-not-include lists. Write one when a type recurs often
enough that deriving it each time yields different sections. For a one-off document, use the
Step 2 derive path instead.

## Where contracts live

Step 1 reads three files, in this order:

```
${CLAUDE_PLUGIN_ROOT}/skills/write-deliverables/reference/doc-types.md   shipped defaults
.claude/doc-types.md     project types; committed, so an unattended run sees it
~/.claude/doc-types.md   personal types across all projects
```

A `##` heading is the key. A heading matching one already loaded replaces it wholesale; a
new heading is added. The personal file therefore overrides the project file.

A cloud or CI session clones the repo and never sees your home directory. A contract that
an unattended run must honor goes in `.claude/doc-types.md`.

## Format

Sections are separated by `---`.

```markdown
## <Type name>

- **READER:** who opens this, and in what situation.
- **GOAL:** what they must decide, do, or be able to do after reading.
- **ALREADY HAS:** the sources they can read themselves.

**Must include**
- <a claim the document fails without>

**Must not include**
- <content that sits in ALREADY HAS, or that answers no reader question>
```

`<Type name>` is matched against the document type named at Step 1. Call it what you would
call the document out loud.

## What each field feeds

| Field | Consumed by |
|---|---|
| `READER` | Step 2 brief; gate G8 front-loading |
| `GOAL` | Step 2 brief; gate G10 missing non-obvious |
| `ALREADY HAS` | Step 2 brief; gate G2 derivable |
| `Must include` / `Must not include` | Step 1; gate G7 structure |

All three fields and both lists are required. Omit `ALREADY HAS` and G2 has no source to
test a sentence against - an omission that is never reported, so the check passes vacuously
and the document ships unchecked.

`COST` and `ONLY YOU` are absent by design: both vary per document rather than per type, so
Step 2 writes them every time.

## Example

```markdown
## Release notes

- **READER:** an existing user deciding whether to upgrade now.
- **GOAL:** know what changed that affects them, and what the upgrade costs.
- **ALREADY HAS:** the changelog, the commit log, the version number.

**Must include**
- Breaking changes, and the migration each one requires.
- Behavior that changed without an API change.
- Known regressions shipped in this release.

**Must not include**
- Every merged PR - that is the changelog.
- Internal refactors with no user-visible effect.
```

## Checks

| Check | Test |
|---|---|
| Heading loads | `grep -n '^## <Type name>' .claude/doc-types.md ~/.claude/doc-types.md` prints a line |
| Heading depth | `##`; `#` and `###` do not match |
| Fields present | all of `READER`, `GOAL`, `ALREADY HAS` |
| Lists present | both `**Must include**` and `**Must not include**` |
| `ALREADY HAS` is enumerable | names specific sources; `the codebase` leaves G2 untestable |

The contract is done when every row passes.
