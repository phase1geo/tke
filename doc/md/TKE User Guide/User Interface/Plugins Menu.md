### Plugins Menu

The Plugins menu contains items that allow third-party plugins to be installed, uninstalled and reloaded.  Additionally, if TKE is run in developer mode, provides a facility for creating a new plugin quickly.  The following table describes the items in this menu.

| Menu Items | Shortcut<br>(Mac) | Shortcut<br>(Other) | Description |
| - | - |
| Install… | Shift-Ctrl-I | Shift-Ctrl-I | Allows new third-party plugins to be installed.  See the “Plugins” chapter for more information. |
| Uninstall… | Shift-Ctrl-U | Shift-Ctrl-U | Allows third-party plugins to be uninstalled.  See the “Plugins” chapter for more information. |
| Show Installed… | Shift-Ctrl-P | Shift-Ctrl-P | Displadys a list of the currently installed plugins which includes plugin information. If a plugin is selected and that plugin contains a README.md file associated with the plugin, the information contained in that file will be opened in a read-only editing buffer, allowing you to view usage information about the selected plugin. |
| Create… | | | Development tool only. Creates the template for a new plugin and displays the file in the editor.  See the “Plugin Development” chapter for more details about how to create third-party plugins. |
| Import... | | | Displays a file picker window that will allow you to browse your filesystem for a plugin package to import.  TKE plugin packages will have a `.tkeplugz` extension. |
| Export... | | | Development tool only.  Exports the plugin associated with the currently selected editing tab.  A form window will be displayed, allowing the plugin developer to specify the save location of the plugin bundle along with changing the plugin version number and creating optional release notes.  Clicking on the `Export` button will create the plugin bundle. |
| Show plugins directory in sidebar | | | Development tool only.  Selecting this menu option will add the local plugin directory (i.e., the user's `~/.tke/iplugins` directory) to the sidebar to allow quick access to editing/viewing plugin code found there. |
| Reload | | | Reloads all installed plugins.  This is primarily useful when developing plugins.  This menu option allows plugins to be quickly reloaded without requiring the application to be quit and relaunched. |