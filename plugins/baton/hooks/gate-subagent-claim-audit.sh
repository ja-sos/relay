#!/bin/sh
# SubagentStart: carry the claim-audit discipline into every subagent. hooks.json registers it
# with no matcher, since a SubagentStart matcher filters agent type names (general-purpose,
# Explore, Plan, fork, <plugin>:<agent>), not tool names - so every agent type gets it.
#
# Why a hook and not skill text: subagent reviewers are where unsupported claims come from - a
# fresh agent with no context reports "confirmed" without a citation. A rule living in the
# dispatching skill's prose can be skipped like any other skill text.
#
# Why SubagentStart and not a pre-call hook on the dispatch tool: there, additionalContext
# reaches the DISPATCHING session, not the subagent, and the one output that does reach the
# subagent - a rewrite of the dispatch's input, appending to its prompt - is refused by auto
# mode on Claude Code 2.1.317, because a hook changed the call's input after the classifier
# reviewed it (#59).
# SubagentStart's additionalContext is added to the subagent's own context at the start of its
# conversation, and the dispatch's input reaches the classifier unchanged.
#
# No stand-down: SubagentStart input carries agent_id and agent_type but no prompt, so there is
# nothing to test for a dispatcher that already asked for the audit. That dispatch gets the
# instruction twice; the duplication is accepted.
#
# No interpreter: the output is a fixed string plus one path, which sed escapes for JSON.
#
# Read, not Skill: some agent types carry no Skill tool in their allowed set, but every one has
# Read - so the instruction names a file path rather than assuming Skill is callable.
#
# Fail-open: every error path exits 0 with no output, and the subagent starts untouched.

cat >/dev/null 2>&1

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." 2>/dev/null && pwd) || exit 0
skill="$root/skills/claim-audit/SKILL.md"
[ -f "$skill" ] || exit 0
# The sed below escapes only backslash and quote; a control character would break the JSON.
case $skill in *[[:cntrl:]]*) exit 0 ;; esac

esc=$(printf '%s' "$skill" | sed 's/\\/\\\\/g; s/"/\\"/g') || exit 0

printf '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"Before your final message, run the claim-audit checklist over every factual claim you are about to report: read %s and classify each as OBSERVED, INFERRED, RECALLED or SPECIFIED, probe or retract per its Step 3, and attach the audit table to your report.\\n\\nA task that produced no factual claims needs no audit - say so in one line instead.\\n\\nThe audit covers claims about what is. A design recommendation is not a claim: never support one with an inventory of current behaviour, and never read an absence from HEAD as an argument against building it."}}\n' "$esc" || exit 0
exit 0
