#!/usr/bin/env bash
# shellcheck disable=2155

cd "$(dirname "${BASH_SOURCE[0]}")" \
  || exit 1

# ------------------------------------------------------------------------------

source "./utils.sh"
source "./spinner.sh"

# ------------------------------------------------------------------------------

declare -r EXPECTED_MIN_OP_CLI_VERSION="2.0.0"
declare -r TMP_TOKEN_FILE="$HOME/.op_tmux_token_tmp"

declare -r OPT_SUBDOMAIN="$(get_tmux_option "@1password-subdomain" "my")"
declare -r OPT_VAULT="$(get_tmux_option "@1password-vault" "")"
declare -r OPT_COPY_TO_CLIPBOARD="$(get_tmux_option "@1password-copy-to-clipboard" "off")"
declare -r OPT_ITEMS_JQ_FILTER="$(get_tmux_option "@1password-items-jq-filter" "")"
declare -r OPT_DEBUG="$(get_tmux_option "@1password-debug" "off")"

declare spinner_pid=""

# ------------------------------------------------------------------------------

spinner_start() {
  if [[ "$OPT_DEBUG" == "on" ]]; then
    echo "... $1"
    return
  fi

  tput civis
  show_spinner "$1" &
  spinner_pid=$!
}

spinner_stop() {
  if [[ "$OPT_DEBUG" == "on" ]]; then
    return
  fi

  tput cnorm
  kill "$spinner_pid" &> /dev/null
  spinner_pid=""
}

# ------------------------------------------------------------------------------

op_login() {
  op signin --account="$OPT_SUBDOMAIN" --cache --session="$(op_get_session)" --force --raw > "$TMP_TOKEN_FILE"
  tput clear
}

op_get_session() {
  cat "$TMP_TOKEN_FILE" 2> /dev/null
}

get_op_items() {

  # The structure (we need) looks like the following:
  #
  # [
  #   {
  #     "uuid": "some-long-uuid",
  #     "templateUuid": "001",
  #     "overview": {
  #       "URLs": [
  #         { "u": "sudolikeaboss://local" }
  #       ],
  #       "title": "Some item",
  #       "tags": ["some_tag"]
  #     }
  #   }
  # ]
  #
  # Where `templateUuid` is:
  #   - `"001"` for a login item
  #   - `"005"` for a password item

  local JQ_FILTER

  if [[ -n "$OPT_ITEMS_JQ_FILTER" ]]; then
    JQ_FILTER="$OPT_ITEMS_JQ_FILTER"
  else
    JQ_FILTER="
      .[]
      | [
          select(
            (.category == \"LOGIN\") or
            (.category == \"PASSWORD\")
          )?
        ]
      | map([ .title, .id ]
      | join(\",\"))
      | .[]
    "
  fi

  op item list \
    --cache \
    --format=json \
    --categories="LOGIN,PASSWORD" \
    --vault="$OPT_VAULT" \
    --session="$(op_get_session)" \
    2> /dev/null \
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
      # For cases where we might get a single item - we always want to start with an array
      [.] + [] | flatten

      # Select the items whose purpose is... being a password
      | map(select(.purpose == \"PASSWORD\"))

      # Select the first one
      | .[0]

      # Return the value
      | .value
    "

  op item get "$ITEM_UUID" \
    --cache \
    --fields type=concealed \
    --format json \
    --session="$(op_get_session)" \
    | jq "$JQ_FILTER" --raw-output
}

get_op_item_totp() {
  local -r ITEM_UUID="$1"

  op --cache get totp "$ITEM_UUID" --session="$(op_get_session)"
}

verify_op_version() {
  local op_version="$(op --version)"

  utils::compare_semver "$op_version" "$EXPECTED_MIN_OP_CLI_VERSION"

  if [[ $? -eq 2 ]]; then
    display_message \
      "1Password CLI version is not compatible with this plugin: ${op_version} < ${EXPECTED_MIN_OP_CLI_VERSION}"

    return 1
  fi

  return 0
}

verify_signin() {
  local connected_accounts_count="$(( $(op account list | wc -l) - 1 ))"

  if [[ "$connected_accounts_count" -eq 0 ]]; then
    utils::ask_for_confirmation "You haven't added any accounts to 1Password CLI. Would you like to add one now?"

    if utils::answer_is_yes; then
      op account add
    else
      return 1
    fi
  fi

  op_login
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

  # Check for version
  if ! verify_op_version; then
      return 0
  fi

  # Verify signin
  if ! verify_signin; then
    display_message "1Password CLI signin has failed"
    return 0
  fi

  spinner_start "Fetching items"
  items="$(get_op_items)"
  spinner_stop

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

    if [[ "$OPT_DEBUG" == "on" ]]; then
      echo "tmux-1password: @1password-debug is on. Press [ENTER] to continue."
      read -r
    fi
  fi
}

main "$@"
