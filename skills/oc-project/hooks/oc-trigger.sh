#!/usr/bin/env bash
# Hook UserPromptSubmit : détecte un projet OpenClassrooms dans le prompt
# (« OC » en majuscules et isolé, ou « openclassroom(s) ») et demande d'invoquer
# le skill oc-project. N'écrit rien sinon. Ne bloque jamais (sortie 0).
set -u

prompt="$(jq -r '.prompt // ""' 2>/dev/null || true)"

detecte=0
# « OC » isolé, sensible à la casse ; « / » exclu à gauche pour ignorer les URL.
if [[ "$prompt" =~ (^|[^[:alnum:]_/])OC([^[:alnum:]_]|$) ]]; then
  detecte=1
elif printf '%s' "$prompt" | grep -qiE 'openclassrooms?'; then
  detecte=1
fi

if [ "$detecte" -eq 1 ]; then
  jq -n '{hookSpecificOutput: {hookEventName: "UserPromptSubmit",
    additionalContext: "Projet OpenClassrooms détecté : invoque le skill oc-project (il reprend le projet là où il en est)."}}'
fi
exit 0
