#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
  || exit 1

# ------------------------------------------------------------------------------

source "./utils/clipboard.sh"
source "./utils/cmd.sh"
source "./utils/op.sh"
source "./utils/prompt.sh"
source "./utils/semver.sh"
source "./utils/spinner.sh"
source "./utils/tmux.sh"

source "./options.sh"

# ------------------------------------------------------------------------------

main() {
  local -r ACTIVE_PANE="$1"

  local items
  local selected_item
  local selected_item_name
  local selected_item_uuid
  local selected_item_password
  local synchronize_panes_reset_value

  local -ra fzf_opts=(
    --no-multi
    "--header=enter=password, ctrl-u=totp"
    --bind "enter:execute(echo pass,{+})+abort"
    --bind "ctrl-u:execute(echo totp,{+})+abort"
  )

  # Check for version
  if ! op::verify_version; then
      return 0
  fi

  # Verify current session
  if ! op::verify_session; then
    tmux::display_message "1Password CLI signin has failed"
    return 0
  fi

  spinner::start "Fetching items"
  items="$(op::get_all_items)"
  spinner::stop

  synchronize_panes_reset_value=$(tmux::disable_synchronize_panes)

  selected_item="$(echo "$items" | awk -F ',' '{ print $1 }' | fzf "${fzf_opts[@]}")"

  tmux::set_synchronize_panes "${synchronize_panes_reset_value}"

  if [[ -n "$selected_item" ]]; then
    selected_item_name=${selected_item#*,}
    selected_item_uuid="$(echo "$items" | grep "^$selected_item_name," | awk -F ',' '{ print $2 }')"

    case ${selected_item%%,*} in
      pass)
        spinner::start "Fetching password"
        selected_item_password="$(op::get_item_password "$selected_item_uuid")"
        spinner::stop
        ;;

      totp)
        spinner::start "Fetching totp"
        selected_item_password="$(op::get_item_totp "$selected_item_uuid")"
        spinner::stop
        ;;

      *)
        tmux::display_message "Unknown item request"
        ;;
    esac

    if options::copy_to_clipboard; then

      # Copy password to clipboard
      clipboard::copy "$selected_item_password"

      # Clear clipboard
      clipboard::clear 30
    else

      # Use `send-keys`
      tmux send-keys -t "$ACTIVE_PANE" "$selected_item_password"
    fi

    if options::debug_mode; then
      echo "tmux-1password: @1password-debug is on. Press [ENTER] to continue."
      read -rs
    fi
  fi
}

main "$@"
