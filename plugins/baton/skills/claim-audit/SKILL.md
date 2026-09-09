---
name: claim-audit
description: Use when the user invokes it on a response, or before stating how any mechanism behaves that was not probed in this session - hook and matcher semantics, glob and permission rules, config loading, API fields, tool internals, library behaviour. The highest-risk moment is the incidental claim: a "this will now work" at the end of a task, a side assertion inside a larger answer, an explanation of why something happened.
---

# Claim audit

Every factual claim gets a class and a verdict, recorded in a table. No table, no audit.
Confidence is not a class, and a fluent causal story is not evidence.

## Step 1 - Extract

Quote each factual claim from the target response verbatim - statements that something **is**
the case. Skip recommendations and opinions.

**A design question is not a claim.** What the system should do once a change ships has no
truth value at HEAD. Do not route it through this checklist, and never answer it with an
inventory of current behaviour.

- PASS: every claim quoted.
- FAIL: paraphrased or summarised. Redo.

## Step 2 - Classify

| Class | PASS test |
|---|---|
| OBSERVED | You can cite the evidence from THIS session: the command and its output, or the `file:line` you read. |
| INFERRED | One step from an OBSERVED base, and you can state observation, inference, and what would falsify it. |
| RECALLED | Everything else - training knowledge, docs from memory, another session, "how these systems usually work". |
| SPECIFIED | The target state, stated by the user in this session or by the issue, handoff or spec - quote it. Governs what *should be*, and carries nothing about what *is*. |

A claim is **not** OBSERVED when:

- it extrapolates runtime behaviour from schema or documentation text you read - the text is
  OBSERVED, the behaviour is INFERRED at best;
- its evidence is absence: "nothing appeared in my context" observes your context, not the system;
- it "matches the existing entries" - existing style is evidence of style, not of working;
- its support is a causal story, however fluent. A mechanism narrative with no citation is RECALLED.

## Step 3 - Sentence

| Class | Anything rests on it? | Verdict |
|---|---|---|
| OBSERVED | - | ACCEPTED, with its citation |
| INFERRED | no | ACCEPTED, inference stated visibly |
| INFERRED | yes | probe, then ACCEPTED or CORRECTED |
| RECALLED | yes | probe, then ACCEPTED or CORRECTED; unprobeable gets LABELLED "unverified" visibly in the response |
| RECALLED | no | RETRACTED - not worth probing means not worth asserting |
| SPECIFIED | - | ACCEPTED for target state, with the quote; never cited as evidence about current behaviour |

A probe is the cheapest command that could falsify the claim, usually one command or one file
read: send a crafted input through the real path, `git check-ignore` for glob semantics, a
harmless `--help` against the actual binary, read the manifest instead of trusting the spec.

## Step 4 - Report

Emit the table `Claim | Class | Evidence or probe | Verdict`, then apply every CORRECTED and
RETRACTED before the user acts on the response.

- PASS: table present, every claim sentenced, corrections applied.
- FAIL: any claim without a row.

## Red flags - you are mid-failure

- About to write "this will now work", or "X will trigger / load / match", for something you
  never ran.
- You have an explanation but no citation.
- The claim is a side remark and probing it feels disproportionate.
- "It matches the existing entries", or "it works like <similar system>".
- About to answer "should we build X?" with a count of what the code references today.

## Rationalizations

| Excuse | Reality |
|---|---|
| "It's incidental, not worth a probe" | Incidental claims are where the failures live. Probe it or retract it. |
| "The schema or docs imply it" | Text is evidence of text. Behaviour is probed, not implied. |
| "I'm confident" | Not a class. Observed, inferred or recalled - pick one. |
| "I verified something similar" | Name the difference, or probe this case. |
| "The user is waiting" | The probe is one command. A wrong claim costs a session. |
| "Nothing references it today" | True of every feature before it ships. A fact about HEAD, not an argument about the target. |
