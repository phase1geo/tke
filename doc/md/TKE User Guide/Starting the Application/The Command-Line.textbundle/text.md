## The Command-Line

For Unix-based systems that support a terminal, you can invoke TKE using the command-line.  To make tke easier to use, it is recommended that you add the TKE installation’s bin directory into your environment path variable (see your shell’s documentation for how to do this as this will be different for different OS types as well as shells).

Next, if you want TKE to always use just one window for editing all files, make sure that your xhost is setup correctly.  If you get a new TKE window every time you open a file in the terminal, it is likely that you have an xhost issue.

Assuming that you have added the TKE installation bin directory to your path, invoking TKE is as simple as typing the following at the shell prompt:

`tke`

If this is the first time that the application has been started, this will create a single TKE window with no tabs opened and an empty sidebar.  If the application is not currently running, this will start the application and load the last TKE session information into the application, including the following information:

- Window dimensions and location
- Previously opened files when the application last exited
- Sidebar entries
- Current tab of previous session will be the current tab of this session

If TKE is already running, this command will simply bring the application to the foreground of the desktop.

This, however, is not the only way of starting the application from the command-line, you can also specify any number of directories and/or files as arguments to TKE.  Any directories specified will be added to the sidebar while any specified files will be opened in new tabs in the editor and their respective directories will be added to the sidebar (if they don’t already exist).

In addition to files and directories, the following options are also available on the command-line invocation.

| Option | Description |
| - | - |
| -h | Displays command-line usage information to standard output and exits immediately. |
| -v | Displays tool version information to standard output and exits immediately. |
| -nosb | Starts the UI without the sidebar being displayed. |
| -e | Exits the application when the last tab is closed (overrides preference setting) |
| -m | Creates a minimal editing environment (overrides preference settings) |
| -n | Opens a new window without attempting to merge with an existing window. |
| -s _session\_name_ | Starts a new session with (if a window does not exist) or switches the current window to a previously saved session specified with _session\_name_. |



