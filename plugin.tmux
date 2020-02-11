#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
  || exit 1

# ------------------------------------------------------------------------------

source "./scripts/utils.sh"

# ------------------------------------------------------------------------------

declare -r CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

declare -a REQUIRED_COMMANDS=(
  'op'
  'jq'
  'fzf'
)

# ------------------------------------------------------------------------------

main() {
  for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! is_cmd_exists "$cmd"; then
      display_message "command '$cmd' not found"
      return 1
    fi
  done

  local -r opt_key="$(get_tmux_option "@1password-key" "u")"
  local -r clear_key="$(get_tmux_option "@1password-key" "C")"

  tmux bind-key "$opt_key" \
    run "tmux split-window -l 10 \"$CURRENT_DIR/scripts/main.sh '#{pane_id}'\""

  tmux bind-key "$clear_key" run "$CURRENT_DIR/scripts/main.sh clear-cache"
}

main "$@"
