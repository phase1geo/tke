## api::plugin::exec_exposed

This function can be used to call an exposed plugin procedure.  This API
call will first check to make sure that the given plugin procedure
exists as an exposed procedure.  If it exists, it will call that procedure
with the given arguments.  If there was an returned error in the
call, a value of -1 will be returned; otherwise, the return value from
calling the exposed proc will be returned.

See the **exposed** action for more details on this functionality.

**Call structure**

`api::plugin::exec_exposed plugin-name::proc-name ?args?`

**Return value**

If there was an returned error in the call, a value of -1 will be returned;
otherwise, the return value from calling the exposed proc will be
returned.

**Parameters**

| Parameter | Description |
| - | - |
| plugin-name | The installed name of the plugin to check. |
| proc-name | The name of an exposed proc within the plugin. |
| args | Zero or more arguments to pass to the plugin proc. |
