### Plugins Menu

The Plugins menu contains items that allow third-party plugins to be installed, uninstalled and reloaded.  Additionally, if TKE is run in developer mode, provides a facility for creating a new plugin quickly.  The following table describes the items in this menu.

| Menu Items | Shortcut<br>(Mac) | Shortcut<br>(Other) | Description |
| - | - |
| Install… | Shift-Cmd-I | Shift-Ctrl-I | Allows new third-party plugins to be installed.  See the “Plugins” chapter for more information. |
| Uninstall… | Shift-Cmd-U | Shift-Ctrl-U | Allows third-party plugins to be uninstalled.  See the “Plugins” chapter for more information. |
| Show Installed… | Shift-Cmd-P | Shift-Ctrl-P | Displays a list of the currently installed plugins which includes plugin information. If a plugin is selected and that plugin contains a README.md file associated with the plugin, the information contained in that file will be opened in a read-only editing buffer, allowing you to view usage information about the selected plugin. |
| Reload | | | Reloads all installed plugins.  This is primarily useful when developing plugins.  This menu option allows plugins to be quickly reloaded without requiring the application to be quit and relaunched. |
| Create… | | | Development tool only. Creates the template for a new plugin and displays the file in the editor.  See the “Plugin Development” chapter for more details about how to create third-party plugins. |