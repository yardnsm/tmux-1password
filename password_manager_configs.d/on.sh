#!/usr/bin/env bash

declare -r OPT_SUBDOMAIN="$(get_tmux_option "@1password-subdomain" "my")"
declare -r OPT_VAULT="$(get_tmux_option "@1password-vault" "")"

declare -r TMP_TOKEN_FILE="$HOME/.op_tmux_token_tmp"
declare -r FILTER_URL="sudolikeaboss://local"

get_session() {
  cat "$TMP_TOKEN_FILE" 2> /dev/null
}
login(){
  on signin "$OPT_SUBDOMAIN" --output=raw > "$TMP_TOKEN_FILE"
  if [ -z "$(get_session)" ]; then
    display_message "1Password CLI signin has failed"
    return 0
  fi
}

get_items() {
  listcmd="list items --vault=\"$OPT_VAULT\" --session=\"$(get_session)\""
  echo INFO: All items found: > /dev/stderr # debug
  filter_list "$($listcmd | log)"
}

# The structure to be filtered from `on list items` is this:
# [
#   {
#     "uuid": "some-long-uuid",
#     "overview": {
#       "URLs": [
#         { "u": "sudolikeaboss://local" }
#       ],
#       "title": "Some item"
#     }
#   }
# ]
JQ_FILTER_LIST="
.[]
| [select(.overview.URLs | map(select(.u == \"$FILTER_URL\")) | length == 1)?]
| map([ .overview.title, .uuid ]
| join(\",\"))
| .[]
"

filter_list(){
  local -r input="$*"
  echo $input | jq "$JQ_FILTER_LIST" --raw-output
}

get_item_password() {
  local -r ITEM_UUID="$1"
  getcmd="get item --session=\"$(get_session)\""
  if $INCLUDE_PASSWORDS_IN_LOG; then
    echo DEBUG: \`on get item\` output: > /dev/stderr # debug
    filter_get "$($getcmd $ITEM_UUID)" | log
  else
    filter_get "$($getcmd $ITEM_UUID)"
  fi
}


# There are two different kind of items that
# we support: login items and passwords.
#
# * Login items: {
#         "details": {
#           "fields": [
#             {
#               "designation": "password",
#               "value": "supersecret"
#             }
#           ]
#         }
#       }
#
# * Password:
#       {
#         "details": {
#           "password": "supersecret"
#         }
#       }
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
filter_get(){
  local -r input="$*"
  echo $input | jq "$JQ_FILTER_GET" --raw-output
}
