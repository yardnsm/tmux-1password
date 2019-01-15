# tmux-1password

[![Build Status](https://travis-ci.org/yardnsm/tmux-1password.svg?branch=master)](https://travis-ci.org/yardnsm/tmux-1password)

> Access your password manager login items within tmux!

![](.github/screenshot.gif)

This plugin allows you to access you password items within tmux, using a password manager's CLI.

Supported managers:

* Personal 1Password accounts, as well as teams accounts
* lastpass-cli

In the works:

* 1pass (`on` wrapper)

Additional managers should be easy to integrate, especially if they can output `json` format.

## Requirements

This plugin relies on the following:

- [1Password CLI](https://support.1password.com/command-line-getting-started/) (or other cli)
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

## Usage

First, sign in with the CLI by running the following in your terminal (you only need to do
this *once*)(1Password example provided):

```console
$ op signin <signinaddress> <emailaddress> <secretkey>
```

For 1Password personal accounts, `<signinaddress>` should be `my.1password.com`. If you're using a
team account, configure the [`@1password-subdomain`](#setting-the-signin-subdomain) option.

From now on, initiate the plugin by using the keybind (`prefix + u` by default). A new pane will be
opened in the bottom, listing the appropriate login items. Press `<Enter>` to choose a login item,
and its password will automatically be filled.

You may be required to perform a re-login (directly in the opened pane) since the 1Password CLI's
sessions expires automatically after 30 minutes of inactivity.

If your manager logs you out (or some other error means no login items can be found) you will be asked to log in again.

### Showing login items from manager

In order to show only relevant login items and to maintain compatibility with
[sudolikeaboss](https://github.com/ravenac95/sudolikeaboss), its required to set the value of the
`website` or `url` field for each login item with the value of `sudolikeaboss://local`.

## Configuration

Customize this plugin by setting these options in your `.tmux.conf` file. Make sure to reload the
environment afterwards.

#### Set Lastpass username (required when logging in again)

```
set -g @lastpass-username 'x'
```

#### Changing the default manager for this plugin

This should be the command typed at the prompt.

```
set -g @password-manager-cmd 'op'
```

#### Changing the default key-binding for this plugin

```
set -g @1password-key 'x'
```

Default: `'u'`

#### Setting the 1Password signin subdomain

```
set -g @1password-subdomain 'acme'
```

Default: `'my'`

#### Setting the default 1Password vault

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

## Prior art

Also see:

- [sudolikeaboss](https://github.com/ravenac95/sudolikeaboss)

---

## Adding new managers

Read password_manager_configs.d/configuring_managers.md

## License

MIT © [Yarden Sod-Moriah](http://yardnsm.net/)
