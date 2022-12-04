#!/usr/bin/env bash

_liq2() {
  COMPREPLY=( $(liq2 server next-commands -- command="${COMP_LINE}") )
}

# Use default file/dir/command/alias/etc. completions when COMPREPLY is empty
complete -o bashdefault -o default -F _liq2 liq2
