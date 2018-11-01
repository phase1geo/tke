### is triplebtick

This command determines if the given character is part of an unescaped triple
backtick-quote (```) on the left or right side of a triple backtick-quoted
string.  It is written to be highly performant and its usage is encouraged.

**Call structure**

`pathname is triplebtick index ?side?

**Return value**

Returns true if the given index is part of an unescaped triple backtick-quote
character.

**Parameters**

| Parameter | Description |
| - | - |
| index | Index of character to check. |
| side | Specifies which triple-backtick-quote we want to check.  Valid values are:  **left**, **right** or **any**.  If this value is not specified, it defaults to **any**. |
