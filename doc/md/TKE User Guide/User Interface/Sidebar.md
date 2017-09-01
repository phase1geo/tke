## Sidebar

The sidebar is located on the left side of the window.  It contains a tree-like view of one or more root directories (any directory in a file system can be a TKE root directory), subdirectories and files.  By default, whenever a file is opened within TKE, the file’s directory is automatically added to the sidebar.  Additionally, the user can open a directory via the “File” menu which is added to the sidebar.  This sidebar view allows the user to quickly open other files that are within the same directory without having to navigate through an open dialog box.  You may also add a directory to the sidebar by dragging and dropping the directory onto the sidebar.  When you have a valid directory dragged into the sidebar, the sidebar border color will turn green to indicate that the item may be dropped.

In addition to being able to quickly open files from the sidebar, several other functions are provided for each type of directory and file.  The following subsections identify the different types and their associated functionalities.  To access the menu of functionality for a given type, simply right-click on an item in the sidebar.  This will display a contextual menu listing the available commands.

Whenever you open a remote file or directory (via the **File / Open Remote…**) menu option, the associated directory will be displayed in the sidebar alongside local directories.  You may perform most of the same operations on remote files that you can with local files with the exception that you may not view difference information.

To hide or show a level of directory hierarchy, left-click on the disclosure triangle next to the directory to show/hide.  Alternatively, you may use the space bar or return key to toggle the disclosure state.  You may also use the left/right keys to specifically close or disclose directory information.

To open a selected file when the sidebar has keyboard input focus, hit the `space` or `return` key. To close a selected file when the sidebar has keyboard input focus, hit the `backspace` key.

To operate on more than one file, you can select multiple files or directories by holding Control or Command while left-clicking and then right-click to display the contextual menu.  Note that TKE will keep you from selecting both files and directories (whichever type the first selection is determines what will be allowed to be selected).

Files within the sidebar can be automatically filtered out of the sidebar via the **Sidebar / Hiding** preference items.  Any files that match any of these patterns will not be displayed in the sidebar.  This is useful for de-cluttering the sidebar with files that cannot be edited within TKE (i.e. object files, image files, etc.)

Files and directories are added in alphabetical order.  If you would prefer to have all folders be listed first, followed by all of the files within the same directory, you can specify that in the View preferences pane.
