### is angled

This command determines if the given character is an unescaped left angled
bracket (&less;) or right angled bracket (&gt;).  It is written for maximized
performance so its usage is encouraged.

**Call structure**

`pathname is angled index ?side?

**Return value**

Returns true if the given character is an unescaped angled bracket.

**Parameters**

| Parameter | Description |
| - | - |
| index | Index of character to check. |
| side | Specifies which angled bracket we want to check.  Valid values are:  **left**, **right** or **any**.  If this value is not specified, it defaults to **any**. |
