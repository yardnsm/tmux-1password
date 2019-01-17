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
declare -r OPT_DEBUG="$(get_tmux_option "@tmux-1pass-debug" "false")"

declare spinner_pid=""

# FILTER_URL="sudolikeaboss://local"
FILTER_URL="https://github.com"
LOGFILE=".tmux-passwords.log"

source ../password_manager_configs.d/$OPT_MANAGER.sh

if [ "$OPT_DEBUG" != "true" ]; then
  # Supress errors by disabling stderr
  exec 3>&2-
  exec 2>/dev/null
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
  # Tee commands to send output to stderr as well as stdin.
  echo -n INFO: $cmd output:: > /dev/stderr # debug
  case $cmd in
    login)
      $pwman $logincmd "$otherOptsLogin" "$@" | tee /dev/stderr
      ;;
    list)
      $pwman $listcmd "$otherOptsList" "$@" | tee /dev/stderr
      ;;
    get)
      $pwman $getcmd "$otherOptsGet" "$@" | tee /dev/stderr
      ;;
    *)
      echo ERROR: Unknown command: $cmd > /dev/stderr # debug
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
  echo INFO: All items found: > /dev/stderr # debug
  filter_list "$(manager list | tee /dev/stderr)"
}

filter_list(){
  if [ -n "$USE_CUSTOM_FILTERS" ]; then
    filter_list_custom "$@"
  else
    local -r input="$*"
    echo $input | jq "$JQ_FILTER_LIST" --raw-output
  fi
}

get_item_password() {
  local -r ITEM_UUID="$1"
  echo INFO: Password: > /dev/stderr # debug
  filter_get "$(manager get $ITEM_UUID)" | tee /dev/stderr
}

filter_get(){
  if [ -n "$USE_CUSTOM_FILTERS" ]; then
    filter_get_custom "$@"
  else
    local -r input="$*"
    echo $input | jq "$JQ_FILTER_GET" --raw-output
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
  echo INFO: Matching items: $items > /dev/stderr # debug

  if [ -z "$items" ]; then

    if [ "$OPT_DEBUG" == "true" ]; then
      echo "No matching items found. Will try to log in again." | tee /dev/stderr # debug
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

  selected_item_name="$(echo "$items" | awk -F ',' '{ print $1 }' | fzf --no-multi 2>/dev/tty)"

  if [ -n "$selected_item_name" ]; then
    selected_item_uuid="$(echo "$items" | grep "$selected_item_name" | awk -F ',' '{ print $2 }')"
    echo item uuid: $selected_item_uuid > /dev/stderr # debug

    spinner_start "Fetching password"
    selected_item_password="$(get_item_password "$selected_item_uuid")"
    spinner_stop
    echo password: $selected_item_password > /dev/stderr # debug

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

# main "$@" 3> >(tee -a "$LOGFILE")
# main "$@" 3> >(tee -a "$LOGFILE")
# main "$@" | tee -a "$LOGFILE"
main "$@"
if [ "$OPT_DEBUG" != "true" ]; then
  # Restore stderr
  exec 2>&3
fi
# vim:sw=2:ts=2
