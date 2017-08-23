# Application Settings

There are a number of files/directories that are created by TKE at application startup, during execution and at application exit.  The following is a list of this application data:

- Emmet aliases
- Favorited files/directories
- Command launcher data
- Preferences
- Installed plugins
- Saved sessions data and preferences
- User and language snippets
- Saved file templates
- Imported themes
- Remote file settings

These files have historically been saved in the user’s home directory in the .tke directory.  As of version 2.7, TKE now has the ability to save these files in either the \~/.tke directory or another directory, called from this point on as the “share directory”, which can be any directory accessible from the file system (but preferably in an automatically sync’ed directory like Dropbox, iCloud Drive, Google Drive, OneDrive, etc.)  Placing files in a shared directory allows the application files to be shared between different computers which can access the shared directory.  Additionally, if any computer setup to use the shared directory makes a change to this directory, other computers will see these changes when they are started.

In addition to specifying a share directory, you can also specify where each of the above items will be stored.  If an items files/directories are stored in the user’s home directory, any updates to those files will remain local to the machine and will not be seen by machines who are using the share directory.  However, if an item is being shared then any changes made to that item will be seen by other sharers.