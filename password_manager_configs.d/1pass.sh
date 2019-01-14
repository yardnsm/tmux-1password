#!/usr/bin/env bash
# vim:ts=2:sw=2
logincmd="1pass"
otherOptsLogin=""
listcmd="1pass"
otherOptsList=""
getcmd="-p"
otherOptsGet=""


USE_CUSTOM_FILTERS=true

JQ_FILTER_LIST="
.[]
| [select(.url == \"$FILTER_URL\")]
| map([ .name, .name ]
| join(\",\"))
| .[]
"
JQ_FILTER_GET=".[].password"
JQ_FILTER_LIST="
.[]
| [select(.overview.URLs | map(select(.u == \"sudolikeaboss://local\")) | length == 1)?]
| map([ .overview.title, .uuid ]
| join(\",\"))
| .[]
"
JQ_FILTER_GET="
.details
| if .password then
.password
  else
    .fields[]
    | select (.designation == \"password\")
    | .value
  end
"

convertToJson(){
  input="$*"
  output=""
  json="[{}]"
  # for line in $input; do
  #   json=$(jq "add_element")
  # done
}

# 1pass can only do 2 things: list names, and return a password. Tricky to convert to json...
filter_list_custom(){
  local -r input="$*"
  convertToJson "$input"
  echo $input | jq "$JQ_FILTER_LIST" --raw-output
}

filter_get_custom(){
  local -r input="$*"
  echo $input | jq "$JQ_FILTER_GET" --raw-output
}
