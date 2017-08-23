### gutter configure

Either allows gutter options to be set to different values or retrieves a list of all option/value pairs associated with the given gutter/symbol name.

**Call structure**

`pathname gutter configure name symbol_name ?option? ?value option value ...?`

**Return value**

If the first call is made, returns a list of all symbol names and associated gutter symbol options assigned to the given gutter.

**Parameters**

| Parameter | Description |
| - | - |
| name | Name of gutter to modify/query. |
| symbol\_name | Name of gutter symbol to modify/query. |
| option | Name of gutter symbol option to modify. |
| value | Value to assign to the associated symbol option. |

