## api::get\_plugin\_source\_directory

Returns the full pathname of the plugin's source file directory.

The contents of this directory should not be modified after it is installed on a user's system.  All file changes should be stored in the plugin data directory (accessible via the `api::get_plugin_data_directory`).  This is because the contents of this directory will be deleted/replaced when the plugin is updated.

**Call structure**

`api::get_plugin_source_directory`

**Return value**

Returns the full pathname of the source directory for the calling plugin.
