## api::edit::title\_case

Transforms all text in the given range of startpos to endpos-1, inclusive, to title case (first character of each word is capitalized while the rest of the characters are set to lowercase).

**Call structure**

`api::edit::title_case txt startpos endpos`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |
| startpos | Starting text widget index in range to modify. |
| endpos | Ending text widget index in range to modify. The character at this position will not be modified. |

**Example**

```Tcl
# Titlecase all text within the next set of double-quotes
set startpos [api::edit::get_index $txt findchar -char \" -dir next -num 1]
set endpos   [api::edit::get_index $txt findchar -char \" -dir next -num 2]
	
api::edit::title_case $txt $startpos $endpos
```
