#!/usr/bin/env bash

SCRIPTDIR="$(eval echo $(cd $( dirname "${BASH_SOURCE[0]}" ) && pwd))"
cd "$SCRIPTDIR" || exit 1

# ------------------------------------------------------------------------------

source "./utils.sh"
source "./spinner.sh"

# ------------------------------------------------------------------------------

declare -r OPT_COPY_TO_CLIPBOARD="$(get_tmux_option "@passwords-copy-to-clipboard" "off")"
declare -r OPT_CLEAR_CLIPBOARD_TIME="$(get_tmux_option "@passwords-clipboard-duration" "30")"
declare -r OPT_MANAGER="$(get_tmux_option "@passwords-manager-cmd" "on")"
declare -r OPT_DEBUG="$(get_tmux_option "@passwords-debug" "false")"

declare spinner_pid=""

# FILTER_URL="https://github.com"

LOGFILE="$SCRIPTDIR/../tmux-passwords.log"
INCLUDE_PASSWORDS_IN_LOG=false

source ../password_manager_configs.d/$OPT_MANAGER.sh

if $OPT_DEBUG; then
  echo "Debug information will be printed to $LOGFILE"
else
  # Supress errors by disabling stderr
  exec 3>&2-
  exec 2>/dev/null
fi

log(){
  read input
  if $OPT_DEBUG; then
    echo $input >> $LOGFILE
    echo $input >&2
  fi
  echo $input
}

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
  echo Press any key to continue... > /dev/tty
  read -rs -n1 key
}

# ------------------------------------------------------------------------------

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
  echo  # Newline after spinner
  echo INFO: Matching items: $items > /dev/stderr # debug

  # Check if items contains non-whitespace characters.
  if [[ $str =~ ^\ +$ ]]; then
    # Needs to login

      if $OPT_DEBUG; then
      echo "No matching items found. Will try to log in." | log # debug
      # Give time to read any messages
      pause
    fi
    login
    if $OPT_DEBUG; then
      echo "Login output shown above." | log # debug
      # Give time to read any messages
      pause
    fi
    if ! $OPT_DEBUG; then
      tput clear
    fi
    spinner_start "Fetching items"
    items="$(get_items | log)"
    spinner_stop
  fi

  selected_item_name="$(echo "$items" | awk -F ',' '{ print $1 }' | fzf --no-multi 2>/dev/tty)"

  if [ -n "$selected_item_name" ]; then
    selected_item_uuid="$(echo "$items" | grep "$selected_item_name" | awk -F ',' '{ print $2 }')"
    echo item uuid: $selected_item_uuid > /dev/stderr # debug

    spinner_start "Fetching password"
    selected_item_password="$(get_item_password "$selected_item_uuid")"
    spinner_stop
    if $INCLUDE_PASSWORDS_IN_LOG; then
      echo password: $selected_item_password > /dev/stderr # debug
    fi

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

main "$@" 2> >(tee $LOGFILE 1>&2)
if ! $OPT_DEBUG; then
  # Restore stderr
  exec 2>&3
fi
