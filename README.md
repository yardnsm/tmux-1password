# tmux-1password

[![Build Status](https://github.com/yardnsm/tmux-1password/workflows/main/badge.svg)](https://github.com/yardnsm/tmux-1password/actions)

> Access your 1Password login items within tmux!

https://user-images.githubusercontent.com/11786506/159118616-9983fca2-edb5-4d0b-b827-43088e84d2c8.mp4

This plugin allows you to access you 1Password items within tmux, using 1Password's CLI. It works
for personal 1Password accounts, as well as teams accounts.

## Requirements

This plugin relies on the following:

- [1Password CLI](https://developer.1password.com/docs/cli) >= 2.0.0
- [fzf](https://github.com/junegunn/fzf)
- [jq](https://stedolan.github.io/jq/)

## Key bindings

In any tmux mode:

- `prefix + u` - list login items in a bottom pane.

## Install

### Using [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

1. Add plugin to the list of TPM plugins in `.tmux.conf`:

    ```
    set -g @plugin 'yardnsm/tmux-1password'
    ```

2. Hit `prefix + I` to fetch the plugin and source it. You should now be able to use the plugin.

### Manual Installation

1. Clone this repo:

    ```console
    $ git clone https://github.com/yardnsm/tmux-1password ~/some/path
    ```

2. Source the plugin in your `.tmux.conf` by adding the following to the bottom of the file:

    ```
    run-shell ~/some/path/plugin.tmux
    ```

3. Reload the environment by running:

    ```console
    $ tmux source-file ~/.tmux.conf
    ```

### Using older versions of 1Password's CLI

If you're using an older version of the CLI (`< 2.0`), you can use this plugin via the
[`legacy`](https://github.com/yardnsm/tmux-1password/tree/legacy) branch. For example, using TPM:

```
set -g @plugin 'yardnsm/tmux-1password#legacy'
```

## Usage

Initiate the plugin by using the keybind (`prefix + u` by default). If you haven't added an account
to the 1Password's CLI, the plugin will prompt you to add one. You can also manage your connected
accounts manually using the [`op account`
command](https://developer.1password.com/docs/cli/reference/management-commands/account).

Once you have an account, while initiating the plugin a new pane will be opened in the bottom,
listing the appropriate login items. Press `<Enter>` to choose a login item, and its password will
automatically be filled.

You can also press `Ctrl+u` while hovering an item to fill a [One-Time
Password](https://support.1password.com/one-time-passwords/).

You may be required to perform a re-login (directly in the opened pane) since the 1Password CLI's
sessions expires automatically after 30 minutes of inactivity.

### Biometric Unlock

For supported systems, you can enable [signing in with biometric
unlock](https://developer.1password.com/docs/cli/about-biometric-unlock). When biometric unlock is
enabled, you'll be prompted to authorize using it when then plugin is being initiated.

## Configuration

Customize this plugin by setting these options in your `.tmux.conf` file. Make sure to reload the
environment afterwards.

#### Changing the default key-binding for this plugin

```
set -g @1password-key 'x'
```

Default: `'u'`

#### Setting the sign-in account

1Password's CLI allows signing in with [multiple
accounts](https://developer.1password.com/docs/cli/use-multiple-accounts/), while this plugin is
able to work against a single one. You can specify which account to use using this option.

As per the
[documentation](https://developer.1password.com/docs/cli/use-multiple-accounts/#find-an-account-shorthand-and-id),
you can use the shorthand, sign-in address, or account ID to refer to a specific account.

```
set -g @1password-account 'acme'
```

Default: `'my'`

#### Setting the default vault

```
set -g @1password-vault 'work'
```

Default: `''` (all vaults)

#### Copy the password to clipboard

By default, the plugin will use `send-keys` to send the selected password to the targeted pane. By
setting the following, the password will be copied to the system's clipboard, which will be cleared
after 30 seconds.

```
set -g @1password-copy-to-clipboard 'on'
```

Default: `'off'`

#### Filter items via tags

By default, all of the items will be shown. You can use this option (comma-separated) if you want to
list items that has specific tags.

```
set -g @1password-filter-tags 'development,servers'
```

Default: `''` (no tag filtering)

#### Debug mode

If you're having any trouble with the plugin and would like to debug it's output in a more
convenient way, this option will prevent the pane from being closed.

```sh
set -g @1password-debug 'on'

# Or running the following withing tmux:
tmux set-option -g @1password-debug "on"

```

## Prior art

Also see:

- [sudolikeaboss](https://github.com/ravenac95/sudolikeaboss)

---

## License

MIT © [Yarden Sod-Moriah](http://yardnsm.net/)
