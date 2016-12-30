### diff ranges

Returns a list of text indices that specify the start and end ranges of text marked as different in the Ctext widget.  The differences from the first file (sub), second file (add) or both can be returned.  All indices are returned in index order.

**Call structure**

`pathname diff ranges type`

**Return value**

A Tcl list containing an even number of text indices specifying the start and end of each difference range.

**Parameters**

| Parameter | Description |
| - | - |
| type | One of three values: <ul><li>sub = returns the ranges of all differences in the first file</li><li>add = returns the ranges of all differences in the second file</li><li>both = returns the ranges of all differences in both files</li></ul> |

