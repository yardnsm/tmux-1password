#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
  || exit 1

# ------------------------------------------------------------------------------

source "./scripts/utils/cmd.sh"
source "./scripts/utils/tmux.sh"

source "./scripts/options.sh"

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
    if ! cmd::exists "$cmd"; then
      tmux::display_message "command '$cmd' not found"
      return 1
    fi
  done

  tmux bind-key "$(options::keybinding)" \
    run "tmux split-window -l 10 \"$CURRENT_DIR/scripts/main.sh '#{pane_id}'\""
}

main "$@"
