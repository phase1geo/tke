## api::get\_plugin\_data\_directory

Returns the full pathname of the plugin's data directory.  Within this directory, a plugin may put any user-specific files that need to exist when the application is exited.

The contents of this directory are not changed when the related plugin is updated, installed or uninstalled.

**Call structure**

`api::get_plugin_data_directory`

**Return value**

Returns the full pathname of the data directory for the calling plugin.
