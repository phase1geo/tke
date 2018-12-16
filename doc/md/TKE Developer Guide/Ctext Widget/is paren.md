### is paren

This command determines if the given character is an unescaped left parenthesis
(() or right parenthesis ()).  It is written for maximized performance so its
usage is encouraged.

**Call structure**

`pathname is paren index ?side?

**Return value**

Returns true if the given character is an unescaped parenthesis.

**Parameters**

| Parameter | Description |
| - | - |
| index | Index of character to check. |
| side | Specifies which parenthesis we want to check.  Valid values are:  **left**, **right** or **any**.  If this value is not specified, it defaults to **any**. |
