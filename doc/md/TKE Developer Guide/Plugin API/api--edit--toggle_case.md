## api::edit::toggle\_case

Toggles the case of all characters in the range of startpos to endpos-1, inclusive.  If text is selected, the selected text is toggled instead of the given range.

**Call structure**

`api::edit::toggle_case txt startpos endpos`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |
| startpos | Starting text widget index to toggle. |
| endpos | Ending text widget index of range to toggle. The character at this position will not be toggled. |

**Example**

```Tcl
# Toggle the case of the current sentence
set sentence_start [api::edit::get_index $txt sentence -dir prev]
set sentence_end   [api::edit::get_index $txt sentence -dir next -startpos $sentence_start]
	
api::edit::toggle_case $txt $sentence_start $sentence_end
```
