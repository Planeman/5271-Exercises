#!/bin/bash

# Creates some additional files that may be helpful

if [[ ! -e "${HOME}/.gdbinit" ]]; then
  cat <<END_OF_STR > "${HOME}/.gdbinit"
set print pretty on
set print array on
set logging on
END_OF_STR
fi
