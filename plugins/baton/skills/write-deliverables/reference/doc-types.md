# Document type contracts

Shipped defaults, covering the types the baton skills write. Binding for the types
listed. Add or replace types in `.claude/doc-types.md` or `~/.claude/doc-types.md`; see
`defining-doc-types.md` for the format.

---

## PR description

- **READER:** a reviewer about to read the diff, or someone finding this PR in history later.
- **GOAL:** understand why this change exists and what to scrutinize.
- **ALREADY HAS:** the full diff, file list, commit list, CI results, the linked issue.

**Must include**
- The problem or goal, in the reader's terms.
- The approach taken, only where the diff does not make it obvious.
- Anything not visible in the diff: behavior changes, migration or deploy steps,
  compatibility breaks, config or secret changes.
- What is deliberately out of scope, and known gaps.
- What the reviewer should look at hardest.

**Must not include**
- A list of changed files, or a per-file walkthrough.
- A narrative of implementation: what was tried, what was refactored, what order things
  happened in.
- Restatement of code the reviewer is about to read.
- Test output that CI already reports.

---

## Tracker issue

- **READER:** a future session picking it up cold to investigate and fix.
- **GOAL:** decide whether to take it, and locate the cause without re-deriving the finding.
- **ALREADY HAS:** the repo at the recorded commit, git history, the label.

**Must include**
- The symptom and its mechanism, with `file:line` for every code claim.
- The downstream effect, per call site.
- For a defect, the shortest reproduction; for a proposal, what is impossible today.
- Constraints any fix must hold, and alternatives satisfying them.
- The commit SHA and branch the line references resolve against.

**Must not include**
- A prescribed patch, or one approach with no alternative and no reason it is forced.
- More than one defect or cause - those are separate issues.
- A `TODO` the code already carries.
- Review narration: what was searched or noticed.

---

## Handoff / context note

- **READER:** a future agent session, or the user, cold, with no memory of this work.
- **GOAL:** resume the work without re-deriving what is already settled.
- **ALREADY HAS:** the repo, git history, and any code already committed.

**Must include**
- Current state: what works, what does not.
- Decisions already made and the constraint behind each, so they are not relitigated.
- The next concrete step.
- Traps: things that look wrong but are correct, and things that look correct but are not.

**Must not include**
- Anything recoverable from git history or the code itself.
- A diary of the session.
- Conclusions restated from a document already in the repo - link it.
