## api::edit::lower\_case

Transforms all text in the given range of startpos to endpos-1, inclusive, to lower case.  If text is selected, the selected text is transformed instead of the given range.

**Call structure**

`api::edit::lower_case txt startpos endpos`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |
| startpos | Starting text widget index of range to lowercase. |
| endpos | Ending text widget index of range to lowercase. The character at this position will not be modified. |

**Example**

	# Make the current character lowercased
	api::edit::lower_case $txt insert "insert+1c"
