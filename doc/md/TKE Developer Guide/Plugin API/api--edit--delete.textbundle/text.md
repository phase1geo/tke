## api::edit::delete

Deletes all characters between the specified starting and ending positions for the given text widget.

**Note**: This is the preferred method of deleting text within an editing buffer.

**Call structure**

`api::edit::delete txt startpos endpos copy`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to delete text from. |
| startpos | Starting text widget index to delete from. |
| endpos | Ending text widget index to delete to.  The character located at this position will not be deleted. |
| copy | If set to 1, copies the deleted text to the clipboard. |

**Example**

```Tcl
# Deletes from the current insertion cursor to the end of the current line
api::edit::delete $txt insert [api::edit::get_index $txt lineend] 1
```