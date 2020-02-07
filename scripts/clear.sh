#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
  || exit 1

# ------------------------------------------------------------------------------

source "./utils.sh"

# ------------------------------------------------------------------------------

clear() {
  clear_cache
}

clear_cache() {
  local -r CACHE_FILE="/tmp/tmux-op-items"

  rm $CACHE_FILE

  display_message "Cache cleared"
}

clear
