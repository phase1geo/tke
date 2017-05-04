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

	# Join the next three lines to the current line
	api::join_lines $txt 3
