## Importing Plugins

As of version 3.5, TKE has the ability to export user-created plugins in a file known as a TKE plugin bundle file which has the ".tkeplugz" extension. Once exported, this single file can be shared with other TKE users and imported into their local TKE setup. After a plugin has been imported, it then can be installed/uninstalled/etc. just like any other plugin in the user's system.

There are several ways to import a plugin.

First, if you are running on macOS, you can double-click the file to open it which will automatically cause TKE to launch and display a popup window which will ask for confirmation that the plugin should be installed. Answering in the affirmative will cause the plugin to be installed in your ~/.tke/iplugins directory.

Second, if drag and drop is enabled for TKE on installation (Windows and macOS should have built-in support for this while Linux requires the tkdnd package), you can import a plugin by dragging and dropping the file into the TKE window. This will cause the same import confirmation dialog to be displayed.

Third, you can select the `Plugins / Import...` menu option which will display a file browser where you can select the plugin bundle file to import.

Fourth, if you attempt to open a plugin bundle file via the `File / Open File...` menu option or open it via the command-line, TKE will display the import popup dialog instead of opening a tab with the file (the file is a compressed binary file so it cannot be viewed within a TKE editing tab).  