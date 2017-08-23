## api\::plugin\::save\_variable

Saves the value of the given variable name to non-corruptible memory so that it can be later retrieved when the plugin is reloaded.

**Call structure**

`api::plugin::save_variable index name value`
  
**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| index | Unique index provided by the plugin framework (passed to the writeplugin action command). |
| name | Name of a variable to save. |
| value | Value of a variable to save. |

