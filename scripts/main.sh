#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
  || exit 1

# ------------------------------------------------------------------------------

source "./utils.sh"
source "./spinner.sh"

# ------------------------------------------------------------------------------

declare -r TMP_TOKEN_FILE="$HOME/.op_tmux_token_tmp"

declare -r OPT_LPASS_USER="$(get_tmux_option "@lastpass-username" "unset")"
declare -r OPT_SUBDOMAIN="$(get_tmux_option "@1password-subdomain" "my")"
declare -r OPT_VAULT="$(get_tmux_option "@1password-vault" "")"
declare -r OPT_COPY_TO_CLIPBOARD="$(get_tmux_option "@1password-copy-to-clipboard" "off")"
declare -r OPT_MANAGER="$(get_tmux_option "@password-manager-cmd" "on")"
declare -r OPT_DEBUG="$(get_tmux_option "@tmux-1pass-debug" "false")"

declare spinner_pid=""

FILTER_URL="sudolikeaboss://local"

source ../password_manager_configs.d/$OPT_MANAGER.sh

# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------

manager() {
  pwman=$OPT_MANAGER
  cmd=$1
  shift # Remove 1st arg (the cmd) from list
  case $cmd in
    login)
      $pwman $logincmd "$otherOptsLogin" "$@"
      ;;
    list)
      $pwman $listcmd "$otherOptsList" "$@"
      ;;
    get)
      $pwman $getcmd "$otherOptsGet" "$@"
      ;;
    *)
      echo Unknown command: $cmd
      sleep 5
      exit
      ;;
  esac
}

login() {
  manager login > "$TMP_TOKEN_FILE"
  tput clear
}

get_session() {
  cat "$TMP_TOKEN_FILE" 2> /dev/null
}

get_items() {
  if [ "$OPT_DEBUG" == "true" ]; then
    filter_list "$(manager list)"
  else
    filter_list "$(manager list 2> /dev/null)"
  fi
}

filter_list(){
  local -r input="$*"
  echo $input | jq "$JQ_FILTER_LIST" --raw-output
}

get_item_password() {
  local -r ITEM_UUID="$1"
  if [ "$OPT_DEBUG" == "true" ]; then
    filter_get "$(manager get $ITEM_UUID)"
  else
    filter_get "$(manager get $ITEM_UUID 2> /dev/null)"
  fi
}

filter_get(){
  local -r input="$*"
  echo $input | jq "$JQ_FILTER_GET" --raw-output
}

# ------------------------------------------------------------------------------

main() {
  local -r ACTIVE_PANE="$1"

  local items
  local selected_item_name
  local selected_item_uuid
  local selected_item_password

  spinner_start "Fetching items"
  items="$(get_items)"
  spinner_stop

  if [[ -z "$items" ]]; then

    # Needs to login
    login

    if [[ -z "$(get_session)" ]]; then
      display_message "1Password CLI signin has failed"
      return 0
    fi

    spinner_start "Fetching items"
    items="$(get_items)"
    spinner_stop
  fi

  selected_item_name="$(echo "$items" | awk -F ',' '{ print $1 }' | fzf --no-multi)"

  if [[ -n "$selected_item_name" ]]; then
    selected_item_uuid="$(echo "$items" | grep "$selected_item_name" | awk -F ',' '{ print $2 }')"

    spinner_start "Fetching password"
    selected_item_password="$(get_item_password "$selected_item_uuid")"
    spinner_stop

    if [[ "$OPT_COPY_TO_CLIPBOARD" == "on" ]]; then

      # Copy password to clipboard
      copy_to_clipboard "$selected_item_password"

      # Clear clipboard
      clear_clipboard 30
    else

      # Use `send-keys`
      tmux send-keys -t "$ACTIVE_PANE" "$selected_item_password"
    fi
  fi
}

main "$@"
# vim:sw=2:ts=2
