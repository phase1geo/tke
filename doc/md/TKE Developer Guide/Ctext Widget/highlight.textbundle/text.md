### highlight

Causes all text between the specified line positions to be re-evaluated for syntax highlighting.  This is most often used after a number of fastdelete or fastinsert commands are called.  This eliminates a lot of syntax highlighting calls which can improve the performance of the widget in certain situations.

**Call structure**

`pathname highlight ?options? startpos endpos`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| options | <ul><li>-moddata <i>data</i> = Value that will be passed to any \<\<Modified\>\> callback procedures via the %d bind variable.</li><li>-insert <i>bool</i> = Set to a value of 1 if the highlight is being performed after inserting text; otherwise, set it to a value of 0.</li><li>-dotags <i>list</i> = Set to any string value to force comment/string parsing to be performed during the highlight process.</li></ul> |
| startpos | Character position index to begin highlighting. The starting character position will be the beginning of the line of this character. |
| endpos | Character position index to end highlighting. The ending character position will be the end of the line containing this character. |

