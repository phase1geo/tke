### fastreplace

This command performs a standard text replacement without performing any syntax highlighting on the inserted text.

**Call structure**

`pathname fastreplace ?options? startpos endpos text`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| options | <ul><li>-moddata <i>data</i> = Value that will be passed to any \<\<Modified\>\> callback procedures via the %d bind variable.</li><li>-update <i>bool</i> = If set to 1 will cause the \<\<Modified\>\> and \<\<CursorChanged\>\> events to be triggered; otherwise, these events will not be generated.</li></ul> |
| startpos | Starting position of text range to delete and starting position to insert text. |
| endpos | Ending position of text range to delete. |
| text | Text to insert in replacement of the deleted text. |

