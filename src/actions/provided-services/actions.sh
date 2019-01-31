requirements-provided-services() {
  requireCatalystfile
  requirePackage
}

provided-services-add() {
  # TODO: check for global to allow programatic use
  local SERVICE_NAME="${1:-}"
  if [[ -z "$SERVICE_NAME" ]]; then
    requireAnswer "Service name: " SERVICE_NAME
  fi

  local SERVICE_DEF=$(cat <<EOF
{
  "name": "${SERVICE_NAME}",
  "interface-classes": [],
  "platform-types": [],
  "purposes": [],
  "ctrl-scripts": [],
  "params-req": [],
  "params-opt": []
}
EOF
)

  function selectOptions() {
    local OPTIONS
    local OPTION
    local OPTIONS_NAME="$1"; shift
    PS3="$1"; shift
    local OPTS_ONLY="$1"; shift

    if [[ -n "$OPTS_ONLY" ]]; then
      selectDoneCancel OPTIONS "$@"
    else
      selectDoneCancelAnyOther OPTIONS "$@"
    fi
    for OPTION in $OPTIONS; do
      SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"$OPTIONS_NAME\": (.\"$OPTIONS_NAME\" + [\"$OPTION\"]) }"`
    done
  }

  selectOptions 'interface-classes' 'Interface class: ' '' $STD_IFACE_CLASSES
  selectOptions 'platform-types' 'Platform type: ' '' $STD_PLATFORM_TYPES
  selectOptions 'purposes' 'Purpose: ' '' $STD_PURPOSES
  selectOptions 'ctrl-scripts' "Control script: " true `find "${BASE_DIR}/bin/" -type f -not -name '*~' -prune -execdir echo '{}' \;`

  echo "Enter required parameters. Enter blank line when done."
  local PARAM_NAME
  while [[ $PARAM_NAME != '...quit...' ]]; do
    read -p "Required parameter: " PARAM_NAME
    if [[ -z "$PARAM_NAME" ]]; then
      PARAM_NAME='...quit...'
    else
      SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"params-req\": (.\"params-req\" + [\"$PARAM_NAME\"]) }"`
    fi
  done

  PARAM_NAME=''
  echo "Enter optional parameters. Enter blank line when done."
  while [[ $PARAM_NAME != '...quit...' ]]; do
    read -p "Optional parameter: " PARAM_NAME
    if [[ -z "$PARAM_NAME" ]]; then
      PARAM_NAME='...quit...'
    else
      SERVICE_DEF=`echo "$SERVICE_DEF" | jq ". + { \"params-opt\": (.\"params-opt\" + [\"$PARAM_NAME\"]) }"`
    fi
  done

  PACKAGE=`echo "$PACKAGE" | jq ". + { \"$CAT_PROVIDES_SERVICE\": (.\"$CAT_PROVIDES_SERVICE\" + [$SERVICE_DEF]) }"`
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}

provided-services-delete() {
  if (( $# == 0 )); then
    echoerrandexit "Must specify service names to delete."
  fi

  local SERV_NAME
  for SERV_NAME in "$@"; do
    if echo "$PACKAGE" | jq -e "(.\"$CAT_PROVIDES_SERVICE\" | map(select(.name == \"$SERV_NAME\")) | length) == 0" > /dev/null; then
      echoerr "Did not find service '$SERV_NAME' to delete."
    fi
    PACKAGE=`echo "$PACKAGE" | jq "setpath([\"$CAT_PROVIDES_SERVICE\"]; .\"$CAT_PROVIDES_SERVICE\" | map(select(.name != \"$SERV_NAME\")))"`
  done
  echo "$PACKAGE" | jq > "$PACKAGE_FILE"
}
