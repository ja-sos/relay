#!/bin/sh
# Checks the claim-audit hook (#59): SubagentStart registration, its output, its fail-open path,
# no interpreter, no leftover PreToolUse wording, and the 0.3.3 release. Runs from any directory:
#   sh tests/gate-subagent-claim-audit.test.sh
# Needs python3 to parse JSON; the hook itself does not.

cd "$(dirname -- "$0")/.." || exit 1

fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1"; echo "  want: $3"; echo "  got:  $2"; fail=1; fi; }

hooks=plugins/baton/hooks
script=$hooks/gate-subagent-claim-audit.sh

# 1. hooks.json registers UserPromptSubmit and SubagentStart only; SubagentStart has no matcher.
got=$(python3 -c 'import json,sys; h=json.load(open(sys.argv[1]))["hooks"]; e=h.get("SubagentStart", []); print(sorted(h), [("matcher" in x) for x in e], e[0]["hooks"][0]["command"] if e else "")' "$hooks/hooks.json")
check "registration" "$got" "['SubagentStart', 'UserPromptSubmit'] [False] sh \"\${CLAUDE_PLUGIN_ROOT}/hooks/gate-subagent-claim-audit.sh\""

# 2. One JSON object, SubagentStart, additionalContext naming the skill's absolute path; exit 0.
root=$(pwd)
out=$(printf '{"agent_id":"a1","agent_type":"general-purpose"}' | sh "$script"); rc=$?
check "exit code" "$rc" 0
got=$(printf '%s' "$out" | python3 -c 'import json,sys; o=json.load(sys.stdin)["hookSpecificOutput"]; print(o["hookEventName"], "claim-audit checklist" in o["additionalContext"], sys.argv[1] in o["additionalContext"])' "$root/plugins/baton/skills/claim-audit/SKILL.md" 2>&1)
check "output" "$got" "SubagentStart True True"
check "one line" "$(printf '%s' "$out" | grep -c '')" 1

# 3. With SKILL.md absent beside the hooks directory: no output, exit 0.
d=$(mktemp -d)
mkdir "$d/hooks"
cp "$script" "$d/hooks/"
got=$(printf '{}' | sh "$d/hooks/gate-subagent-claim-audit.sh"; echo "exit=$?")
rm -r "$d"
check "missing skill" "$got" "exit=0"

# 4. No python, python3 or node in the script.
check "no interpreter" "$(grep -cE 'python|node' "$script")" 0

# 5. No PreToolUse/updatedInput outside CHANGELOG.md; no stand-down sentence.
check "no PreToolUse wording" "$(grep -rlE 'PreToolUse|updatedInput' --exclude=CHANGELOG.md plugins/baton)" ""
check "no stand-down" "$(grep -c 'stands down' plugins/baton/skills/implement-handoff/SKILL.md)" 0

# 6. Version 0.3.3 in both manifests; CHANGELOG opens with ## 0.3.3.
check "plugin.json" "$(python3 -c 'import json; print(json.load(open("plugins/baton/.claude-plugin/plugin.json"))["version"])')" 0.3.3
check "marketplace.json" "$(python3 -c 'import json; print([p["version"] for p in json.load(open(".claude-plugin/marketplace.json"))["plugins"] if p["name"]=="baton"][0])')" 0.3.3
check "changelog" "$(sed -n '/^## /{p;q}' plugins/baton/CHANGELOG.md)" "## 0.3.3"

exit $fail
