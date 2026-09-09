#!/bin/sh
# PreToolUse on Task: carry the claim-audit discipline into every subagent dispatch.
#
# Why a hook and not skill text: subagent reviewers are where unsupported claims come from - a
# fresh agent with no context reports "confirmed" without a citation. A rule living in the
# dispatching skill's prose can be skipped like any other skill text.
#
# Where the text lands: additionalContext on PreToolUse reaches the DISPATCHING session, not
# the subagent. Probes confirm it - subagents asked to quote every instruction injected into
# them never saw it, and answered "no" when asked directly. Only updatedInput, which rewrites
# the Task tool_input, puts text inside the subagent's own context. tool_input carries four
# keys (description, prompt, subagent_type, model) and is echoed back whole, so the undocumented
# replace-vs-merge question never arises. permissionDecision is deliberately not set: it is not
# needed for delivery, and "allow" would auto-approve every dispatch for users not in auto mode.
#
# Why the interpreter probe: updatedInput needs a JSON parser to re-serialise an arbitrary
# prompt string, and no manifest can require one - plugin.json's `dependencies` field covers
# other plugins and npm packages, never system binaries.
#
# The probe is ordered, first match wins: python3, then python, then node. These are
# alternatives, not requirements - any one of them is enough, and the branches emit identical
# JSON, since all the transform needs is a language that parses and re-serialises JSON. Nothing
# here is Python-specific. python leads only because it is present on more Linux and macOS
# machines than node, so it is the branch most likely to be exercised; node is no less capable
# and is not guaranteed either, since Claude Code ships as a native binary, not a Node script.
#
# Windows ships `python`, not `python3`, and some systems still have Python 2 on that name, so
# the probe tests the interpreter's version rather than trusting the name.
#
# Fallback: with no parser, the pure-sh path emits additionalContext addressed to the
# dispatcher, asking it to carry the requirement into the prompt it writes. One indirection
# through a model that may not comply, which is why it is the fallback and not the default.
#
# Read, not Skill: some agent types carry no Skill tool in their allowed set, but every one has
# Read - so the instruction names a file path rather than assuming Skill is callable.
#
# Fail-open: every error path exits 0 and the dispatch proceeds untouched.

raw=$(cat) || exit 0
[ -n "$raw" ] || exit 0

# Skip when the dispatching skill already asked for the audit in its own prompt.
printf '%s' "$raw" | grep -qi 'claim-audit' && exit 0

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." 2>/dev/null && pwd) || exit 0
skill="$root/skills/claim-audit/SKILL.md"
[ -f "$skill" ] || exit 0

instruction="Before your final message, run the claim-audit checklist over every factual claim you are about to report: read $skill and classify each as OBSERVED, INFERRED, RECALLED or SPECIFIED, probe or retract per its Step 3, and attach the audit table to your report.

A task that produced no factual claims needs no audit - say so in one line instead.

The audit covers claims about what is. A design recommendation is not a claim: never support one with an inventory of current behaviour, and never read an absence from HEAD as an argument against building it."

# Preferred path: rewrite the Task prompt so the text reaches the subagent itself.
py=''
for c in python3 python; do
    command -v "$c" >/dev/null 2>&1 || continue
    "$c" -c 'import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)' >/dev/null 2>&1 || continue
    py=$c
    break
done

out=''
if [ -n "$py" ]; then
    out=$(printf '%s' "$raw" | "$py" -c '
import json, sys
d = json.load(sys.stdin)
ti = dict(d.get("tool_input") or {})
p = ti.get("prompt")
if not isinstance(p, str):
    sys.exit(1)
ti["prompt"] = p + "\n\n" + sys.argv[1]
json.dump({"hookSpecificOutput": {"hookEventName": "PreToolUse", "updatedInput": ti}}, sys.stdout)
' "$instruction" 2>/dev/null) || out=''
elif command -v node >/dev/null 2>&1; then
    out=$(printf '%s' "$raw" | node -e '
let s = "";
process.stdin.on("data", c => s += c).on("end", () => {
  try {
    const d = JSON.parse(s);
    const ti = Object.assign({}, d.tool_input || {});
    if (typeof ti.prompt !== "string") process.exit(1);
    ti.prompt = ti.prompt + "\n\n" + process.argv[1];
    process.stdout.write(JSON.stringify({hookSpecificOutput: {hookEventName: "PreToolUse", updatedInput: ti}}));
  } catch (e) { process.exit(1); }
});
' "$instruction" 2>/dev/null) || out=''
fi

if [ -n "$out" ]; then
    printf '%s\n' "$out"
    exit 0
fi

# Fallback: no parser, or the payload had no prompt to rewrite. Address the dispatcher.
esc=$(printf '%s' "$skill" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"This instruction reaches you, the dispatching session, not the subagent. Append the following to the prompt you are sending, so the subagent receives it:\\n\\nBefore your final message, run the claim-audit checklist over every factual claim you are about to report: read %s and classify each as OBSERVED, INFERRED, RECALLED or SPECIFIED, probe or retract per its Step 3, and attach the audit table to your report. A task that produced no factual claims needs no audit - say so in one line instead. The audit covers claims about what is; a design recommendation is not a claim."}}\n' "$esc"
exit 0
