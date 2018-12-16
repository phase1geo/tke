### gutter create

A gutter is a single character column drawn in the linemap area of the widget.  All gutters are added to the right of the line number column (if displayed).  Each row in the gutter will correspond to the associated line in the editing area.  Each gutter row can display a background color and/or a symbol (i.e., unicode character).  If the user moves the mouse over a gutter row an on\_enter or on\_leave event can be bound to handle the event.  Additionally, if the user left clicks on a gutter row, an on\_click event can be bound to handle the event.

The ‘gutter create’ command must be called prior to calling any other gutter commands.  Each gutter is given a developer-provided name.  This name is used in all of the other gutter commands to refer to which gutter to operate on.

This command adds the gutter to the gutter area and, optionally, configures its setup/behavior.

**Call structure**

`pathname gutter create name ?symbol_name symbol_opt_list ...?`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| name | Developer-supplied name of the gutter to create.  All other gutter commands require this name. |
| symbol\_name | Name of a symbol that will exist in the gutter. |
| symbol\_opt\_list | List containing an even number of option/value pairs that will be associated with the symbol called symbol\_name.  The possible values contained in this list are represented in the Gutter Symbol Options table. |

**Gutter Symbol Options**

The following options are used in the ‘gutter create’, ‘gutter cget’ and ‘gutter configure’ commands.

| Option | Value(s) | Description |
| - | - | - |
| -symbol | Unicode character | Specifies the character to draw in all gutter rows associated with the given symbol name. |
| -bg | color | Specifies background color to use for all rows tagged with the associated symbol name. |
| -fg | color | Specifies foreground color to use for all rows tagged with the associated symbol name. |
| -onenter | command | Command to execute whenever the user mouse cursor enters a row represented by the associated symbol name.  The pathname of the widget is appended to the command when executed. |
| -onleave | command | Command to execute whenever the user mouse cursor leaves a row represented by the associated symbol name.  The pathname of the widget is appended to the command when executed. |
| -onclick | command | Command to execute whenever the user left clicks on a row represented by the associated symbol name.  The pathname of the widget and the line number of the clicked symbol is appended to the command when executed. |
| -onshiftclick | command | Command to execute whenever the user holds the Shift key while left clicking on a row represented by the associated symbol name.  The pathname of the widget and the line number of the clicked symbol is appended to the command when executed. |
| -oncontrolclick | command | Command to execute whenever the user holds the Control key while left clicking on a row represented by the associated symbol name.  The pathname of the widget and the line number of the clicked symbol is appended to the command when executed. |



