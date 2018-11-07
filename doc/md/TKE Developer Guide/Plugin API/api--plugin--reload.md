## api\::plugin::reload

Reloads the plugin within the application without restarting TKE.  This
function is useful if your plugin contains code which rewrites itself.
This will have the effect of re-sourcing the plugin code, allowing the
changed code to be executable immediately afterwards.

**Call structure**

`api::plugin::reload

**Return value**

None.
