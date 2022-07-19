liq-dispatch() {
  if (( $# == 0 )); then
    echoerrandexit "No arguments provided. Try:\nliq help"
  fi
  
  liq-try-core "${@}" && return

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

# credit: https://gist.github.com/cdown/1163649
urlencode() {
    # urlencode <string>

    old_lc_collate=${LC_COLLATE:-}
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}

liq-try-core() {
  # we read through command tokens, treating everything before '--' as part of the endpoint and everything after as a
  # parameter
  local ENDPOINT PARAMETERS
  while (( $# > 0 )); do
    if [[ -n "${PARAMETERS}" ]]; then
      PARAMETERS="${PARAMETERS} ${1}"
    elif [[ ${1} == '--' ]]; then
      PARAMETERS="${2:-}"
      shift
    else
      ENDPOINT="${ENDPOINT}/$(urlencode "$1")"
    fi
    shift
  done
  
  if [[ "${ENDPOINT}" == *'/./'* ]]; then
    requirePackage
    local ORG PKG
    ORG=${PACKAGE_NAME#@}
    ORG=${ORG%/*}
    PKG=${PACKAGE_NAME#*/}
    ENDPOINT="${ENDPOINT/./"${ORG}/${PKG}"}"
  fi
  
  if ! [[ -f ${LIQ_CORE_API} ]]; then return 1; fi
  
  local i ENDPOINT_COUNT
  ENDPOINT_COUNT=$(jq '. | length' "${LIQ_CORE_API}")
  i=0
  # First, we test against known endpoints (as published in ~/.liq/core-api.json)
  while (( ${i} < ${ENDPOINT_COUNT} )); do
    local MATCHER METHOD HEADERS
    MATCHER="$(jq -r ".[${i}].matcher" "${LIQ_CORE_API}")"
    MATCHER="${MATCHER//\\/}" # remove unecessary escaping
    MATCHER="${MATCHER//\?:/}" # remove unsupported non-capture groups
    MATCHER="${MATCHER//\?)/)}" # TODO: is this is alternate/optional syntax for non-capture groups? or what? See if it can be removed
    MATCHER="${MATCHER//\?<*>/}" # remove unsupported named capture groups
    if [[ ${ENDPOINT} =~ ${MATCHER} ]]; then
      # If we get a match, then we extract the method used
      METHOD="$(jq -r ".[${i}].method" "${LIQ_CORE_API}")"
      local PARAM QUERY PARAM_FLAG
      if [[ "${PARAMETERS}" =~ =@ ]]; then
        PARAM_FLAG="-F"
      else
        PARAM_FLAG="-d"
      fi
      local REQUIRE_OUTPUT=0
      local OUTPUT
      for PARAM in ${PARAMETERS}; do
        if [[ ${PARAM} == format=* ]]; then
          local FORMAT="${PARAM#*=}"
          # 'format' is controlled with the accept header
          case "${FORMAT}" in
            md|markdown)
              FORMAT='text/markdown';;
            csv)
              FORMAT='text/csv';;
            tsv)
              FORMAT='text/tab-separated-values';;
            pdf)
              FORMAT='application/pdf'
              REQUIRE_OUTPUT=1;;
            docx)
              FORMAT='application/vnd.openxmlformats-officedocument.wordprocessingml.document'
              REQUIRE_OUTPUT=1;;
            *) # */?json <- JSON is our default
              FORMAT='application/json';;
          esac
          HEADERS="-H \"Accept: ${FORMAT}\""
        elif [[ ${PARAM} =~ =@ ]]; then
          local FILE="${PARAM#*=@}"
          if ! [[ -f "${FILE}" ]]; then
            echo "Could not find local file '${FILE}' specified in parameter '${PARAM%%=@*}'; bailing out." >&2
            exit 4
          fi
        elif [[ "${PARAM}" == output* ]]; then
          if [[ "${PARAM}" == output=* ]]; then
            OUTPUT="--output ${PARAM#*=}"
            PARAM=''
          elif [[ "${PARAM}" == "output" ]]; then
            OUTPUT="--remote-name --remote-header-name"
            PARAM=''
          fi # else, the parameter is something like 'outputPath' and we just pass it thru
        elif [[ "${PARAM}" != *=* ]]; then # it's a bare 'boolean' flag, but we need to give it a value
          PARAM="${PARAM}=true"
        fi
        
        if [[ -n "${PARAM}" ]]; then
          QUERY="${QUERY} ${PARAM_FLAG} ${PARAM}"
        fi
      done # end parameter processing
      # TODO: derive this kind of thing from the core API spec; for now we just handle as a one-off
      if (( ${REQUIRE_OUTPUT} == 1 )) && [[ -z "${OUTPUT}" ]] && [[ "${QUERY}" != *' outputPath='* ]]; then
        # then we use the 'Content-disposition'
        OUTPUT='--remote-name --remote-header-name'
      fi
      if [[ -n "${QUERY}" ]] && [[ "${METHOD}" != 'POST' ]]; then
        QUERY="-G ${QUERY}"
      fi
      # TODO: unless we eval, the headers gets incorrectly parsed; I know this happens sometimes, but I'm not sure why;
      # e.g.:
      # curl -X GET -H "Accept: text/markdown" http://127.0.0.1:3260/
      # is parsed such that it thinks 'text' is the host... We've tried different quotations and escaping spaces. So far
      # nothing works.
      eval curl --max-time 20 -X ${METHOD} ${HEADERS} ${OUTPUT} http://127.0.0.1:32600${ENDPOINT} ${QUERY}
      # curl -X ${METHOD} ${HEADERS} http://127.0.0.1:32600${ENDPOINT} ${QUERY}
      return 0 # bash for 'success'
    fi
    i=$(( ${i} + 1 ))
  done
  # no matches found
  return 1
}
