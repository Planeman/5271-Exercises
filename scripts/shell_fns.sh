#!/bin/bash

# These functions or variables are meant to wrap certain functionality to make
# it easier for everyone and support multiple people using

# This should be sourced at the end of the appropriate .bashrc file

function gpush() {
  if [[ $# == 0 ]]; then
    echo "Usage: gpush <username> [email]"
    return  1
  fi

  AUTH_NAME=$1
  AUTH_EMAIL="student@nosite.com"
  if [[ $# == 2 ]]; then
    AUTH_EMAIL=$2
  fi

  #Turns out we don't need to do this but the code is handy anyways
  #SAVED_USER=$(git config -l | grep user.name | sed 's/user.name=\(.*\)$/\1/')
  #echo "Current git identity: ${SAVED_USER}"
  AUTH_STR="${AUTH_NAME} <${AUTH_EMAIL}>"
  echo "Pushing with author: ${AUTH_STR}"

  CM_MSG=`git log -n 1 HEAD --format=format:%s%n%b`
  echo "Using commit message: \"${CM_MSG}\""

  # Amend the commit
  git commit --amend --author "${AUTH_STR}" -m "${CM_MSG}"

  # Now do the push
  git push
}
