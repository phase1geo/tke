#### Moving around in a file

| Command or KEY | Description |
| - | - |
| **h** | Moves left one character |
| **j** | Moves down one line |
| **k** | Moves up one line |
| **l** | Moves right one character |
| **w** | Moves the insertion cursor to the beginning of the next word. |
| **b** | Moves the insertion cursor to the beginning of the previous word. |
| **0** | Moves to the beginning of current line |
| **^** | Moves to the first non-whitespace character of the current line. |
| **$** | Moves to the end of the current line |
| **:**_num_ | Moves to line _num_ (note: _num_ value of 0 or 1 takes you to the first line). |
| **gg** | Moves to the beginning of the file. |
| **G** | Moves to the end of the file. |
| _num_**G** | Moves to the line _num_. |
| RETURN | Moves the insertion cursor to the first non-whitespace character in the line after the current line. |
| SPACE | Moves the insertion cursor one character to the right, moving to the next line below the current line if the cursor is at the end of the line. |
| BACKSPACE | Moves the insertion cursor one character to the left, moving to the next line above the current line if the cursor is at the end of the line. |
| **-** | Moves the insertion cursor to the first non-whitespace character in the line before the current line. |
| **H** | Moves the insertion cursor to the first line on the screen. |
| **M** | Moves the insertion cursor to the middle line on the screen. |
| **L** | Moves the insertion cursor to the last line on the screen. |
| _num_**\|** | Moves the insertion cursor to the specified column in the current line. |
| CONTROL-**f** | Scrolls forward one screen. |
| CONTROL-**b** | Scrolls backward one screen. |
| UP | Moves the cursor one line up. |
| DOWN | Moves the cursor one line down. |
| LEFT | Moves the cursor one character to the left. |
| RIGHT | Moves the cursor one character to the right. |
| **f**_char_ | Moves the cursor to the next occurrence of the specified character in the current line. |
| **t**_char_ | Moves the cursor to the character just before the next occurrence of the specified character in the current line. |
| **F**_char_ | Moves the cursor to the previous occurrence of the specified character in the current line. |
| **T**_char_ | Moves the cursor to the character just after the previous occurrence of the specified character in the current line. |
| **%** | Moves to matching (, ), \{, \}, [, ], \>, \<, “ or ‘ character. |
| _num_**%** | Moves the cursor to the line which _num_ percent of the way through the file. The value of _num_ must be a whole number. |
