#!/usr/bin/env bash

# ------------------------------------------------------------------------------

get_tmux_option() {
  local option=$1
  local default_value=$2
  local option_value; option_value=$(tmux show-option -gqv "$option")

  if [[ -z "$option_value" ]]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

display_message() {
  tmux display-message "tmux-1password: $1"
}

is_cmd_exists() {
  command -v "$1" &> /dev/null
  return $?
}

copy_to_clipboard() {
  if [[ "$(uname)" == "Darwin" ]] && is_cmd_exists "pbcopy"; then
    echo -n "$1" | pbcopy
  elif [[ "$(uname)" == "Linux" ]] && is_cmd_exists "xsel"; then
    echo -n "$1" | xsel -b
  elif [[ "$(uname)" == "Linux" ]] && is_cmd_exists "xclip"; then
    echo -n "$1" | xclip -i
  else
    return 1
  fi
}

clear_clipboard() {
  local -r SEC="$1"

  if [[ "$(uname)" == "Darwin" ]] && is_cmd_exists "pbcopy"; then
    tmux run-shell -b "sleep $SEC && echo '' | pbcopy"
  elif [[ "$(uname)" == "Linux" ]] && is_cmd_exists "xclip"; then
    tmux run-shell -b "sleep $SEC && echo '' | xclip -i"
  else
    return 1
  fi
}

# Shamelessly taken from:
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash/4025065#4025065
utils::compare_semver() {
    if [[ $1 == $2 ]]; then
        return 0
    fi

    local IFS="."
    local i
    local version_1="$1"
    local version_2="$2"

    # Fill empty fields in version_1 with zeros
    for ((i=${#version_1[@]}; i<${#version_2[@]}; i++)); do
        version_1[i]=0
    done

    for ((i=0; i<${#version_1[@]}; i++)); do
        if [[ -z ${version_2[i]} ]]; then
            # Fill empty fields in version_2 with zeros
            version_2[i]=0
        fi

        if ((10#${version_1[i]} > 10#${version_2[i]})); then
            return 1
        fi

        if ((10#${version_1[i]} < 10#${version_2[i]})); then
            return 2
        fi
    done

    return 0
}

utils::ask_for_confirmation() {
  local question="$1"

  printf "\\e[0;33m[?]\\e[0m %b [y/N] " "$question"
  read -r -n 1
  echo -ne "\n"
}

utils::answer_is_yes() {
  [[ "$REPLY" =~ ^[Yy]$ ]] \
    && return 0 \
    || return 1
}
