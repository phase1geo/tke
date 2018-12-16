## api::get\_home\_directory

This procedure returns the full pathname to the plugin-specific home directory.  If the directory does not currently exist, it will be automatically created when this procedure is called.  The plugin-specific home directory exists in the user’s TKE home directory under \~/.tke/plugins/name\_of\_plugin.  This directory will be unique for each plugin so you may store any plugin-specific files in this directory.

**Call structure**

`api::get_home_directory`

**Return value**

Returns the full pathname to the plugin-specific home directory.