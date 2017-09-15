## api::file::add\_file

Adds a new tab to the editor.  If a filename is specified, the contents of the file are added to the editor.  If no filename is specified, the new tab file will be blanked and named “Untitled”.

**Call structure**

`api::file::add_file ?filename? ?options?`

**Return value**

Returns the pathname of the created ctext widget.

**Parameters**

| Parameter | Description |
| - | - |
| filename | Optional.  If specified, opens the given file in the added tab. |
| options | Optional arguments passed to the newly created tab. See the table below for a list of valid values. |

**Options**

| Option | Description |
| - | - |
| -savecommand _command_ | Specifies the name of a command to execute after the file is saved. |
| -lock _boolean_ | If set to 0, the file will begin in the unlocked state (i.e., file is editable); otherwise, the file will begin in the locked state. |
| -readonly _boolean_ | If set to 1, the file will be considered readonly (file will be indefinitely locked); otherwise, the file will be editable. |
| -sidebar _boolean_ | If set to 1 (default), the file’s directory contents will be included in the sidebar; otherwise, the file’s directory components will not be added to the sidebar. |
| -diff _boolean_ | If set to 0 (default), the file will be added as an editable file; however, if set to 1, the file will be inserted as a difference viewer, allowing the user to view file differences visually within the editor. |
| -gutters gutter\_list | Creates one or more gutters in the editor (one character wide vertical strip to the left of the line number gutter which allows additional information/functionality to be provided for each line in the editor).  See the gutter\_list description below for additional details about the structure of this option. |
| -other _boolean_ | If set to 0 (default), the file will be added to the current pane; however, if set to 1, the file will be added to the other pane (the other pane will be created if it currently does not exist). |
| -tags _tags_ | Specifies a list of text bindings that can only be associated with this tab. |
| -name _filename_ | If this option is specified when the filename is not specified, it will add a new tab to the editor whose name matches the given name. If the user saves the file, the contents will be saved to disk with the given file name. The given filename does not need to exist prior to calling this procedure. |

