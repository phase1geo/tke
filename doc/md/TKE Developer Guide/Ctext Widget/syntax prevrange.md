## syntax prevrange

Searches the text widget at the given _startpos_ index, moving towards the beginning of the widget until either _endpos_ index or the beginning of the text widget is reached.  Returns the first range of text that has the given highlight class applied to it.

**Call Structure**

`pathname syntax prevrange classname startpos ?endpos?`

**Return Value**

Returns the starting and ending range of text which has the given highlight class applied to it.  If there is no text which is has the given class applied to it before the empty string is returned.

**Parameters**

| Parameter | Description |
| - | - |
| _classname_ | Name of class to get the previous applied range of. |
| _startpos_ | Text widget index to begin searching at. |
| _endpos_ | Text widget index to stop searching at.  If this option is not specified, the beginning index is used. | 