### inLineComment / inLineCommentRange

The inLineComment and inLineCommentRange commands return a value of true if the specified index exists within a line comment.  The latter will also return the range of the comment in the given text widget.

**Call structure**

`ctext::inLineComment pathname index`
`ctext::inLineCommentRange pathname index rangeref`

**Return value**

Returns a value of true if the specified index exists within a line comment; otherwise, returns a value of false.

**Parameters**

The _pathname_ references the ctext widget to check.  The _index_ value refers to the ctext index to check.  The _rangeref_ parameter, will be populated with a list containing the starting and ending position of the comment that surrounds the given index.  This value will only be valid when the procedure returns a value of true.