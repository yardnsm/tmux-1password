#!/usr/bin/env bash

# ------------------------------------------------------------------------------

tmux::get_option() {
  local option=$1
  local default_value=$2
  local option_value; option_value=$(tmux show-option -gqv "$option")

  if [[ -z "$option_value" ]]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

tmux::display_message() {
  tmux display-message "tmux-1password: $1"
}
