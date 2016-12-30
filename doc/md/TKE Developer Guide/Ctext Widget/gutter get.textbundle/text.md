### gutter get

Returns a list of information about the specified gutter, depending on the call structure.  In the first call structure where only the name of the gutter is specified, the command returns a list of all symbol names stored in the gutter.  If both the name of the gutter and the name of a symbol is specified, returns a list of rows that are tagged with the given symbol.

**Call structure**

`pathname gutter get name ?symbol_name?`

**Return value**

If _symbol\_name_ is not specified, returns a list of all symbol names in the first case; otherwise, returns a list of rows tagged with the given symbol in the second case.

**Parameters**

| Parameter | Description |
| - | - |
| name | Name of gutter to query. |
| symbol\_name | Name of gutter symbol to query. |

