#!/usr/bin/env bash

# ------------------------------------------------------------------------------

declare -r __DEPRECATED_OPT_SUBDOMAIN="$(tmux::get_option "@1password-subdomain" "")"

declare -r OPT_KEYBINDING="$(tmux::get_option "@1password-key" "u")"
declare -r OPT_ACCOUNT="$(tmux::get_option "@1password-account" "my")"
declare -r OPT_VAULT="$(tmux::get_option "@1password-vault" "")"
declare -r OPT_FILTER_TAGS="$(tmux::get_option "@1password-filter-tags" "")"
declare -r OPT_COPY_TO_CLIPBOARD="$(tmux::get_option "@1password-copy-to-clipboard" "off")"
declare -r OPT_DEBUG="$(tmux::get_option "@1password-debug" "off")"

# ------------------------------------------------------------------------------

options::keybinding() {
  echo "$OPT_KEYBINDING"
}

options::op_account() {
  if [[ -n "$__DEPRECATED_OPT_SUBDOMAIN" ]]; then
    echo "$__DEPRECATED_OPT_SUBDOMAIN"
  else
    echo "$OPT_ACCOUNT"
  fi
}

options::op_valut() {
  echo "$OPT_VAULT"
}

options::op_filter_tags() {
  echo "$OPT_FILTER_TAGS"
}

options::copy_to_clipboard() {
  [[ "$OPT_COPY_TO_CLIPBOARD" == "on" ]]
  return $?
}

options::debug_mode() {
  [[ "$OPT_DEBUG" == "on" ]]
  return $?
}
