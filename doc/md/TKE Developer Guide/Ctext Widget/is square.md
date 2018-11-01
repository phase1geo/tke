### is square

This command determines if the given character is an unescaped left square
bracket ([) or right square bracket (]).  It is written for maximized
performance so its usage is encouraged.

**Call structure**

`pathname is square index ?side?

**Return value**

Returns true if the given character is a square bracket.

**Parameters**

| Parameter | Description |
| - | - |
| index | Index of character to check. |
| side | Specifies which square bracket we want to check.  Valid values are:  **left**, **right** or **any**.  If this value is not specified, it defaults to **any**. |
