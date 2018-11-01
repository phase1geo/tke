### is escaped

This command can be used to determine if the character at the given index is
escaped with the escape character (\).  Note that this command takes into
account whether the escape character is escaped or not.  It is also written
to be highly performant so its use is encouraged over doing the check manually.

**Call structure**

`pathname is escaped index`

**Return value**

Returns true if the character at the given index is escaped.

**Parmaters**

| Parameter | Description |
| - | - |
| index | Index of character to check. |
