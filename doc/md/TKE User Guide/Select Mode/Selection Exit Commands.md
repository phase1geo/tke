## Selection Exit Commands

When you have your selection setup just the way you need, it's time to exit selection mode so that you can get on with your text editing. There are several commands that will exit selection mode, performing various functions on exit. The following table describes these commands.

| Commands | Description |
| - | - |
| ESCAPE | Removes the selection from the text. This has the effect of cancelling the selection. |
| RETURN | Leaves the selection intact. |
| DELETE or BACKSPACE | Deletes the selected text. |
| **~** | Inverts the selection in the entire editing buffer. Whatever text was not selected becomes selected while all selected text is deselected. |
| **/** | Searches the entire editing buffer for all occurrences of the selected text. Adds all matching text to the selection. Note that this command is not available when multiple selections currently exist. In this case, this command will have the same effect as entering the RETURN key. |
