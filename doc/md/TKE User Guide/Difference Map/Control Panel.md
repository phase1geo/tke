## Control Panel

The control panel is displayed just below the main file viewing area.  It provides the user a simple method of changing which versions of the given file are differenced in the main file viewing area.

On the left side of the control panel is the version system selection menu.  By default, TKE will attempt to automatically determine which version system is managing the file.  The following values are currently supported:

| System | Description |
| - | - |
| Mercurial | Uses the Mercurial version control system.  Select the first and second versions using the selectors in the control panel to change which versions are differenced. |
| Bazaar | Uses the Bazaar version control system.  Select the first and second versions using the selectors in the control panel to change which versions are differenced. |
| Git | Uses the Git version control system.  Select the first and second version using the selectors in the control panel to change which versions are differenced.  Versions are represented by their shortened SHA-1 values. |
| Perforce | Uses the Perforce version control system.  Select the first and second versions using the selectors in the control panel to change which versions are differenced. |
| Subversion | Uses the Subversion version control system.  Select the first and second versions using the selectors in the control panel to change which versions are differenced. |
| diff | Allows the user to perform a Unix diff of the current file and another file in the file system.  Simply enter the pathname of the file to compare to the file loaded in the main file viewing area to perform the difference. |
| custom | Allows the user to enter in a specific difference command to execute in the shell.  The output of the difference command must be in unified difference output format. |

**Note:**  If you have one of the above tools installed on your system, but TKE fails to identify which tool is to be used for the file, most likely the problem is that the tool is not in your environment’s binary path.  To fix this you can either add the directory to your PATH environment variable path (if you are starting TKE from the command-line) or use the preference General panel, select the Variables tab and set the PATH environment variable within the Variables table.  Once you have properly setup the PATH variable within the preferences panel, TKE should be able to (without a restart) find the proper tool that is managing the file.

To the right of the version system menu is either a group of version selectors (if the menu displays a file version system), a file entry box (if the menu displays the “diff” option), or a command entry box (if the menu displays the “custom” option).  Use these widgets to quickly display the desired difference.  By default, if TKE was able to automatically determine the version system being used, TKE will setup the selector widgets such that the first version is the last committed version and the second version is the current working copy of the file.  The main file viewing area will automatically display the difference information.  Whenever the user clicks on one of these widgets or changes the displayed version, an information window will be displayed just above the control panel displaying the logfile information of the current version in the widget.  A preference value exists that can allow the user to show/hide this information when versions are changed.  Changing the mouse/keyboard focus to another widget will hide this informational display from view.

To change the file versions, simply adjust the selector widgets to match the desired versions and click on the “Update” button that will be displayed on the right side of the control panel.  The file viewing area will only be modified after the “Update” button is clicked.  If the “Update” button is not available, it indicates that the output data in the main file viewer matches the current selections in the control panel.

