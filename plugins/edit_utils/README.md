
# What is this?


This plugin allows the user to perform the following operations:

  1) Delete the current line or the lines of selection.
  2) Duplicate the current line or the selection.
  3) Indent/unindent the current line or the lines of selection.
  4) Normalize the Tcl script's indention
  5) Comment/uncomment the TCL coded line or the lines of selection.

The first operation allows to erase one or few lines quickly.

2nd and 3rd operations being applied to a selected text do not take off the selection which is their special hit.

The 4th operation allows to get the "standard" indention of selected text (if any) or the whole edited Tcl script.

The 5th operation is useful while editing Tcl code. Tcl is famous for its peculiar relation to comments. Especially, if you are commenting a piece of Tcl code containing left and/or right braces you are going to get a most elaborate Tcl error which is rather hard to identify. The more braces the more troubles.

The 5th operation allows you to get rid of the troubles while commenting Tcl code lines.

Also, the 5th operation can help you find out what braces are unpaired in your TCL code.

All these operations can be applied to the current line or to the selected text.

Note:
The plugin was tested under Linux (Debian) and Windows. All bug fixes and corrections for other platforms would be appreciated at aplsimple$mail.ru.


# Menu usage


It would be convenient to assign the following shortkeys for "Plugin/ Edit utils" operations:

  *Ctrl-Y* - Delete Line
  *Ctrl-D* - Duplicate Selection
  *Ctrl-I* - Indent Selection
  *Alt-I*  - Unindent Selection
  *F4*     - Normalize indentation
  *Alt-[*  - Comment TCL
  *Alt-]*  - Uncomment TCL


# Tips and traps


You can select several lines of text and then duplicate them, but you should notice the cursor position at that. The duplicated selection will appear at the position of cursor.

While commenting Tcl code, notice the new lines that can appear after. They would be formed as
  #? TODO braces
  where "braces" are set for parity with braces of commented Tcl code.
Of course, these lines should be (and are) removed at the uncommenting.

If the commented lines are few, you need not to select them in order to uncomment. Just place the cursor in the first (last) of them and begin to run "Plugin/ Edit utils/ Uncomment TCL". The cursor would follow the comments and stop when they are over. The "Comment TCL" behaves the similar way (moving only the cursor down).

While normalizing the code, notice that the indention width is defined with the first indented line of the current selection/script even if the line is in global (0th) level. The 0th level lines will be set at column 0, other levels are indented according to the "{" and "}" ("begin" and "end" of code block).

The normalization isn't performed at all, if in some line of text/selection the accumulated number of "}" is greater than of "{" which means you want to indent to left of column 0. In this case the plugin puts out an error message and exits.

The normalization doesn't touch the following:
 - comments
 - continued lines
 - quoted multiline strings except for the 1st (command itself)
So, only 2nd line would be touched below:
 # comments are not normalized:
    set multiline "this line is normalized
  second multiline string    isn't normalized \
  continued line             isn't normalized
  last multiline string      isn't normalized"

If some normalized piece of code does not suit your taste, you can set the continuation mark ("\") in order to disable the normalization. For example:
  if {$condition} {
     thecommand}
after normalization will be
  if {$condition} {
  thecommand}
You can force it to suit your indention by "\":
  if {$condition} { \
     thecommand}

Also notice that an ugly/tricky code may be not normalized as you want.

In any cases, the normalization is secure and doesn't distort the real code.

