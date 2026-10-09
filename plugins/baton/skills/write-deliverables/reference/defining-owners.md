# Defining an owner map

An **owner map** names, for a kind of fact, the one file that states it. `SKILL.md` Step 4
searches that file before a document states such a fact, and gate row G12 fails a document
that restates it. Write one when the same fact keeps reappearing in PR bodies, reports and
docs, and drifts from the file that defines it.

## Where maps live

Put project rows in `.claude/owners.md`, committed so an unattended run sees them, and
personal rows in `~/.claude/owners.md`. `SKILL.md` Step 1 loads the project map first and
the personal map second.

No map ships with the plugin. With neither file present, Step 4's search and G12 have nothing
to act on, and a document passes exactly as it would without this file.

## Format

One two-column Markdown table per file, headed `Fact` and `Owner`:

```markdown
| Fact | Owner |
|---|---|
| <kind of fact, as a writer would name it> | <repo-relative path>[, <section, step or symbol>] |
```

`Fact` names a kind of fact, not one sentence: `version number`, `backend operation
semantics`, `release steps`. `Owner` names a file relative to the repository root, and
optionally the section, step or symbol inside it that states the fact. The path runs to the
first comma.

## Combining

Drop inactive rows first. A row whose `Owner` file does not exist in the current repository
is inactive there: it replaces no project row, Step 4 searches nothing for it, and G12 does
not fire on it. A personal map loads in every repository, so most of its rows are inactive in
most of them.

The remaining rows combine across the two files. A personal row whose `Fact` cell matches a
project row's `Fact` cell exactly - case counts, the cell's surrounding spaces do not -
replaces that row; every other personal row is added. A personal map therefore adds rows
without restating the project's, and overrides only the rows it names.

## Example

```markdown
| Fact | Owner |
|---|---|
| document type contract format | plugins/baton/skills/write-deliverables/reference/defining-doc-types.md, `## Format` |
| backend operation semantics | plugins/baton/reference/defining-backends.md, `## Operations` |
| pull request draft policy | plugins/baton/skills/implement-handoff/SKILL.md, Step 5 |
```

## Checks

| Check | Test |
|---|---|
| File loads | `cat .claude/owners.md ~/.claude/owners.md 2>/dev/null` prints the table |
| Header | the table's header row names `Fact`, then `Owner` |
| Owner exists | in `.claude/owners.md`, `test -e <path>` succeeds from the repository root for every `Owner` path |
| Owner names a place | `Owner` adds a section, step or symbol wherever the file states more than one kind of fact; a line number is not one, since it drifts |
| Override is exact | a personal row meant to replace a project row repeats its `Fact` cell exactly |

The map is done when every row passes.
