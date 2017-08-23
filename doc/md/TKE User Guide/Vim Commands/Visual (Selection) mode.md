#### Visual (Selection) mode

| Command or KEY | Description |
| - | - |
| **v** | Changes the mode to visual character mode.  If we are in visual mode, switches the mode back to command mode. Using the navigation commands during visual mode will change the current selection. |
| **vv** | Changes the mode to visual block mode. This selects a block of text using the character position when this command is invoked as the anchor point of the selection. Using motion when in visual block mode will change the shape of the block. |
| **V** | Changes the mode to visual line mode.  If we are in visual mode, switches the mode back to command mode. Using the navigation commands during visual line mode will change the current selection by lines. |
| **gv** | Reselects the last selection that was made in the editing buffer. Mode will not change to visual mode. |
| **vi\{** or **vi\}** | Selects all characters between the surrounding curly bracket pairs. |
| **vi(** or **vi)** | Selects all characters between the surrounding parenthesis. |
| **vi[** or **vi]** | Selects all characters between the surrounding square brackets. |
| **vi\<** or **vi\>** | Selects all characters between the surrounding angled brackets.