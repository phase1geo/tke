# Plugins

In addition to all of the built-in functionality that comes standard, TKE also provides a plugin API
which can allow development of new functionality and tools without needing to modify the source code.
TKE ships with a small set of these plugins which are located in the TKE installation directory under
the “plugins” directory.

Out of the box, plugins are not installed and available from within the tool; however, any plugin can
be installed, uninstalled or reloaded within TKE (no restart is required). This will save those plugin
settings to the user’s “plugin.dat” file in their ~/.tke directory. When TKE is exited and restarted,
any previously installed plugins will be installed on application start.

Plugins can interface to TKE in a variety of ways. Which interfaces are used is entirely up to the
developer of the plugin. Each plugin can create multiple interfaces into the tool to accomplish its
purposes. The following table lists the various ways that plugins can interface into TKE.

| Interface Type | Description |
| - | - |
| menu | Plugins can create an entire subdirectory structure under the “Plugins” menu. |
| tab | popups Create menu items within a tab’s popup menu. |
| sidebar | popups Create menu items within any of the sidebar’s popup menus. |
| application events | Plugins can be run at certain application events (i.e., on start, opening a file, closing a file, saving a file, receiving editor focus, on exit, etc.) |
| syntax highlighting descriptions | Provide a file containing a syntax highlighting description which is added to the built-in list of syntax highlighting schemes. |
