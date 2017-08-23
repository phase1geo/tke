## api\::file\::add\_buffer

Adds a new tab to the editor which is a blank editing buffer (no file is associated with the contents of the editing buffer).

**Call structure**

`api::file::add_buffer name save_command ?options?`

**Return value**

Returns the pathname of the created ctext widget.

**Parameters**

| Parameter | Description |
| - | - |
| name | Title of editor tab. |
| save\_command | Command to run when the user attempts to save the contents of the buffer.  If the save command returns a value of 1, TKE will prompt the user for a filename and the contents will be saved to the specified file.  From that point on, the editing buffer will transition to a normal file and the save command will no longer be invoked on future saves.  If the save command returns a value of 1, the save\_command will continue to be used for future saves. |
| options | Optional arguments passed to the newly added tab. See the list of valid options in the table below. |

**Options**

| Option | Description |
| - | - |
| -lock _boolean_ | Initial value of the lock setting of the buffer (the user does have permission to unlock the file). |
| -readonly _boolean_ | Specifies if the buffer will be editable by the user. |
| -gutters _gutter\_list_ | Creates one or more gutters in the editor (one character wide vertical strip to the left of the line number gutter which allows additional information/functionality to be provided for each line in the editor).  See the gutter\_list description below for additional details about the structure of this option. |
| -other _boolean_ | Specifies if the buffer should be added to pane that does not currently have the focus. |
| -tags _tags_ | Specifies a list of text bindings that can only be associated with this tab. |
| -lang _language_ | Specifies the initial syntax highlighting language to use for highlighting the buffer. |
| -background _boolean_ | If true, causes the added buffer tab to be created but not made the current editing buffer; otherwise, if false, the tab will be made the current tab. |

