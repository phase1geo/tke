## api::edit::unformat

Removes any formatting that is applied to the selected text.

**Call structure**

`api::edit::unformat txt`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to unformat. |

**Example**

```Tcl
# Remove all formatting applied to the current line
$txt tag add sel "insert linestart" "insert lineend"
api::edit::unformat $txt
```
