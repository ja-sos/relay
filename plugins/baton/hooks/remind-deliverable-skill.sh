#!/bin/sh
# UserPromptSubmit: when the prompt asks for text someone else will read, inject one line
# naming the skill - before the turn starts, which is the only point at which the skill can
# still run first.
#
# No JSON envelope: UserPromptSubmit is one of the four events where Claude Code adds
# plain-text stdout as context Claude can see, so echo is the whole output interface.
#
# It reminds; it cannot deny. Nothing gates the model's own message text, so this is the
# whole of the enforcement for a draft written into a chat reply rather than into a file.
#
# Matching still runs against the raw payload rather than a named field: the field is `prompt`
# in the command-hook payload but documented as `user_prompt` for prompt-type hooks, and
# matching raw removes the dependency on which is right. What the two filters below remove is
# text that carries no user intent in the first place, so the trigger set stays exactly as
# sensitive as it reads - over-firing on a real prompt is intended, and is preserved.
#
# Fail-open: every path exits 0, which keeps a failure silent. Stderr from a hook that exits 0
# reaches the debug log only, while any non-zero exit would print a hook error notice on every
# single prompt.

raw=$(cat) || exit 0
[ -n "$raw" ] || exit 0

# Filter 1 - synthetic prompts. Background task notifications and system reminders arrive
# through the same field a typed prompt does, carrying returned subagent output that trips the
# trigger set on text the user never wrote.
case $raw in
    *'<task-notification>'*|*'SYSTEM NOTIFICATION - NOT USER INPUT'*|*'<local-command-stdout>'*)
        exit 0 ;;
esac

# Filter 2 - path-bearing fields. cwd, transcript_path and scratchpad_dir are always present
# and never hold a request: a repository checked out at drafts/ would otherwise fire the
# reminder on every prompt in it.
text=$(printf '%s' "$raw" | sed \
    -e 's/"transcript_path"[[:space:]]*:[[:space:]]*"[^"]*"//g' \
    -e 's/"cwd"[[:space:]]*:[[:space:]]*"[^"]*"//g' \
    -e 's/"scratchpad_dir"[[:space:]]*:[[:space:]]*"[^"]*"//g' \
    -e 's/"session_id"[[:space:]]*:[[:space:]]*"[^"]*"//g' \
    -e 's/"prompt_id"[[:space:]]*:[[:space:]]*"[^"]*"//g') || exit 0

# Code artefacts, excluded from the "write a <noun>" branch only. Every other trigger fires
# independently, so "write a script and draft the PR body" still reminds via "draft".
code='scripts?|tests?|quer(y|ies)|functions?|methods?|class(es)?|migrations?|regexe?s?'
code="$code"'|wrappers?|helpers?|mocks?|stubs?|fixtures?|parsers?|validators?|loops?'
code="$code"'|commands?|hooks?|gates?|assertions?'

# Over-firing costs one injected line; under-firing costs the pass.
asks='re-?draft|draft|rewrite|rewor[dk]|write (it|the|this|up)|write-?up'
asks="$asks"'|update the (skill|memory|issue|description|pr|handoff|page)'
asks="$asks"'|remember (this|that)|save (this|that) to memory|reply to|comment on'
asks="$asks"'|pr (body|description)|handoff doc|write up the'

remind=0
if printf '%s' "$text" | grep -qiE "$asks"; then
    remind=1
elif printf '%s' "$text" | grep -qiE 'write an? '; then
    printf '%s' "$text" | grep -qiE "write an? ($code)" || remind=1
fi

[ "$remind" -eq 1 ] || exit 0

echo 'This prompt asks for text someone else will read. Invoke the baton:write-deliverables skill before writing it, not after.'
exit 0
