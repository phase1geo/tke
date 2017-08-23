### diff add

Like its other diff command ‘diff sub’, the ‘diff add’ command marks lines in the text widget as being different from the first file.  All lines marked with this command are highlighted using the background color specified by the -diffaddbg option.  After this command has been called, the line numbers in the linemap area will be automatically changed to match the difference information.

**Call structure**

`pathname diff add startline linecount`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| startline | Starting line containing file difference information. |
| linecount | Specifies the number of lines that will be inserted into the widget. |

