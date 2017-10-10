### getLang

Since the ctext widget allows embedding syntax blocks of languages that can differ from the primary syntax (i.e., a Javascript block within an HTML file), it is necessary to have a method of asking the ctext widget what syntax block a given text index is within. This procedure provides that information to the caller.

**Call structure**

`ctext::getLang pathname index`

**Return value**

Returns the empty string if the syntax located at the given index is the primary language for the file; otherwise, returns the name of the embedded syntax language at the given index.

**Parameters**

| Parameter | Description |
| - | - |
| pathname | The full pathname of the text widget to check. |
| index | Any valid text index within the given text widget to check. |

**Example**

```Tcl
# Get the language used at index 5.2 of the text widget
set lang [ctext::getLang $txt 5.2] 
```