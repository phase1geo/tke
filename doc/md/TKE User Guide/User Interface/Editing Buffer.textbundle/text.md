### Editing Buffer

The editing buffer provides the main source of editing functionality.  TKE supports two modes of editing functionality:  Vim mode and standard mode.  See the Vim chapter to see what functions are available when editing in this mode, the rest of this section will only mention functions available when the editor is not in Vim command mode (i.e., either Vim insert mode or standard mode).

Visually the editing buffer contains two basic UI elements:  the text editor pane and the scrollbars.

The text editor pane allows text to be read and modified. The following table specifies the different key and mouse bindings on the editor that the user can take advantage of.

| Key/Mouse Binding | Description |
| - | - |
| Left-mouse click | Sets insertion cursor just before the character underneath the mouse cursor.  Clears any selections.  If left-button is held while mouse is moved, selection is created between insertion cursor and under mouse cursor. |
| Left-mouse double click | Selects the word under the mouse and positions insertion cursor at the start of the word.  Holding mouse button while dragging will select all words between insertion cursor and mouse cursor. |
| Left-mouse triple click | Selects the entire line under the mouse.  Holding mouse button while dragging will select all lines between insertion line and mouse cursor line. |
| Shift + Left-mouse click + drag | Adjusts the end of the selection nearest the mouse cursor when the left button is pressed. |
| Shift + Left-mouse double click + drag | Adjusts the end of the selection nearest the mouse cursor in whole word units. |
| Shift + Left-mouse triple click + drag | Adjusts the end of the selection nearest the mouse cursor in line units. |
| Control + left-mouse click | Repositions the cursor without affecting the selection. |
| Middle-mouse click | Selection is copied into the text at the position of the mouse cursor. |
| Middle-mouse click + drag | Moves the current view of the text window. |
| Insert key | Inserts the current selection at the position of the insertion cursor. |
| Left/Right key | Moves the insertion cursor one position to the left/right and clears the selection. |
| Shift + left/right key | Moves the insertion cursor one position to the left/right and adds the character to the selection. |
| Control + left/right key | Moves the insertion cursor to the left/right by one word. |
| Shift + Control + left/right key | Moves the insertion cursor to the left/right by one word and adds the word to the selection. |
| Up/Down key | Moves the insertion cursor one line up/down and clears the selection. |
| Shift + up/down key | Moves the insertion cursor one line up/down, extending the selection. |
| Control + up/down key | Moves the insertion cursor by paragraphs (groups of lines separated by blank lines). |
| Shift + Control + up/down key | Moves the insertion cursor by paragraphs, extending the selection. |
| Next/Prior key | Moves insertion cursor forward/backward by one screenful of text and clears the selection. |
| Shift + next/prior key | Moves insertion cursor forward/backward by one screenful of text, extending the selection. |
| Control + next/prior key | Moves screen forward/backward by one screenful of text without affecting insertion cursor or selection. |
| Home key OR Control + ‘a’ key | Moves the insertion cursor to the beginning of its current line and clears any selection. |
| Shift + Home key | Moves the insertion cursor to the beginning of the line, extending the selection to that point. |
| Control + Home key | Moves the insertion cursor to the beginning of the text and clears the selection. |
| Shift + Control + Home key | Moves the insertion cursor to the beginning of the text, extending the selection. |
| End key OR Control + ‘e’ key | Moves the insertion cursor to the end of its current line and clears the selection. |
| Shift + End key | Moves the insertion cursor to the end of its current line, extending the selection to that point. |
| Control + End key | Moves the insertion cursor to the end of the text and clears the selection. |
| Shift + Control + End key | Moves the insertion cursor to the end of the text, extending the selection. |
| Control + ‘/‘ key | Selects all of the text. |
| Control + ‘\\’ key | Clears the selection. |
| Delete key | Deletes the selection (if one exists) or deletes the character to the right of the insertion cursor. |
| Backspace key | Deletes the selection (if one exists) or deletes the character to the left of the insertion cursor. |
| Control + ‘k’ key | Deletes from the insertion cursor to the end of the line.  If the insertion cursor is already at the end of the line, the newline character is deleted. |
| Control + ‘o’ key | Opens a new line by inserting a newline character in front of the insertion cursor without moving the insertion cursor. |
| Control + ‘+’ key | Increases the font size of the editor text by a size of one. |
| Control + ‘-‘ key | Decreases the font size of the editor text by a size of one. |
| File drag-drop | Inserts the contents of the file at the location of the cursor (which will follow the mouse cursor). |
| Text drag-drop | Inserts the selected text associated with the drag-drop operation at the location of the cursor (which will follow the mouse cursor). |
| Alt + Left mouse click | Adds a cursor to the multicursor list at the character under the mouse cursor.  Also makes the current cursor the anchor cursor. |
| Alt + Right mouse click | Adds one or more cursors between the anchor cursor and the current cursor such that one cursor will be placed on each line at the same column location as the anchor cursor. |
| Shift + Alt + Left mouse click + drag | Selects a column of text with the upper left corner of the selection starting at the button press position and the lower right corner ending at the button release position. |

On MacOS and WIndows, you can drag a file into the text editing area to insert the files contents into the editing buffer starting at the insertion cursor.  You can also drag and drop text into the editing buffer to just insert that text into the editing buffer.