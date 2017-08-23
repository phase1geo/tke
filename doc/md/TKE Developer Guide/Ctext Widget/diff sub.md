### diff sub

Adds a difference change for the first file (as it would be displayed in unified diff format).  Before any calls can be made to this command, the diff reset command must be called.

When the editor operates in diff mode, it is important the the second file in the diff is displayed in the Ctext widget in its entirety.  The ‘diff sub’ command contains an extra parameter when called which contains the text that exists in the first file but not in the second file.  This text is inserted into the widget at the given line number and line numbers in the gutter are adjusted accordingly.  All inserted text will be highlighted in the background color specified by the -diffsubbg option.

**Call Structure**

`pathname diff sub startline linecount text`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| startline | Starting line containing file difference information. |
| linecount | Specifies the number of lines that will be inserted into the widget. |
| text | String containing text that exists in the first file but not in the second file.  If a unified diff file is parsed, this string would be all contiguous lines prefixed by a single ‘-‘ character in the output. |

