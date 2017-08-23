### Plugin management

At any time after initial startup time, the user may install/uninstall plugins via the Plugins menu or the command launcher.  If a plugin is installed, the associated plugin file is sourced.  If there are any errors in a newly sourced plugin, the plugin will remain in the uninstalled state.  If the plugin is uninstalled, its associated namespace is deleted from memory and any hooks into the UI are removed.

Once a plugin is installed or uninstalled, the status of all of the plugins is immediately saved to the plugin configuration file (if no plugin configuration file exists in the current directory, it is created).