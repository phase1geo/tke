## api::edit::upper\_case

Transforms all text in the given range of startpos to endpos-1, inclusive, to upper case.  If text is selected, the selected text is transformed instead of the given range.

**Call structure**

`api::edit::upper_case txt startpos endpos`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |
| startpos | Starting text widget index of range to uppercase. |
| endpos | Ending text widget index of range to uppercase. The character at this position will not be modified. |

**Example**

```Tcl
# Make the previous character uppercase
api::edit::upper_case $txt insert-1c insert
```
