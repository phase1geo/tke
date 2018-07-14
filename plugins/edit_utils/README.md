

### What is this?

This plugin allows the user to perform the following operations:

  1) Delete the current line or the lines of selection.
  2) Duplicate the current line or the selection.
  3) Indent/unindent the current line or the lines of selection.
  4) Comment/uncomment the TCL coded line or the lines of selection.

The first operation allows to erase one or few lines quickly.

2nd and 3rd operations being applied to a selected text do not take off the selection which is their special hit.

The 4th operation is useful while editing Tcl code. Tcl is famous for its peculiar relation to comments. Especially, if you are commenting a piece of Tcl code containing left and/or right braces you are going to get a most elaborate Tcl error which is rather hard to identify. The more braces the more troubles.

The 4th operation allows you to get rid of the troubles while commenting Tcl code lines.

Also, the 4th operation can help you find out what and how many braces are unpaired in your TCL code.

All these operations can be applied to the current line or to the selected text.


### Menu usage

It would be convenient to assign the following shortkeys for "Plugin/ Edit utils" operations:

  *Ctrl-Alt-Y* - Delete Line
  *Ctrl-Alt-U* - Duplicate Selection
  *Ctrl-I*     - Indent Selection
  *Alt-I*      - Unindent Selection
  *Alt-[*      - Comment TCL
  *Alt-]*      - Uncomment TCL


### Tips and traps

You can select several lines of text and then duplicate them, but you should notice the cursor position at that. The duplicated selection will appear at the position of cursor.

While commenting Tcl code, notice the new lines that can appear after. They would be formed as
  `#? TODO braces`
  where `braces` are set for parity with braces of commented Tcl code.
Of course, these lines should be (and are) removed at the uncommenting.

If the commented lines are few, you need not to select them in order to uncomment. Just place the cursor in the first (last) of them and begin to run "Plugin/ Edit utils/ Uncomment TCL". The cursor would follow the comments and stop when they are over. The "Comment TCL" behaves the similar way (moving only the cursor down).

