### Directory

A non-root directory is any directory in the sidebar which has a parent directory associated with it (i.e., any directory in the sidebar that is not a root directory).

The following image depicts the sidebar with a non-root directory highlighted.

![][image-1]

The following table lists the available contextual menu functions available for non-root directories.

| Menu Item | Description |
| - | - |
| New File | Adds a new file to the directory in both the sidebar and the file system.  If this menu item is selected, an entry field at the bottom of the window displayed, allowing the user to specify a filename for the new file.  Entering a name and hitting the RETURN key will create the new file in the directory and open the file in the editor. |
| New File From Template | Opens a new file to the selected directory in an editing buffer. A prompt for a filename will be displayed at the bottom of the main window. After a name is entered and the RETURN key pressed, a list of available templates will be displayed. Selecting a template will create the new tab, insert the text, and perform any snippet substitutions. |
| New Directory | Adds a new directory under the selected directory in both the sidebar and the file system.  If this menu item is selected, an entry field at the bottom of the window is displayed, allowing the user to specify a name for the directory.  Entering a name and hitting the RETURN key will create the new directory. |
| Open Directory Files | Opens all shown files that are within the directory. |
| Close Directory Files | All open files in the editor that exist within the directory and below it will be closed.  Any files which require a save will prompt the user to save or discard the file modifications. |
| Hide Directory Files | Hides all opened file tabs within the selected directory in the tabbar.  Useful for focused workflows. |
| Show Directory Files | Shows all hidden tabs in the tabbar whose associated files exist within the selected directory. |
| Copy Pathname | Copies the selected directory pathname to the clipboard. |
| Rename | Renames the directory in the file system.  The current full pathname will be specified in an entry field at the bottom of the application window.  Once filename editing is complete, hit the RETURN key to cause the rename to occur.  Hit the ESCAPE key to cancel the renaming operation. |
| Delete | Deletes the directory from the filesystem and removes the directory from the sidebar.  If this item is selected, an affirmation prompt will be displayed to confirm or cancel the deletion. This option will be displayed if the “Use Move to Trash” general preference option is unset. |
| Move to trash | Moves the selected directories to the trash. Directories will be moved without a user prompt. This option will be displayed if the “Use Move to Trash” general preference option is set. |
| Favorite/Unfavorite | Marks the selected directory to be a favorite (if the Favorite command is selected) or removes it from the favorites list (if the Unfavorite command is selected).  Favorited directories can be quickly added to the sidebar via the File / Open Favorite menu or the command launcher. |
| Remove from Sidebar | Removes the directory from the sidebar (no modification to the file system will take place).  If this item is selected, the entire directory is removed from the sidebar. |
| Remove Parent from Sidebar | Removes all parent directories of the selected directory from the the sidebar and makes the selected directory a root directory in the sidebar. |
| Make Current Working Directory | Changes the current working directory to the selected directory.  Selecting this item will make all file operations within the editor relative to the selected directory.  Additionally, the working directory information in the title bar will be updated to match this directory. |
| Refresh Directory Files | Updates the sidebar contents for the selected directory. |

After these functions will be listed any directory popup menu items that are added via plugins.  See the Plugins and Plugin Development chapters for how to create these plugin types.

[image-1]:	assets/DraggedImage.png