# Reviewing run output

The rules a review follows when the branch under it was written by an unattended
`baton:implement-handoff` run, and the severity and disposition scales that run and its
reviewer share. `baton:self-review` loads this file for a person-attended review;
`baton:review-handoff` loads it for the unattended review that run launches;
`baton:implement-handoff` loads it for "Severity" and "Dispositions" alone. Each skill says at
which of its steps each section below applies, and none changes what a section says.

## Whose code this is

The branch was written by an unattended `baton:implement-handoff` run, which committed under the
user's git identity. Every ownership check therefore says the code is theirs. That is a routing
signal - findings become fixes in the working tree rather than comments on a pull request - and
says nothing about who wrote the code or what its claims are worth.

**Every artifact that run produced carries no evidentiary weight.** Each is an unverified
assertion by an agent whose reasoning cannot be inspected, and none of them resolves, downgrades
or pre-empts a finding. Only the diff and the code around it are evidence:

- the pull request body - what was tested, why an approach was chosen, which edge cases are covered;
- replies in review threads, and a thread marked resolved: an agent said it was handled, not that
  it was;
- commit messages;
- comments and `TODO`s the diff added, which are claims to check against the code rather than
  statements of intent that explain it away;
- the handoff it implemented, and any deviation it recorded there;
- a green test run it left behind: the assertions that exist passed, not that they assert the
  right thing.

The user authored nothing on this branch. What a person says in the session is authoritative;
what is written on the branch is not. Name the writer as the `baton:implement-handoff` run -
never "the author", never a pronoun, never "your change" or "you decided" about this branch.
Carry this rule into every subagent prompt the review spawns, not only the first.

## Collecting the review threads

With the pull request settled, run `review-threads` on it and keep every thread it returns.
No resolved-state filter and no author filter. `address-review` Step 3 takes a resolved
thread as context rather than a row; that rule does not hold here, where a thread marked
resolved records an agent's claim and nothing more. An author filter cannot help either:
the run commits under the user's git identity and replies through the credentials
`reachable` resolves to, so its replies and the user's are indistinguishable by author.

Write down three facts per thread:

- the finding - the thread's first comment;
- what the code at the reviewed head does now at that thread's path;
- what the latest reply claimed, or `no reply`.

The thread comment's numeric id is not among them: neither skill loading this file names a
`thread-reply`, and nothing a review here does writes back to a thread.

Where there is no pull request, or it carries no threads, this collects nothing and the review
covers the diff alone.

## Checking the threads

The collected threads stay out of the `code-review` call: `code-review` takes `<target>` and
`<locator>` and nothing else, so no thread reaches it. Once it returns, check each thread
yourself against its three facts, by its latest reply:

- A reply claiming a fix: check the claim against the diff. Where the diff contains the fix,
  the thread is fixed as claimed.
- A reply rejecting the finding: check the reasoning against the code. Where the reasoning
  holds, the rejection holds.
- Any other reply - an acknowledgement, a deferral, a question, a reviewer's pushback - or
  no reply: rule on the finding's merits.

A fix claim the diff does not contain, or reasoning the code contradicts, discards the reply
and nothing more: rule on the finding's merits. A ruling on the merits is settled by what
the code at the reviewed head does, and ends in stands or the finding does not hold.

Every check ends in one of four dispositions - stands, fixed as claimed, the rejection holds,
or the finding does not hold - each with the evidence that settled it, so every collected
thread gets one whether it was resolved or answered or neither. A thread whose finding stands
is a finding like any `code-review` returns, and is fixed the same way.

## Severity

Classify every finding against this table before deciding anything about it. `code-review`
resolves to whatever engine the project named, on whatever scale that engine uses, so a
severity the engine attaches is evidence about the finding and not the answer: map it onto a
row here, and where it maps onto none, class the finding from what it says.

| Severity | The finding says |
|---|---|
| Critical | The change is wrong or unsafe as written - a defect this diff introduces, a security hole, data loss, or a contradiction of an acceptance criterion the handoff set. |
| Important | The change works, and a reviewer would still send it back - a case it fails to handle, a statement in code or docs it leaves false, a missing test for behaviour the handoff names. |
| Minor | Everything else - style, naming, a cleanup in code this diff did not touch. |

Severity is about the finding, not about how hard it is to fix. A Critical finding the run
cannot fix stays Critical and is reported as one.

## Dispositions

Every finding ends with one disposition:

| Disposition | The finding | Carries |
|---|---|---|
| applied | is fixed on the branch the run commits to | nothing further |
| rejected | does not hold, or contradicts a decision the handoff recorded | which of the two, and why |
| deferred | holds, and its fix is outside the handoff's scope or costs more than it is worth | what it waits on, or why it was left |
| unresolved | needs an answer nobody here could give | what blocks the call |

The three reasons a finding cannot be fixed map onto these: outside the handoff's scope is
deferred, contradicts a decision the handoff recorded is rejected, needs an answer nobody here
can give is unresolved. The two judgements a round makes on its own take the remaining shapes -
a finding read and found not to hold is rejected, a Minor one the loop chose to leave is
deferred - so neither reaches the reader as silence. Every disposition but applied carries its
reason, and every finding carries its severity: an unresolved Critical and a Minor left alone
are different news. A finding a round applied and a later round reopened takes the disposition
it ends on.

## Red flags - you are deferring to an agent

- "The description says this was covered", "the author chose X for a reason", "presumably
  intentional".
- Calling the branch's writer "the author", or giving them a pronoun.
- "Your change", "your code", "you decided" about this branch.
- A finding dropped or downgraded on the strength of a reply, a resolved thread, a commit message
  or a code comment.
- A collected thread missing from the dispositions because it was resolved or already answered.
- A subagent prompt sent without the provenance rule.
- A passing suite read as evidence the behaviour is right.

Each means: substantiate it against the diff, or say you cannot.
