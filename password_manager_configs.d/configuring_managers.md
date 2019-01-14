Files in this directory needs to declare variables `logincmd`, `listcmd`, and `getcmd`.

They also need to declare two functions:

* `filter_list` that takes as a parameter the output of `listcmd`,
and returns "`name`,`uuid`", where:

    - `name` = a human-readable identifier
    - `uuid` = a unique identifier.

* `filter_get` that takes the output of `getcmd` and returns the password only.
