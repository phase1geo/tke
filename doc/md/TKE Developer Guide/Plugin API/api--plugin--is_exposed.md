## api\::plugin::is_exposed

This function can be used to check if a given plugin is loaded and has an
exposed function of the given name available for call execution.

See the **exposed** action for more details on this functionality.

**Call structure**

`api::plugin::is_exposed plugin-name::proc-name`

**Return value**

Returns a value of 1 if the given plugin procedure is available to be
called by this plugin; otherwise, returns a value of 0.

**Parameters**

| Parameter | Description |
| - | - |
| plugin-name | The installed name of the plugin to check. |
| proc-name | The name of an exposed proc within the plugin. |
