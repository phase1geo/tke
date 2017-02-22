### View Menu

The View menu allows the user to change the interface as desired.  The following table lists the available menu items.

| Menu Item | Shortcut<br>(Mac) | Shortcut<br>(Other) | Description |
| - | - |
| Show/Hide Sidebar | Cmd-K | Ctrl-K | Shows or hides the sidebar panel. |
| Show/Hide Console | | | For operating systems that allow a Tcl/Tk console to be viewed, shows/hides this console window from view.  This menu item is only displayed if a console is available.  The console is mostly useful for TKE development purposes only. |
| Show/Hide Tab Bar | | | Shows or hides the tab bar. |
| Show/Hide Status Bar | | | Shows or hides the status bar at the bottom of the window. |
| Show/Hide Line Numbers | | | Shows or hides the line numbers in the current buffer. |
| Line Numbering / Absolute | | | Displays line numbers starting at 1 and incrementing by one to the end of the file. |
| Line Numbering / Relative | | | Displays the current line number as 0 and counts up above and below the current line. |
| Show/Hide Marker Map | | | Shows or hides the marker map in the text scrollbar region. |
| Show/Hide Meta Characters | | | Shows or hides any characters in the current edit tab that are syntax highlighted as “meta” characters.  Examples of meta characters would be formatting characters used in languages like Markdown. |
| Display Text Info | Cmd-T | Ctrl-T | Displays the current line count and character count for the current file in the information bar. |
| Split View | Ctrl-S | Ctrl-S | When selected, creates a second view into the current file.  Each view can be independently manipulated; however, any text modifications made in either window will be available in the other view.  Deselecting this menu option will return the file to only showing a single view of the file in the editor. |
| Bird’s Eye View | | | When selected, displays the bird’s eye view within each opened tab. Deselecting this option will hide the bird’s eye view in all opened tabs. |
| Move to Other Pane | Ctrl-M | Ctrl-M | Moves the current file to the other text pane.  If only one text pane is currently viewable, a second pane will be displayed to the right of the current pane and the file will be moved to that pane.  If a pane only contains the file that is being moved, that pane will be removed from view.  This allows two files to be viewed “side by side”. |
| Panes / Enable Synchronized Scrolling | | | When selected, synchronizes the scrolling of both panes to keep the displayed lines in alignment with one another when either pane is scrolled. |
| Panes / Align Panes | | | Causes the current line in both panes to align to each other horizontally. |
| Panes / Merge Panes | Ctrl-Alt-M | Ctrl-Alt-M | Merges all tabs in both panes into a single pane. |
| Tabs / Goto Next Tab | Ctrl-N | Ctrl-N | Changes the current file to be the file in the next tab in the current pane to the right of the current tab. |
| Tabs / Goto Previous Tab | Ctrl-P | Ctrl-P | Changes the current file to be the file in the next tab in the current pane to the left of the current tab. |
| Tabs / Goto Last Tab | Ctrl-L | Ctrl-L | Changes the current file to be the file in the last viewed tab in the current pane. |
| Tabs / Goto Other Pane | Ctrl-O | Ctrl-O | Changes the current keyboard focus to the current tab in the other pane.  This menu item is only available if both panes in viewable. |
| Tabs / Sort Tabs | | | Alphabetically sorts the tabs in the current pane. |
| Tabs / Hide Current Tab | | | Hides the current tab from view. |
| Tabs / Hide All Tabs | | | Hides all of the opened tabs from view. |
| Tabs / Show All Tabs | | | Displays all hidden tabs in the tabbar. |
| Folding / Enable Code Folding | | | Enables/disables code folding in the current editing buffer.  If this option is set to the enable state, the indentation mode dictates what type of code folding will be performed. (`OFF` = Manual, `IND` = Indentation-based, `IND+` = Syntax-based (if syntax doesn’t contain indent/unindent/reindent tokens, indentation-based code folding will be used)).
| Folding / Create Fold From Selection | | | When manual code folding mode is enabled, creates a new fold such that the selected code will be folded. |
| Folding / Delete Current Fold | | | When manual code folding mode is enabled, removes the fold indicator at the current cursor’s line. If the cursor is not on a fold indicator line, this command will be disabled. |
| Folding / Delete Selected Folds | | | When manual code folding mode is enabled, removes all opened/closed folds that are selected in the current editing buffer. |
| Folding / Delete All Folds | | | When manual code folding mode is enabled, deletes all of the folds in the current editing buffer. |
| Folding / Close Current Fold / One Level | | | Folds the code fold by one level on the cursor’s current line. |
| Folding / Close Current Fold / All Levels | | | Folds all levels of the code fold located at the cursor’s current line. |
| Folding / Close Selected Folds / One Level | | | Folds all selected folds by one level. |
| Folding / Close Selected Folds / All Levels | | | Folds all selected folds for all levels. |
| Folding / Close All Folds | | | Folds all of the code folds in the current editing buffer. |
| Folding / Open Current Fold / One Level | | | Unfolds the code fold by one level on the cursor’s current line. |
| Folding / Open Current Fold / All Levels | | | Unfolds all levels of the code fold located at the cursor’s current line. |
| Folding / Open Selected Folds / One Level | | | Unfolds all selected folds by one level. |
| Folding / Open Selected Folds / All Levels | | | Unfolds all selected folds for all levels. |
| Folding / Open All Folds | | | Unfolds all of the code folds in the current editing buffer. |
| Folding / Show Cursor | | | If the cursor is hidden inside of folded code, this command will unfold enough code folds to make the cursor visible. |
| Folding / Jump to Next Fold Mark | | | Moves the cursor to the next code fold indicator in the current editing buffer. |
| Folding / Jump to Previous Fold Mark | | | Moves the cursor to the previous code fold indicator in the current editing buffer. |
| Set Syntax | | | Changes the syntax highlighting and language-specific functionality to the specified language.  By default, the language is determined by file extension.  This menu allows the user to override the default behavior.  To permanently add an extension to a language syntax handler, you will need to modify the associated syntax file.  See the “Syntax Handling” chapter for more information about the structure of this file. Note: this menu option will not be shown on Mac OS X due to a system crash issue.  Please change the menu using either the command launcher or the language selector on the bottom right corner of the editing buffer. |
| Set Theme | | | Changes the current syntax coloring scheme to one of the available themes.  Setting the theme to this value will only be in effect while the application is running.  If the application is quit and restarted, the default theme as specified in the preferences will be used. |