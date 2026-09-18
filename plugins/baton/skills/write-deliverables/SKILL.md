---
name: write-deliverables
description: Use when writing or revising any text another person or a future session will read - README, repo docs, PR descriptions and comments, commit messages, reports, analyses, handoff/context notes, ADRs, runbooks, issue bodies, prompt/agent docs - or a draft of one. Sets the reader, the shape, and the admission test every sentence must pass before the document counts as done.
---

# Write deliverables

**Scope is the audience, not the location.** A draft pasted into the conversation for approval
is still text for its reader and takes these passes in full; showing it to the user first does
not make it a chat message. The one exemption is your conversational reply to the user - the
answer to their question, not an artifact they will forward, keep, or act on later.

**A skill that mandates a template outranks this one.** Where another skill fixes the section
list - `baton:file-issue`'s category headings, `baton:write-handoff`'s handoff header, a
repo's PR template - it owns which sections exist, and this skill applies only *inside* them.
Never put a mandated heading through Step 3 and never drop one as redundant: an empty mandated
section is a signal to its reader, not padding.

Content works the same way as sections. Where a skill requires something by name in a document
it mandates, that skill owns whether it is present, and no contract's must-not-include - shipped
or overridden - removes it. The contract still owns the reader it is written for and the order,
emphasis and wording it gets.

**Being asked for this skill authorizes reworking text already approved.** A direction here -
by slash command, by a workflow step, by an instruction naming the text - is permission to
change wording the user has already seen. The exception is your own mid-turn discovery that the
skill never ran: say so in one line and let the user decide, rather than reworking first.

**One run per document.** Having run this skill earlier in the session buys nothing for the
next one. Re-read these steps rather than recalling them - a half-remembered checklist is the
failure this skill exists to prevent.

## Step 1 - Contract

Load the contracts, later files overriding earlier by `##` heading:

```
cat ${CLAUDE_PLUGIN_ROOT}/skills/write-deliverables/reference/doc-types.md
cat .claude/doc-types.md 2>/dev/null
cat ~/.claude/doc-types.md 2>/dev/null
```

A listed type fills the first three lines of the Step 2 brief, and its must-include and
must-not-include lists are binding. An unlisted type leaves all five lines to Step 2, which
derives the sections there as well.

Adding a type: `reference/defining-doc-types.md`.

## Step 2 - Name the reader and what they already have

Before any prose, write these five lines in your working notes, not in the document. Every
deletion below follows from them. A contract supplies `READER`, `GOAL` and `ALREADY HAS`;
`ONLY YOU` and `COST` are yours to write either way.

```
READER:      who opens this, and in what situation
GOAL:        what they must decide, do, or be able to do after reading
ALREADY HAS: sources they can read themselves - the diff, the code, the ticket, the
             dashboard, the linked doc, common knowledge in this domain
ONLY YOU:    what they cannot get from ALREADY HAS - why something is shaped this way,
             a constraint that must keep holding, a decision and the option rejected,
             something they must check that their own materials do not show
COST:        what goes wrong if they misread it or it omits something
```

- PASS: you can state in one line what the reader lacks.
- FAIL: "context" or "background" is the answer - those are not facts. Redo.
- Never write for "everyone". If READER is unknown, name the likeliest one and state that
  assumption in your reply to the user, not in the document.

With no contract for this type, derive its shape here: write the 3-6 questions READER will
ask, in the order they ask them. Those questions are your sections. A section answering no
reader question does not exist.

## Step 3 - Outline verdict, before a word is written

List the headings you intend to write. Give each one line: **KEEP**, naming the ONLY YOU fact
it will carry, or **CUT**. A section you cannot justify here is one you never open.

This pass prevents; Step 5 only cleans up, and a section is far harder to delete once it
exists and reads well.

**No headings is not an exemption.** A one-sentence reply takes this pass too - with nothing
to list, the verdict is on the whole text.

## Step 4 - Draft, in the file

Draft in the file itself - the gate runs on real text, not on intent.

- Answer first: the opening paragraph answers the reader's first question.
- Current state, not history: what *is*, not what it *was* or how it got there. Prior state
  earns a place in three cases only - the reader still holds the old thing, the old shape
  still exists somewhere they must change, or the contrast *is* the decision being recorded.
- One claim per sentence. Concrete nouns, numbers, names, paths - not adjectives.
- Link an authoritative source instead of summarizing it.
- Say the non-obvious thing plainly. Traps, constraints, manual steps, deliberate omissions
  and risks are the parts only you can supply.

### Delete on sight

- **Narration of the diff** - a bullet per changed file, before/after pairs where the after
  is obvious.
- **Narration of your process** - "searched X, then read Y, then found Z".
- **Restating the prompt, ticket or task** back to whoever set it.
- **A Background or Context paragraph** re-telling something already linked.
- **Section scaffolding on a single concern** - Summary / Changes / Motivation / Testing /
  Notes / Risks as a default skeleton.
