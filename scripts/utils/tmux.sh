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

tmux::disable_synchronize_panes() {
  if [ "$(tmux show-options -wv synchronize-panes)" == "on" ]; then
    tmux::set_synchronize_panes "off"
    echo "on"
  else
    echo "off"
  fi
}

tmux::set_synchronize_panes() {
  tmux set-window-option synchronize-panes "${1}"
}
