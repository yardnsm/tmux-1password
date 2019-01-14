#!/bin/bash
filter="'.[] | [select(.overview.URLs | map(select(.u == \"wiggle.co.nz\")) | length == 1)?] | map([ .overview.title, .uuid ] | join(\",\")) | .[] '"
lpass show --json --expand-multi -G '.*' | jq $filter
