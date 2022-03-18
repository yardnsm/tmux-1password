#!/usr/bin/env bash

# ------------------------------------------------------------------------------

prompt::ask() {
  local question="$1"

  printf "\\e[0;33m[?]\\e[0m %b [y/N] " "$question"
  read -r -n 1
  echo -ne "\n"
}

prompt::answer_is_yes() {
  [[ "$REPLY" =~ ^[Yy]$ ]] \
    && return 0 \
    || return 1
}
