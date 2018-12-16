### edit cursorhist

Returns a list of cursor indices from the undo stack such that the first index corresponds to the oldest cursor in the stack while the newest cursor position is at the end of the list.

**Call structure**

`pathname edit cursorhist`

**Return value**

Returns a list of indices containing the history of stored cursor positions from oldest to newest.  If the undo stack is empty, an empty list will be returned.

**Parameters**

None.