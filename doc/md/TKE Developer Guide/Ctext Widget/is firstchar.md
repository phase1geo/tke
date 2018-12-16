### is firstchar

This command determines if the character at the given index is the first
non-whitespace character in the line.  It is written to be highly performant
so its use is encouraged instead of figuring this out using other means.

**Call structure**

`pathname is firstchar index`

**Return value**

Returns true if the character at the given index is the first non-whitespace
character on the current line.

**Parameters**

| Parameter | Description |
| - | - |
| index | Index of character to check. |
