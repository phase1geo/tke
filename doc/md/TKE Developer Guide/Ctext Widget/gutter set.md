### gutter set

Tags one or more rows in the gutter with one or more gutter symbols.  If a gutter row in one of the lists already is tagged with a different symbol, that symbol is replaced with the new symbol.

**Call structure**

`pathname gutter set name ?symbol_name rows ...?`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| name | Name of gutter to modify. |
| symbol\_name | Name of symbol to associate the given list of rows with.  The value of symbol\_name must be created prior to the ‘gutter set’ call in either the ‘gutter create’ or ‘gutter configure’ commands. |
| rows | A list containing one or more integer values ranging from 1 to the maximum number of lines in the widget. |

