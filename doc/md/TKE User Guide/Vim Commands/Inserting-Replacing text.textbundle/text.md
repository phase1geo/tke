#### Inserting/Replacing text

| Command or KEY | Description |
| - | - |
| **i** | Inserts before the current character. |
| **a** | Inserts after the current character. |
| **A** | Inserts at the end of the current line. |
| **I** | Inserts at the beginning of the current line. |
| **o** | Inserts below the current line (opens new line). |
| **O** | Inserts above the current line (opens new line). |
| **r** | Replaces the current character (no ESC necessary). |
| **R** | Replaces from current cursor position to end of line; does not change characters not typed over. |
| **cl** | Replaces the character to the right of the insertion cursor. |
| **ch** | Replaces the character to the left of the insertion cursor. |
| **cw** | Replaces the current word. |
| **ci**_char_ | Replaces all text contained within the pair of _char_ characters before and after the current insertion cursor. If the value of _char_ is a bracket type (i.e., **{**, **}**, **[**, **]**, **(**, **)**, **\<**, **\>**), all characters between that bracket and its matching bracket around the current insertion cursor will be replaced. |
| **cc** | Replaces the current line. |
| **C** | Replaces all text from the current insertion cursor to the end of the current line. |
