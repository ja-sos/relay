# Reference documents

Five skills load this file before ruling on what the code should do: `investigate-issue`,
`address-review`, `self-review`, `review-pr` and `file-issue`. It reads the specification
documents the backend's `## References` section routes an issue to. The section's columns, and
how a Document resolves to a file, are `defining-backends.md`'s, under `## Sections`.

Each caller supplies two things: the **issue set** the documents are read for, and what a stop
here ends. Everything else is this file's.

## No section, no match

**A backend with no `## References` section leaves this file with nothing to do.** The caller
goes on with the steps it runs without it, and nothing that follows in the caller depends on a
document.

Where the section exists and no row matches the issue set, say so in one line to the user,
naming each issue's repository, labels and components, and go on the same way.

## Selecting rows

A row matches where its Repository equals an issue's repository, ignoring case, and its Match is
`*` or equals, ignoring case, one of that issue's labels or components as `view` prints them for
that issue. Run the row selection once per issue in the set, in that issue's own repository, and
read the union of what matches: a document two issues select is read once.

**Where the caller has no issue** - a finding not yet filed, a pull request naming none, a branch
with no pull request - the issue set is one issue-less entry: its repository is
`verify-checkout`'s answer and its label set is empty, so only `*` rows for that repository match.

Resolve each matching row's Document to a file as `defining-backends.md` says - a pattern
Document through its `find ... | sort -V | tail -1` command. Read every document a matching row
names, and no document of a row that does not match.

## Reading a document

Read each document by its extension:

- `.md` or `.txt`: the file itself.
- Any other extension: convert it with `pandoc -t gfm "<file>" -o "<scratch dir>/<file name>.md"`,
  outside every checkout, and read the file it writes. Where `command -v pandoc` fails, that is a
  stop, below, naming the document; never skip it.

List that file's headings with `grep -n '^#' "<file>"` first, then read the sections that bear on
what the caller is ruling on, not the whole document. Where it lists no headings, read the file
whole.

## Stops

**A matching row whose file does not exist, whose pattern selects nothing, or whose read is denied
or fails is a stop**, naming the row as the section writes it. So is a missing `pandoc`. Report it
to the user rather than ruling without the specification. The caller says what the stop ends -
its `wrap-up` included, where it runs one.

## Citing what was read

Keep each document's file name - the last segment of the resolved path, which for a pattern row
carries the version it selected - and the sections read.

Any text that leaves the session - a handoff, an issue body, a review comment, a reply - names a document by its file name, the heading of the section the
clause sits under, and the clause quoted. Never by its path.
