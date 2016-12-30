## Options

The following options are available in the Ctext widget.

| Option | Default Value | Description |
| - | - | - |
| -highlightcolor _color_ | yellow | Specifies the color that will be drawn around the outside of the editor window when the window has keyboard input focus. |
| -unhighlightcolor _color_ | None | Specifies the color that will be drawn around the outside of the editor window when the window does not have keyboard input focus. |
| -linemap _boolean_ | TRUE | If true displays the line number information in the gutter; otherwise, hides the line number information. |
| -linemapfg _color_ | Same as the value of the -fg option. | Specifies the color of the foreground in the line information in the gutter. |
| -linemapbg _color_ | Same as the value of the -bg option. | Specifies the color of the background in the line information in the gutter. |
| -linemap\_mark\_command _command_ | None | Specifies a command to execute when the user creates a marker in the gutter area.  The command has the following information appended to this command: pathname of the ctext widget, a value of “marked” (if a marker was added to the gutter) or “unmarked” (if a marker was deleted from the gutter), and the tag name of the marker created. |
| -linemap\_markable _boolean_ | TRUE | If true, specifies that the linemap can be clicked on to create and remove markers.  If -linemap is false when this option is true, the line numbers will not be displayed, but a one character area will be visible allowing the user to click on a line to create a visible marker. |
| -linemap\_select\_fg _color_ | black | Specifies the foreground color of line numbers when they are marked with a marker. |
| -linemap\_select\_bg _color_ | yellow | Specifies the background color of line numbers when they are marked with a marker. |
| -linemap\_cursor _cursor_ | left\_ptr | Specifies the name of a Tk cursor to display when the mouse cursor is within the linemap gutter area. |
| -linemap\_relief _relief_ | Same value as the -relief text option | Specifies the relief to to use when displaying the linemap area. |
| -linemap\_minwidth _number_ | 1 | Specifies the minimum number of characters to show for line numbers.  If the number of characters required to display the last line number of the current file exceeds this value, that value is used instead. |
| -linemap\_type (**absolute** or **relative**) | absolute | Specifies if line numbering should use absolute line numbering (i.e., the first line of the file is numbered 1 and subsequent line numbers increment from there) or relative line numbering (i.e., the line containing the insertion cursor is numbered 0 with lines above incrementing by 1 from 0 and lines below the current line incrementing by 1). |
| -warnwidth _number_ | None | If set to a positive number, sets the width warning line just after the specified text column.  If set to the empty string, the warning line will be removed from the display. |
| -warnwidth\_bg _color_ | red | Specifies the color of the width warning line (if it is displayed). |
| -casesensitive _boolean_ | 1 | Specifies the case-sensitivity of the syntax highlight parser. |
| -maxundo _number_ | 0 | Specifies the maximum number of undo operations stored in memory.  If this value is set to 0, unlimited undo is supported (if the Tk text -undo option is set to a value of true). |
| -diff\_mode _boolean_ | 0 | If set to true, runs the Ctext editor in diff mode.  In this mode, the gutter displays two sets of line numbers (one for each file in the diff).  This option also enables the diff commands (documented in the Commands section of this appendix).  If set to false, runs the editor in normal editing mode.  Note that diff mode still allows syntax highlighting to occur.  Additionally, if we are running in diff mode, the line number gutter will always be displayed regardless of the value of -linemap. |
| -diffsubbg _color_ | pink | Specifies the background color of difference lines from the first file (i.e., lines that are not a part of the second file). |
| -diffaddbg _color_ | {light green} | Specifies the background color of difference lines from the second file (i.e., lines that are not a part of the first file). |

