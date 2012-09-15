#!/bin/bash

# Note: Before running anything read below and modify any variables under a # -!-!-!-

# Add some extra stuff to the bashrc file
# While nothing in here should break your .bashrc if added twice you shouldn't just
# so your .bashrc file isn't confusing to read

# Make sure you test anything you add here to make sure the world doesn't blow up

# -!-!-!-
BASHRC="/home/student/.bashrc"

function add_bashrc() {
  echo $1 >> ${BASHRC}
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
