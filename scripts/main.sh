#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
  || exit 1

# ------------------------------------------------------------------------------

source "./utils.sh"
source "./spinner.sh"

# ------------------------------------------------------------------------------

declare -r TMP_TOKEN_FILE="$HOME/.op_tmux_token_tmp"

declare -r OPT_SUBDOMAIN="$(get_tmux_option "@1password-subdomain" "my")"
declare -r OPT_VAULT="$(get_tmux_option "@1password-vault" "")"
declare -r OPT_COPY_TO_CLIPBOARD="$(get_tmux_option "@1password-copy-to-clipboard" "off")"
declare -r OPT_ITEMS_JQ_FILTER="$(get_tmux_option "@1password-items-jq-filter" "")"

declare spinner_pid=""

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

op_login() {
  op signin "$OPT_SUBDOMAIN" --output=raw > "$TMP_TOKEN_FILE"
  tput clear
}

op_get_session() {
  cat "$TMP_TOKEN_FILE" 2> /dev/null
}

get_op_items() {

  # The structure (we need) looks like the following:
  # [
  #   {
  #     "uuid": "some-long-uuid",
  #     "overview": {
  #       "URLs": [
  #         { "u": "sudolikeaboss://local" }
  #       ],
  #       "title": "Some item",
  #       "tags": ["some_tag"]
  #     }
  #   }
  # ]

  local JQ_FILTER

  if [[ -n "$OPT_ITEMS_JQ_FILTER" ]]; then
    JQ_FILTER="$OPT_ITEMS_JQ_FILTER"
  else
    JQ_FILTER="
      .[]
      | [select(.overview.URLs | map(select(.u)) | length == 1)?]
      | map([ .overview.title, .uuid ]
      | join(\",\"))
      | .[]
    "
  fi

  op list items --vault="$OPT_VAULT" --session="$(op_get_session)" 2> /dev/null \
    | jq "$JQ_FILTER" --raw-output
}

get_op_item_password() {
  local -r ITEM_UUID="$1"

  # There are two different kind of items that
  # we support: login items and passwords.
  #
  # * Login items:
  #       {
  #         "details": {
  #           "fields": [
  #             {
  #               "designation": "password",
  #               "value": "supersecret"
  #             }
  #           ]
  #         }
  #       }
  #
  # * Password:
  #       {
  #         "details": {
  #           "password": "supersecret"
  #         }
  #       }

  local -r JQ_FILTER="
    .details
    | if .password and .password != \"\" then
        .password
      else
        .fields[]
        | select (.designation == \"password\")
        | .value
      end
    "

  op get item "$ITEM_UUID" --session="$(op_get_session)" \
    | jq "$JQ_FILTER" --raw-output
}

get_op_item_totp() {
  local -r ITEM_UUID="$1"

  op get totp "$ITEM_UUID" --session="$(op_get_session)"
}

# ------------------------------------------------------------------------------

main() {
  local -r ACTIVE_PANE="$1"

  local items
  local selected_item
  local selected_item_name
  local selected_item_uuid
  local selected_item_password

  local -ra fzf_opts=(
    --no-multi
    "--header=enter=password, ctrl-u=totp"
    --bind "enter:execute(echo pass,{+})+abort"
    --bind "ctrl-u:execute(echo totp,{+})+abort")

  spinner_start "Fetching items"
  items="$(get_op_items)"
  spinner_stop

  if [[ -z "$items" ]]; then

    # Needs to login
    op_login

    if [[ -z "$(op_get_session)" ]]; then
      display_message "1Password CLI signin has failed"
      return 0
    fi

    spinner_start "Fetching items"
    items="$(get_op_items)"
    spinner_stop
  fi

  selected_item="$(echo "$items" | awk -F ',' '{ print $1 }' | fzf "${fzf_opts[@]}")"

  if [[ -n "$selected_item" ]]; then
    selected_item_name=${selected_item#*,}

    selected_item_uuid="$(echo "$items" | grep "^$selected_item_name," | awk -F ',' '{ print $2 }')"

    case ${selected_item%%,*} in
      pass)
        spinner_start "Fetching password"
        selected_item_password="$(get_op_item_password "$selected_item_uuid")"
        spinner_stop
        ;;

      totp)
        spinner_start "Fetching totp"
        selected_item_password="$(get_op_item_totp "$selected_item_uuid")"
        spinner_stop
        ;;

      *)
        display_message "Unknown item request"
        ;;
    esac

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
