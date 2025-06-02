#!/usr/bin/env bash

# ------------------------------------------------------------------------------

declare -r OP_RECENT_FILE=~/.op_tmux_recent

recent::file() {
  echo "${OP_RECENT_FILE}_$(options::op_account)"
}

recent::add() {
  local recent=$(tmux::get_option "@1password-recent" "0")
  local recents

  if [[ $recent -eq 0 ]]; then
    rm -f "$(recent::file)"
  else
    echo $1 >> "$(recent::file)"
    recents=$(cat "$(recent::file)")
    echo "$recents" | tac | awk '!seen[$0]++' | tac | tail -n $recent > "$(recent::file)"
  fi
}

recent::get() {
  local recent=$(tmux::get_option "@1password-recent" "0")

  if [[ $recent -eq 0 ]]; then
    rm -f "$(recent::file)"
  elif [ -f "$(recent::file)" ]; then
    cat "$(recent::file)" | tac
  fi
}

recent::get_all_items() {
  local op_items="$1"
  local recent_item
  local rencent_items=$(recent::get)

  if ! [[ -z "$rencent_items" ]]; then
    while IFS= read recent_item; do
      echo $(echo "$op_items" | grep "^$recent_item,")
      op_items=$(echo "$op_items" | grep -v "^$recent_item,")
    done <<< "$(echo -e "$rencent_items")"
  fi

  echo "$op_items"
}
