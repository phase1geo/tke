### fastinsert

This command performs a standard insertion without performing any syntax highlighting on the inserted text.

**Call structure**

`pathname fastinsert ?options? startpos text`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| options | <ul><li>-moddata <i>data</i> = Value that will be passed to any \<\<Modified\>\> callback procedures via the %d bind variable.</li><li>-update <i>bool</i> = If set to 1 will cause the \<\<Modified\>\> and \<\<CursorChanged\>\> events to be triggered; otherwise, these events will not be generated.</li></ul> |
| startpos | Starting text position to begin inserting the given text. |
| text | Text to insert. |

