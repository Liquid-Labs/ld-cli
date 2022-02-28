liq-dispatch() {
  if (( $# == 0 )); then
    echoerrandexit "No arguments provided. Try:\nliq help"
  fi
  
  liq-try-core "${*}" && return

  local GROUP ACTION
  # support for trailing 'help'
  local LAST_ARG="${@: -1}"
  if [[ "${LAST_ARG}" == 'help' ]] || [[ "${LAST_ARG}" == '?' ]]; then
    GROUP='help'
    set -- "${@:1:$(($#-1))}" # 'pops' the last arg
  else
    GROUP="${1:-}"; shift # or global command
  fi

  case "$GROUP" in
    # global actions
    help|?)
      help "$@";;
    # components and actionsprojct
    *)
      if (( $# == 0 )); then
        help $GROUP
        echoerrandexit "\nNo action argument provided. See valid actions above."
  		elif [[ $(type -t "requirements-${GROUP}" || echo '') != 'function' ]]; then
  			exitUnknownHelpTopic "$GROUP"
      fi
      ACTION="${1:-}"; shift
      if [[ $(type -t "${GROUP}-${ACTION}" || echo '') == 'function' ]]; then
        # the only exception to requiring a playground configuration is the
        # 'playground init' command
        if [[ "$GROUP" != 'meta' ]] || [[ "$ACTION" != 'init' ]]; then
          # source is not like other commands (?) and the attempt to replace possible source error with friendlier
          # message fails. The 'or' never gets evaluated, even when source fails.
          source "${LIQ_SETTINGS}" \ #2> /dev/null \
            # || echoerrandexit "Could not source global Catalyst settings. Try:\nliq meta init"
        fi
        requirements-${GROUP}
        ${GROUP}-${ACTION} "$@"
      else
        exitUnknownHelpTopic "$ACTION" "$GROUP"
      fi;;
  esac
}

liq-try-core() {
  local COMMAND="${1:-}"
  local ENDPOINT="/${COMMAND// //}"
  
  if ! [[ -f ${LIQ_CORE_API} ]]; then return 1; fi
  
  local i ENDPOINT_COUNT
  ENDPOINT_COUNT=$(jq '. | length' "${LIQ_CORE_API}")
  i=0
  while (( ${i} < ${ENDPOINT_COUNT} )); do
    local MATCHER METHOD
    MATCHER="$(jq -r ".[${i}].matcher" "${LIQ_CORE_API}")"
    MATCHER="${MATCHER//\\/}"
    MATCHER="${MATCHER/?:/}"
    MATCHER="${MATCHER/?)/)}"
    if [[ ${ENDPOINT} =~ ${MATCHER} ]]; then
      METHOD="$(jq -r ".[${i}].method" "${LIQ_CORE_API}")"
      curl -X ${METHOD} http://127.0.0.1:32600${ENDPOINT}
      return 0 # bash for 'success'
    fi
    i=$(( ${i} + 1 ))
  done
  # no matches found
  return 1
}
