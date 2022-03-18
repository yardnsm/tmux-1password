#!/usr/bin/env bash

# Taken from:
# https://github.com/yardnsm/dotfiles/blob/master/_setup/utils/spinner.sh

# ------------------------------------------------------------------------------

declare __SPINNER_PID=""

# ------------------------------------------------------------------------------

__start_spinner() {

  local -r MSG="$1"

  local -r FRAMES="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
  local -r DELAY=0.05

  local i=0
  local current_symbol

  trap 'exit 0' SIGTERM

  while true; do
    current_symbol="${FRAMES:i++%${#FRAMES}:1}"

    printf "\\e[0;34m%s\\e[0m  %s" "$current_symbol" "$MSG"

    printf "\\r"

    sleep $DELAY
  done

  return $?
}

spinner:start() {
  if options::debug_mode; then
    echo "... $1"
    return
  fi

  tput civis
  __start_spinner "$1" &
  __SPINNER_PID=$!
}

spinner::stop() {
  if options::debug_mode; then
    return
  fi

  tput cnorm
  kill "$__SPINNER_PID" &> /dev/null
  __SPINNER_PID=""
}
