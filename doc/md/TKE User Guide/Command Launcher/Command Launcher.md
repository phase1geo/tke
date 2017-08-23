# Command Launcher

The command launcher provides access to all of the available functionality from anywhere within the application.  To call up the launcher, simply hit the key combination (by default, the key combination is Control-Space but this can be changed within the menu bindings file).  The resulting widget is a simple entry field displayed in the upper center portion of the window.  The cursor will be placed within the entry field for immediate command entry.

To perform a command, simply begin typing the name of the command that you wish to perform.  As you enter characters, the command list will be immediately updated with the best matches.  The command launcher uses a fuzzy search algorithm for matching that remembers the most used commands based on the input string, allowing you to quickly perform most commands with only a few typed characters.

If one or more matches are found, the top-most entry will be the best match.  The best match will also be selected.  To execute the best match, simply enter the RETURN key.  To change the selection to another displayed match in the list, simply use the up/down arrow keys until the desired command is selected and hit the RETURN key.

The following table describes the types of commands that can be executed within the command launcher along with any special characters that call up specific functionality.

| Command Type | Description | Character Sequence
| - | - | - |
| Menu commands | Any menu item commands can be executed from within the launcher. | (Enter any portion of the menu command string) |
| Clipboard History | Inserts any of the items stored in the clipboard history into the current editor and/or copies the text into the clipboard. | #… |
| Snippet insertion | Inserts any of the language-specific snippets available for the current editor. | ;… |
| Symbol Jumping | Jump to any supported language symbol (i.e., procedure, function, etc.) in the current editor. | @… |
| Marker Jumping | Jump to any marker in the current editor. | ,… |
| Sidebar File Open | Open any shown file in the sidebar for editing. | \>… |
| Calculator | Perform numerical calculator expressions (any valid numerical Tcl expression is allowed).  Selected result is copied to the clipboard. | (Enter any valid Tcl calculation) |
| URL launcher | Open a specified URL in the local web browser or recall a previously used URL from history and open that location. | (Enter any valid URL) |
| URI launcher | Executes the given URI and stores the URI in its history for quickly performing the same function later on. (Ex. `dash://tcl.text` — opens the Dash application (if installed) and displays the documentation for the Tcl/Tk text widget). | (Enter any valid URI that is supported on your system). |
| Plugin installation | Displays all available plugins that can be installed.  Selecting a plugin in the resulting list installs the plugin. | install |
| Plugin uninstallation | Displays all available plugins that can be uninstalled.  Selecting a plugin in the resulting list uninstalls a plugin. | uninstall |
| Syntax modification | Changes the syntax highlighting rules for the current editor. | Enter a name of any supported language or `Syntax:` for a full list of all available languages.|
| Theme modification | Changes the syntax highlighting color scheme for all editors | Enter a name of any installed theme or enter `Theme:` for a full list of all available themes.|

In addition to the normal command launcher UI (entry field with a list of matching commands listed below), the command launcher also has a preview window that is available for a subset of functionality.  The preview window will be displayed below the entry field and to the right of the command list.  Highlighting a command in the command list will update the preview window.  The preview window is available for the following command launcher functions.

| Function | Displayed in Preview |
| - | - |
| Snippets | Raw snippet content from the snippet file. |
| Clipboard history | Full content for a paste item. |
| Plugin installations | Revision and description of the selected plugin. |

Additionally, you may move the location of the command launcher widget by grabbing any edge of the launcher and drag it to a new location.  If the associated preference value is set, the launcher will display in the new location each time that is invoked.  If the preference value is cleared, the launcher widget will display in the default location the next time it is invoked.

