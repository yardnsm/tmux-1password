#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
  || exit 1

# ---------------------------------------------

source "./utils.sh"
source "./spinner.sh"

# ---------------------------------------------

declare -r TMP_TOKEN_FILE="$HOME/.op_tmux_token_tmp"
declare -r OPT_SUBDOMAIN="$(get_tmux_option "@1password-subdomain" "my")"

declare spinner_pid=""

# ---------------------------------------------

spinner_start() {
  tput civis
  show_spinner "$1" &
  spinner_pid=$!
}

spinner_stop() {
  tput cnorm
  kill "$spinner_pid" &> /dev/null
  spinner_pid=""
}

# ---------------------------------------------

op_login() {
  op signin "$OPT_SUBDOMAIN" --output=raw > "$TMP_TOKEN_FILE"
}

op_get_session() {
  cat "$TMP_TOKEN_FILE" 2> /dev/null
}

get_op_items() {
  local -r JQ_FILTER=".[] \
    | [select(.overview.URLs | map(select(.u == \"sudolikeaboss://local\")) | length == 1)?] \
    | map([ .overview.title, .uuid ] \
    | join(\",\")) \
    | .[]"

  op list items --session="$(op_get_session)" 2> /dev/null | jq "$JQ_FILTER" --raw-output
}

get_op_item_password() {
  local -r ITEM_UUID="$1"
  local -r JQ_FILTER=".details.fields[] \
    | select (.designation == \"password\") \
    | .value"

  op get item "$ITEM_UUID" --session="$(op_get_session)" | jq "$JQ_FILTER" --raw-output
}

# ---------------------------------------------

main() {
  local -r ACTIVE_PANE="$1"

  local items
  local selected_item_name
  local selected_item_uuid
  local selected_item_password

  spinner_start "Fetching items"
  items="$(get_op_items)"
  spinner_stop

  if [[ -z "$items" ]]; then
    # Need to login
    op_login

    if [[ -z "$(op_get_session)" ]]; then
      tmux display-message "1password-tmux: 1Password CLI signin has failed"
      return 0
    fi

    items="$(get_op_items)"
  fi

  selected_item_name="$(echo "$items" | awk -F ',' '{ print $1 }' | fzf --no-multi)"

  if [[ -n "$selected_item_name" ]]; then
    selected_item_uuid="$(echo "$items" | grep "$selected_item_name" | awk -F ',' '{ print $2 }')"

    spinner_start "Fetching password"
    selected_item_password="$(get_op_item_password "$selected_item_uuid")"
    spinner_stop

    tmux send-keys -t "$ACTIVE_PANE" "$selected_item_password"
  fi
}

main "$@"
