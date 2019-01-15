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
| -linemap\_mark\_color _color_ | black | Specifies the foreground color of line numbers when they are marked with a marker. |
| -linemap\_cursor _cursor_ | left\_ptr | Specifies the name of a Tk cursor to display when the mouse cursor is within the linemap gutter area. |
| -linemap\_relief _relief_ | Same value as the -relief text option | Specifies the relief to to use when displaying the linemap area. |
| -linemap\_minwidth _number_ | 1 | Specifies the minimum number of characters to show for line numbers.  If the number of characters required to display the last line number of the current file exceeds this value, that value is used instead. |
| -linemap\_type (**absolute** or **relative**) | absolute | Specifies if line numbering should use absolute line numbering (i.e., the first line of the file is numbered 1 and subsequent line numbers increment from there) or relative line numbering (i.e., the line containing the insertion cursor is numbered 0 with lines above incrementing by 1 from 0 and lines below the current line incrementing by 1). |
| -linemap\_align (**left** or **right**) | left | Specifies whether line numbers that are less than the width allotted for line numbers are aligned to the left of the line number area or the right. |
| -linemap\_separator (**auto**, **0**, **1**) | auto | Specifies if the vertical line that separates the linemap and the editing buffer should be drawn. If this value is set to **auto**, it will be drawn only if the -linemapbg color and the -background colors are the same. |
| -linemap\_separator\_color _color_ | red | If the linemap separator is displayed, it will be displayed using the color specified by this option. |
| -highlight _boolean_ | true | If this value is set to true, syntax highlighting will be performed and applied to the text automatically whenever text in the editing buffer changes. If this value is set to false, syntax highlighting will no longer be applied as the buffer changes. |
| -lmargin _number_ | 0 | Specifies the number of pixels of left margin to add to the text widget when rendering text. This option is mostly useful when the ctext widget is being used to display/edit prose-like content. |
| -warnwidth _number_ | None | If set to a positive number, sets the width warning line just after the specified text column.  If set to the empty string, the warning line will be removed from the display. |
| -warnwidth\_bg _color_ | red | Specifies the color of the width warning line (if it is displayed). |
| -casesensitive _boolean_ | 1 | Specifies the case-sensitivity of the syntax highlight parser. |
| -escapes _boolean_ | 1 | Specifies if the syntax highlighter should pay attention to escape characters (i.e., \\) when parsing text. Escaped text will not be treated as special highlightable characters. |
| -maxundo _number_ | 0 | Specifies the maximum number of undo operations stored in memory.  If this value is set to 0, unlimited undo is supported (if the Tk text -undo option is set to a value of true). |
| -diff\_mode _boolean_ | 0 | If set to true, runs the Ctext editor in diff mode.  In this mode, the gutter displays two sets of line numbers (one for each file in the diff).  This option also enables the diff commands (documented in the Commands section of this appendix).  If set to false, runs the editor in normal editing mode.  Note that diff mode still allows syntax highlighting to occur.  Additionally, if we are running in diff mode, the line number gutter will always be displayed regardless of the value of -linemap. |
| -diffsubbg _color_ | pink | Specifies the background color of difference lines from the first file (i.e., lines that are not a part of the second file). |
| -diffaddbg _color_ | {light green} | Specifies the background color of difference lines from the second file (i.e., lines that are not a part of the first file). |
| -delimiters _regexp_ | \[^\s\(\{\[\}\]\)\.\t\n\r;:=\"'\|,<>\]+ | Specifies the characters that are used to delimit words in the text for the purpose of syntax highlighting words and charstart highlight classes. |
| -matchchar _bool_ | 0 | If this option is set to a true value, the editing buffer will automatically highlight the matching character when the cursor is placed on a bracket/string character. |
| -matchchar_bg _color_ | | Specifies the background color of the matching character indicator. Only used if -matchchar is set to a true value. |
| -matchchar_fg _color_ | | Specifies the foreground color of the matching character indicator. Only used if -matchchar is set to a true value. |
| -matchaudit _bool_ | 0 | If this option is set to a true value, the editing buffer will automatically highlight any bracket/string characters that do not have matching characters. |
| -matchaudit_bg _color_ | | Specifies the background color used for the mismatched bracket/string characters. Only used if the -matchaudit option is set to a true value. |
| -theme _list_ | {} | A key/value Tcl list in the form of `classname color ?classname color ...?` used for applying colors to highlighted syntax. For every _classname_ used by one of the `syntax addclass` or `syntax search`, there must be an existing key of the same name in this option. |
| -hidemeta _boolean_ | 0 | If set to 1, hides all characters marked with a meta class.  If set to 0, shows all characters marked with a meta class. |