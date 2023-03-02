#!/usr/bin/env bash

import echoerr
import fileslib

echo "Starting liq install..."

function npm-install() {
  local PKG="${1}"
  local INSTALL_TEST="${2}"

  if ! ${INSTALL_TEST}; then
    npm install -g ${PKG}
  fi
}

npm-install yalc 'which yalc >/dev/null'

declare COMPLETION_SEUTP
echo "Setting up liq CLI tab completion support..."
for i in /etc/bash_completion.d /usr/local/etc/bash_completion.d; do
  if [[ -e "${i}" ]]; then
    COMPLETION_PATH="${i}"
    COMPLETION_SETUP=true
    break
  fi
done
[[ -n "${COMPLETION_SETUP}" ]] || echowarn "Could not setup completion; did not find expected completion paths."
cp ./src/completion/liq-completion.sh "${COMPLETION_PATH}/liq"

COMPLETION_SETUP=false
for i in /etc/bash.bashrc "${HOME}/.bash_profile" "${HOME}/.profile"; do
  if [[ -e "${i}" ]]; then
    # TODO: update this to return/echo whether or not something was added; for use in TODO below
    fileslib-append-string "${i}" "[ -d '$COMPLETION_PATH' ] && . '${COMPLETION_PATH}/liq'"
    COMPLETION_SETUP=true
    break
  fi
done

if [[ "${COMPLETION_SETUP}" == 'false' ]]; then
  echoerr "Completion support not set up; could not find likely bash profile/rc."
else
  echo "Completion setup complete."
fi
# TODO: accept '-e' option which echos the source command so user can do 'eval ./install.sh -e'
# TODO: only echo if lines added (here or in POST_INSTALL)
[[ -z "${PS1}" ]] || echo "You must open a new shell or 'source ~/.bash_profile' to enable completion updates."
