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
declare -r OPT_CLEAR_CLIPBOARD_TIME="$(get_tmux_option "@1password-clipboard-duration" "30")"
declare -r OPT_MANAGER="$(get_tmux_option "@password-manager-cmd" "on")"
declare -r OPT_DEBUG="$(get_tmux_option "@tmux-1pass-debug" "true")"

declare spinner_pid=""

# FILTER_URL="sudolikeaboss://local"
FILTER_URL="https://github.com"

source ../password_manager_configs.d/$OPT_MANAGER.sh

# Note that using this variable requires a command to be prefaced with "eval"
# and the variable to be used unquoted, eg `eval echo test $DEBUG_REDIRECT`.
if [ "$OPT_DEBUG" == "true" ]; then
  # Tee output to stderr, because otherwise gets captured and hidden.
  DEBUG_REDIRECT=" | tee /dev/stderr"
else
  # Supress errors
  DEBUG_REDIRECT=" 2> /dev/null"
fi

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

pause(){
  # give time to read any messages
  read -rsp $'Press any key to continue...\n' -n1 key
}

# ------------------------------------------------------------------------------

manager() {
  pwman=$OPT_MANAGER
  cmd=$1
  shift # Remove 1st arg (the cmd) from list
  case $cmd in
    login)
      eval $pwman $logincmd "$otherOptsLogin" "$@" $DEBUG_REDIRECT
      ;;
    list)
      eval $pwman $listcmd "$otherOptsList" "$@" $DEBUG_REDIRECT
      ;;
    get)
      eval $pwman $getcmd "$otherOptsGet" "$@" $DEBUG_REDIRECT
      ;;
    *)
      echo Unknown command: $cmd
      pause
      exit
      ;;
  esac
}

login() {
  manager login > "$TMP_TOKEN_FILE"

  if [ "$OPT_DEBUG" != "true" ]; then
    tput clear
  fi
}

get_session() {
  cat "$TMP_TOKEN_FILE" 2> /dev/null
}

get_items() {
  eval filter_list "$(manager list)" $DEBUG_REDIRECT
}

filter_list(){
  if [ -n "$USE_CUSTOM_FILTERS" ]; then
    eval filter_list_custom "$@" $DEBUG_REDIRECT
  else
    local -r input="$*"
    eval echo $input | jq "$JQ_FILTER_LIST" --raw-output $DEBUG_REDIRECT
    eval jq -n --argjson data "$input" "$JQ_FILTER_LIST" --raw-output $DEBUG_REDIRECT
  fi
}

get_item_password() {
  local -r ITEM_UUID="$1"
  eval filter_get "$(manager get $ITEM_UUID)" $DEBUG_REDIRECT
}

filter_get(){
  if [ -n "$USE_CUSTOM_FILTERS" ]; then
    eval filter_get_custom "$@" $DEBUG_REDIRECT
  else
    local -r input="$*"
    eval jq -n --argjson data "$input" "$JQ_FILTER_GET" --raw-output $DEBUG_REDIRECT
  fi
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

  if [ -z "$items" ]; then

    if [ "$OPT_DEBUG" == "true" ]; then
      echo "No matching items found. Will try to log in again."
      # Give time to read any messages
      pause
    fi
    # Needs to login
    login

    if [ -z "$(get_session)" ]; then
      display_message "1Password CLI signin has failed"
      # Give time to read any messages
      pause
      return 0
    fi

    spinner_start "Fetching items"
    items="$(get_items)"
    spinner_stop
  fi

  selected_item_name="$(echo "$items" | awk -F ',' '{ print $1 }' | fzf --no-multi)"

  if [ -n "$selected_item_name" ]; then
    selected_item_uuid="$(echo "$items" | grep "$selected_item_name" | awk -F ',' '{ print $2 }')"

    spinner_start "Fetching password"
    selected_item_password="$(get_item_password "$selected_item_uuid")"
    spinner_stop

    if [ "$OPT_COPY_TO_CLIPBOARD" == "on" ]; then

      # Copy password to clipboard
      copy_to_clipboard "$selected_item_password"

      # Clear clipboard
      clear_clipboard ${OPT_CLEAR_CLIPBOARD_TIME}
    else

      # Use `send-keys`
      tmux send-keys -t "$ACTIVE_PANE" "$selected_item_password"
    fi
  fi
}

main "$@"
# vim:sw=2:ts=2
