## api::edit::bubble\_up

Moves the current line up by one (unless the current line is the first line in the buffer.  If any text is selected, lines containing a selection will be moved up by one line.

**Call structure**

`api::edit::bubble_up txt`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |

**Example**

	# Move the current line up
	api::edit::bubble_up $txt
