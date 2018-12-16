### syntax nextrange

Searches the text widget at the given _startpos_ index, moving towards the end of the widget until either _endpos_ index or the end of the text widget is reached.  Returns the first range of text that has the given highlight class applied to it.

**Call Structure**

`pathname syntax nextrange classname startpos ?endpos?`

**Return Value**

Returns the starting and ending range of text which has the given highlight class applied to it.  If there is no text which is has the given class applied to it before 

**Parameters**

| Parameter | Description |
| - | - |
| _classname_ | Name of class to get the next applied range to. |
| _startpos_ | Text widget index to begin searching at. |
| _endpos_ | Text widget index to stop searching at.  If this option is not specified, the end index is used. |
