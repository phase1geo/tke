#### Moving around in a file

These Vim commands are also known as _motions_ with Vim documentation. Most of these can be combined with Vim operators (such a `d`, `c` and `y`) to allow operating on a range of text (typically starting at the current insertion cursor position).

Most motions can be preceded by a number which causes the motion to be repeated that number of times. If the motion follows a Vim operator and a number precedes the operator, the operator number is multiplied by the motion number and then applied to the motion.

| Command or KEY | Description |
| - | - |
| **h** | Moves left one character. |
| **j** | Moves down one line. |
| **k** | Moves up one line. |
| **l** | Moves right one character. |
| **w** | Moves the insertion cursor to the beginning of the next word. |
| **W** | Moves the insertion cursor to the beginning of the next WORD. |
| **b** | Moves the insertion cursor to the beginning of the current word. |
| **B** | Moves the insertion cursor to the beginning of the current WORD. |
| **e** | Moves the insertion cursor to the ending of the current word. |
| **E** | Moves the insertion cursor to the ending of the current WORD. |
| **ge** | Moves the insertion cursor to the ending of the previous word. |
| **gE** | Moves the insertion cursor to the ending of the previous WORD. |
| **0** | Moves to the beginning of current line. |
| **^** | Moves to the first non-whitespace character of the current line. |
| _num_**\_** (underscore) | Moves _num_-1 lines downward to the first non-whitespace character. |
| DOLLAR\_SIGN | Moves to the end of the current line. |
| **:**_num_ | Moves to line _num_ (note: _num_ value of 0 or 1 takes you to the first line). |
| **gg** | Moves to the beginning of the file. |
| **G** | Moves to the end of the file. |
| _num_**G** | Moves to the first non-whitespace character in line _num_. |
| **g\_** | Moves the cursor to the last non-whitespace character in the current line. |
| **g0** | When line wrapping is enabled, moves the cursor to the first character of displayed line. When line wrapping is disabled, moves the cursor to the leftmost displayed character of the current line. |
| **g^** | When line wrapping is enabled, moves the cursor to the first non-whitespace character of the displayed line. When line wrapping is disabled, moves the cursor to the leftmost non-whitespace character of the current line. |
| **g$** | When line wrapping is enabled, moves the cursor to the last character of the displayed line. When line wrapping is disabled, moves the cursor to the rightmost displayed character of the current line. |
| **gm** | Moves the cursor to the character of the current line which is in the middle of the displayed area. |
| RETURN or **+** | Moves the insertion cursor to the first non-whitespace character in the line after the current line. |
| SPACE | Moves the insertion cursor one character to the right, moving to the next line below the current line if the cursor is at the end of the line. |
| BACKSPACE | Moves the insertion cursor one character to the left, moving to the next line above the current line if the cursor is at the end of the line. |
| **-** (minus) | Moves the insertion cursor to the first non-whitespace character in the line before the current line. |
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
| _num_**%** | Moves the cursor to the first non-whitespace character in the line which is _num_ percent of the way through the file. |
| **\(** | Moves the cursor to the beginning of the current sentence. |
| **\)** | Moves the cursor to the beginning of the next sentence. |
| **\{** | Moves the cursor to the beginning of the current paragraph. |
| **\}** | Moves the cursor to the ending of the next paragraph. |