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
  
  local ENDPOINT="${COMMAND%%--*}" # strip everything from '--'
  ENDPOINT="/${ENDPOINT// //}"
  local PARAMETERS="${COMMAND#*--}" # keep everything after '--'
  
  if ! [[ -f ${LIQ_CORE_API} ]]; then return 1; fi
  
  local i ENDPOINT_COUNT
  ENDPOINT_COUNT=$(jq '. | length' "${LIQ_CORE_API}")
  i=0
  # First, we test against known endpoints (as published in ~/.liq/core-api.json)
  while (( ${i} < ${ENDPOINT_COUNT} )); do
    local MATCHER METHOD HEADERS
    MATCHER="$(jq -r ".[${i}].matcher" "${LIQ_CORE_API}")"
    MATCHER="${MATCHER//\\/}"
    MATCHER="${MATCHER//\?:/}"
    MATCHER="${MATCHER//\?)/)}"
    if [[ ${ENDPOINT} =~ ${MATCHER} ]]; then
      # If we get a match, then we extract the method used
      METHOD="$(jq -r ".[${i}].method" "${LIQ_CORE_API}")"
      local PARAM QUERY PARAM_FLAG
      if [[ "${PARAMETERS}" =~ =@ ]]; then
        PARAM_FLAG="-F"
      else
        PARAM_FLAG="-d"
      fi
      for PARAM in ${PARAMETERS}; do
        if [[ ${PARAM} == format=* ]]; then
          local FORMAT="${PARAM#*=}"
          # 'format' is controlled with the accept header
          case "${FORMAT}" in
            md|markdown)
              FORMAT='text/markdown';;
            */?json|*)
              FORMAT='application/json';;
          esac
          HEADERS="-H \"Accept: ${FORMAT}\""
        else
          if [[ ${PARAM} =~ =@ ]]; then
            local FILE="${PARAM#*=@}"
            if ! [[ -f "${FILE}" ]]; then
              echo "Could not find file '${FILE}' specified in parameter '${PARAM%%=@*}'; bailing out." >&2
              exit 4
            fi
          fi
          QUERY="${QUERY} ${PARAM_FLAG} ${PARAM}"
        fi
      done
      if [[ -n "${QUERY}" ]] && [[ "${METHOD}" != 'POST' ]]; then
        QUERY="-G ${QUERY}"
      fi
      # TODO: unless we eval, the headers gets incorrectly parsed; I know this happens sometimes, but I'm not sure why;
      # e.g.:
      # curl -X GET -H "Accept: text/markdown" http://127.0.0.1:3260/
      # is parsed such that it thinks 'text' is the host... We've tried different quotations and escaping spaces. So far
      # nothing works.
      eval curl -X ${METHOD} ${HEADERS} http://127.0.0.1:32600${ENDPOINT} ${QUERY}
      # curl -X ${METHOD} ${HEADERS} http://127.0.0.1:32600${ENDPOINT} ${QUERY}
      return 0 # bash for 'success'
    fi
    i=$(( ${i} + 1 ))
  done
  # no matches found
  return 1
}
