## api\::plugin\::load\_variable

Retrieves the value of the named variable from non-corruptible memory (from a previous save\_variable call).

**Call structure**

`api::plugin::load_variable index name`

**Return value**

Returns the saved value of the given variable.  If the given variable name does not exist, an empty string will be returned.
  
**Parameters**

| Parameter | Description |
| - | - |
| index | Unique index provided by the plugin framework (passed to the readplugin action command). |
| name | Name of a variable to retrieve the value for. |

