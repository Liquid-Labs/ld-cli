#!/usr/bin/env bash

_liq2() {
  local PROJECT ORG NEXT_CONTEXT
  PROJECT=$(basename "$PWD")
  ORG=$(basename "$(dirname "$PWD")")

  NEXT_CONTEXT="$( echo "$COMP_LINE" | perl -pe "s|(.* projects) +[.](.*)?|\\1 ${ORG} ${PROJECT}\2|" )"

  COMPREPLY=( $(liq2 server next-commands -- command="${NEXT_CONTEXT}") )
}

# Use default file/dir/command/alias/etc. completions when COMPREPLY is empty
complete -o bashdefault -o default -F _liq2 liq2
