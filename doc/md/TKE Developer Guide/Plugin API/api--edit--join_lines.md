## api::edit::join\_lines

Joins the given number of lines, guaranteeing that on a single space separates the text of each joined line, starting at the current insertion cursor position.  If text is selected, any line that contains a selection will be joined together.

**Call structure**

`api::edit::join_lines txt ?num?`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |
| num | Number of lines below the current line to join to the current line. Default is 1. |

**Example**

```Tcl
# Output all of the opened filenames
api::log "Opened filenames:"
foreach index [api::file::all_indices] {
  api::log "  [api::file::get_info $index fname]"
}
```
