## api::edit::move\_cursor

Moves the cursor to the given cursor position.  The value of position and args are the same as those of the \ref api::edit::get\_index.

**Call structure**

`api::edit::move_cursor txt pos`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to change. |
| pos | Text widget index to set the insertion cursor to. |

**Example**

	# Move the insertion cursor to the first non-whitespace character of the next line.
	api::edit::move_cursor $txt firstchar -dir next
