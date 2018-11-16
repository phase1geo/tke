### syntax clear

Removes the highlighting information for a specific class or all classes in a range of text (or the entirety of the text).  Unlike the `syntax delete` command, this command does not remove the highlight classes from memory.

**Call Structure**

`pathname syntax clear ?classname? ?startpos endpos?`

**Return Value**

None.

**Parameters**

| Parameters | Description |
| - | - |
| _classname_ | Specifies a highlight class to clear.  If a highlight class is not provided, all highlight classes will be cleared. |
| _startpos_ | Text widget index indicating the starting position to clear syntax highlighting from.  If the _startpos_ and _endpos_ parameters are omitted, all text will be cleared. |
| _endpos_ | Text widget index indicating the ending position to clear syntax highlighting. 
