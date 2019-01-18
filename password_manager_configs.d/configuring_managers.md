Files in this directory need to be named `[password manager cli command].sh` and should declare several functions:

* `login`
    * Should log in to the manager, asking the user for whatever input is needed. 
* `get_items`
    * Should return a string containing "name,uuid" on one line per entry, where:
        - `name` = a human-readable identifier
        - `uuid` = a unique identifier
* `get_item_password`
    * Should take the `uuid` and return the associated password.

The output of these functions should be `tee`ed to `/dev/stderr` so it can be outputted in debug mode.

Note: use `if $INCLUDE_PASSWORDS_IN_LOG; then` before sending any passwords to stderr.
