### Starting up

When TKE is started, one of the startup tasks is to read the file contents contained in the TKE plugin directory.  This directory contains all of the TKE plugin bundles.

The plugin directory exists in both the TKE installation directory under the “plugins” directory along with the user's TKE home directory (i.e., .tke/iplugins).  Only
bundles in these two directories that are properly structured (as described later on in this chapter) are considered for plugin access.

Each plugin bundle is a directory that should contain at least the following files:

| File | Required | Description |
| - | - | - |
| header.tkedat | Yes | Contains plugin information that describes the plugin and is used by the plugin installer. |
| main.tcl | Yes | The main Tcl file that is sourced by the plugin installer.  This file must contain a call to the api\::register procedure.  In addition, this file should either contain the plugin namespace and action procedures or source one or more other files in the plugin bundle that contain the action code. |
| README.md | No | Optional file that should contain usage information about the plugin. This file is displayed as a read-only file in an editing buffer when the user selects an installed plugin with the “Plugin / Show Installed Plugins…” menu option. |

After the header.tkedat and main.tcl files are found and the header file is properly parsed, the header contents are stored in a Tcl array.  If a plugin bundle does not parse correctly, it is ignored and not made available for usage.

Once this process has completed, the TKE plugin configuration file is read.  This file is located at \~/.tke/plugins.tkedat.  If this file does not exist, TKE continues without error and its default values take effect.  If this file is found, the contents of this file are stored in a Tcl array within TKE.  Information stored in this file include which plugins the user has previously selected to use and whether the user has granted the plugin trust (note: trusted plugins are allowed to view and modify the file system and execute system commands) when the plugin was installed.

If a plugin was previously selected by a previous TKE session, the plugin file is included into a separate Tcl interpreter via the Tcl "source" command.  If there were any Tcl syntax errors in a given plugin file that are detectable with this source execution, the plugin is marked to be in error.  If no syntax errors are found in the file, the plugin registers itself with the plugin framework at this time.

The plugin registration is performed with the api\::register procedure.  This procedure call associates the plugin with its stored header information.  All of the plugin action types associated with the plugin are stored for later retrieval by the plugin framework.

Once all of the selected plugins have been registered, TKE continues on, building the GUI interface and performing other startup actions.

