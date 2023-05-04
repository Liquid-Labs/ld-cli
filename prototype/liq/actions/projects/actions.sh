requirements-projects() {
  :
}

# see: liq help projects build
projects-build() {
  findBase
  cd "$BASE_DIR"
  projectsRunPackageScript build
}

# see: liq help projects close
projects-close() {
  eval "$(setSimpleOptions FORCE -- "$@")"

  # check that we can access GitHub
  check-git-access

  local PROJECT_NAME="${1:-}"

  # first figure out what to close
  if [[ -z "$PROJECT_NAME" ]]; then # try removing the project we're in
    findBase
    cd "$BASE_DIR"
    PROJECT_NAME=$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name | @sh' | tr -d "'")
  fi
  PROJECT_NAME="${PROJECT_NAME/@/}"

  deleteLocal() {
    cd "${LIQ_PLAYGROUND}" \
      && rm -rf "$PROJECT_NAME" && echo "Removed local work directory for project '@${PROJECT_NAME}'."
    # now check to see if we have an empty "org" dir
    local ORG_NAME
    ORG_NAME=$(dirname "${PROJECT_NAME}")
    if [[ "$ORG_NAME" != "." ]] && (( 0 == $(ls "$ORG_NAME" | wc -l) )); then
      rmdir "$ORG_NAME"
    fi
  }

  cd "$LIQ_PLAYGROUND"
  if [[ -d "$PROJECT_NAME" ]]; then
    if [[ "$FORCE" == true ]]; then
      deleteLocal
      return
    fi

    cd "$PROJECT_NAME"
    # Are remotes setup as expected?
    if ! git remote | grep -q '^upstream$'; then
      echoerrandexit "Did not find expected 'upstream' remote. Try:\n\ncd '$LIQ_PLAYGROUND'\n\nThen manually verify everything has been saved and pushed to the canonical remote. Then you can force local deletion with:\n\nliq projects close --force '${PROJECT_NAME}' #use-with-extreme-caution"
    fi
    requireCleanRepo --check-all-branches "$PROJECT_NAME" # exits if not clean + branches saved to remotes
    deleteLocal # didn't exit? OK to delete
  else
    echoerrandexit "Did not find project '$PROJECT_NAME'" 1
  fi
  # TODO: need to check whether the project is linked to other projects
}

# see: liq help projects deploy
projects-deploy() {
  if [[ -z "${GOPATH:-}" ]]; then
    echoerr "'GOPATH' is not defined. Run 'liq go configure'."
    exit 1
  fi
  colorerr "GOPATH=$GOPATH bash -c 'cd $GOPATH/src/$REL_GOAPP_PATH; gcloud app deploy'"
}

# see: liq help projects edit
projects-edit() {
  findBase # TODO: basically, we use this to imply that we're in a repo. It's not quite the right quetsion.

  local EDITOR_CMD="${LIQ_EDITOR_CMD:-}"
  [[ -n "${EDITOR_CMD}" ]] || EDITOR_CMD="atom ."
  cd "${BASE_DIR}" && ${EDITOR_CMD}
}

projects-focus() {
  local PROJECT_DIR="${1:-}"

  if [[ -z "${PROJECT_DIR:-}" ]]; then
    # Check if current working directory appears to be in the playground.
    # TODO: this check is week
    [[ "${PWD}" == "${LIQ_PLAYGROUND}/"* ]] \
      || {
        echoerrandexit "Current working directory does not appear to be a sub-directory of the playground. To reset, try\nliq projects focus <project>"
        return 1 # This function may be used with 'ECHO_NEVER_EXIT'; the return handles that.
      }
    echo "${PWD/${LIQ_PLAYGROUND}\//}"
  else
    local DEST_DIR="${LIQ_PLAYGROUND}/${PROJECT_DIR}"
    [[ -d "${DEST_DIR}" ]] || echoerrandexit "Did not find expected targeted directory '${DEST_DIR}'."
    cd "${DEST_DIR}" && echofmt --info "Focus: ${PROJECT_DIR}"
  fi

  return 0
}

