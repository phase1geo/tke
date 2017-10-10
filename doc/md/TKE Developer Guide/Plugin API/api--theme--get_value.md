## api::theme::get\_value

The `api::theme::get_value` allows the plugin to get theme information about the current theme. This procedure takes two arguments: the category and name of the option to retrieve. These parameter correspond to the same strings displayed in the theme editor. This method can be useful if your plugin is attempting to colorize widgets to match the current theme.

**Call structure**

`api::theme::get_value category name`

**Return value**

Returns the associated theme value if one exists; otherwise, returns an error.

**Parameters**

| Parameter | Description |
| - | - |
| category | The name of the theme option category to refer to. This is the same string value used in the theme editor category sidebar. |
| name | The name of the theme option within the category to retrieve. |

**Example**

```Tcl
# Get the background color used in an editing buffer
set bgcolor [api::theme::get_value syntax background]
```