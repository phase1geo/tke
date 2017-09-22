### commentCharRanges

The commentCharRanges command returns a Tcl list containing 3 or 4 ctext index values which contain positional information for a comment which contains the index parameter. If the specified index is not within a comment, the empty list is returned. The returned list will contain the following information:

1. The starting index of the entire comment block.
2. The ending index of the start comment syntax.
3. The starting index of the end comment syntax.
4. The ending index of the entire comment block.

**Call structure**

`ctext::commentCharRanges pathname index`

**Return value**

Returns a Tcl list containing positional text widget indices for the comment block that contains the _index_ parameter. See the above description for details.

**Parameters**

The _index_ value refers to the ctext index which is potentially contained within a comment block, including the comment begin/end syntax characters.