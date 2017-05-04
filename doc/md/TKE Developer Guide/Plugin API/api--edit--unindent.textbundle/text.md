## api::edit::unindent

Unindents the given range of text between startpos and endpos-1, inclusive, by one level of indentation.  If text is currently selected, the selected text is unindented instead.

**Call structure**

`api::edit::unindent txt ?startpos ?endpos??`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |
| startpos | Starting position of text to indent. Indentation will be performed on the whole line that this index is on. Defaults to the current insertion point if not specified. |
| endpos | Ending position of text to indent. Indentation will be performed on the whole line that this index is on. Defaults to the current insertion point if not specified.

**Example**

	# Unindent the line above the current line
	api::edit::unindent $txt [api::edit::get_index $txt up]
