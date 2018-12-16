### getMatchBracket

Given an index, returns the index of the matching specified bracket type. It is important to note that the starting index does not need to the be index of the bracket to match. Note that unlike the getNextBracket/getPrevBracket procedures, the returned bracket index may not be the first one found before or after the index.

**Call structure**

`ctext::getMatchBracket pathname type ?index?`

**Return value**

Returns the index of the matching bracket. If no match is found, returns the empty string.

**Parameters**

| Parameter | Description |
| - | - |
| pathname | Full pathname to the text widget to search. |
| type | Specifies the type of bracket to search for. The type value used here is the same a that used in the getNextBracket / getPrevBracket procedures. If the type specified is an 'L' type, we will search backwards from the starting index position. If the type specified is an 'R' type, we will search forwards from the starting index position. |
| index | Index to begin searching from. If this value is not specified, the current insertion cursor index will be used. |

**Example**

```Tcl
# Find the surrounding curly brackets around the insertion cursor
set left  [ctext::getMatchBracket $txt curlyL]
set right [ctext::getMatchBracket $txt curlyR $left]
```