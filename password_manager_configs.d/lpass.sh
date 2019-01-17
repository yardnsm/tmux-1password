#!/usr/bin/env bash
# vim:ts=2:sw=2
logincmd="login"
OPT_LPASS_USER="$(get_tmux_option "@lastpass-username" "unset")"

lastpass_login(){
  if ! lpass status; then
    echo "Lastpass is not logged in."
    if [ -z "${LPUSERNAME}" ] && [ "unset" == "$OPT_LPASS_USER" ]; then
      echo "set @lastpass_username in tmux options or set LPUSERNAME to speed up this process in future"
      read -r -p "Enter lastpass username : " LPUSERNAME
      OPT_LPASS_USER="$LPUSERNAME"
    fi
    if [ -z "$LPUSERNAME" ]; then LPUSERNAME="$OPT_LPASS_USER"; fi
    lpass login "$LPUSERNAME"
  fi
}
lastpass_login

otherOptsLogin="$OPT_LPASS_USER"
# listcmd="ls"
# Creates an output that will match 1pass's output
# 1pass_format_str=" [{ \"uuid\": \"%ai\", \"overview\": { \"URLs\": [ {\"u\": \"%al\" } ], \"title\": \"%an\" } }] "
listcmd="show --json --expand-multi -G"
otherOptsList=".*"
getcmd="show"
otherOptsGet="--json"

JQ_FILTER_LIST="
.[]
| [select(.url == \"$FILTER_URL\")]
| map([ .name, .id ]
| join(\",\"))
| .[]
"
JQ_FILTER_GET=".[].password"
