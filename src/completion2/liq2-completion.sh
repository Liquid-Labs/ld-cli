#!/usr/bin/env bash

_liq2() {
  local COMPLETED_COMMAND
  local i=0
  while (( ${i} < ${COMP_CWORD} )); do
    if (( ${i} == 0 )); then
      COMPLETED_COMMAND="${COMP_WORDS[0]}"
    else
      COMPLETED_COMMAND="${COMPLETED_COMMAND} ${COMP_WORDS[${i}]}"
    fi
    i=$(( ${i} + 1 ))
  done
  
  local CURR_COMMAND="${COMP_WORDS[COMP_CWORD]}"
  local OPTS
  OPTS=$(liq2 server next-commands -- command="${COMPLETED_COMMAND}")
  
  COMPREPLY=( $(compgen -W "${OPTS}" -- ${CURR_COMMAND}) )
}

complete -F _liq2 liq2
