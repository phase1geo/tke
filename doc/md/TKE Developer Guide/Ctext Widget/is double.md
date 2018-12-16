### is double

This command determines if the given character is an unescaped double-quote
character (") on the left or right side of a double-quoted string.  It is
written to be highly performant and its usage is encouraged.

**Call structure**

`pathname is double index ?side?

**Return value**

Returns true if the given character is an unescaped double-quote character.

**Parameters**

| Parameter | Description |
| - | - |
| index | Index of character to check. |
| side | Specifies which double-quote we want to check.  Valid values are:  **left**, **right** or **any**.  If this value is not specified, it defaults to **any**. |
