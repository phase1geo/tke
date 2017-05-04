## api::edit::indent

Indents the given range of text between startpos and endpos-1, inclusive, by one level of indentation.  If text is currently selected, the selected text is indented instead.

**Call structure**

`api::edit::indent txt ?startpos ?endpos??`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |
| startpos | Starting position of text to indent. Indentation will be performed on the whole line that this index is on. Defaults to the current insertion point. |
| endpos | Ending position of text to indent. Indentation will be performed on the whole line that this index is on. Defaults to the current insertion point. |

**Example**

	# Indent the current paragraph
	set startpos [api::edit::get_index $txt paragraph -dir prev]
	set endpos [api::edit::get_index $txt paragraph -dir next -startpos $startpos]
	
	api::edit::indent $txt $startpos $endpos
