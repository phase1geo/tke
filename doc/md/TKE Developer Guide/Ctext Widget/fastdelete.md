### fastdelete

This command performs a standard deletion without repairing any syntax highlighting due to removing the text.

**Call structure**

`pathname fastdelete ?options? startpos endpos`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| options | <ul><li>-moddata <i>data</i> = Value that will be passed to any \<\<Modified\>\> callback procedures via the %d bind variable.</li><li>-update <i>bool</i> = If set to 1 will cause the \<\<Modified\>\> and \<\<CursorChanged\>\> events to be triggered; otherwise, these events will not be generated.</li></ul> |
| startpos | Starting text position of character range to delete. |
| endpos | Ending test position of character range to delete. |

