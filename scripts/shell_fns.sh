#!/bin/bash

# These functions or variables are meant to wrap certain functionality to make
# it easier for everyone and support multiple people using

# This should be sourced at the end of the appropriate .bashrc file

function gpush() {
  if [[ $# != 1 ]]; then
    echo "Usage: gpush <username>"
    return  1
  fi

  saved_user = `git config -l`
  echo "Current git identity: ${saved_user}"
  echo "Pushing with username: ${1}"
  git config user.name "${1}"

  git commit --amend --reset-author

  echo "Resetting to previous user"
  git config user.name "${saved_user}"

  if [[ `git config -l` != ${saved_user} ]]; then
    echo "Failed to reset to user: ${saved_user}"
    return 1
  fi

  return 0
}