# see: liq help projects import; The '--set-name' and '--set-url' options are for internal use and each take a var name
# which will be 'eval'-ed to contain the project name and URL.
projects-import() {
  local PROJ_SPEC __PROJ_NAME _PROJ_URL PROJ_STAGE
  eval "$(setSimpleOptions NO_FORK:F NO_INSTALL SET_NAME= SET_URL= -- "$@")"

  set-stuff() {
    # TODO: protect this eval
    if [[ -n "$SET_NAME" ]]; then eval "$SET_NAME='$_PROJ_NAME'"; fi
    if [[ -n "$SET_URL" ]]; then eval "$SET_URL='$_PROJ_URL'"; fi
  }

  fork_check() {
    local GIT_URL="${1:-}"
    local PRIVATE GIT_OWNER GIT REPO
    echo "URL: $GIT_URL"

    if [[ -z "$NO_FORK" ]]; then
      GIT_URL="$(echo "$GIT_URL" | sed -e 's/[^:]*://' -e 's/\.git$//')"
      echo "URL2: $GIT_URL"
      GIT_OWNER="$(basename "$(dirname "$GIT_URL")")"
      GIT_REPO="$(basename "$GIT_URL")"

      echo hub api -X GET "/repos/${GIT_OWNER}/${GIT_REPO}"
      PRIVATE="$(hub api -X GET "/repos/${GIT_OWNER}/${GIT_REPO}" | jq '.private')"
      if [[ "${PRIVATE}" == 'true' ]]; then
        NO_FORK='true'
      fi
    fi
  }

  if [[ "$1" == *:* ]]; then # it's a URL
    _PROJ_URL="${1}"
    fork_check "${_PROJ_URL}"
    # We have to grab the project from the repo in order to figure out it's (npm-based) name...
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$_PROJ_URL"
    else
      projectForkClone "$_PROJ_URL"
    fi
    _PROJ_NAME=$(cat "$PROJ_STAGE/package.json" | jq --raw-output '.name' | tr -d "'")
    if [[ -n "$_PROJ_NAME" ]]; then
      set-stuff
      if projectCheckIfInPlayground "$_PROJ_NAME"; then
        echo "Project '$_PROJ_NAME' is already in the playground. No changes made."
        return 0
      fi
    else
      rm -rf "$PROJ_STAGE"
      echoerrandexit -F "The specified source is not a valid Liquid Dev package (no 'package.json'). Try:\nliq projects create --type=bare --origin='$_PROJ_URL' <project name>"
    fi
  else # it's an NPM package
    _PROJ_NAME="${1}"
    set-stuff
    if projectCheckIfInPlayground "$_PROJ_NAME"; then
      echo "Project '$_PROJ_NAME' is already in the playground. No changes made."
      _PROJ_URL="$(projectsGetUpstreamUrl "$_PROJ_NAME")"
      set-stuff
      return 0
    fi
    # Note: NPM will accept git URLs, but this saves us a step, let's us check if in playground earlier, and simplifes branching
    _PROJ_URL=$(npm view "$_PROJ_NAME" repository.url) \
      || echoerrandexit "Did not find expected NPM package '${_PROJ_NAME}'. Did you forget the '--url' option?"
    set-stuff
    _PROJ_URL=${_PROJ_URL##git+}
    fork_check "$_PROJ_URL"
    if [[ -n "$NO_FORK" ]]; then
      projectClone "$_PROJ_URL"
    else
      projectForkClone "$_PROJ_URL"
    fi
  fi

  projectMoveStaged "$_PROJ_NAME" "$PROJ_STAGE"

  echo "'$_PROJ_NAME' imported into playground."
  if [[ -z "$NO_INSTALL" ]]; then
    cd "${LIQ_PLAYGROUND}/${_PROJ_NAME/@/}"
    echo "Installing project..."
    npm install || echoerrandexit "Installation failed."
    echo "Install complete."
  fi
}

projects-list() {
  local OPTIONS
  OPTIONS="$(pre-options-liq-projects) ORG:= LOCAL ALL_ORGS NAMES_ONLY FILTER="
  eval "$(setSimpleOptions ${OPTIONS} -- "$@")"
  post-options-liq-projects
  # DEBUG: testing this deletion...
  # orgs-lib-process-org-opt

  [[ -z "${LOCAL}" ]] || [[ -n "${NAMES_ONLY}" ]] || NAMES_ONLY=true # local implies '--names-only'
  [[ -n "${ORG}" ]] || ALL_ORGS=true # ALL_ORGS is default

  # INTERNAL HELPERS
  local NON_PROD_ORGS # gather up non-prod so we can issue warnings
  function echo-header() { echo -e "Name\tRepo scope\tPublished scope\tVersion"; }
  # Extracts data to display from package.json data embedded in the projects.json or from the package.json file itself
  # in the local checkouts.
  function process-proj-data() {
    local PROJ_NAME="${1}"
    local PROJ_DATA="$(cat -)"

    # Name; col 1
    echo -en "${PROJ_NAME}\t"

    # Repo scope status cos 2
    echo -en "$(echo "${PROJ_DATA}" | jq -r 'if .repository.private then "private" else "public" end')\t"

    # Published scope status cos 3
    echo -en "$(echo "${PROJ_DATA}" | jq -r 'if .package then if .package.liq.public then "public" else "private" end else "-" end')\t"

    # Version cols 4
    local VERSION # we do these extra steps so echo, which is known to provide the newline, does the output
    VERSION="$(echo "${PROJ_DATA}" | jq -r '.package.version // "-"')"
    echo "${VERSION}"
  }

  function process-org() {
    if [[ -z "${LOCAL}" ]]; then # list projects from the 'projects.json' file
      local DATA_PATH
      [[ -z "${ORG_PROJECTS_REPO:-}" ]] || DATA_PATH="${LIQ_PLAYGROUND}/${ORG_PROJECTS_REPO/@/}"
      [[ -n "${DATA_PATH:-}" ]] || DATA_PATH="${CURR_ORG_PATH}"
      DATA_PATH="${DATA_PATH}/data/orgs/projects.json"

      [[ -f "${DATA_PATH}" ]] || echoerrandexit "Did not find expected project definition '${DATA_PATH}'. Try:\nliq orgs refresh --projects"

      if [[ -n "${NAMES_ONLY}" ]]; then
        cat "${DATA_PATH}" | jq -r 'keys | .[]'
      else
        local PROJ_DATA="$(cat "${DATA_PATH}")"
        local PROJ_NAME
        while read -r PROJ_NAME; do
          echo "${PROJ_DATA}" | jq ".[\"${PROJ_NAME}\"]" | process-proj-data "${PROJ_NAME}"
        done < <(echo "${PROJ_DATA}" | jq -r 'keys | .[]')
      fi

      # The non-production source is only a concern if we're looking at the org repo.
      if ! projects-lib-is-at-production "${CURR_ORG_PATH}"; then
        list-add-item NON_PROD_ORGS "${ORG}"
      fi
    else # list local projects; recall this is limited to '--name-only'
      local PROJ
      find "${CURR_ORG_PATH}/.." -maxdepth 1 -type d -not -name '.*' -exec basename {} \; \
        | while read -r PROJ; do ! [[ -f "${CURR_ORG_PATH}/../${PROJ}/package.json" ]] || echo "${PROJ}"; done \
        | sort
    fi
  }

  # This is where all the data/output is generated, which gets fed to the filter and formatter
  function process-cmd() {
    [[ -n "${NAMES_ONLY:-}" ]] || echo-header
    if [[ -n "${ALL_ORGS}" ]]; then # all is the default
      for ORG in $(orgs-list); do
        orgs-lib-process-org-opt
        process-org
      done
    else
      process-org
    fi
  }

  if [[ -n "${FILTER}" ]]; then
    process-cmd > >(awk "\$1~/.*${FILTER}.*/" | column -s $'\t' -t)
  else
    process-cmd > >(column -s $'\t' -t)
  fi

  # finally, issue non-prod warnings if any
  exec 10< <(echo "${NON_PROD_ORGS:-}") # this craziness is because if we do 'process-cmd | column...' above, then
  # 'process-cmd' would get run in a sub-shell and NON_PROD_ORGS updates get trapped. So, we have to rewrite without
  # pipes. BUT that causes 'read -r NP_ORG; do... done<<<${NON_PROD_ORGS}' to fail with a 'cannot create temp file for
  # here document: Interrupted system call'. I *think* the <<< creates the heredoc but the redirect to column still has
  # a handle on STDIN... Really, I'm not clear, but this seems to work.
  local NP_ORG
  [[ -z "${NON_PROD_ORGS:-}" ]] || while read -u 10 -r NP_ORG; do
    echowarn "\nWARNING: Non-production data shown for '${NP_ORG}'."
  done
  exec 10<&-
}

# see: liq help projects publish
projects-publish() {
  echoerrandexit "The 'publish' action is not yet implemented."
}

# see: liq help projects qa
projects-qa() {
  eval "$(setSimpleOptions UPDATE^ OPTIONS=^ AUDIT LINT LIQ_CHECK VERSION_CHECK -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  findBase
  cd "$BASE_DIR"

  local RESTRICTED=''
  if [[ -n "$AUDIT" ]] || [[ -n "$LINT" ]] || [[ -n "$LIQ_CHECK" ]] || [[ -n "$VERSION_CHECK" ]]; then
    RESTRICTED=true
  fi

  local FIX_LIST
  if [[ -z "$RESTRICTED" ]] || [[ -n "$AUDIT" ]]; then
    projectsNpmAudit "$@" || list-add-item FIX_LIST '--audit'
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$LINT" ]]; then
    projectsLint "$@" || list-add-item FIX_LIST '--lint'
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$LIQ_CHECK" ]]; then
    projectsLiqCheck "$@" || true # Check provides it's own instrucitons.
  fi
  if [[ -z "$RESTRICTED" ]] || [[ -n "$VERSION_CHECK" ]]; then
    projectsVersionCheck "$@" || list-add-item FIX_LIST '--version-check'
  fi
  if [[ -n "$FIX_LIST" ]]; then
    echowarn "To attempt automated fixes, try:\nliq projects qa --update $(list-join FIX_LIST ' ')"
    return 1
  fi
}

# see: liq help projects sync
projects-sync() {
  eval "$(setSimpleOptions FETCH_ONLY NO_WORK_MASTER_MERGE:M PROJECT= -- "$@")" \
    || { contextHelp; echoerrandexit "Bad options."; }

  if [[ -z "$PROJECT" ]]; then
    [[ -n "${BASE_DIR:-}" ]] || findBase
    PROJECT="$(cat "${BASE_DIR}/package.json" | jq --raw-output '.name' | tr -d "'")"
  fi
  PROJECT=${PROJECT/@/}
  local PROJ_DIR="${LIQ_PLAYGROUND}/${PROJECT}"

  if [[ -z "$NO_WORK_MASTER_MERGE" ]] && [[ -z "$FETCH_ONLY" ]]; then
    requireCleanRepo "$PROJECT"
  fi

  local CURR_BRANCH REMOTE_COMMITS MASTER_UPDATED
  CURR_BRANCH="$(workCurrentWorkBranch)"

  echo "Fetching remote histories..."
  local DEFAULT_BRANCH
  DEFAULT_BRANCH=$(lib-git-determine-default-branch)  
  git fetch upstream ${DEFAULT_BRANCH}:remotes/upstream/${DEFAULT_BRANCH}
  if [[ "$CURR_BRANCH" != "${DEFAULT_BRANCH}" ]]; then
    git fetch workspace ${DEFAULT_BRANCH}:remotes/workspace/${DEFAULT_BRANCH}
    git fetch workspace "${CURR_BRANCH}:remotes/workspace/${CURR_BRANCH}"
  fi
  echo "Fetch done."

  if [[ "$FETCH_ONLY" == true ]]; then
    return 0
  fi

  cleanupMaster() {
    cd "${LIQ_PLAYGROUND}/${PROJECT}"
    # heh, need this to always be 'true' or 'set -e' complains
    [[ ! -d _main ]] || git worktree remove _main
  }

  REMOTE_COMMITS=$(git rev-list --right-only --count ${DEFAULT_BRANCH}...upstream/${DEFAULT_BRANCH})
  if (( $REMOTE_COMMITS > 0 )); then
    local DEFAULT_BRANCH
    DEFAULT_BRANCH=$(lib-git-determine-default-branch)
    echo "Syncing with upstream ${DEFAULT_BRANCH}..."
    cd "${PROJ_DIR}"
    if [[ "$CURR_BRANCH" != "${DEFAULT_BRANCH}" ]]; then
      (git worktree add _main ${DEFAULT_BRANCH} \
        || echoerrandexit "Could not create '${DEFAULT_BRANCH}' worktree.") \
      && { cd _main; git merge remotes/upstream/${DEFAULT_BRANCH}; } || \
          { cleanupMaster; echoerrandexit "Could not merge upstream ${DEFAULT_BRANCH} to local ${DEFAULT_BRANCH}."; }
      MASTER_UPDATED=true
    else
      git pull upstream ${DEFAULT_BRANCH} \
        || echoerrandexit "There were problems merging upstream ${DEFAULT_BRANCH} to local ${DEFAULT_BRANCH}."
    fi
  fi
  echo "Upstream ${DEFAULT_BRANCH} synced."

  if [[ "$CURR_BRANCH" != "${DEFAULT_BRANCH}" ]]; then
    REMOTE_COMMITS=$(git rev-list --right-only --count ${DEFAULT_BRANCH}...workspace/${DEFAULT_BRANCH})
    if (( $REMOTE_COMMITS > 0 )); then
      echo "Syncing with workspace ${DEFAULT_BRANCH}..."
      cd "${PROJ_DIR}/_main"
      git merge remotes/workspace/${DEFAULT_BRANCH} || \
          { cleanupMaster; echoerrandexit "Could not merge upstream ${DEFAULT_BRANCH} to local ${DEFAULT_BRANCH}."; }
      MASTER_UPDATED=true
    fi
    echo "Workspace ${DEFAULT_BRANCH} synced."
    cleanupMaster

    REMOTE_COMMITS=$(git rev-list --right-only --count ${CURR_BRANCH}...workspace/${CURR_BRANCH})
    if (( $REMOTE_COMMITS > 0 )); then
      echo "Synching with workspace workbranch..."
      git pull workspace "${CURR_BRANCH}:remotes/workspace/${CURR_BRANCH}"
    fi
    echo "Workspace workbranch synced."

    if [[ -z "$NO_WORK_MASTER_MERGE" ]] \
         && ( [[ "$MASTER_UPDATED" == true ]] || ! git merge-base --is-ancestor ${DEFAULT_BRANCH} $CURR_BRANCH ); then
      echo "Merging ${DEFAULT_BRANCH} updates to work branch..."
      git merge ${DEFAULT_BRANCH} --no-commit --no-ff || true # might fail with conflicts, and that's OK
      if git diff-index --quiet HEAD "${PROJ_DIR}" \
         && git diff --quiet HEAD "${PROJ_DIR}"; then
        echowarn "Hmm... expected to see changes from ${DEFAULT_BRANCH}, but none appeared. It's possible the changes have already been incorporated/recreated without a merge, so this isn't necessarily an issue, but you may want to double check that everything is as expected."
      else
        if ! git diff-index --quiet HEAD "${PROJ_DIR}/dist" || ! git diff --quiet HEAD "${PROJ_DIR}/dist"; then # there are changes in ./dist
          echowarn "Backing out merge updates to './dist'; rebuild to generate current distribution:\nliq projects build $PROJECT"
          git checkout -f HEAD -- ./dist
        fi
        if git diff --quiet "${PROJ_DIR}"; then # no conflicts
          git add -A
          git commit -m "Merge updates from ${DEFAULT_BRANCH} to workbranch."
          work-save --backup-only
          echo "Master updates merged to workbranch."
        else
          echowarn "Merge was successful, but conflicts exist. Please resolve and then save changes:\nliq work save"
        fi
      fi
    fi
  fi # on workbranach check
}

# see: liq help projects test
projects-test() {
  eval "$(setSimpleOptions TYPES= NO_DATA_RESET:D GO_RUN= NO_START:S NO_SERVICE_CHECK:C -- "$@")" \
    || ( contextHelp; echoerrandexit "Bad options." )

  if [[ -z "${NO_SERVICE_CHECK}" ]] \
     && ( [[ -z "${TEST_TYPES:-}" ]] \
       || echo "$TEST_TYPES" | grep -qE '(^|, *| +)int(egration)?(, *| +|$)' ); then
    if type -t projects-services-list | grep -q 'function'; then
      requireEnvironment
      echo -n "Checking services... "
      if ! projects-services-list --show-status --exit-on-stopped --quiet > /dev/null; then
        if [[ -z "${NO_START:-}" ]]; then
          services-start || echoerrandexit "Could not start services for testing."
        else
          echo "${red}necessary services not running.${reset}"
          echoerrandexit "Some services are not running. You can either run unit tests are start services. Try one of the following:\nliq projects test --types=unit\nliq services start"
        fi
      else
        echo "${green}looks good.${reset}"
      fi
    fi # check if runtime extesions present
  fi

  # note this entails 'pretest' and 'posttest' as well
  TEST_TYPES="$TYPES" NO_DATA_RESET="$NO_DATA_RESET" GO_RUN="$GO_RUN" projectsRunPackageScript test || \
    echoerrandexit "If failure due to non-running services, you can also run only the unit tests with:\nliq projects test --type=unit" $?
}