- **A heading whose body only restates the heading**, or kept for symmetry with nothing under it.
- **A summary of a document short enough to read**, and a closing paragraph restating the opening.
- **Value claims** - "more maintainable", "robust", "cleaner", "properly". Unfalsifiable, and
  no reader acts on them.
- **Predicted impact you cannot observe** - "this will improve performance".
- **Test enumeration the diff already shows.**
- **Human-time or effort estimates** - hours, days, story points, "quick win", "major
  refactor". Size work in files, call sites and decisions instead.
- **Emoji, checkmark tables, severity badges.**
- **Hedging stacks** - "it may be worth possibly considering" is "consider".
- **In a reply:** restating the comment before answering it, agreement preamble, and three
  sentences explaining a one-line fix.

## Step 5 - The gate

Re-read the file from disk - not from memory of what you meant to write. Check every row
against the actual text and record PASS or FAIL.

**On any FAIL: fix it, then restart the gate at G1.** Fixes introduce new violations - that is
why it restarts. Done means one full clean pass.

| # | Check | Test |
|---|-------|------|
| G1 | **Process leakage** | Sentences whose subject is you, the work, or the change: `I`, `we`, `initially`, `originally`, `then`, `after that`, `tried`, `decided to`, `ended up`, `was changed`, `used to`, `previously`, `turns out`. FAIL unless GOAL is history. Imperative steps the *reader* performs are exempt. |
| G2 | **Derivable** | Per sentence: could READER get this from ALREADY HAS in under a minute? FAIL - cut, or replace with a pointer. |
| G3 | **Wrong reader** | Name the Step 2 reader again, on this sentence. A sentence addressed to you, your session, or whoever set the task is FAIL however accurate - correct content aimed at the wrong person is not wordy, so no other row catches it. |
| G4 | **Padding** | Run the grep below. Any hit outside a quoted example is FAIL - delete it or name the concrete thing it stands in for. |
| G5 | **Vacuous** | A sentence that would be equally true of a different project, PR, or report. FAIL - delete. |
| G6 | **Redundancy** | A claim stated twice keeps only the instance nearest where READER needs it. A trailing Summary or Conclusion adding no new claim is FAIL. |
| G7 | **Structure** | Every heading maps to a Step 2 reader question, or is mandated by the skill that owns the template. A section holding one sentence merges into its parent. |
| G8 | **Front-loading** | If READER must read past the opening paragraph to learn what this is and what it means for them: FAIL, rewrite it. |
| G9 | **Length** | The document is as short as its claims allow. A passage you could delete without losing a claim READER needs for GOAL is FAIL - delete it. |
| G10 | **Missing non-obvious** | Anything READER cannot derive but needs for GOAL - a trap, constraint, manual step, known gap, risk - must be present. Absent is FAIL. The one check that fails for writing too little. |
| G11 | **Cited** | Every sentence stating something **is** the case has evidence you could paste: the command and the line of its output, or `file:line`. Uncitable is FAIL - **delete it**, never soften it to "appears to". Hedging keeps a claim you cannot support and spends a word doing it. |

G4 grep:

```
grep -noiE "\b(it'?s (important|worth) (to note|noting)|please note|as mentioned|in order to|this (document|section)|comprehensive|robust|seamless|leverage|utilize|powerful|simply|just|very|really|essentially|basically|a variety of|delve)\b" FILE
```

### G11: produce the citation, do not assess your confidence

A fact you read and a fact you generated arrive feeling identical, so "did I verify this?"
cannot be answered from the inside. Ask what you would paste.

**The connective sentence is where this bites.** Two real observations, and the sentence
bridging them states a mechanism neither one showed. The conclusion stays right while the
stated reason is invented - the shape that survives every other row here, because a
specific-looking detail reads as evidence. Cite the bridge itself, or state what you observed
and stop.

Audit by shape, not by feel. Run `baton:claim-audit` over every one of these whether or not
it feels solid - it classes each claim observed, inferred or recalled, and retracts what
recall cannot support:

- a causal claim - "because", "due to", "which is why", "so that"
- a scope claim - "no other callers", "only", "always", "nothing else"
- a version, identifier, path, flag or config string
- a behavioural claim about code you did not run

### Keeping flagged text

One way out, written explicitly:

```
KEEP "<quoted text>" - serves <the READER, GOAL, ONLY YOU or COST line it serves>
```

If you cannot name the line it serves, cut it. More than two KEEP lines means the draft is
aimed at the wrong audience - return to Step 2.

### The gate is not advisory

- Pass/fail only. "Close enough", "mostly fine" and "reads well" are FAIL.
- Do not rule that a check does not apply here. If the trigger appears, it fires.
- Length never suspends the gate. A long document runs it too.
- A CUT is deleted, never shortened - a shortened section leaves the skeleton behind.
- Never report a document finished while any check is FAIL.

Report the result in one line: `gate: clean on pass 3`. Not a checklist dump.
