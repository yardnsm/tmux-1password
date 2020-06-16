#!/usr/bin/env bash

# ------------------------------------------------------------------------------

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

copy_to_clipboard() {
  if [[ "$(uname)" == "Darwin" ]] && is_cmd_exists "pbcopy"; then
    echo -n "$1" | pbcopy
  elif [[ "$(uname)" == "Linux" ]] && is_cmd_exists "$OPT_CLIPBOARD_CMD"; then
    echo -n "$1" | "$OPT_CLIPBOARD_CMD" "$OPT_CLIPBOARD_OPTS"
  else
    return 1
  fi
}

clear_clipboard() {
  local -r SEC="$1"

  if [[ "$(uname)" == "Darwin" ]] && is_cmd_exists "pbcopy"; then
    tmux run-shell -b "sleep $SEC && echo '' | pbcopy"
  elif [[ "$(uname)" == "Linux" ]] && is_cmd_exists "$OPT_CLIPBOARD_CMD"; then
    tmux run-shell -b "sleep $SEC && echo '' | $OPT_CLIPBOARD_CMD $OPT_CLIPBOARD_OPTS"
  else
    return 1
  fi
}
