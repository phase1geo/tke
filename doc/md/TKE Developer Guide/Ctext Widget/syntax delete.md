## syntax delete

Deletes one or more syntax highlighting classes from memory, removing their visual highlighting characteristics from the text widget.

If no classes are passed, all existing highlight classes will be deleted.

**Call Structure**

`pathname syntax delete ?classname ...?`

**Return Value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| _classname_ | If one or more classes are specified, those highlight classes will be deleted from the ctext widget.  Deleted classes have all memory associated with them deleted.  To re-apply a class that was previously deleted, use the `syntax addclass` command. |
