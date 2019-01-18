#!/usr/bin/env bash
login(){
  1pass -rv
}
get_items(){
  1pass
}

filter_get_custom(){
  local -r input="$*"
  echo 1pass -p $input
}
get_items() {
  echo INFO: All items found: > /dev/stderr # debug
  itemlist="$(1pass | log)"
  while read -r line; do
    # Double the input (uses the name as the uuid).
    echo "$line" | awk '{print $0 "," $0}'
  done <<< "$itemlist"
}

get_item_password() {
  local -r ITEM_UUID="$1"
  getcmd="1pass -p \"$ITEM_UUID\""
  if $INCLUDE_PASSWORDS_IN_LOG; then
    echo DEBUG: `1pass -p` output: > /dev/stderr # debug
    $getcmd | log
  else
    $getcmd
  fi
}
