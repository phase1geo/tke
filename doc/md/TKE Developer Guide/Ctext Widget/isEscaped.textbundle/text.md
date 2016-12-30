### isEscaped

The isEscaped command returns a value of true if the specified character has an odd number of subsequent escape (\\) characters preceding it on the same line.  This procedure has been optimized for speed so it is recommended to use this if this information needs to be retrieved.

**Call structure**

`ctext::isEscaped pathname index`

**Return value**

Returns a value of true if the character at the given index is immediately preceded by an odd number of escape (\\) characters; otherwise, returns a value of false.

**Parameters**

The _pathname_ references the ctext widget to check.  The _index_ value refers to the ctext index to check.