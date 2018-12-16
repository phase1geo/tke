## api::edit::bubble\_down

Moves the current line down by one (unless the current line is the last line in the buffer.  If any text is selected, lines containing a selection will be moved down by one line.

**Call structure**

`api::edit::bubble_down txt`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |

**Example**

```Tcl
# Move the current row down
api::edit::bubble_down $txt
```
