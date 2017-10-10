### inCommentString / inCommentStringRange

The inCommentString and inCommentStringRange commands return a value of true if the specified index exists within a comment or a string.  The latter will also return the range of the comment/string in the given text widget.

**Call structure**

`ctext::inCommentString pathname index`<br>
`ctext::inCommentStringRange pathname index rangeref`

**Return value**

Returns a value of true if the specified index exists within a comment or string; otherwise, returns a value of false.

**Parameters**

The _pathname_ references the ctext widget to check.  The _index_ value refers to the ctext index to check.  The _rangeref_ parameter, will be populated with a list containing the starting and ending position of the comment/string that surrounds the given index.  This value will only be valid when the procedure returns a value of true.