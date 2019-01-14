Files in this directory needs to declare variables `logincmd`, `listcmd`, and `getcmd`.

They also need to declare a function called `filter_list` that takes the output
of `listcmd` and returns only the records you need, and a function called
`filter_get` that takes the output of `getcmd` and returns the password only.
