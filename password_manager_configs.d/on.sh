#!/usr/bin/env bash
# vim:ts=2:sw=2
logincmd="signin"
otherOptsLogin="\"$OPT_SUBDOMAIN\" --output=raw"
listcmd="list items"
otherOptsList="--vault=\"$OPT_VAULT\" --session=\"$(get_session)\""
getcmd="get item"
otherOptsGet="--session=\"$(get_session)\""

filter_list(){
  # The structure to be filtered from `on show items` is this:
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
  read input
  local -r JQ_FILTER="
  .[]
  | [select(.overview.URLs | map(select(.u == \"sudolikeaboss://local\")) | length == 1)?]
  | map([ .overview.title, .uuid ]
  | join(\",\"))
  | .[]
  "
  echo $input | jq "$JQ_FILTER" --raw-output
}

filter_get(){
  # There are two different kind of items that
  # we support: login items and passwords.
  #
  # * Login items:
  #       {
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
  read input
  local -r JQ_FILTER="
    .details
    | if .password then
    .password
  else
    .fields[]
    | select (.designation == \"password\")
    | .value
  end
"
echo $input | jq "$JQ_FILTER" --raw-output
}
