ctrlScriptEnv() {
  local ENV_SETTINGS="BASE_DIR='${BASE_DIR}' _CATALYST_ENV_LOGS='${_CATALYST_ENV_LOGS}' SERV_IFACE='${SERV_IFACE}' PROCESS_NAME='${PROCESS_NAME}' SERV_LOG='${SERV_LOG}' SERV_ERR='${SERV_ERR}' PID_FILE='${PID_FILE}'"
  local REQ_PARAM
  for REQ_PARAM in $(getRequiredParameters "$SERVICE_KEY"); do
    ENV_SETTINGS="$ENV_SETTINGS $REQ_PARAM='${!REQ_PARAM}'"
  done

  echo "$ENV_SETTINGS"
}

testServMatch() {
  local KEY="$1"; shift
  if [[ -z "${1:-}" ]]; then
    # if there's nothing to match, then everything matches
    return 0
  fi
  local CANDIDATE
  for CANDIDATE in "$@"; do
    # Match on the interface class only; trim the script name.
    if [[ "$KEY" == `echo $CANDIDATE | sed -Ee 's/\..+//'` ]]; then
      return 0
    fi
  done
  return 1
}

testScriptMatch() {
  local KEY="$1"; shift
  if [[ -z "${1:-}" ]]; then
    # if there's nothing to match, then everything matches
    return 0
  fi
  local CANDIDATE
  for CANDIDATE in "$@"; do
    # If script bound and match or not script bound
    if [[ "$CANDIDATE" != *"."* ]] || [[ "$KEY" == `echo $CANDIDATE | sed -Ee 's/^[^.]+\.//'` ]]; then
      return 0
    fi
  done
  return 1
}

runtime-services() {
  if [[ "${1:-}" == "-s" ]]; then
    shift
    runtime-services-start "$@"
  elif [[ "${1:-}" == "-S" ]]; then
    shift
    runtime-services-stop "$@"
  elif [[ "${1:-}" == "-r" ]]; then
    shift
    runtime-services-restart "$@"
  else
    runtime-services-list "$@"
  fi
}

runtimeServiceRunner() {
  # TODO: currently, we check for matches before running, but we don't give any feedback on bad specs that don't match anything
  source "${CURR_ENV_FILE}"
  declare -a ENV_SERVICES
  if [[ -z "${REVERSE_ORDER:-}" ]]; then
    ENV_SERVICES=("${CURR_ENV_SERVICES[@]}")
  else
    local I=$(( ${#CURR_ENV_SERVICES[@]} - 1 ))
    while (( $I >= 0 )); do
      ENV_SERVICES+=("${CURR_ENV_SERVICES[$I]}")
      (( $I-- ))
    done
  fi
  for SERVICE_KEY in ${ENV_SERVICES[@]}; do
    local SERV_IFACE=`echo "$SERVICE_KEY" | cut -d: -f1`
    if testServMatch "$SERV_IFACE" "$@"; then
      local SERV_PACKAGE_NAME=`echo "$SERVICE_KEY" | cut -d: -f2`
      local SERV_NAME=`echo "$SERVICE_KEY" | cut -d: -f3`
      local SERV_PACKAGE=`npm explore "$SERV_PACKAGE_NAME" -- cat package.json`
      local SERV_SCRIPT
      local SERV_SCRIPTS=`echo "$SERV_PACKAGE" | jq --raw-output ".\"$CAT_PROVIDES_SERVICE\" | .[] | select(.name == \"$SERV_NAME\") | .\"ctrl-scripts\" | @sh" | tr -d "'"`
      local SERV_SCRIPT_ARRAY=( $SERV_SCRIPTS )
      local SERV_SCRIPT_COUNT=${#SERV_SCRIPT_ARRAY[@]}
      for SERV_SCRIPT in $SERV_SCRIPTS; do
        local SCRIPT_NAME=$(npx --no-install $SERV_SCRIPT name)
        local PROCESS_NAME="${SERV_IFACE}"
        if testScriptMatch "$SCRIPT_NAME" "$@"; then
          if (( $SERV_SCRIPT_COUNT > 1 )); then
            PROCESS_NAME="${SERV_IFACE}.${SCRIPT_NAME}"
          fi
          local SERV_OUT_BASE="${_CATALYST_ENV_LOGS}/${SERV_IFACE}.${SCRIPT_NAME}"
          local SERV_LOG="${SERV_OUT_BASE}.log"
          local SERV_ERR="${SERV_OUT_BASE}.err"
          local PID_FILE="${SERV_OUT_BASE}.pid"
          eval "$MAIN"
        fi
      done
    fi
  done
}

runtime-services-list() {
  local MAIN=$(cat <<'EOF'
    echo "$PROCESS_NAME ($(eval "$(ctrlScriptEnv) npx --no-install $SERV_SCRIPT status"))"
EOF
)
  runtimeServiceRunner "$@"
}

runtime-services-start() {
  # TODO: check status before starting
  local MAIN=$(cat <<'EOF'
    # rm -f "${SERV_LOG}" "${SERV_ERR}"

    echo "Starting ${PROCESS_NAME}..."
    eval "$(ctrlScriptEnv) npx --no-install $SERV_SCRIPT start"
    sleep 1
    if [[ -f "${SERV_ERR}" ]] && [[ `wc -l "${SERV_ERR}" | awk '{print $1}'` -gt 0 ]]; then
      cat "${SERV_ERR}"
      echoerr "Possible errors while starting ${PROCESS_NAME}. See error log above."
    fi
    runtime-services-list "${PROCESS_NAME}"
EOF
)
  runtimeServiceRunner "$@"
}

runtime-services-stop() {
  # TODO: check status before stopping
  local MAIN=$(cat <<'EOF'
    echo "Stopping ${PROCESS_NAME}..."
    eval "$(ctrlScriptEnv) npx --no-install $SERV_SCRIPT stop"
    sleep 1
    runtime-services-list "${PROCESS_NAME}"
EOF
)
  local REVERSE_ORDER=true
  runtimeServiceRunner "$@"
}

runtime-services-restart() {
  local MAIN=$(cat <<'EOF'
    echo "Restarting ${PROCESS_NAME}..."
    eval "$(ctrlScriptEnv) npx --no-install $SERV_SCRIPT restart"
    sleep 1
    runtime-services-list "${PROCESS_NAME}"
EOF
)
  runtimeServiceRunner "$@"
}
