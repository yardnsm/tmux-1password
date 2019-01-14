#!/usr/bin/env bash
# vim:ts=2:sw=2
logincmd="login"
if [ "$OPT_LPASS_USER" == "unset" ]; then
  echo "set @lastpass_username in tmux options"
  sleep 5
  exit
fi
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
