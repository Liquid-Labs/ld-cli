#!/usr/bin/env bash

_liq() {
  local PROJECT ORG NEXT_CONTEXT
  PROJECT=$(basename "$PWD")
  ORG=$(basename "$(dirname "$PWD")")

  COMPREPLY=( $(liq server next-commands -- command="${COMP_LINE}") )
  if [[ ${COMP_LINE} =~ '^ *liq *$' ]]; then
    COMPREPLY+=( 'setup' 'update' )
  fi
}

# Use default file/dir/command/alias/etc. completions when COMPREPLY is empty
complete -o bashdefault -o default -F _liq liq
