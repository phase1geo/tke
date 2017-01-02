### inBlockComment / inBlockCommentRange

The inBlockComment and inBlockCommentRange commands return a value of true if the specified index exists within a block comment.  The latter will also return the range of the comment in the given text widget.

**Call structure**

`ctext::inBlockComment pathname index`
`ctext::inBlockCommentRange pathname index rangeref`

**Return value**

Returns a value of true if the specified index exists within a block comment; otherwise, returns a value of false.

**Parameters**

The _pathname_ references the ctext widget to check.  The _index_ value refers to the ctext index to check.  The _rangeref_ parameter, will be populated with a list containing the starting and ending position of the block comment that surrounds the given index.  This value will only be valid when the procedure returns a value of true.