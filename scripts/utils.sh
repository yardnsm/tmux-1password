#!/usr/bin/env bash

get_tmux_option() {
  local option=$1
  local default_value=$2
  local option_value; option_value=$(tmux show-option -gqv "$option")

  if [[ -z "$option_value" ]]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

display_message() {
  tmux display-message "tmux-1password: $1"
}

is_cmd_exists() {
  command -v "$1" &> /dev/null
  return $?
}
