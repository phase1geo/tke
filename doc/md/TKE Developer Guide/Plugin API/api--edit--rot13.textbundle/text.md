## api::edit::rot13

Transforms all text in the given range of startpos to endpos-1, inclusive, to its rot13 equivalent.  If text is selected, the selected text is transformed instead of the given range.

The rot13 encoding transforms each character by rotating it character by 13 characters in the alphabet (i.e., an 'a' would be changed to an 'n' and vice versa). This is a simple/poor method for encoding information. It can be decoded by performing the transformation on the same text a second time.

**Call structure**

`api::edit::rot13 txt startpos endpos`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to rot13. |
| startpos | Starting text widget index in range to modify. |
| endpos | Ending text widget index in range to modify. The character at this index will not be modified. |

**Example**

	# Encode the entire file using rot13
	api::edit::rot13 $txt 1.0 end
