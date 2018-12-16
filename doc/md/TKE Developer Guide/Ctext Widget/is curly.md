### is curly

This command determines if the given character is an unescaped left curly
bracket ({) or right curly bracket (}).  It is written for maximized
performance so its usage is encouraged.

**Call structure**

`pathname is curly index ?side?

**Return value**

Returns true if the given character is a curly bracket

**Parameters**

| Parameter | Description |
| - | - |
| index | Index of character to check. |
| side | Specifies which curly bracket we want to check.  Valid values are:  **left**, **right** or **any**.  If this value is not specified, it defaults to **any**. |
