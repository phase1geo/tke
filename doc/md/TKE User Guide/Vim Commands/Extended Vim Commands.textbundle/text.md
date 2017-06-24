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

- _prefix_[0-9]+([**+-**][0-9]\*)
	- Inserts prefix followed by a decimal value.
	- If a plus (+) or minus (-) character follows the starting value, the enumeration will increase or decrease by the number following this character. If no number is specified after the +/-, a value of 1 will be assumed.

- _prefix_**d**[0-9]+([**+-**][0-9]\*)
	- Inserts prefix followed by a decimal value.
	- If a plus (+) or minus (-) character follows the starting value, the enumeration will increase or decrease by the number following this character. If no number is specified after the +/-, a value of 1 will be assumed.

- _prefix_**b**[0-1]+([**+-**][0-9]\*)
	- Inserts prefix followed by a binary value.
	- If a plus (+) or minus (-) character follows the starting value, the enumeration will increase or decrease by the number following this character. If no number is specified after the +/-, a value of 1 will be assumed.

- _prefix_**o**[0-7]+([**+-**][0-9]\*)
	- Inserts prefix followed by an octal value.
	- If a plus (+) or minus (-) character follows the starting value, the enumeration will increase or decrease by the number following this character. If no number is specified after the +/-, a value of 1 will be assumed.

- _prefix_[**xh**][0-9a-fA-F]+([**+-**][0-9]\*)
	- Inserts prefix followed by a hexadecimal value.
	- If a plus (+) or minus (-) character follows the starting value, the enumeration will increase or decrease by the number following this character. If no number is specified after the +/-, a value of 1 will be assumed.

Note: If a value is not specified, a value of zero is assumed.

Some examples, suppose we have the following code that we need to enumerate, placing the numerical value after the string "Line " in each line:

	 Line 
	 Line 
	 Line 

**Example 1:**   Start at decimal zero and increment each by one.

Command = "0"

	Line 0
	Line 1
	Line 2

**Example 2:**  Start a hexadecimal value 14 and increment each by one, outputting in hexadecimal format.

Command = "0xxe"

	Line 0xe
	Line 0xf
	Line 0x10

**Example 3:**  Start at binary value 1 and increment by one, outputting a binary value without a prefix.

Command = "b1"

	Line 1
	Line 10
	Line 11

**Example 4:**  Start at decimal 0 and increment by 10.

Command = "0+10"

	Line 0
	Line 10
	Line 20

**Example 5:**  Start at octal value 8 and decrement by 2, outputting an octal value with a prefix of "0o".

Command = "0oo10-2"

	Line 0o10
	Line 0o6
	Line Oo4


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








