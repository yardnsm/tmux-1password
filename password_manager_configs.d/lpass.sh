#!/usr/bin/env bash
OPT_LPASS_USER="$(get_tmux_option "@lastpass-username" "unset")"
declare -r FILTER_URL="https://github.com"

login(){
  if ! lpass status; then
    echo "Lastpass is not logged in."
    if [ -z "${LPUSERNAME}" ] && [ "unset" == "$OPT_LPASS_USER" ]; then
      echo "set @lastpass_username in tmux options or set LPUSERNAME to speed up this process in future"
      echo "Enter lastpass username: "
      read -r LPUSERNAME
      OPT_LPASS_USER="$LPUSERNAME"
    fi
    if [ -z "$LPUSERNAME" ]; then LPUSERNAME="$OPT_LPASS_USER"; fi
    lpass login "$LPUSERNAME"
  fi
}

get_items() {
  listcmd="lpass show --json --expand-multi -G .*"
  if $INCLUDE_PASSWORDS_IN_LOG; then
    echo INFO: All items found: > /dev/stderr # debug
    filter_list "$($listcmd | log)"
  else
    filter_list "$($listcmd)"
  fi
}

JQ_FILTER_LIST="
.[]
| [select(.url == \"$FILTER_URL\")]
| map([ .name, .id ]
| join(\",\"))
| .[]
"
filter_list(){
  local -r input="$*"
  echo $input | jq "$JQ_FILTER_LIST" --raw-output
}

get_item_password() {
  local -r ITEM_UUID="$1"
  getcmd="lpass show -p"
  if $INCLUDE_PASSWORDS_IN_LOG; then
    echo DEBUG: \`$getcmd\` output: > /dev/stderr # debug
    $getcmd $ITEM_UUID | log
  else
    $getcmd $ITEM_UUID
  fi
}
