### File Menu

The File Menu contains commands that are related to either the currently selected file (i.e., the file in view within the editor which has the keyboard focus) or all files.  The following table describes the listed menu items and their associated functionality

| Menu Item | Shortcut<br>(Mac) | Shortcut<br>(Other) | Description |
| - | - |
| New Window | | | Launches a new TKE session window. |
| New File | Cmd-N | Ctrl-N | Creates a new, unnamed file in a new tab. |
| New From Template… | | | Creates a new file based on a previously saved template file. |
| Open File… | Cmd-O | Ctrl-O | Displays an open file dialog, allowing the user to select one or more files to open.  Each file will be opened in a separate tab in the editor.  Any directories containing these files that are not in the sidebar will be added to the sidebar. |
| Open Directory… | Shift-Cmd-O | Shift-Ctrl-O | Displays an open directory dialog, allowing the user to select one or more directories to add to the sidebar. |
| Open Remote… | | | Displays the remote file/directory dialog window which will allow you to connect to a remote file server via FTP/SFTP and select either a directory or a file to open. |
| Open Recent | | | Displays a list of directories and files that have been recently opened.  Click on a directory to add it to the sidebar.  Click on a file to open it in a separate tab in the editor. |
| Open Favorite | | | Displays the list of favorited files/directories for quick opening in either the editor (file) or sidebar (directory). |
| Reopen File | | | Reopens the current file for editing, destroying any unsaved changes. |
| Change Working Directory | | | Changes the current working directory. |
| Show File Difference | Cmd-D | Ctrl-D | Displays a new tab containing the current file in a difference view.  From within the view, the user can view file differences between any two versions of the given file (if managed by a version system) or between it and another file (using the diff utility). |
| Save | Cmd-S | Ctrl-S | Saves the contents of the current file to its original name.  If an original name does not exist for the content, a “Save As” dialog will be displayed allowing the user to specify a file name. |
| Save As… | Shift-Cmd-S | Shift-Ctrl-S | Displays a save file dialog window, allowing the user to save the current file contents to the given filename.  The original filename of the content will be changed to this new name. |
| Save As Remote… | | | Displays the remote file/directory dialog window to allow you to select a server, directory and filename to save the contents of the current editing buffer to via FTP/SFTP/WebDAV. |
| Save As Template… | | | Displays an entry field at the bottom of the window, allowing the current file to be saved as a template file under the given name. If you specify an extension to the template name, any new files based on this template will use the template’s extension for syntax highlighting purposes. |
| Save Selection As… | | | Saves only the currently selected text to a file without saving the current editing buffer. |
| Save All | | | Saves all files opened in the editor to their original file names.  Any files which do not have original names, will have a save file dialog window shown, allowing the user to specify the name. |
| Export… | Cmd-E | Ctrl-E | If the current editing buffer language is set to Markdown, this option will run the file contents through the Markdown parser, generating either HTML or XHTML output (the General/DefaultMarkdownExportExtension specifies the default extension to use for Markdown exporting but can be overridden in the save file dialog window).  Additionally, the user can embed snippet text within \<tke:ExportString\>\</tke:ExportString\> tags.  Any snippets will be generated at the time of export, replacing the tags and snippet text with the generated text. |
| Line Ending / Windows | | | Changes the line ending to use for the current file to CRLF when the file is saved. |
| Line Ending / Unix | | | Changes the line ending to use for the current file to LF when the file is saved. |
| Line Ending / Classic Mac | | | Changes the line ending to use for the current file to CR when the file is saved. |
| Rename | Shift-Cmd-R | Shift-Ctrl-R | Renames and/or moves the location of the current file in the file system. |
| Duplicate | Shift-Cmd-D | Shift-Ctrl-D | Creates a copy of the current file and immediately opens the file for editing. |
| Delete | Shift-Cmd-T | Shift-Ctrl-T | Deletes the current file from the file system and removes the tab from the editor. This option will be displayed if the “Use Move to Trash” general preference option is unset. |
| Move To Trash | Shift-Cmd-T | Shift-Ctrl-T | Moves the current file to the trash. This option will be displayed if the “Use Move to Trash” general preference option is set. |
| Lock/Unlock | Cmd-L | Ctrl-L | The “Lock” option will change the state of the editor to not allow text modifications to the window (content is effectively “Read Only”).  A small lock icon will be displayed in the associated tab to indicate that the file content is currently “locked”.  The “Unlock” option will change the state of the editor back to the modifiable state. |
| Favorite/Unfavorite | | | Marks the current file as a favorite (with the “Favorite” command) or removes the file as a favorite (with the “Unfavorite” command).  Favorited files can be opened quickly with the “Open Favorite” menu list or the command launcher.  Additionally, favorited files/directories can be used in the “Find in File” feature. |
| Close | Cmd-W | Ctrl-W | Closes the current tab.  If the text content is in the modified state (as indicated by the “\*” character in the tab), a prompt will be displayed asking the user if the content should be saved prior to closing. |
| Close All | Shift-Cmd-W | Shift-Ctrl-W | Closes all tabs in the editor.  If text content in a tab has been modified, a prompt will be displayed asking the user if the content should be saved prior to closing. |
| Quit | Cmd-Q | Ctrl-Q | Exits the application.  Any modified files in the editor will prompt the user if the content should be saved prior to exiting the application. |