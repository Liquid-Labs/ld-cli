#!/usr/bin/env bash

_liq2() {
  local COMPLETE_BIT="${COMP_WORDS[COMP_CWORD-1]}"
  local CURR_COMMAND="${COMP_WORDS[COMP_CWORD]}"
  local OPTS
  OPTS=$(liq2 server next-commands -- command="${COMPLETE_BIT}")
  
  COMPREPLY=( $(compgen -W "${OPTS}" -- ${CURR_COMMAND}) )
}

complete -F _liq2 liq2
