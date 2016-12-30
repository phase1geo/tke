### inDoubleQuote

The inDoubleQuote command returns a value of true if the specified index exists within a double-quoted string.  It can also return the range of the string in the given text widget.

**Call structure**

`ctext::inDoubleQuote pathname index ?rangeref?`

**Return value**

Returns a value of true if the specified index exists within a double-quoted string; otherwise, returns a value of false.

**Parameters**

The _pathname_ references the ctext widget to check.  The _index_ value refers to the ctext index to check.  The _rangeref_ parameter, if specified, will be populated with a list containing the starting and ending position of the string that surrounds the given index.  This value will only be valid when the procedure returns a value of true.