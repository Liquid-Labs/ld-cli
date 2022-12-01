#!/usr/bin/env bash

_liq2() {  
  COMPREPLY=( $(liq2 server next-commands -- command="${COMP_LINE}") )
}

complete -F _liq2 liq2
