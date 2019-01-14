#!/usr/bin/env bash
# vim:ts=2:sw=2
logincmd="signin"
otherOptsLogin="\"$OPT_SUBDOMAIN\" --output=raw"
listcmd="list items"
otherOptsList="--vault=\"$OPT_VAULT\" --session=\"$(get_session)\""
getcmd="get item"
otherOptsGet="--session=\"$(get_session)\""

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
JQ_FILTER_LIST="
.[]
| [select(.overview.URLs | map(select(.u == \"sudolikeaboss://local\")) | length == 1)?]
| map([ .overview.title, .uuid ]
| join(\",\"))
| .[]
"

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
