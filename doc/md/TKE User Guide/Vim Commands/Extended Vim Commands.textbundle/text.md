## Extended Vim Commands

To provide additional functionality to the user, Vim command extensions have been added to the standard list.  The following table specifies these Vim command extensions.

### Tab or Text Pane Traversal

| Command or KEY | Description |
| - | - |
| **:N** | Changes to the previous tab. |
| **:p** | Changes focus to the tab in the other opened text pane (only available when the other pane exists). |

### Marker (Bookmark) Creation

| Command or KEY | Description |
| - | - |
| **:m** | Creates a marker (bookmark) for the current line.  This marker can be named in the subsequent entry field that is displayed.  Hitting return in the marker entry field will create a named marker (or if no text was typed, an unnamed marker).  Hitting the ESC key in the entry field will cancel the marker creation process. |
| **:m** _marker_ | Creates a marker (bookmark) for the current line using the provided name. |
| **:cd** _directory_ | Changes the current working directory (as displayed in the title bar) to the specified directory. |

### Multicursor Functionality

| Command or KEY | Description |
| - | - |
| **s** | Sets a multicursor cursor on the current character.  Also makes this character the anchor for any multiline cursor sets. |
| **S** | Sets multicursors for every line between the current line and the last multicursor anchor, inclusive.  Each multicursor will match the column of the anchor multicursor. |
| **m** | When multiple cursors are set, allows the multicursors to be moved using the standard cursor movement commands. Until the **m** command is input, all cursor movement commands will move the selection cursor only. To exit multicursor move command, enter the `Escape` key. |
| **\#** | When one or more multicursors are set, allows the user to insert an ascending numerical values at each cursor input. See below for details on its usage. |

#### Multicursor Enumeration

When the ‘#’ Vim command is entered after multiple cursors have been set, an entry field called  “Starting number:” will be displayed, allowing you to specify the numerical value to insert at the first cursor position. TKE will parse that number and use it for calculating all subsequent cursor positions, incrementing the value by one for each cursor. The following are valid starting number representations:

- _prefix_ [0-9]+
	- Inserts prefix followed by a decimal value.

- _prefix_**d**[0-9]+
	- Inserts prefix followed by a decimal value preceded by “d”

- _prefix_**b**[0-1]+
	- Inserts prefix followed by a binary value preceded by “b”

- _prefix_**o**[0-7]+
	- Inserts prefix followed by an octal value preceded by “o”

- _prefix_[**xh**][0-9a-fA-F]+
	- Inserts prefix followed by a hexadecimal value preceded by either “x” or “h”.

Note: If a value is not specified, a value of zero is assumed.

### String/Bracket Insertion

| Command or KEY | Description |
| - | - |
| **ca‘** | If a selection exists, all selected code will be encapsulated in single quotes.  If no selection exists and current insertion cursor is within a single quote quotation, the right single quote is moved one word to the right.  If none of the above is true, the current word is encapsulated in single quotes. |
| **ca“** | If a selection exists, all selected code will be encapsulated in double quotes.  If no selection exists and current insertion cursor is within a double quote quotation, the right double quote is moved one word to the right.  If none of the above is true, the current word is encapsulated in double quotes. |
| **ca\{** | If a selection exists, all selected code will be encapsulated in curly brackets.  If no selection exists and current insertion cursor is within a curly bracketed code block, the right curly bracket is moved one word to the right.  If none of the above is true, the current word is encapsulated in curly brackets. |
| **ca[** | If a selection exists, all selected code will be encapsulated in square brackets.  If no selection exists and current insertion cursor is within a square bracketed code block, the right square bracket is moved one word to the right.  If none of the above is true, the current word is encapsulated in square brackets. |
| **ca(** | If a selection exists, all selected code will be encapsulated in parenthesis.  If no selection exists and current insertion cursor is within a parenthetical code block, the right parenthesis is moved one word to the right.  If none of the above is true, the current word is encapsulated in parenthesis. |
| **ca\<** | If a selection exists, all selected code will be encapsulated in angled brackets.  If no selection exists and current insertion cursor is within a angle bracketed code block, the right angle bracket is moved one word to the right.  If none of the above is true, the current word is encapsulated in angled brackets. |

### Line Bubbling

| Command or KEY | Description |
| - | - |
| CONTROL-**j** | Moves the current line down one line, moving the line below the current line above it.  If lines are selected, this command moves all of the selected lines down by one line. |
| CONTROL-**k** | Moves the current line up one line, moving the line above the current line below it.  If lines are selected, this command moves all of the selected lines up by one line. |

### Deletion

| Command or KEY | Description |
| - | - |
| **dn** | Deletes all subsequent characters that are numbers. |
| **dN** | Deletes all preceding characters that are numbers. |
| **ds** | Deletes all subsequent space and tab characters. |
| **dS** | Deletes all preceding space and tab characters. |









