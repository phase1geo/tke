## api::file::all\_indices

This API procedure will return the list of all currently opened files within the application. This procedure can be useful when used within plugin actions that do not operate on a single file (i.e., on_theme_changed).

**Call structure**

`api::file::all_indices`

**Return value**

Returns a list containing the file indices of all currently opened files within the application. If no files are currently opened, an empty list will be returned.

**Parameters**

None.

**Example**

```Tcl
# Output all of the opened filenames
api::log "Opened filenames:"
foreach index [api::file::all_indices] {
  api::log "  [api::file::get_info $index fname]"
}
```