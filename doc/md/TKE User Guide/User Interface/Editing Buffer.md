### Editing Buffer

The editing buffer provides the main source of editing functionality.  TKE supports two modes of editing functionality:  Vim mode and standard mode.  See the Vim chapter to see what functions are available when editing in this mode, the rest of this section will only mention functions available when the editor is not in Vim command mode (i.e., either Vim insert mode or standard mode).

Visually the editing buffer contains two basic UI elements:  the text editor pane and the scrollbars.

The text editor pane allows text to be read and modified. The following table specifies the different key and mouse bindings on the editor that the user can take advantage of.

| Key/Mouse Binding | Description |
| - | - |
| Left-mouse click | Sets insertion cursor just before the character underneath the mouse cursor.  Clears any selections.  If left-button is held while mouse is moved, selection is created between insertion cursor and under mouse cursor. |
| Left-mouse double click | Selects the word under the mouse and positions insertion cursor at the start of the word. |
| Left-mouse triple click | Selects the entire line under the mouse. |
| Shift + Left-mouse click + drag | Adjusts the end of the selection nearest the mouse cursor when the left button is pressed. |
| Shift + Left-mouse double click + drag | Adjusts the end of the selection nearest the mouse cursor in whole word units. |
| Shift + Left-mouse triple click + drag | Adjusts the end of the selection nearest the mouse cursor in line units. |
| Control + left-mouse click | Repositions the cursor without affecting the selection. |
| Control + left-mouse double click | Selects the sentence under the mouse cursor. |
| Control + left-mouse triple click | Selects the paragraph under the mouse cursor. |
| Shift + Control + left-mouse double click | Selects the text within the closest matching brackets or string or comment. |
| Shift + Control + left-mouse triple click | Selects the text within the closest XML/HTML node. |
| Insert key | Inserts the current selection at the position of the insertion cursor. |
| Left/Right key | Moves the insertion cursor one position to the left/right and clears the selection. |
| Up/Down key | Moves the insertion cursor one line up/down and clears the selection. |
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
| Alt + Left mouse click + drag | Selects a column of text with the upper left corner of the selection starting at the button press position and the lower right corner ending at the button release position. |

#### Auto-disabling of syntax highlighting

Normally, syntax highlighting is applied to the displayed text when the file is first opened and whenever it is edited; however, in certain situations TKE will omit syntax highlighting when it detects that the file's structure will cause major performance issues when attempting to render the text (i.e., when a single line in the file exceeds a certain character threshold). If syntax highlighting is disabled for a file, some functions will also be disabled, including code folding support, bracket matching/auditing, etc. This file check is only performed when a file is initially opened or after the file is reopened via the `File` menu.