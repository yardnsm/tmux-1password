Files in this directory need to be named `[password manager cli command].sh` and should declare several variables:

* `logincmd`
* `listcmd`
* `getcmd`
* `JQ_FILTER_LIST`
* `JQ_FILTER_GET`

`listcmd` and `getcmd` should return a .json.

* `JQ_FILTER_LIST` is a string containing a JQ_FILTER that takes the output of `listcmd`,
and returns "`name`,`uuid`", where:

    - `name` = a human-readable identifier
    - `uuid` = a unique identifier.

* `JQ_FILTER_GET` that takes the output of `getcmd` and returns the password only.

