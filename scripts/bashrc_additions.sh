#!/bin/bash

# Note: Before running anything read below and modify any variables under a # -!-!-!-

# Add some extra stuff to the bashrc file
# While nothing in here should break your .bashrc if added twice you shouldn't just
# so your .bashrc file isn't confusing to read

# Make sure you test anything you add here to make sure the world doesn't blow up

# -!-!-!-
BASHRC="/home/student/.bashrc"

# This functions expects that if a given string exists in the .bashrc it is
# on a line by itself
function check_if_added() {
  local SEARCH_STR="^${1}$"
  EXISTS=`cat ${BASHRC} | grep "${SEARCH_STR}"`
  if [[ -z "$EXISTS" ]]; then
    EXISTS=0
  else
    EXISTS=1
  fi
  return 0
}

function add_bashrc() {
  # Simple check so we don't add stuff twice
  check_if_added "$1"
  if [[ $EXISTS == 1 ]]; then
    echo "Addition already exists: ${1}"
    return 0
  fi

  echo $1 >> ${BASHRC}
  return 1
}

echo "Running bashrc_additions as (`whoami`)"
if [[ -z ${BASHRC} ]]; then
  echo "Cannot fine .bashrc file at \"${BASHRC}\""
  return 1
fi
# Setup vi as your terminal editor
add_bashrc "set -o vi"

ERASE_CHAR=
add_bashrc "stty erase ${ERASE_CHAR}"

# -!-!-!-
REPO_DIR="~/repo"

if [[ -z ${REPO_DIR} ]]; then
  echo "Cannot find repository: ${REPO_DIR}"
  return 1
fi
# Source our shell functions for extra functionality
add_bashrc "source ${REPO_DIR}/scripts/shell_fns.sh"

# This isn't really a bashrc addition but I added it here anyways. It is more of a vimrc addition
if [[ ! -f "$HOME/.vimrc.after" ]]; then
  # Janus vim plugins likely not installed so lets do it now
  echo "Installing Janus Vim plugin pack"
  # I'm not installing these now becuase this is intended to be run as student who cannot
  # execute sudo commands. So make sure you install these first in a different environment
  # sudo apt-get install ack ctags ruby rake curl
  curl -Lo- https://bit.ly/janus-bootstrap | bash
fi
