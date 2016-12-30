### Find Menu

The Find menu contains items for searching and, optionally, replacing text in the current file.  It also contains items that can add search text to the current selection and items for finding text in a group of files (regardless if they are currently opened in the editor or not).  The following table contains the items found in this menu along with the description of its functionality.

| Menu Item | Description |
| - | - |
| Find | Searches the current file for a given regular expression.  The displayed search bar also contains a checkbutton for specifying whether a case sensitive search should be performed or not and a checkbutton for saving the search input.  Using the up/down keys while the input is in the entry field will allow you to traverse the find history and previously saved searches.  Hitting the return key will cause all matches in the current file to be highlighted, the first match after the current cursor to be in view, and the cursor placed at the  beginning of the match. |
| Find and Replace | Searches the current file for a given regular expression and replaces it with an associated string.  The displayed search and replace bar also contains three checkbuttons:  one for specifying case sensitivity of the match, one for replacing the first match or all matches, and one for saving the search input.  Using the up/down keys will traverse Find/Replace history and previously saved searches.  Hitting the return key will perform the replacement. |
| Select Next Occurrence | Selects the next matched occurrence. |
| Select Previous Occurrence | Selects the previous matched occurrence. |
| Select All Occurrences | Selects all matched occurrences. |
| Append Next Occurrence | Adds the next matched occurrence to the selection. |
| Jump Backward | Jumps to the last cursor position that was more than 2 lines from the current cursor position.  The number of minimum lines can be adjusted in the preferences file. |
| Jump Forward | Jumps to the next cursor position. |
| Jump To Line | Displays a user input interface that allows the user to specify a line number to jump to.  Sets the cursor to the given line number and makes the insertion cursor visible. |
| Next Difference | If the current buffer is in difference mode, jumps to the next difference that is not currently in view.  If no difference exists below the current view, jumps to the first difference in the file. |
| Previous Difference | If the current buffer is in difference mode, jumps to the previous difference that is not currently in view.  If no difference exists above the current view, jumps to the last difference in the file. |
| Show Selected Line Change | If the current buffer is in difference mode and a line is currently selected, sets the first file version to the version that last modified the first line of the selection. |
| Markers / Create at Current Line | Sets a marker at the current insertion index. |
| Markers / Remove From Current Line | Clears the marker at the current insertion index if one exists. |
| Markers / Remove All Markers | Clears all markers in the current buffer. |
| Markers / _marker\_name_ | Jumps the cursor and file view to show the selected marker.  The cursor will be placed at the beginning of the marked line. |
| Find Matching Bracket | Jumps the cursor and file view to show the parenthesis, bracket or quotation mark that matches the parenthesis, bracket or quotation mark under the current cursor.  The cursor will be placed on the matched pair.  If the cursor is currently not on a parenthesis, bracket or quotation mark, this option will set the cursor to the previous indentation character (if one exists for the current language). |
| Find Next Bracket Mismatch | If there is a bracket mismatch after the current insertion cursor, selecting this option will place the insertion cursor on the mismatching curly bracket, square bracket, parenthesis or angled bracket. To enable bracket mismatch highlighting, enable the Editor/HighlightMismatchingChars preference item. |
| Find Previous Bracket Mismatch | If there is a bracket mismatch before the current insertion cursor, selecting this option will place the insertion cursor on the mismatching curly bracket, square bracket, parenthesis or angled bracket. To enable bracket mismatch highlighting, enable the Editor/HighlightMismatchingChars preference item. |
| Find In Files | Performs a regular expression search in a specified list of files/directories. The resulting list of matches are displayed in a read-only editing buffer allowing you to jump to matches by clicking on a match result. |
