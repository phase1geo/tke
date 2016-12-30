### Edit Menu

The Edit menu contains menu items that affect the contents within the current file.  The following table describes the items available within this menu.

| Menu Item | Description |
| - | - |
| Undo | Undoes the last change made to the file content.  Each file can have an unlimited number of items that can be undone.  Saving a file clears the undo stack for that file. |
| Redo | Re-applies the last undone change made to the file content.  Saving a file clears the redo stack for that file. |
| Cut | Deletes the selected text, copying the deleted content to the clipboard.  If no text is currently selected, the current line is deleted and sent to the clipboard. |
| Copy | Copies the selected text to the clipboard.  If no text is currently selected, the current line is copied to the clipboard. |
| Paste | Pastes the content in the clipboard, inserting the text before the insertion cursor.  The content is copied “as is”. |
| Paste and Format | Pastes the content in the clipboard, inserting the text before the insertion cursor.  The content is indented to fit into the current insertion point. |
| Select All | Selects all of the text in the current editor. |
| Vim Mode | When selected, changes the editing environment to use Vim-style interaction.  When deselected, changes the editing environment back to “normal” editing mode. |
| Toggle Comment | Detects the comment state of the current selection.  If the selected text is not commented out, places a line comment in front of any selected text in the current file.  If the selected text is commented out, the comments are removed from the selected lines.  If a selection does not exist, the current line (or lines, if multicursors are enabled) is commented/uncommented in a similar fashion. |
| Indentation / Indent | Indents the selected text by one level of indentation. |
| Indentation / Unindent | Unindents the selected text by one level of indentation. |
| Indentation / Format Text | Modifies either the selected text or the entire file content (depending on whether text is currently selected or not) to match the indentation in the current context. |
| Indentation / Indent Off | Turns indentation mode off for the current editor.  Hitting the ENTER key in the editing window will place the cursor in the first column of the next row. |
| Indentation / Auto-Indent | Turns auto-indentation mode on for the current editor.  Hitting the ENTER key in the editing window will place the cursor in the same column as the previous line’s starting character. |
| Indentation / Smart Indent | Turns smart indentation mode on for the current editor.  Hitting the ENTER key in the editing window will perform the proper indentation based on the current language and context.  If a character sequence is entered that completes an indentation, the character sequence will be adjusted to the proper indentation level. |
| Cursor / Move to First Line | Moves the cursor to the start of the first line of the file and adjusts the view so the cursor is visible. |
| Cursor / Move to Last Line | Moves the cursor to the start of the last line of the file and adjusts the view so the cursor is visible. |
| Cursor / Move to Next Page | Moves the cursor down by a single page and adjusts the view so the cursor is visible. |
| Cursor / Move to Previous Page | Moves the cursor up by a single page and adjusts the view so the cursor is visible. |
| Cursor / Move to Screen Top | Moves the cursor to the start of the line at the top of the current screen. |
| Cursor / Move to Screen Middle | Moves the cursor to the start of the line in the middle of the current screen. |
| Cursor / Move to Screen Bottom | Moves the cursor to the start of the line at the bottom of the current screen. |
| Cursor / Move to Line Start | Moves the cursor to the start of the current line. |
| Cursor / Move to Line End | Moves the cursor to the end of the current line. |
| Cursor / Move to Next Word | Moves the cursor to the beginning of the next word. |
| Cursor / Move to Previous Word | Moves the cursor to the beginning of the previous word. |
| Cursor / Move Cursors Up | In multicursor mode, moves all of the cursors up by one line. |
| Cursor / Move Cursors Down | In multicursor mode, moves all of the cursors down by one line. |
| Cursor / Move Cursors Left | In multicursor mode, moves all of the cursors to the left by one character. |
| Cursor / Move Cursors Right | In multicursor mode, moves all of the cursors to the right by one character. |
| Cursor / Align Cursors | When multicursors are set in the current file, this command will adjust each line such that all cursors will be aligned to the same column.  The cursors will be aligned to the highest column in the multicursor set. |
| Insert / Line Above Current | Inserts a blank line above the current line and places the cursor at the beginning of the blank line for editing. |
| Insert / Line Below Current | Inserts a blank line below the current line and places the cursor at the beginning of the blank line for editing. |
| Insert / File Contents | Prompts the user to select a file for insertion. If a file is selected, the entire contents of the file are inserted the line below the current line. |
| Insert / Command Result | Prompts the user to input a shell command. If a legal shell command is entered, the result of the command is inserted below the current line. |
| Insert / From Clipboard | Displays the command launcher in clipboard mode to allow the user to view and select one of the clipboard history elements to insert into the current editor. |
| Insert / Snippet | Displays the command launcher in snippet mode to allow the user to view and select one of the language-specific snippets to insert into the current editor. |
| Insert / Enumeration | When one or more multicursors are set, allows the user to insert ascending numerical values at each cursor insertion position. |
| Delete / Current Line | Deletes the current line and places the cursor at the beginning of the next line.  The deleted line is placed into the clipboard. |
| Delete / Current Word | Deletes the current word and places the cursor at the beginning of the next word.  The deleted word is placed into the clipboard. |
| Delete / Current Number | Deletes the current number and places the cursor just after the deleted text.  The deleted number is placed into the clipboard. |
| Delete / Cursor to Line End | Deletes all characters between the current cursor and the end of the line, placing the cursor on the character previous to the current character. |
| Delete / Cursor to Line Start | Deletes all characters between the start of the current line and up to (but not including) the current cursor. |
| Delete / Whitespace Forward | Deletes all consecutive whitespace (i.e., space and tab) characters from the current cursor towards the end of the current line. |
| Delete / Whitespace Backward | Deletes all consecutive whitespace characters from the current cursor towards the start of the current line. |
| Delete / Text Between Character | Displays an input field allowing a single character to be entered.  The character is searched for the first occurrence before the current cursor and the first occurrence after the current cursor. All characters between these two characters is deleted and placed in the clipboard. |
| Transform / Toggle Case | Toggles the case of the character at the current insertion cursor or of all selected characters. |
| Transform / Lower Case | Sets the case of the character at the current cursor or all selected characters to lower case. |
| Transform / Upper Case | Sets the case of the character at the current cursor or all selected characters to upper case. |
| Transform / Title Case | Sets the case of the character at the current cursor or all selected characters such that the first character of each word is capitalized while all other characters are placed into lower case. |
| Transform / Join Lines | If multiple lines are selected, joins all lines containing a selection are joined with a single space character into one line.  If no lines are selected, the line below the current line is joined to the current line. |
| Transform / Bubble Up | If multiple lines are selected, all selected lines are moved up by one line (the line above will be moved below the bubbled line(s)); otherwise, the current line is bubbled up one line. |
| Transform / Bubble Down | If multiple lines are selected, all selected lines are moved down by one line (the line below will be moved above the bubbled line(s)); otherwise, the current line is bubbled down by one line. |
| Transform / Replace Line With Script | If the current line contains an executable shell command, the command is executed and the resulting output replaces the current line. |
| Snippets / Edit User | Adds the user's global snippet file into the editor. |
| Snippets / Edit Language | Adds the user’s snippet file into the editor for the current language. |
| Snippets / Reload | Reloads the contents of the snippets for the current language and user.  Useful if the snippet file contents are not usable within the editor. |
| Templates / Edit | Opens an existing named template for editing. |
| Templates / Delete | Deletes an existing named template. |
| Templates / Reload | Reloads the names of the existing templates. |
| Emmet / Expand Abbreviation | Expands the Emmet abbreviation syntax that is found to the left of the cursor (i.e., cursor must be placed on the right side of the abbreviation for proper expansion to occur). |
| Emmet / Edit Custom Abbreviations | Displays the custom Emmet abbreviation file in a new editing buffer allowing the user to change, remove or add custom Emmet syntax to their liking. Saving the editing buffer will cause the file changes to go into effect immediately. |
| Preferences / Edit User - Global | Displays the user’s global (cross-language) preferences in an editor tab.  Saving changes made to this tab will immediately update the environment without restarting. |
| Preferences / Edit User - Language | Displays the user’s current language preferences in an editor tab.  Saving changes made to this tab will immediately update the environment without restarting. |
| Preferences / Edit Session - Global | Displays the current session’s global (cross-language) preferences in an editor tab.  This option will only be available if a named session is currently opened (see Session menu for details).  Saving changes made to this tab will immediately update the environment without restarting. |
| Preferences / Edit Session - Language | Displays the current session's current language preferences in an editor tab.  This option will only be available if a named session is currently opened.  Saving changes made to this tab will immediately update the environment without restarting. |